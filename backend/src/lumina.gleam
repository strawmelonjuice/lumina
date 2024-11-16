//  Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
//  Licensed under the BSD 3-Clause License. See the LICENSE file for more info.

import argv
import gleam/bool
import gleam/erlang
import gleam/erlang/os
import gleam/erlang/process
import gleam/io
import gleam/list
import gleam/option
import gleam/string
import gleamy_lights/premixed
import gleamyshell
import lumina/data/config
import lumina/data/context.{Context}
import lumina/database
import lumina/web/routing
import mist
import simplifile as fs
import wisp
import wisp_kv_sessions/actor_store
import wisp_kv_sessions/session
import wisp_kv_sessions/session_config

const me = "lumina"

pub fn main() {
  case argv.load().arguments {
    ["start", ..] -> start_def()
    ["start-in", folder, ..] -> start(folder)
    _ -> {
      io.println("Usage: ")
      io.println(
        premixed.text_purple(me <> premixed.text_lime(" start"))
        <> "\t\t\t"
        <> "Starts the server with default luminafolder",
      )
      io.println(
        premixed.text_purple(me <> premixed.text_lime(" start-in "))
        <> premixed.text_yellow("<folder>")
        <> "\t"
        <> "Starts the server with custom luminafolder",
      )
    }
  }
}

fn start_def() {
  let home = case gleamyshell.home_directory() {
    Ok(home) -> home
    Error(e) -> {
      let a = "Could not load the user folder" <> string.inspect(e)
      panic as a
    }
  }
  start(string.replace(home, "\\", "/") <> "/.luminainstance/")
}

fn start(in: String) {
  use <- bool.lazy_guard(
    when: bool.and(
      os.family() == os.WindowsNt,
      bool.negate(list.contains(argv.load().arguments, "--allow-windows")),
    ),
    return: fn() {
      io.println(premixed.text_error_red(
        "Lumina does not run correctly on Windows yet. Please use WSL for now, or be brave and use the '--allow-windows' flag.",
      ))
      Nil
    },
  )
  // Configure erlang logger.
  wisp.configure_logger()
  // Check if environment exists
  case fs.is_directory(in) {
    Ok(True) -> Nil
    Ok(False) -> {
      case fs.create_directory(in) {
        Error(_) -> {
          wisp.log_critical("Directory '" <> in <> "' cannot be written.")
        }
        Ok(_) -> Nil
      }
    }
    Error(_) -> {
      wisp.log_critical("Directory '" <> in <> "' cannot be read.")
    }
  }
  // Load environment
  let lumina_config = config.load(in)

  // Set a secret_key_base
  let secret_key_base = wisp.random_string(64)
  let assert Ok(priv_directory) = erlang.priv_directory("lumina")

  // Connect to database
  let dbc = database.connect(lumina_config, in)
  // Sets up database in case of need.
  database.c(dbc)

  // Set up session store
  let assert Ok(actor_store) = actor_store.try_create_session_store()
  let attempt = actor_store.try_create_session_store()
  let cache_store = case attempt {
    Ok(store) -> option.Some(store)
    Error(e) -> {
      wisp.log_error(
        "Could not setup session cache store: " <> string.inspect(e),
      )
      option.None
    }
  }

  // Set up session config
  let session__config =
    session_config.Config(
      default_expiry: session.ExpireIn(60 * 60),
      cookie_name: "SESSION_COOKIE",
      store: actor_store,
      cache: cache_store,
    )
  // Create context
  let ctx =
    Context(
      config_dir: in,
      session_config: session__config,
      priv_directory: priv_directory,
      config: lumina_config,
      db: dbc,
    )

  // Add context to handler
  let handler = routing.handle_request(_, ctx)

  let assert Ok(_) =
    wisp.mist_handler(handler, secret_key_base)
    |> mist.new
    |> mist.port(ctx.config.lumina_server_port)
    |> mist.start_http
  process.sleep_forever()
}
