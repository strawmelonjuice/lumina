//  Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
//  Licensed under the BSD 3-Clause License. See the LICENSE file for more info.

import argv
import gleam/bool
import gleam/erlang
import gleam/erlang/os
import gleam/erlang/process
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleamy_lights/premixed
import gleamyshell
import lumina/data/config
import lumina/data/context.{Context}
import lumina/database
import lumina/web/routing
import lumina_rsffi
import mist
import simplifile as fs
import wisp
import wisp_kv_sessions/actor_store
import wisp_kv_sessions/session
import wisp_kv_sessions/session_config

const me = "lumina"

pub fn main() {
  let assert 3 = lumina_rsffi.add(1, 2)
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
  case gleamyshell.home_directory() {
    Ok(home) -> start(string.replace(home, "\\", "/") <> "/.luminainstance/")
    Error(e) -> {
      { "Could not load the user folder" <> string.inspect(e) }
      |> wisp.log_critical
    }
  }
}

fn start(in: String) {
  case start_l(in) {
    Ok(Nil) -> Nil
    Error(e) -> {
      io.println_error(
        premixed.text_dark_black(premixed.bg_error_red("FAIL")) <> ": " <> e,
      )
      Nil
    }
  }
}

fn start_l(in: String) -> Result(Nil, String) {
  use <- bool.lazy_guard(
    when: bool.and(
      os.family() == os.WindowsNt,
      bool.negate(list.contains(argv.load().arguments, "--allow-windows")),
    ),
    return: fn() {
      Error(premixed.text_error_red(
        "Lumina does not run correctly on Windows yet. Please use WSL or use the '--allow-windows' flag to run Lumina on Windows.",
      ))
    },
  )
  // Configure erlang logger.
  wisp.configure_logger()
  // Check if environment exists
  use exists <- result.try(result.replace_error(
    fs.is_directory(in),
    "Could not check whether the selected directory exists.",
  ))

  use _ <- result.try(case exists {
    True -> Ok(Nil)
    False -> {
      case fs.create_directory(in) {
        Error(_) -> {
          Error("Failed to create directory '" <> in <> "'.")
        }
        Ok(_) -> Ok(Nil)
      }
    }
  })
  // Load environment
  let lumina_config = config.load(in)

  // Set a secret_key_base
  let secret_key_base = wisp.random_string(64)
  let priv_directory = get_priv_directory()
  // Connect to database
  use dbc <- result.try(database.connect(lumina_config, in))

  // Sets up database in case of need. Exits on error.
  use _ <- result.try(database.setup(dbc))

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

  case
    wisp.mist_handler(handler, secret_key_base)
    |> mist.new
    |> mist.port(ctx.config.lumina_server_port)
    |> mist.start_http
  {
    Ok(_) -> {
      Ok(process.sleep_forever())
    }
    Error(e) -> {
      Error("Failed to start server: " <> string.inspect(e))
    }
  }
}

fn get_priv_directory() -> String {
  case
    {
      let a =
        erlang.priv_directory("lumina")
        |> result.unwrap("")

      use <- bool.guard(
        when: a
          |> fs.is_directory
          |> result.unwrap(False),
        return: Some(a),
      )
      let a =
        erlang.priv_directory("backend")
        |> result.unwrap("")

      use <- bool.guard(
        when: a
          |> fs.is_directory
          |> result.unwrap(False),
        return: Some(a),
      )
      let a = "./priv"
      use <- bool.guard(
        when: a
          |> fs.is_directory
          |> result.unwrap(False),
        return: Some(a),
      )
      None
    }
  {
    Some(a) -> a
    None -> {
      "Could not find a suitable priv directory."
      |> io.println_error
      panic
    }
  }
}
