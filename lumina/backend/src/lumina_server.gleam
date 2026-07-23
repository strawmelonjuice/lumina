//// **Lumina >**
//// # Backend
////
//// Main entry point for Lumina. Starts and supervises all parts of the server.

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

import envoy
import gleam/erlang/atom
import gleam/erlang/process
import gleam/otp/actor
import gleam/otp/static_supervisor as supervisor
import gleam/result
import group_registry
import logging
import lumina_server/config
import lumina_server/data
import lumina_server/server
import witness

// Main ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

/// This is the main entrypoint to `gleam run`, and as long as this function runs, the application defined in `start()` runs.
/// It also starts the OTP observer when ran with `just dev`.
pub fn main() {
  let _ =
    envoy.get("START_OBSERVER")
    |> result.map(fn(_) { observer_start() })

  process.sleep_forever()
}

type ErlangResult

@external(erlang, "observer", "start")
fn observer_start() -> ErlangResult

/// This callback is ran by the OTP runtime when Lumina is loaded into the BEAM, it
/// starts the application as an OTP application, which means the supervision tree is actually utilised!
pub fn start(
  _app: atom.Atom,
  _type: a,
) -> Result(process.Pid, actor.StartError) {
  witness.set_process_fields([witness.string("Process", "Initial OTP Starter")])
  case start_supervisor() {
    Ok(actor.Started(pid, _data)) -> {
      let sup_name = process.new_name("Lumina")
      let _ = process.register(pid, sup_name)
      witness.this(witness.Info, "Started Lumina server!", [])
      Ok(pid)
    }
    Error(reason) -> Error(reason)
  }
}

pub fn start_supervisor() -> Result(
  actor.Started(supervisor.Supervisor),
  actor.StartError,
) {
  logging.configure()

  witness.set_process_fields([
    witness.string("Process", "Lumina OTP Supervisor"),
  ])
  case config.application_debug() {
    True -> {
      logging.set_level(logging.Debug)
      witness.with_global_fields(witness.empty_config(), [
        witness.bool("Debug", True),
      ])
    }
    False -> {
      logging.set_level(logging.Info)

      witness.empty_config()
    }
  }
  |> witness.with_sink(witness.Text, fn(level, msg) {
    logging.log(
      case level {
        witness.Debug -> logging.Debug
        witness.Info -> logging.Info
        witness.Warning -> logging.Warning
        witness.Error -> logging.Error
      },
      msg,
    )
  })
  |> witness.set_config()
  let db_pool = process.new_name("Databasepool")
  let global_app_registry_name =
    process.new_name("App message registry: Intersession")
  let session_app_registry_name =
    process.new_name("App message registry: Globally")
  let global_context =
    data.initialise_global_context(
      postgres_pool_name: db_pool,
      global_app_registry_name:,
      session_app_registry_name:,
    )
  supervisor.new(supervisor.RestForOne)
  |> supervisor.add(group_registry.supervised(global_app_registry_name))
  |> supervisor.add(group_registry.supervised(session_app_registry_name))
  |> supervisor.add(data.db_child(db_pool))
  |> supervisor.add(server.child(global_context))
  |> supervisor.add(data.session_janitor(global_context.sessions))
  |> supervisor.start
}
