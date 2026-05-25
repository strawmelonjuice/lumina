//// Lumina > Server
//// Main entry point for Lumina.

// Lumina/Peonies
// Copyright (C) 2018-2026 MLC 'Strawmelonjuice' Bloeiman and contributors.
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
// This software is provided "AS IS", WITHOUT WARRANTY OF ANY KIND.
// See the Licence for the specific language governing permissions and limitations.

import booklet
import envoy
import ewe.{type Request, type Response}
import gleam/bit_array
import gleam/bytes_tree
import gleam/dict
import gleam/erlang/application
import gleam/erlang/process.{type Selector, type Subject}
import gleam/http/cookie
import gleam/http/request
import gleam/http/response
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{Some}
import gleam/order
import gleam/pair
import gleam/result
import gleam/string
import gleam/time/duration
import gleam/time/timestamp
import gleam/uri
import lumina/database/events
import lumina_client
import lumina_client/message
import lustre
import lustre/attribute
import lustre/element
import lustre/element/html.{html}
import lustre/server_component
import off_topic
import simplifile
import sqlight
import woof
import youid/uuid

type HandlerContext {
  HandlerContext(
    db: sqlight.Connection,
    client_hash: String,
    assets: String,
    static_responses: StaticResponses,
    csrf_token_store: booklet.Booklet(
      dict.Dict(String, #(String, timestamp.Timestamp)),
    ),
  )
}

type StaticRoute {
  RouteForIndex
  RouteForClientAsMinifiedJavascript
  RouteForClientAsJavascript
  RouteForClientStyles
  RouteForIconAsPNG
  RouteForIconAsSVG
  RouteForLustreComponentRuntime
  RouteForLustreComponentRuntimeMinified
  RouteForOffTopicComponentRuntime
  RouteForOffTopicComponentRuntimeMinified
}

type StaticResponses =
  fn(StaticRoute) -> response.Response(ewe.ResponseBody)

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
              woof.str("db_logging", "failed: " <> e.message),
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

  let assets = case application.priv_directory("lumina") {
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
        woof.str("revision", outcome),
      ])
      outcome
    }
  }
  let context =
    HandlerContext(
      db:,
      assets:,
      client_hash:,
      static_responses: static(client_hash, assets, setuplog),
      csrf_token_store: booklet.new(dict.new()),
    )
  // And start!
  let assert Ok(_) =
    handler(_, context)
    |> ewe.new()
    |> ewe.bind("0.0.0.0")
    |> ewe.listening(
      port: envoy.get("PORT")
      |> result.map(int.parse)
      |> result.flatten()
      |> result.unwrap(3000),
    )
    |> ewe.start

  process.spawn(csrf_token_cleaner(context.csrf_token_store))

  process.sleep_forever()
}

