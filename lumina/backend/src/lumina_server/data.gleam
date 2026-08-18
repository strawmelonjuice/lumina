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

// Imports ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
import argus
import envoy
import gleam/bit_array
import gleam/bool
import gleam/crypto
import gleam/erlang/charlist
import gleam/erlang/process.{type Timer}
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/otp/supervision
import gleam/pair
import gleam/result
import gleam/string
import group_registry
import lumina_server/async_crypto
import lumina_server/config
import lumina_server/data/sql
import pog
import rasa/table.{type Table}
import simplifile
import witness
import youid/uuid

const hour = 3_600_000

// Globals ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
pub type Globals {
  Globals(
    secrets: GlobalSecrets,
    sessions: Table(String, SessionData),
    global_app_registry_name: process.Name(
      group_registry.Message(GlobalMessage),
    ),
    session_app_registry_name: process.Name(
      group_registry.Message(SessionMessage),
    ),
    postgres_pool_name: process.Name(pog.Message),
    datamgr: process.Subject(DataManagerMessage),
  )
}

pub fn establish_globals(
  db_pool_name db_pool: process.Name(pog.Message),
  data_manager_name datamgr_name: process.Name(DataManagerMessage),
  global_app_registry_name global_app_registry_name: process.Name(
    group_registry.Message(GlobalMessage),
  ),
  session_app_registry_name session_app_registry_name: process.Name(
    group_registry.Message(SessionMessage),
  ),
) -> Globals {
  let sessions =
    table.new()
    |> table.with_kind(table.Set)
    |> table.with_access(table.Public)
    |> table.build
  let secrets =
    GlobalSecrets(cookie_secret: {
      let secretfile = absname_join(data_dir(), "./session-cookie-secret")
      case
        simplifile.read(secretfile)
        |> result.map_error(Some)
        |> result.try(fn(string) {
          string.split_once(string, "\n") |> result.replace_error(None)
        })
        |> result.map(pair.second)
        |> result.try(fn(string) {
          bit_array.base64_decode(string)
          |> result.replace_error(None)
        })
      {
        Ok(res) -> res
        Error(is_fs) -> {
          use <- bool.lazy_guard(
            is_fs |> option.is_some
              && simplifile.is_file(secretfile) == Ok(True),
            fn() {
              witness.this(witness.Error, "Could not read cookie secrets file", [
                witness.string("path", secretfile),
              ])
              panic as "Could not read cookie secrets file."
            },
          )
          witness.this(witness.Info, "Writing new cookie secrets file.", [
            witness.string("path", secretfile),
          ])
          let new_secret = crypto.strong_random_bytes(300)
          case
            simplifile.write(
              to: secretfile,
              contents: string.join(
                [
                  "This file contains the secret used to sign session cookies with, please don't ever edit it! If you want to invalidate all cookies, deleting this file is better.",
                  new_secret |> bit_array.base64_encode(False),
                ],
                with: "\n",
              ),
            )
          {
            Ok(Nil) -> new_secret
            Error(e) -> {
              witness.this(
                witness.Error,
                "Could not write cookie secrets file",
                [
                  witness.string("path", secretfile),
                  witness.string("error", simplifile.describe_error(e)),
                ],
              )
              panic as "Could not write cookie secrets file."
            }
          }
        }
      }
    })
  Globals(
    secrets:,
    sessions:,
    global_app_registry_name:,
    session_app_registry_name:,
    postgres_pool_name: db_pool,
    datamgr: process.named_subject(datamgr_name),
  )
}

pub type GlobalSecrets {
  GlobalSecrets(cookie_secret: BitArray)
}

/// Messages sent between either server components or from the server to it's components.
pub type GlobalMessage {
  /// Broadcasts the creation of a new user globally, for now this has no use.
  NewUser(id: BitArray)
}

/// Messages sent between components --or sent from the server to it's components-- within a specific session.
pub type SessionMessage {
  SessionAuthorized(UserSession)
}

// Data manager actor ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
pub type DataManagerMessage {
  /// Call the manager with this message to have the Globals spit out.
  GetGlobals(process.Subject(Globals))
  /// Gets or creates a session on the browser sessions ETS table, where possible prefer using `get_csrf_for_session()`
  /// over this, as the manager is a busy actor.
  GetSession(session_id: String, subject: process.Subject(SessionData))
  /// Clean a session and it's timer from the ETS table.
  DiscardSession(session_id: String)
}

pub type DataManagerState {
  DataManagerState
}

