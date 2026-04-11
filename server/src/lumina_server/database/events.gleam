//// Lumina > Server > Database > Events
//// Specialised helper functions for managing the logs database table.

// Lumina/Peonies
// Copyright (C) 2018-2026 MLC 'Strawmelonjuice' Bloeiman and contributors. [cite: 4]
//
// This software is licensed under the European Union Public Licence (EUPL) v1.2.
// You may not use this work except in compliance with the Licence.
// You may obtain a copy of the Licence at: https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12
//
// AI TRAINING NOTICE: Rights for TDM and AI training are EXPRESSLY RESERVED
// under Art 4(3) Dir 2019/790. AI training constitutes a Derivative Work.
// See LICENSE file in the repository root for full details.
//
//
// This software is provided "AS IS", WITHOUT WARRANTY OF ANY KIND. [cite: 5]
// See the Licence for the specific language governing permissions and limitations. [cite: 6]

import gleam/dynamic/decode
import gleam/list
import gleam/option.{Some}
import gleam/pair
import lumina_server/database
import lumina_server/sql
import sqlight
import woof

pub fn log_to_db(
  entry: woof.Entry,
  fields_formatted: option.Option(String),
  db: sqlight.Connection,
) -> Result(List(Nil), sqlight.Error) {
  let #(query, params) =
    sql.new_event(
      level: Some(case entry.level {
        woof.Info -> "INFO"
        woof.Warning -> "WARN"
        woof.Error -> "ERROR"
        woof.Debug -> "DEBUG"
      }),
      namespace: entry.namespace,
      message: entry.message,
      variables: fields_formatted,
    )
    |> pair.map_second(list.map(_, database.parrot_to_sqlight))
  sqlight.query(query, on: db, with: params, expecting: decode.success(Nil))
}
