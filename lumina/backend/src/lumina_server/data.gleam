//// **Lumina > Server >**
//// # Data
////
//// Module for managing both persistent and runtime data, both globally and more local data kinds.

// Lumina/Peonies
// Copyright (C) 2018-2026 MLC 'Strawmelonjuice' Bloeiman and contributors.
//
// This software is licensed under the European Union Public Licence (EUPL) v1.2.
// You may not use this work except in compliance with the Licence.
// You may obtain a copy of the Licence at: https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12
//
// AI TRAINING NOTICE: Rights for TDM and AI training are EXPRESSLY RESERVED
// under Art 4(3) Dir 2019/790. AI training constitutes a Derivative Work.
// See LICENCE file in the repository root for full details.
//
//
// This software is provided "AS IS", WITHOUT WARRANTY OF ANY KIND.
// See the Licence for the specific language governing permissions and limitations.

// Imports
import argus
import gleam/bit_array
import gleam/bool
import gleam/erlang/process
import gleam/option.{Some}
import gleam/order
import gleam/otp/actor
import gleam/otp/supervision
import gleam/result
import gleam/string
import gleam/time/duration
import gleam/time/timestamp.{type Timestamp}
import group_registry
import logging
import lumina_server/config
import lumina_server/data/sql
import pog
import rasa/queue.{type Queue}
import rasa/table.{type Table}
import witness

// Globals ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
pub type Globals {
  Globals(
    sessions: SessionsStore,
    app_registries: #(
      group_registry.GroupRegistry(GlobalMessage),
      group_registry.GroupRegistry(SessionMessage),
    ),
    postgres_pool_name: process.Name(pog.Message),
  )
}

/// Messages sent between either server components or from the server to it's components.
pub type GlobalMessage {
  /// Broadcasts the creation of a new user globally, for now this has no use.
  NewUser(id: BitArray)
}

/// Messages sent between components --or sent from the server to it's components-- within a specific session.
pub type SessionMessage {
  SessionAuthorized
}

pub fn initialise_global_context(
  postgres_pool_name postgres_pool_name: process.Name(pog.Message),
) -> Globals {
  let sessions: SessionsStore = {
    SessionsStore(
      table: table.new()
        |> table.with_kind(table.Set)
        |> table.with_access(table.Public)
        |> table.build,
      cleanup_queue: queue.new()
        |> queue.with_access(table.Public)
        |> queue.build,
    )
  }

  let app_registries = {
    let assert Ok(actor.Started(data: global_app_registry, ..)) =
      group_registry.start(process.new_name("global-app-registry"))
    let assert Ok(actor.Started(data: session_app_registry, ..)) =
      group_registry.start(process.new_name("session-app-registry"))
    #(global_app_registry, session_app_registry)
  }
  Globals(sessions:, app_registries:, postgres_pool_name:)
}

// Sessions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/// Stored sessions and a queue to delete them.
pub opaque type SessionsStore {
  SessionsStore(table: Table(String, SessionData), cleanup_queue: Queue(String))
}

/// Session data
pub type SessionData {
  SessionData(csrf_token: String, created_at: Timestamp)
}

const session_janitor_delay = 50_000

/// Cleans up sessions older than 12 hours.
pub fn session_janitor(
  sessions: SessionsStore,
) -> supervision.ChildSpecification(process.Subject(Nil)) {
  let name: process.Name(Nil) = process.new_name("session janitor")
  use <- supervision.worker()
  let inner =
    actor.new(Nil)
    |> actor.named(name)
    |> actor.on_message(fn(state, msg) {
      witness.set_process_fields([witness.string("Process", "Session Janitor")])
      assert msg == Nil
      witness.this(logging.Info, "Session janitor check in progress", [])

      case
        queue.first(sessions.cleanup_queue)
        |> result.try(fn(checked) { table.lookup(sessions.table, checked.1) })
      {
        Ok(SessionData(csrf_token: _, created_at:)) -> {
          use <- bool.lazy_guard(
            {
              {
                timestamp.difference(created_at, timestamp.system_time())
                |> duration.compare(duration.hours(12))
              }
              // Must be Less-than 12 hours old.
              == order.Lt
            },
            fn() { process.sleep(session_janitor_delay) },
          )
          // Not Less-than 12 hours old means cleanup time!
          let assert Ok(session_id) = queue.pop(sessions.cleanup_queue)
          case table.delete(sessions.table, session_id) {
            Error(Nil) -> {
              witness.this(
                logging.Warning,
                "Could not clean up expired session",
                [
                  witness.string("session id", session_id),
                ],
              )
            }
            Ok(_) -> {
              witness.this(logging.Info, "Cleaned up expired session", [
                witness.string("session id", session_id),
              ])
              process.sleep(session_janitor_delay)
            }
          }
          witness.this(logging.Info, "Session janitor check ended.", [])
        }
        Error(_) -> {
          witness.this(
            logging.Info,
            "Session janitor found no sessions yet. Waiting longer before next check.",
            [],
          )
          process.sleep(session_janitor_delay)
        }
      }

      process.sleep(session_janitor_delay)
      actor.send(process.named_subject(name), Nil)
      actor.continue(state)
    })
    |> actor.start()
  actor.send(process.named_subject(name), Nil)
  inner
}

