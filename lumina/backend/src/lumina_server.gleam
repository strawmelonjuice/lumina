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

import gleam/erlang/process
import gleam/otp/static_supervisor as supervisor
import logging
import lumina_server/config
import lumina_server/data
import lumina_server/server
import witness

// Main ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

pub fn main() {
  logging.configure()

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
  |> witness.with_sink(witness.Text, logging.log)
  |> witness.set_config()
  let db_pool = process.new_name("Databasepool")
  let global_context =
    data.initialise_global_context(postgres_pool_name: db_pool)
  let assert Ok(_) =
    supervisor.new(supervisor.RestForOne)
    |> supervisor.add(data.db_child(db_pool))
    |> supervisor.add(server.child(global_context))
    |> supervisor.add(data.session_janitor(global_context.sessions))
    |> supervisor.start

  process.sleep_forever()
}