pub fn manager(
  globals globals: Globals,
) -> supervision.ChildSpecification(process.Subject(DataManagerMessage)) {
  let assert Ok(name) =
    globals.datamgr
    |> process.subject_name

  use <- supervision.worker()
  actor.new_with_initialiser(300, fn(subj) {
    witness.set_process_fields([
      witness.string("process", "Data management actor"),
    ])
    witness.this(witness.Info, "Initialising database", [])
    let conn = pog.named_connection(globals.postgres_pool_name)
    let db_init_result = case sql.get_self_instance(conn) {
      Ok(pog.Returned(1, [sql.GetSelfInstanceRow(name:)])) -> {
        witness.this(witness.Info, "Instance name found", [
          witness.string("Instance name", name),
        ])
        Ok(Nil)
      }
      _ -> {
        let name = config.application_name()
        case name {
          "" -> {
            witness.this(
              witness.Emergency,
              "Instance name needs to be set in application.json!",
              [],
            )
            Error(Nil)
          }
          name ->
            case sql.set_self_instance(conn, name) {
              Ok(_) -> {
                witness.this(
                  witness.Info,
                  "Instance name imported from config",
                  [
                    witness.string("Instance name", name),
                  ],
                )
                Error(Nil)
              }

              Error(_) -> {
                witness.this(
                  witness.Emergency,
                  "Could not import instance name from config.",
                  [],
                )
                Error(Nil)
              }
            }
        }
      }
    }

    let debug_accounts_inserted = {
      use <- bool.guard(!config.application_debug(), Ok(Nil))

      witness.this(
        witness.Notice,
        "Debug is active, creating development user accounts.",
        [],
      )

      let username = "testuser1"
      let password = "MyTestPassw9292!"
      let email = "test@lumina123.co"
      use _ <- result.try(
        exec_insert_user(
          conn,
          email:,
          display_name: "Test User 1",
          username:,
          password:,
        )
        |> result.map(fn(created) {
          witness.this(
            witness.Notice,
            "Made development account " <> created.0,
            [
              witness.string(
                "did:key",
                pk_ldid_key_encode(created.1.public_key),
              ),
              witness.string("did:lumina", pk_ldid_encode(created.1.public_key)),
              witness.string("debug password", password),
            ],
          )
          created
        }),
      )

      let username = "testuser2"
      let password = "MyTestPassw9292!"
      let email = "test@lumina234.co"
      use _ <- result.try(
        exec_insert_user(
          conn,
          email:,
          display_name: "Test User 2",
          username:,
          password:,
        )
        |> result.map(fn(created) {
          witness.this(
            witness.Notice,
            "Made development account " <> created.0,
            [
              witness.string(
                "did:key",
                pk_ldid_key_encode(created.1.public_key),
              ),
              witness.string("did:lumina", pk_ldid_encode(created.1.public_key)),
              witness.string("debug password", password),
            ],
          )
          created
        }),
      )
      Ok(Nil)
    }

    let _ =
      result.map_error(debug_accounts_inserted, fn(_) {
        witness.this(
          witness.Warning,
          "Database could not be properly initialised for development mode.",
          [],
        )
      })

    use _ <- result.map(
      db_init_result
      |> result.replace_error("Database could not be properly initialised"),
    )
    DataManagerState
    |> actor.initialised()
    |> actor.returning(subj)
  })
  |> actor.on_message(fn(state: DataManagerState, msg: DataManagerMessage) {
    case msg {
      GetGlobals(reply_to) -> {
        actor.send(reply_to, globals)
        actor.continue(state)
      }
      GetSession(subj, session_id:) -> {
        let _ =
          globals.sessions
          |> table.lookup(session_id)
          |> result.lazy_or(fn() {
            witness.this(witness.Info, "Creating new session", [
              witness.string("task", "GetSession"),
              witness.string("session_id", session_id),
            ])
            // No session found, creating new session!
            // Auto clean after 12 hours.
            let timer =
              process.send_after(
                process.named_subject(name),
                hour * 12,
                DiscardSession(session_id:),
              )
            let csrf_token = uuid.v4_string()
            let session_data = SessionData(csrf_token:, timer:)
            case table.insert_new(globals.sessions, session_id, session_data) {
              Ok(Nil) -> {
                Ok(session_data)
              }
              Error(Nil) -> {
                witness.this(
                  witness.Error,
                  "Could not insert session into table.",
                  [
                    witness.string("task", "GetSession"),
                    witness.string("session_id", session_id),
                  ],
                )
                Error(Nil)
              }
            }
          })
          |> result.map(actor.send(subj, _))

        actor.continue(state)
      }
      DiscardSession(session_id:) -> {
        let _ =
          globals.sessions
          |> table.lookup(session_id)
          |> result.map(fn(session) { session.timer |> process.cancel_timer() })
        let _ = table.delete(globals.sessions, session_id)

        actor.continue(state)
      }
    }
  })
  |> actor.named(name)
  |> actor.start
}