pub fn get_csrf_for_session(session_store: SessionsStore, session_id: String) {
  use value <- result.map(table.lookup(session_store.table, session_id))
  value.csrf_token
}

pub fn csrf_create_session(
  session_store: SessionsStore,
  session_id: String,
  csrf_token: String,
) {
  use _ <- result.try(queue.push(session_store.cleanup_queue, session_id))
  table.insert_new(
    session_store.table,
    session_id,
    SessionData(csrf_token:, created_at: timestamp.system_time()),
  )
}

// Postgres interaction ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

/// Actor managing the Postgres database pool in the background.
/// Supervised by main process.
pub fn db_child(pool_name: process.Name(pog.Message)) {
  let db_url = config.database_url()
  case pog.url_config(pool_name, db_url) {
    Ok(config) -> config
    Error(_) -> {
      witness.this(
        logging.Critical,
        "Database url could not be parsed properly.",
        [witness.string("database url", db_url)],
      )
      panic
    }
  }
  |> pog.pool_size(25)
  |> pog.supervised
}

// Users ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

/// Encodes a public key into a `did:lumina: ...` DID, allowing it to be a unique identifyer over the larger federated
/// Lumina network.
pub fn pk_ldid_encode(pubkey pk: BitArray) -> String {
  "did:lumina:" <> bit_array.base64_url_encode(pk, False)
}

/// Decodes a `did:lumina: ...` DID to the public key used to create it.
pub fn pk_ldid_decode(lumina_did ldid: String) -> Result(BitArray, Nil) {
  case ldid {
    "did:lumina:" <> base64_url -> {
      bit_array.base64_url_decode(base64_url)
    }
    _ -> Error(Nil)
  }
}

// User sessions
pub type UserSessionAuthError {
  UserSessionAuthNotExists
  UserSessionAuthHasIncorrectDid
  UserSessionAuthNoMatch
  UserSessionAuthDBError
  UserSessionAuthArgon2Error
}

/// Given a session id and basic username-password credentials, creates a UserSession in the database and then returns
/// the logged in users' information.
pub fn user_session_authorise(
  postgres_pool_name postgres_pool_name: process.Name(pog.Message),
  session_id session_id: String,
  identifyer identifyer: String,
  password password: String,
) {
  let conn = pog.named_connection(postgres_pool_name)
  use id <- result.try(case identifyer, string.contains(identifyer, "@") {
    email, True -> {
      case sql.local_user_id_by_email(conn, email) {
        Ok(pog.Returned(count: 1, rows: [sql.LocalUserIdByEmailRow(id)])) ->
          id
          |> Ok
        Ok(pog.Returned(count: 0, rows: [])) -> Error(UserSessionAuthNotExists)
        Ok(pog.Returned(count: _, rows: _)) -> Error(UserSessionAuthDBError)
        Error(_) -> Error(UserSessionAuthDBError)
      }
    }
    "did:lumina:" <> _, _ ->
      pk_ldid_decode(identifyer)
      |> result.replace_error(UserSessionAuthHasIncorrectDid)

    username, _ -> {
      case sql.local_user_id_by_username(conn, username) {
        Ok(pog.Returned(count: 1, rows: [sql.LocalUserIdByUsernameRow(id)])) ->
          id
          |> Ok
        Ok(pog.Returned(count: 0, rows: [])) -> Error(UserSessionAuthNotExists)
        Ok(pog.Returned(count: _, rows: _)) -> Error(UserSessionAuthDBError)
        Error(_) -> Error(UserSessionAuthDBError)
      }
    }
  })
  use password_hashed <- result.try(
    case sql.password_hash_for_userid(conn, id) {
      Ok(pog.Returned(
        count: 1,
        rows: [sql.PasswordHashForUseridRow(password: Some(hashed))],
      )) -> Ok(hashed)
      // We just fetched their id, so if this returns an error in any way,
      // it's a database error.
      _ -> Error(UserSessionAuthDBError)
    },
  )
  use match <- result.try(
    user_password_hash_verify(password_hashed:, password_humane: password)
    |> result.replace_error(UserSessionAuthArgon2Error),
  )
  use <- bool.guard(!match, Error(UserSessionAuthNoMatch))
  todo as "On successful authorization"
}

fn user_password_hash_gen(password_humane: String) {
  use hashes <- result.map({
    argus.hasher_argon2i()
    |> argus.hash(password_humane, argus.gen_salt())
  })
  hashes.encoded_hash
}

fn user_password_hash_verify(
  password_hashed password_hashed: String,
  password_humane password_humane: String,
) {
  argus.verify(password_hashed, password_humane)
}