fn handler(req: Request, handler_ctx: HandlerContext) -> Response {
  let httplogger = fn(
    level: woof.Level,
    msg: String,
    vars: List(#(String, woof.FieldValue)),
  ) {
    woof.new("SERVER/HTTP")
    |> woof.log(level, msg, [
      woof.str("uri path", req.path),
      woof.str("request-host", case req.host {
        "0.0.0.0" -> "local (unsure)"
        d -> d
      }),
      ..vars
    ])
  }
  let ok = fn() { httplogger(woof.Info, "200/OK", []) }
  case req.path |> uri.path_segments() {
    ["/"] | [""] | [] -> serve_html(req, handler_ctx.csrf_token_store)
    ["legacy"] | ["legacy.html"] -> {
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
    ["static", "lustre-thin.mjs"] ->
      handler_ctx.static_responses(RouteForLustreComponentRuntime)
    ["static", "lustre-thin.min.mjs"] ->
      handler_ctx.static_responses(RouteForLustreComponentRuntimeMinified)
    ["static", "off-topic.mjs"] ->
      handler_ctx.static_responses(RouteForOffTopicComponentRuntime)
    ["static", "off-topic.min.mjs"] ->
      handler_ctx.static_responses(RouteForOffTopicComponentRuntimeMinified)
    // Newer implementation, the server component.
    ["client"] -> serve_component(req, handler_ctx.csrf_token_store)

    _ -> {
      httplogger(woof.Warning, "Not found.", [])
      response.new(404)
      |> response.set_header("content-type", "text/plain; charset=utf-8")
      |> response.set_body(ewe.TextData("404! Not found!"))
    }
  }
}

fn serve_component(
  request: Request,
  csrf_token_store: booklet.Booklet(
    dict.Dict(String, #(String, timestamp.Timestamp)),
  ),
) {
  use session <- with_session(request:)
  let expected_csrf_token = csrf_token(session, csrf_token_store)
  // Extracts csrf token from request
  let provided_csrf_token =
    request
    |> request.get_query
    |> result.try(list.key_find(_, "csrf-token"))

  case provided_csrf_token {
    Ok(token) if token == expected_csrf_token ->
      ewe.upgrade_websocket(
        request,
        on_init: init_component_socket,
        handler: loop_message_socket,
        on_close: close_component_socket,
      )

    Ok(_) | Error(_) -> {
      response.new(403)
      |> response.set_body(ewe.BytesData(bytes_tree.new()))
    }
  }
}

type LuminaServerComponentSocket {
  LuminaServerComponentSocket(
    component: lustre.Runtime(off_topic.Message(message.Message)),
    self: Subject(
      server_component.ClientMessage(off_topic.Message(message.Message)),
    ),
  )
}

type LuminaServerComponentSocketMessage =
  server_component.ClientMessage(off_topic.Message(message.Message))

fn init_component_socket(
  _: ewe.WebsocketConnection,
  _: Selector(LuminaServerComponentSocketMessage),
) -> #(
  LuminaServerComponentSocket,
  Selector(LuminaServerComponentSocketMessage),
) {
  let assert Ok(component) =
    lustre.start_server_component(
      lumina_client.app(todo as "Update function goes here"),
      Nil,
    )
  let self = process.new_subject()
  let selector =
    process.new_selector()
    |> process.select(self)
  let selector = process.select(selector, self)

  server_component.register_subject(self)
  |> lustre.send(to: component)

  #(LuminaServerComponentSocket(component:, self:), selector)
}

fn loop_message_socket(
  connection: ewe.WebsocketConnection,
  state: LuminaServerComponentSocket,
  message: ewe.WebsocketMessage(LuminaServerComponentSocketMessage),
) -> ewe.WebsocketNext(
  LuminaServerComponentSocket,
  LuminaServerComponentSocketMessage,
) {
  case message {
    ewe.Text(json) -> {
      case json.parse(json, server_component.runtime_message_decoder()) {
        Ok(runtime_message) -> lustre.send(state.component, runtime_message)
        Error(_) -> Nil
      }

      ewe.websocket_continue(state)
    }

    ewe.Binary(_) -> {
      ewe.websocket_continue(state)
    }

    ewe.User(client_message) -> {
      let json = server_component.client_message_to_json(client_message)
      let assert Ok(_) = ewe.send_text_frame(connection, json.to_string(json))

      ewe.websocket_continue(state)
    }
  }
}

fn close_component_socket(_, state: LuminaServerComponentSocket) -> Nil {
  lustre.shutdown()
  |> lustre.send(to: state.component)
}

// Helpers

fn with_session(then: fn(String) -> Response, request req: Request) {
  let session =
    request.get_cookies(req)
    |> list.key_find("session-set")
    |> result.lazy_unwrap(uuid.v4_string)
  woof.with_context([woof.str("server-session", session)], fn() {
    then(session)
    |> response.set_cookie(
      "session-set",
      session,
      cookie.Attributes(
        ..cookie.defaults(req.scheme),
        http_only: True,
        same_site: Some(cookie.Lax),
        path: Some("/"),
      ),
    )
  })
}

fn csrf_token_cleaner(
  csrf_token_store: booklet.Booklet(
    dict.Dict(String, #(String, timestamp.Timestamp)),
  ),
) {
  fn() {
    process.sleep(50_000)
    booklet.update(
      csrf_token_store,
      dict.filter(_, fn(_, token) {
        {
          timestamp.difference(token.1, timestamp.system_time())
          |> duration.compare(duration.hours(12))
        }
        // Must be Less-than 12 hours old.
        == order.Lt
        // ... otherwise is removed.
      }),
    )
    csrf_token_cleaner(csrf_token_store)()
  }
}

fn csrf_token(
  session: String,
  csrf_token_store: booklet.Booklet(
    dict.Dict(String, #(String, timestamp.Timestamp)),
  ),
) {
  case booklet.get(csrf_token_store) |> dict.get(session) {
    Ok(token) -> token.0
    Error(Nil) -> {
      let new_token = #(uuid.v4_string(), timestamp.system_time())
      booklet.update(csrf_token_store, dict.insert(_, session, new_token))
      new_token.0
    }
  }
}

// HTML ------------------------------------------------------------------------

fn serve_html(
  request: Request,
  csrf_token_store: booklet.Booklet(
    dict.Dict(String, #(String, timestamp.Timestamp)),
  ),
) -> Response {
  use session <- with_session(request:)
  let csrf_token = csrf_token(session, csrf_token_store)
  let html =
    html([attribute.lang("en")], [
      html.head([], [
        html.meta([attribute.charset("utf-8")]),
        html.meta([
          attribute.content(
            "width=device-width, initial-scale=1.0, viewport-fit=cover",
          ),
          attribute.name("viewport"),
        ]),
        html.title([], "Lumina"),
        html.link([
          attribute.crossorigin(""),
          attribute.href("https://fonts.mar.ollie.earth/"),
          attribute.rel("preconnect"),
        ]),
        html.link([
          attribute.rel("stylesheet"),
          attribute.href(
            "https://fonts.mar.ollie.earth/https://fonts.googleapis.com/css2?family=DM+Mono:ital,wght@0,300;0,400;0,500;1,300;1,400;1,500&family=Elms+Sans:ital,wght@0,100..900;1,100..900&family=Gantari:ital,wght@0,100..900;1,100..900&family=Josefin+Sans:ital,wght@0,100..700;1,100..700&family=Vend+Sans&display=swap",
          ),
        ]),
        html.link([
          attribute.href("/static/lumina.css"),
          attribute.rel("stylesheet"),
        ]),
        html.meta([
          attribute.content("noai, noimageai, nofollow"),
          attribute.name("robots"),
        ]),
        html.meta([
          attribute.name("csrf-token"),
          attribute.content(csrf_token),
          // attribute.content("invalid-token"),
        ]),
        html.title([], "Lumina"),
        html.script(
          [
            attribute.type_("module"),
            attribute.src("/static/lustre-thin.min.mjs"),
          ],
          "",
        ),
        html.script(
          [
            attribute.type_("module"),
            attribute.src("/static/off-topic.min.mjs"),
          ],
          "",
        ),
      ]),
      html.body([], [
        server_component.element([server_component.route("/client")], []),
      ]),
    ])
    |> element.to_document_string_tree
    |> bytes_tree.from_string_tree

  response.set_body(
    response.set_header(
      response.new(200),
      "content-type",
      "text/html; charset=utf-8",
    ),
    ewe.BytesData(html),
  )
}

fn static(
  client_hash: String,
  assets: String,
  setuplog: woof.Logger,
) -> StaticResponses {
  let client_servible =
    [
      <<
        "<!doctype html><html lang=\"en\"><head><meta charset=\"UTF-8\" /><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, viewport-fit=cover\" /><title>Lumina</title><link rel=\"preconnect\" href=\"https://fontlay.com\" crossorigin /><link href=\"https://fontlay.com/css2?family=DM+Mono:ital,wght@0,300;0,400;0,500;1,300;1,400;1,500&family=Elms+Sans:ital,wght@0,100..900;1,100..900&family=Gantari:ital,wght@0,100..900;1,100..900&family=Josefin+Sans:ital,wght@0,100..700;1,100..700&family=Vend+Sans&display=swap\" rel=\"stylesheet\"><link	rel=\"stylesheet\" href=\"/static/lumina.css\"/><meta name=\"robots\" content=\"noai, noimageai, nofollow\"><script>window.clientHash = \"":utf8,
      >>,
      client_hash |> bit_array.from_string,
      <<"\";</script><script type=\"module\">":utf8>>,
      case simplifile.read_bits(assets <> "/static/lumina_client.min.mjs") {
        Error(_) -> {
          setuplog
          |> woof.log(woof.Error, "Missing application assets.", [
            woof.str("File", assets <> "/static/lumina_client.min.mjs"),
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

  let builtin_file = fn(file: String, mime: String) -> response.Response(
    ewe.ResponseBody,
  ) {
    case simplifile.read_bits(file) {
      Error(_) -> {
        setuplog
        |> woof.log(woof.Error, "Missing application assets.", [
          woof.str("File", file),
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
  let lustre_component_runtime_min = {
    let assert Ok(lustre_priv) = application.priv_directory("lustre")
    let file_path = lustre_priv <> "/static/lustre-server-component.min.mjs"
    builtin_file(file_path, "application/javascript; charset=utf-8")
  }
  let lustre_component_runtime = {
    let assert Ok(lustre_priv) = application.priv_directory("lustre")
    let file_path = lustre_priv <> "/static/lustre-server-component.mjs"
    builtin_file(file_path, "application/javascript; charset=utf-8")
  }
  let offtopic_component_runtime_min = {
    let assert Ok(offtopic_priv) = application.priv_directory("off_topic")
    let file_path = offtopic_priv <> "/static/off-topic.min.mjs"
    builtin_file(file_path, "application/javascript; charset=utf-8")
  }
  let offtopic_component_runtime = {
    let assert Ok(offtopic_priv) = application.priv_directory("off_topic")
    let file_path = offtopic_priv <> "/static/off-topic.mjs"
    builtin_file(file_path, "application/javascript; charset=utf-8")
  }
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
      RouteForLustreComponentRuntime -> lustre_component_runtime
      RouteForLustreComponentRuntimeMinified -> lustre_component_runtime_min
      RouteForOffTopicComponentRuntime -> offtopic_component_runtime
      RouteForOffTopicComponentRuntimeMinified -> offtopic_component_runtime_min
    }
  }
}