// Sessions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
pub type SessionsStore =
  Table(String, SessionData)

/// Session data
pub type SessionData {
  SessionData(csrf_token: String, timer: Timer)
}

// Earlier, this session store was managed by a dedicated 'session janitor' actor, this now
// is part of the bigger `data.manager()` actor.

pub fn get_csrf_for_session(
  session_store: Table(String, SessionData),
  session_id: String,
) {
  use value <- result.map(table.lookup(session_store, session_id))
  value.csrf_token
}

// Postgres interaction ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

/// Actor managing the Postgres database pool in the background.
/// Supervised by main process
pub fn db_child(pool_name: process.Name(pog.Message)) {
  let db_url = config.database_url()
  witness.this(witness.Info, "Connecting to the database", [
    witness.string("database url", db_url),
  ])
  case pog.url_config(pool_name, db_url) {
    Ok(config) -> config
    Error(_) -> {
      witness.this(
        witness.Critical,
        "Database url could not be parsed properly.",
        [],
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

pub fn pk_ldid_key_encode(pubkey pk: BitArray) -> String {
  let encoded =
    bit_array.concat([<<0xed01:16>>, pk])
    |> base58_encode
  "did:key:z" <> encoded
}

const did_key_prefix_ed25519 = <<0xed01:16>>

pub type DidDecodeError {
  ///Unsupported did type. Currently supported are `did:lumina` or `did:key`, both are based on ed25519.
  DidUnsupported
  DidInvalidBase64
  DidKeyInvalidBase58
  DidKeyUnknownPrefix
}

/// Decodes a `did:lumina: ...` DID to the public key used to create it.
/// Though `did:key` is also supported for decoding, encoding needs to be done with a different function.
/// `did:lumina:` is a laxer implementation of the same key, so even though two strings may not match, they may be the
/// same DID upon closer inspection.
pub fn pk_ldid_decode(
  lumina_did ldid: String,
) -> Result(BitArray, DidDecodeError) {
  case ldid {
    "did:lumina:" <> base64_url -> {
      bit_array.base64_url_decode(base64_url)
      |> result.replace_error(DidInvalidBase64)
    }
    "did:key:z" <> base58btcmulticodec -> {
      use bits <- result.try(
        result.try_recover(
          result.replace_error(
            base58_decode(base58btcmulticodec),
            DidKeyInvalidBase58,
          ),
          fn(original_error) {
            bit_array.base64_url_decode(base58btcmulticodec)
            |> result.replace_error(original_error)
          },
        ),
      )
      let slicing = case bits {
        <<prefix:size(16), others:bits>>
          if <<prefix:16>> == did_key_prefix_ed25519
        -> {
          others
          |> Ok
        }
        _ -> Error(DidKeyUnknownPrefix)
      }
      use sliced <- result.try(slicing)
      Ok(sliced)
    }
    "did:key:" <> _ -> Error(DidKeyUnknownPrefix)
    _ -> Error(DidUnsupported)
  }
}

// User sessions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
pub type UserSessionAuthError {
  UserSessionAuthNotExists
  UserSessionAuthHasIncorrectDid
  UserSessionAuthNoMatch
  UserSessionAuthSessionUUIDInvalid
  UserSessionAuthDBError
  UserSessionAuthArgon2Error
}

pub type UserSession {
  UserSession(
    user_id: BitArray,
    session_uuid: uuid.Uuid,
    revival_key: String,
    username: String,
    email: Option(String),
  )
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
  use session_uuid <- result.try(
    session_id
    |> uuid.from_string()
    |> result.replace_error(UserSessionAuthSessionUUIDInvalid),
  )
  use user_id <- result.try(case identifyer, string.contains(identifyer, "@") {
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
    case sql.password_hash_for_userid(conn, user_id) {
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
  // User is authenticated! Time to make a UserSession for them.
  let revival_key = random_string(80)
  case
    sql.create_authenticated_usersession(
      conn,
      session_uuid,
      user_id,
      crypto.hash(crypto.Sha384, <<revival_key:utf8>>),
    )
  {
    Ok(pog.Returned(
      count: 1,
      rows: [sql.CreateAuthenticatedUsersessionRow(username:, email:)],
    )) ->
      Ok(UserSession(user_id:, revival_key:, username:, session_uuid:, email:))
    _ -> Error(UserSessionAuthDBError)
  }
}

pub type UserRegistrationError {
  RegistrationSuccessButSessionCreationFailed(UserSessionAuthError)
  MissingInviteCode
  InvalidInviteCode
  UserRegistrationDBError
}

pub fn user_register_and_authorise(
  postgres_pool_name postgres_pool_name: process.Name(pog.Message),
  session_id session_id: String,
  email new_email: String,
  username new_username: String,
  password new_password: String,
  display_name new_display_name: String,
  invite_code invite_code: Option(String),
) -> Result(UserSession, UserRegistrationError) {
  let conn = pog.named_connection(postgres_pool_name)
  let revival_key = random_string(80)
  let new_user_keypair = async_crypto.generate_keypair()
  let usersession_key = <<revival_key:utf8>>

  use session_uuid <- result.try(
    session_id
    |> uuid.from_string()
    |> result.replace_error(RegistrationSuccessButSessionCreationFailed(
      UserSessionAuthSessionUUIDInvalid,
    )),
  )
  case config.application_users_register_inviteonly(), invite_code {
    True, Some(given_invite_code) -> {
      case
        sql.consume_invite(
          conn,
          new_user_keypair.public_key,
          given_invite_code,
          new_email,
          new_display_name,
          new_username,
          new_password,
          new_user_keypair.private_key,
          session_uuid,
          usersession_key,
        )
      {
        Ok(pog.Returned(
          count: 1,
          rows: [sql.ConsumeInviteRow(username:, email:)],
        )) ->
          Ok(UserSession(
            user_id: new_user_keypair.public_key,
            revival_key:,
            username:,
            session_uuid:,
            email:,
          ))
        _ -> Error(UserRegistrationDBError)
      }
      // |> result.map_error(RegistrationSuccessButSessionCreationFailed)
    }
    True, None -> Error(MissingInviteCode)
    False, _ -> Ok(todo as "Implement inviteless registration.")
  }
}

// Helpers ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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

pub fn random_string(length: Int) -> String {
  crypto.strong_random_bytes(length)
  |> bit_array.base64_url_encode(False)
  |> string.slice(0, length)
}

pub fn base58_encode(bits: BitArray) -> String {
  let out = charlist.to_string(erl_base58_encode(bits))

  assert base58_decode(out) == Ok(bits)
    as "The base58 produced should decode back to the same bits."
  out
}

pub fn base58_decode(from: String) -> Result(BitArray, Nil) {
  let chars = charlist.from_string(from)
  use <- bool.guard(!erl_base58_check(chars), Error(Nil))
  erl_base58_decode(chars) |> Ok
}

@external(erlang, "base58", "binary_to_base58")
fn erl_base58_encode(from: BitArray) -> charlist.Charlist

@external(erlang, "base58", "base58_to_binary")
fn erl_base58_decode(from: charlist.Charlist) -> BitArray

@external(erlang, "base58", "check_base58")
fn erl_base58_check(from: charlist.Charlist) -> Bool

@external(erlang, "filename", "absname_join")
fn absname_join(dir: String, file: String) -> String

pub fn log_file(name name: String) {
  let logs_dir = absname_join(data_dir(), "./logs/")
  let assert Ok(_) = simplifile.create_directory_all(logs_dir)
    as "Could not create folder for logging."
  absname_join(logs_dir, "./" <> name <> ".log")
  |> witness.new_file()
}

fn data_dir() -> String {
  envoy.get("LUMINA_DATA_DIR")
  |> result.unwrap("/data/data")
}

fn exec_insert_user(
  conn,
  email email: String,
  display_name display_name: String,
  username username: String,
  password password: String,
) {
  let keypair = async_crypto.generate_keypair()
  use password <- result.try(
    password
    |> user_password_hash_gen
    |> result.replace_error(Nil),
  )
  sql.insert_user(
    conn,
    keypair.public_key,
    email,
    display_name,
    username,
    password,
    keypair.private_key,
  )
  |> result.replace(#(username, keypair))
  |> result.replace_error(Nil)
}
