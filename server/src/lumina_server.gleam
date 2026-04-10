//// Lumina > Server
//// Main entry point for Lumina.

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

import booklet.{type Booklet}
import envoy
import ewe.{type Request, type Response}
import gleam/bit_array
import gleam/erlang/application
import gleam/erlang/process
import gleam/http/response
import gleam/int
import gleam/option.{None}
import gleam/result
import gleam/uri
import humanise
import simplifile
import sqlight
import woof

type HandlerContext {
  HandlerContext(
    db: sqlight.Connection,
    client_hash: String,
    assets: String,
    static_responses: StaticResponses,
  )
}

type StaticRoute {
  RouteForIndex
  RouteForClientAsMinifiedJavascript
  RouteForClientAsJavascript
  RouteForClientStyles
  RouteForIconAsPNG
  RouteForIconAsSVG
}

type StaticResponses =
  fn(StaticRoute) -> response.Response(ewe.ResponseBody)

type ClientConnectionData {
  ClientConnectionData(
    client_type: option.Option(ClientType),
    user: option.Option(User),
  )
}

type ClientType {
  WebClient
  NativeApp
}

type User {
  User(
    // Todo
    Nil,
  )
}

pub fn main() {
  use db <- sqlight.with_connection("/data/instance.db")
  // At some point everything should go here, I think.
  // woof.set_sink(woof.beam_logger_sink)
  // But for now, do both!
  woof.set_sink(fn(entry, formatted) {
    woof.beam_logger_sink(entry, formatted)
    woof.default_sink(entry, formatted)
  })
  let setuplog = woof.new("WARMUP")
  // PRAGMA's
  let _ = sqlight.exec("PRAGMA journal_mode = WAL;", db)
  let _ = sqlight.exec("PRAGMA synchronous = NORMAL;", db)
  let _ = sqlight.exec("PRAGMA cache_size = -64000;", db)
  let _ = sqlight.exec("PRAGMA foreign_keys = ON;", db)

  // Logging
  woof.configure(woof.Config(
    level: woof.Debug,
    format: woof.Text,
    colors: woof.Auto,
  ))

  let assets = case application.priv_directory("lumina_server") {
    Ok(outcome) -> outcome
    Error(_) -> {
      setuplog |> woof.log(woof.Error, "could not get priv folder.", [])
      panic
    }
  }

  // Check client hash
  let client_hash = case
    simplifile.read(assets <> "/static/lumina_client_rev.hash")
  {
    Error(_) -> {
      setuplog
      |> woof.log(
        woof.Error,
        "could not load client revision's hash from filesystem.",
        [],
      )
      panic
    }
    Ok(outcome) -> {
      setuplog
      |> woof.log(woof.Info, "Found client revision!", [
        woof.field("revision", outcome),
      ])
      outcome
    }
  }

  let static_responses = static(client_hash, assets, setuplog)
  // And start!
  let assert Ok(_) =
    ewe.new(handler(
      _,
      HandlerContext(db:, assets:, client_hash:, static_responses:),
    ))
    |> ewe.bind("0.0.0.0")
    |> ewe.listening(
      port: envoy.get("PORT")
      |> result.map(int.parse)
      |> result.flatten()
      |> result.unwrap(3000),
    )
    |> ewe.start

  process.sleep_forever()
}

