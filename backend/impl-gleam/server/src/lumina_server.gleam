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

import booklet
import envoy
import ewe.{type Request, type Response}
import gleam/bit_array
import gleam/erlang/application
import gleam/erlang/process
import gleam/http/response
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/pair
import gleam/result
import gleam/string
import gleam/uri
import humanise
import lumina_server/database/events
import simplifile
import sqlight
import webapi.{WebClient}
import woof
import youid/uuid

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
    client_type: option.Option(webapi.ClientKind),
    user: option.Option(User),
  )
}

type User {
  User(uid: uuid.Uuid, username: String)
}

pub fn main() {
  case simplifile.create_directory_all("/data/configvars") {
    Ok(_) -> Nil
    Error(_) -> {
      panic as "Could not create /data/configvars"
    }
  }
  let output_format = {
    case
      simplifile.read("/data/configvars/log_format")
      |> result.unwrap("")
      |> string.split_once("\n")
      |> result.map(pair.first)
      |> result.map(string.lowercase)
    {
      Ok("compact") -> woof.Compact
      Ok("json") -> woof.Json
      Ok("text") -> woof.Text
      _ -> {
        let _ =
          simplifile.write(
            "/data/configvars/log_format",
            "json\n\nThis file sets the log format!"
              <> "Default is 'json', other values available are 'compact' and 'text'."
              <> "\nIf the set value is invalid or onextistent, this file is reset.",
          )
        woof.Json
      }
    }
  }
  let debug = simplifile.is_file("/data/configvars/debug") == Ok(True)
  use db <- sqlight.with_connection("/data/instance.db")
  let log_to_db = booklet.new(True)
  // At some point everything should go here, I think.
  // But for now, do both!
  woof.set_sink(fn(entry, formatted) {
    woof.default_sink(entry, formatted)
    let fields_formatted =
      entry.fields
      |> list.map(fn(field) { field.0 <> ": " <> field.1 })
      |> string.join("; ")
      |> string.to_option()
    case log_to_db |> booklet.get() {
      True ->
        case events.log_to_db(entry, fields_formatted, db) {
          Ok(_) -> Nil
          Error(e) -> {
            woof.error("Could not log to database!\n\n" <> e.message, [])
            woof.append_global_context([
              woof.field("db_logging", "failed: " <> e.message),
            ])
            booklet.set(in: log_to_db, to: False)
          }
        }
      False -> Nil
    }
    woof.beam_logger_sink(entry, formatted)
  })
  let setuplog = woof.new("WARMUP")
  // PRAGMA's
  let _ = sqlight.exec("PRAGMA journal_mode = WAL;", db)
  let _ = sqlight.exec("PRAGMA synchronous = NORMAL;", db)
  let _ = sqlight.exec("PRAGMA cache_size = -64000;", db)
  let _ = sqlight.exec("PRAGMA foreign_keys = ON;", db)

  // Logging
  case debug {
    True -> {
      woof.configure(woof.Config(
        level: woof.Debug,
        format: woof.Text,
        colors: woof.Auto,
      ))
      woof.info(
        "Debug mode enabled.\n\n"
          <> "This also means `configvars/log_format` is overridden to 'text'",
        [],
      )
    }
    False ->
      woof.configure(woof.Config(
        level: woof.Info,
        format: output_format,
        colors: woof.Auto,
      ))
  }

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

fn handler(req: Request, handler_ctx: HandlerContext) -> Response {
  let httplogger = fn(
    level: woof.Level,
    msg: String,
    vars: List(#(String, String)),
  ) {
    woof.new("SERVER/HTTP")
    |> woof.log(level, msg, [
      woof.field("uri path", req.path),
      woof.field("request-host", case req.host {
        "0.0.0.0" -> "local (unsure)"
        d -> d
      }),
      ..vars
    ])
  }
  let ok = fn() { httplogger(woof.Info, "200/OK", []) }
  case req.path |> uri.path_segments() {
    ["/"] | [""] | [] -> {
      ok()
      handler_ctx.static_responses(RouteForIndex)
    }
    ["static", "lumina.min.mjs"] -> {
      ok()
      handler_ctx.static_responses(RouteForClientAsMinifiedJavascript)
    }
    ["static", "lumina.mjs"] -> {
      ok()
      handler_ctx.static_responses(RouteForClientAsJavascript)
    }
    ["static", "lumina.css"] -> {
      ok()
      handler_ctx.static_responses(RouteForClientStyles)
    }

    ["favicon.ico"] | ["static", "logo.png"] -> {
      ok()
      handler_ctx.static_responses(RouteForIconAsPNG)
    }
    ["static", "logo.svg"] -> {
      ok()
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
              logger: fn(
                level: woof.Level,
                msg: String,
                vars: List(#(String, String)),
                conn_data: ClientConnectionData,
              ) {
                woof.new("WEB/SOCKET:CLIENT")
                |> woof.log(level, msg, [
                  woof.field("uri path", req.path),
                  woof.field("request-host", case req.host {
                    "0.0.0.0" -> "local (unsure)"
                    d -> d
                  }),
                  woof.field(
                    "user",
                    conn_data.user
                      |> option.map(fn(user) { user.username })
                      |> option.unwrap("unknown"),
                  ),
                  ..vars
                ])
              },
            )
          httplogger(woof.Info, "101/PROTOCOL UPGRADE", [])
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
  WebsocketState(
    ctx: HandlerContext,
    conn_data: ClientConnectionData,
    logger: fn(
      woof.Level,
      String,
      List(#(String, String)),
      ClientConnectionData,
    ) ->
      Nil,
  )
}

fn client_communication_handler(
  conn: ewe.WebsocketConnection,
  state: WebsocketState,
  // That Nil is the internal message, again if we'd follow the example. But
  // Lumina mostly communicates with the database and stores more global variables in Booklets (which is ETS)... So no need.
  message: ewe.WebsocketMessage(Nil),
) -> ewe.WebsocketNext(WebsocketState, Nil) {
  let #(handler_context, connection_data, connection_logger) = {
    #(
      state.ctx,
      state.conn_data,
      fn(level: woof.Level, message: String, variables: List(#(String, String))) {
        state.logger(level, message, variables, state.conn_data)
      },
    )
  }
  case message {
    ewe.Text(json_str) -> {
      connection_logger(woof.Debug, "Received: " <> json_str, [])
      case json.parse(json_str, webapi.ws_msg_from_client_decoder()) {
        Error(_) -> {
          woof.tap_debug(
            woof.Warning,
            "Received malformed message from client.",
            [
              woof.field("message", json_str),
            ],
          )
          ewe.send_close_frame(
            conn,
            ewe.CustomCloseCode(code: 4000, data: "Malformed message received."),
          )
          Some(ewe.websocket_stop_abnormal("Malformed message received."))
        }
        Ok(message) ->
          case message {
            webapi.Introduction(client_kind:, try_revive:) -> {
              case try_revive {
                Some(_) -> todo as "Revive is not implemented yet."
                None -> Nil
              }
              let client_type = case client_kind {
                WebClient -> {
                  connection_logger(woof.Debug, "A web client greets us!", [])
                  client_kind
                }
                webapi.NativeImplementation("android-reflector-" <> _) -> {
                  connection_logger(
                    woof.Debug,
                    "A android client greets us!",
                    [],
                  )
                  client_kind
                }

                _ -> {
                  connection_logger(
                    woof.Debug,
                    "A unknown native client greets us!",
                    [],
                  )
                  client_kind
                }
              }
              Some(ewe.websocket_continue(
                WebsocketState(
                  ..state,
                  conn_data: ClientConnectionData(
                    ..connection_data,
                    client_type: Some(client_type),
                  ),
                ),
              ))
            }
            webapi.PostContentRequest(post_id:) -> todo
            webapi.RegisterPrecheck(email:, username:, password:) -> todo
            webapi.TimeLineRequest(timeline_name:, page:) -> todo
            webapi.RegisterRequest(email:, username:, password:) -> todo
            webapi.LoginAuthenticationRequest(email_username:, password:) ->
              todo
            webapi.OwnUserInformationRequest -> todo
          }
      }
      |> option.unwrap(ewe.websocket_continue(state))
    }
    ewe.Binary(_) -> ewe.websocket_continue(state)
    ewe.User(Nil) -> ewe.websocket_continue(state)
  }
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
