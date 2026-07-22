//// **Lumina > Backend >**
//// # Configuration
////
//// Loads in configuration from JSON files.

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
import gleam/dynamic/decode
import gleam/json
import gleam/result
import logging
import simplifile
import witness

// Public getters ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
pub fn application_debug() {
  gets(
    config_module: "application",
    with: decode.at(["debug"], decode.bool),
    initial: application_config_init,
  )
}

pub fn application_admins() {
  gets(
    config_module: "application",
    with: decode.at(["admins"], decode.list(decode.string)),
    initial: application_config_init,
  )
}

pub fn application_web_port() {
  gets(
    config_module: "application/web",
    with: decode.at(["port"], decode.int),
    initial: application_web_config_init,
  )
}

pub fn application_web_host() {
  gets(
    config_module: "application/web",
    with: decode.at(["host"], decode.string),
    initial: application_web_config_init,
  )
}

pub fn database_url() {
  gets(
    config_module: "database",
    with: decode.at(["database-url"], decode.string),
    initial: database_config_init,
  )
}

// Config initial values per module ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/// Initial values for config module `application`.
fn application_config_init() -> json.Json {
  json.object([
    #("debug", json.bool(False)),
    #("admins", json.array([], json.string)),
  ])
}

/// Initial values for config module `application/web`.
fn application_web_config_init() -> json.Json {
  json.object([
    #("port", json.int(3000)),
    #("host", json.string("0.0.0.0")),
  ])
}

/// Initial values for config module `database`.
fn database_config_init() -> json.Json {
  json.object([
    #(
      "database-url",
      json.string(
        envoy.get("LUMINA_DB_URL")
        |> result.unwrap("postgresql://username:password@localhost/Lumina"),
      ),
    ),
  ])
}

// Helpers ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
fn config_dir() -> String {
  envoy.get("LUMINA_CONF_DIR")
  |> result.unwrap("/data/config")
}

@external(erlang, "filename", "absname_join")
fn absname_join(dir: String, file: String) -> String

@external(erlang, "filename", "dirname")
fn dirname(filename: String) -> String

fn gets(
  config_module module: String,
  with with: decode.Decoder(a),
  initial init: fn() -> json.Json,
) -> a {
  let file = absname_join(config_dir(), module <> ".json")
  case
    result.try(
      simplifile.is_file(file) |> result.replace_error(Nil),
      fn(exists) {
        case exists {
          True ->
            simplifile.read(file)
            |> result.replace_error(Nil)
            |> result.map(fn(string) {
              case json.parse(string, with) {
                Ok(a) -> a
                Error(_) -> {
                  witness.this(
                    witness.Error,
                    "The json at "
                      <> file
                      <> " no longer matches the expected data. Did something corrupt it?",
                    [
                      witness.string("config_module", module),
                      witness.string("filepath", file),
                    ],
                  )
                  panic as "Corrupted config"
                }
              }
            })
          False -> {
            let json_str = json.to_string(init())
            result.replace_error(
              result.replace(
                {
                  result.try(
                    { simplifile.create_directory_all(dirname(file)) },
                    fn(_) { simplifile.write(contents: json_str, to: file) },
                  )
                },
                json_str
                  |> json.parse(with)
                  |> result.replace_error(Nil),
              ),
              Nil,
            )
            |> result.flatten
          }
        }
      },
    )
  {
    Error(Nil) -> {
      witness.this(
        witness.Error,
        "Could not read configuration files - File system error.",
        [
          witness.string("config_module", module),
          witness.string("filepath", file),
        ],
      )
      panic as "Could not read configuration files - File system error."
    }
    Ok(a) -> a
  }
}