fn static(
  client_hash: String,
  assets: String,
  setuplog: woof.Logger,
) -> StaticResponses {
  let client_servible =
    [
      <<
        "<!doctype html><html lang=\"en\"><head><meta charset=\"UTF-8\" /><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, viewport-fit=cover\" /><title>Lumina</title><link rel=\"preconnect\" href=\"https://fontlay.com\" corossorigin /><link href=\"https://fontlay.com/css2?family=DM+Mono:ital,wght@0,300;0,400;0,500;1,300;1,400;1,500&family=Elms+Sans:ital,wght@0,100..900;1,100..900&family=Gantari:ital,wght@0,100..900;1,100..900&family=Josefin+Sans:ital,wght@0,100..700;1,100..700&family=Vend+Sans&display=swap\" rel=\"stylesheet\"><link	rel=\"stylesheet\" href=\"/static/lumina.css\"/><meta name=\"robots\" content=\"noai, noimageai, nofollow\"><script>window.clientHash = \"":utf8,
      >>,
      client_hash |> bit_array.from_string,
      <<"\";</script><script type=\"module\">":utf8>>,
      case simplifile.read_bits(assets <> "/static/lumina_client.min.mjs") {
        Error(_) -> {
          setuplog
          |> woof.log(woof.Error, "Missing application assets.", [
            woof.field("File", assets <> "/static/lumina_client.min.mjs"),
          ])
          panic as "Missing application assets."
        }
        Ok(outcome) -> {
          outcome
        }
      },
      <<"</script></head><body id=\"app\"></body></html>":utf8>>,
    ]
    |> bit_array.concat()
  setuplog
  |> woof.log(
    woof.Debug,
    "Total client size is: "
      <> bit_array.byte_size(client_servible) |> humanise.bytes_int(),
    [#("revision", client_hash)],
  )
  let builtin_file = fn(file: String, mime: String) -> response.Response(
    ewe.ResponseBody,
  ) {
    case simplifile.read_bits(file) {
      Error(_) -> {
        setuplog
        |> woof.log(woof.Error, "Missing application assets.", [
          woof.field("File", file),
        ])
        panic as "Missing application assets."
      }
      Ok(outcome) -> {
        response.new(200)
        |> response.set_header("content-type", mime)
        |> response.set_body(ewe.BitsData(outcome))
      }
    }
  }
  let index =
    response.set_body(
      response.set_header(
        response.new(200),
        "content-type",
        "text/html; charset=utf-8",
      ),
      ewe.BitsData(client_servible),
    )
  let client_js_min =
    builtin_file(
      assets <> "/static/lumina_client.min.mjs",
      "application/javascript; charset=utf-8",
    )
  let client_js =
    builtin_file(
      assets <> "/static/lumina_client.mjs",
      "application/javascript; charset=utf-8",
    )
  let client_styles =
    builtin_file(
      assets <> "/static/lumina_client.css",
      "text/css; charset=utf-8",
    )
  let icon_png = builtin_file(assets <> "/static/logo.png", "image/png")
  let icon_svg = builtin_file(assets <> "/static/logo.svg", "image/svg+xml")
  fn(route: StaticRoute) {
    case route {
      RouteForIndex -> index
      RouteForIconAsSVG -> icon_svg
      RouteForIconAsPNG -> icon_png
      RouteForClientStyles -> client_styles
      RouteForClientAsJavascript -> client_js
      RouteForClientAsMinifiedJavascript -> client_js_min
    }
  }
}

fn handler(req: Request, handler_ctx: HandlerContext) -> Response {
  let httplogger = fn(
    level: woof.Level,
    msg: String,
    vars: List(#(String, String)),
  ) {
    woof.new("WEBSERVER")
    |> woof.log(level, msg, [woof.field("uri path", req.path), ..vars])
  }
  case req.path |> uri.path_segments() {
    ["/"] | [""] | [] -> {
      httplogger(woof.Info, "OK", [])
      handler_ctx.static_responses(RouteForIndex)
    }
    ["static", "lumina.min.mjs"] -> {
      httplogger(woof.Info, "OK", [])
      handler_ctx.static_responses(RouteForClientAsMinifiedJavascript)
    }
    ["static", "lumina.mjs"] -> {
      httplogger(woof.Info, "OK", [])
      handler_ctx.static_responses(RouteForClientAsJavascript)
    }
    ["static", "lumina.css"] -> {
      httplogger(woof.Info, "OK", [])
      handler_ctx.static_responses(RouteForClientStyles)
    }

    ["favicon.ico"] | ["static", "logo.png"] -> {
      httplogger(woof.Info, "OK", [])
      handler_ctx.static_responses(RouteForIconAsPNG)
    }
    ["static", "logo.svg"] -> {
      httplogger(woof.Info, "OK", [])
      handler_ctx.static_responses(RouteForIconAsSVG)
    }
    ["connection"] -> {
      ewe.upgrade_websocket(
        req,
        // If ever we need to send messages through processes to get to and from the client over here, we should
        // take a second look at the ewe example on
        // https://github.com/vshakitskiy/ewe/blob/mistress/examples/src/websocket.gleam
        on_init: fn(_conn, selector) {
          // Initial state for THIS specific client
          let state =
            WebsocketState(
              ctx: handler_ctx,
              conn_data: ClientConnectionData(None, None),
            )
          #(state, selector)
        },
        handler: client_communication_handler,
        on_close: fn(_conn, _state) { Nil },
      )
    }
    _ -> {
      httplogger(woof.Warning, "Not found.", [])
      response.new(404)
      |> response.set_header("content-type", "text/plain; charset=utf-8")
      |> response.set_body(ewe.TextData("404! Not found!"))
    }
  }
}

type WebsocketState {
  WebsocketState(ctx: HandlerContext, conn_data: ClientConnectionData)
}

fn client_communication_handler(
  _conn: ewe.WebsocketConnection,
  state: WebsocketState,
  // That Nil is the internal message, again if we'd follow the example. But
  // Lumina mostly communicates with the database and stores more global variables in Booklets (which is ETS)... So no need.
  message: ewe.WebsocketMessage(Nil),
) -> ewe.WebsocketNext(WebsocketState, Nil) {
  case message {
    ewe.Text(json_str) -> {
      // Todo
      ewe.websocket_continue(state)
    }
    ewe.Binary(_) -> ewe.websocket_continue(state)
    ewe.User(Nil) -> ewe.websocket_continue(state)
  }
}
