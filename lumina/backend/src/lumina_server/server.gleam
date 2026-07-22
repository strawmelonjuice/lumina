//// **Lumina > Backend >**
//// # HTTP Server
////
//// Server side routing as well as other webserver-related stuff is handled here.

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
import ewe.{type Request, type Response}
import gleam/bytes_tree
import gleam/crypto
import gleam/erlang/application
import gleam/erlang/process
import gleam/http
import gleam/http/cookie
import gleam/http/request
import gleam/http/response
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import lumina_server/config
import lumina_server/data.{type SessionsStore}
import lumina_server/server/components
import lumina_server/server/components/shared
import lustre/attribute
import lustre/element
import lustre/element/html
import witness
import youid/uuid

// Router ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
pub fn child(global_context: data.Globals) {
  witness.set_process_fields([
    witness.string("Process", "Webserver - main"),
  ])
  ewe.new(fn(req: Request) -> Response {
    witness.set_process_fields([
      witness.string("Process", "Webserver - request handler"),
      witness.string("path", req.path),
      witness.string("method", req.method |> http.method_to_string),
    ])
    witness.this(level: witness.Info, message: "New request", fields: [])
    req
    |> case req.method, request.path_segments(req) {
      http.Get, [] | http.Get, ["app"] | http.Get, ["app", ..] -> serves_spa(
        _,
        global_context:,
      )
      http.Get, ["static", "lumina", "lumina.svg"]
      | http.Get, ["favicon.ico"]
      | http.Get, ["lumina.svg"]
      -> serves_priv_file(
        _,
        global_context:,
        application: "lumina_server",
        path: "/static/lumina.svg",
        mime: "image/svg+xml; charset=utf-8",
      )
      http.Get, ["static", "lumina", "lumina.min.css"] -> serves_priv_file(
        _,
        global_context:,
        application: "lumina_server",
        path: "/lumina.min.css",
        mime: "text/css; charset=utf-8",
      )
      http.Get, ["static", "lumina", "lumina.css"] -> serves_priv_file(
        _,
        global_context:,
        application: "lumina_server",
        path: "/lumina.css",
        mime: "text/css; charset=utf-8",
      )
      http.Get, ["static", "lumina", "client.min.js"] -> serves_priv_file(
        _,
        global_context:,
        application: "lumina_server",
        path: "/client.min.js",
        mime: "application/javascript; charset=utf-8",
      )
      http.Get, ["static", "lumina", "client.js"] -> serves_priv_file(
        _,
        global_context:,
        application: "lumina_server",
        path: "/client.js",
        mime: "application/javascript; charset=utf-8",
      )
      http.Get, ["api", "3.1", "session", "auth-status"] -> api_auth_status(
        _,
        global_context,
      )
      http.Get, ["ws", "web", "login"] -> serve_component(
        _,
        global_context,
        components.login,
      )

      http.Get, ["ws", "web", "register"] -> serve_component(
        _,
        global_context,
        components.signup,
      )
      // Legals
      _, ["robots.txt"] -> serves_robots_txt
      _, ["licence.txt"]
      | _, ["license.txt"]
      | _, ["licence"]
      | _, ["license"]
      -> serves_priv_file(
        _,
        global_context:,
        application: "lumina_server",
        path: "/licence",
        mime: "text/plain",
      )
      _, _ -> not_found
    }
  })
  |> ewe.bind(config.application_web_host())
  |> ewe.listening(port: config.application_web_port())
  |> ewe.on_start(fn(scheme, addr) {
    let address = case addr.ip {
      ewe.IpV6(..) -> "[" <> ewe.ip_address_to_string(addr.ip) <> "]"
      ewe.IpV4(..) -> ewe.ip_address_to_string(addr.ip)
    }

    witness.this(
      witness.Info,
      "Server started on "
        <> {
        http.scheme_to_string(scheme)
        <> "://"
        <> address
        <> ":"
        <> int.to_string(addr.port)
      },
      [
        // witness.string("Scheme", scheme |> http.scheme_to_string()),
        witness.string("Address", ewe.ip_address_to_string(addr.ip)),
        witness.int("Port", addr.port),
        // Repeating this here as we apparently crossed a session boundary
        witness.string("Process", "Webserver - main"),
      ],
    )
  })
  |> ewe.idle_timeout(20_000)
  |> ewe.supervised()
}

// Responders ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

fn serve_component(
  request: request.Request(ewe.Connection),
  global: data.Globals,
  component: fn(
    shared.ComponentInitialisation,
    fn(
      fn(ewe.WebsocketConnection, process.Selector(a)) ->
        #(b, process.Selector(a)),
      fn(ewe.WebsocketConnection, b, ewe.WebsocketMessage(a)) ->
        ewe.WebsocketNext(b, a),
      fn(ewe.WebsocketConnection, b) -> Nil,
    ) -> response.Response(ewe.ResponseBody),
  ) -> response.Response(ewe.ResponseBody),
) -> response.Response(ewe.ResponseBody) {
  use session_id <- with_session(request:, global_context: global)
  let consumption =
    shared.ComponentInitialisation(session_id:, global_context: global)
  component(consumption, fn(value, value_2, value_3) {
    ewe.upgrade_websocket(request, value, value_2, value_3)
  })
}

fn api_auth_status(
  request: request.Request(ewe.Connection),
  global_context: data.Globals,
) -> response.Response(ewe.ResponseBody) {
  use session <- with_session(request:, global_context:)
  witness.this(witness.Info, "Request answered with hardcoded answer", [
    witness.int("HTTP CODE", 200),
  ])
  response.new(200)
  |> response.set_header("content-type", "text/plain; charset=utf-8")
  |> response.set_body(ewe.BytesData(
    // This is hardcoded, because for now, this is always false.
    json.object([#("authenticated", json.bool(False))])
    |> json.to_string_tree()
    |> bytes_tree.from_string_tree,
  ))
}

fn serves_priv_file(
  request: Request,
  global_context global_context: data.Globals,
  application application: String,
  path path: String,
  mime mime: String,
) -> Response {
  use _ <- with_session(request:, global_context:)
  use dir <- try_404(application.priv_directory(application))
  let resolved = absname_join(dir, string.remove_prefix(path, "/"))
  case string.starts_with(resolved, dir <> "/") {
    True -> {
      use file <- try_404(ewe.file(resolved, offset: None, limit: None))

      witness.this(witness.Info, "Request answered with file", [
        witness.int("HTTP CODE", 200),
        witness.string("File", resolved),
      ])
      response.new(200)
      |> response.set_header("content-type", mime)
      |> response.set_body(file)
    }
    False -> not_found(request)
  }
}

fn not_found(_) -> Response {
  witness.this(witness.Warning, "Not found", [
    witness.int("HTTP CODE", 404),
  ])
  response.new(404)
  |> response.set_header("content-type", "text/plain; charset=utf-8")
  |> response.set_body(ewe.TextData("Could not find that!"))
}

fn serves_spa(
  request: Request,
  global_context global_context: data.Globals,
) -> Response {
  let session_store = global_context.sessions
  use session_id <- with_session(request:, global_context:)
  let csrf_token = csrf_token(session_id, session_store)
  let html =
    html.html([attribute.lang("en")], [
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
          attribute.href("/static/lumina/lumina.min.css"),
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
            attribute.src("/static/lumina/client.js"),
          ],
          "",
        ),
      ]),
      html.body([], [
        html.div(
          [
            attribute.style("height", "100VH"),
            attribute.style("width", "100VW"),
            attribute.attribute("data-spinner", "large overlay"),
            attribute.attribute("aria-busy", "true"),
          ],
          [
            html.div([attribute.data("sidebar-layout", "")], [
              html.nav(
                [
                  attribute.data("topnav", ""),
                  attribute.styles([
                    #("background-color", "var(--accent)"),
                    #("color", "var(--accent-foreground)"),
                  ]),
                ],
                [
                  html.button(
                    [
                      // attribute.class("outline"),
                      attribute.attribute("aria-label", "Toggle menu"),
                      attribute.data("sidebar-toggle", ""),
                      attribute.data("variant", "secondary"),
                      attribute.styles([
                        #("background-color", "var(--primary)"),
                        #("width", "40px"),
                        #("height", "40px"),
                      ]),
                    ],
                    [html.text("☰")],
                  ),
                  html.span(
                    [
                      attribute.class("justify-center flex"),
                      attribute.styles([
                        #("font-family", "var(--font-logo)"),
                        #("font-size", "var(--text-2)"),
                      ]),
                    ],
                    [
                      html.span(
                        [
                          attribute.class("logo"),
                        ],
                        [
                          html.img([
                            attribute.styles([
                              #("margin-inline-end", "var(--text-3)"),
                            ]),
                            attribute.style("height", "40px"),
                            attribute.src("/favicon.ico"),
                            attribute.alt("icon"),
                          ]),
                        ],
                      ),
                      html.text("Lumina"),
                    ],
                  ),
                  html.div(
                    [
                      attribute.class("hstack flex align-right skeleton box"),
                    ],
                    [],
                  ),
                ],
              ),
              html.aside(
                [
                  attribute.data("sidebar", ""),
                  attribute.class("skeleton box"),
                  // attribute.styles([
                //   #("background-color", "var(--card)"),
                //   #("color", "var(--card-foreground)"),
                // ]),
                ],
                [],
              ),
              html.main(
                [
                  attribute.class("p-4 skeleton box"),
                  attribute.styles([
                    #("background-color", "var(--muted)"),
                    #("color", "var(--muted-foreground)"),
                  ]),
                ],
                [],
              ),
            ]),
          ],
        ),
      ]),
    ])
    |> element.to_document_string_tree
    |> bytes_tree.from_string_tree
  witness.this(witness.Info, "Request answered with index", [
    witness.int("HTTP CODE", 200),
  ])
  response.set_body(
    response.set_header(
      response.new(200),
      "content-type",
      "text/html; charset=utf-8",
    ),
    ewe.BytesData(html),
  )
}

fn serves_robots_txt(_) -> response.Response(ewe.ResponseBody) {
  response.new(200)
  |> response.set_header("content-type", "text/plain; charset=utf-8")
  |> response.set_body(ewe.TextData(
    "User-agent: *
Disallow: /

# Specifically targeting AI crawlers
User-agent: GPTBot
Disallow: /

User-agent: ChatGPT-User
Disallow: /

User-agent: Google-Extended
Disallow: /

User-agent: CCBot
Disallow: /
",
  ))
}

// Helpers ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

fn with_session(
  then: fn(String) -> Response,
  request req: Request,
  global_context globals: data.Globals,
) {
  let session =
    request.get_cookies(req)
    |> list.key_find("session-set")
    |> result.map(fn(unverified) {
      case
        crypto.verify_signed_message(unverified, globals.secrets.cookie_secret)
      {
        Ok(verified) -> uuid.from_bit_array(verified)
        Error(Nil) -> {
          witness.this(
            witness.Warning,
            "Tampered session cookie found, new session is generated.",
            [],
          )
          uuid.v4()
          |> Ok
        }
      }
    })
    |> result.flatten()
    |> result.lazy_unwrap(fn() {
      witness.this(
        witness.Error,
        "Could not decode session cookie, new session is generated.",
        [],
      )
      uuid.v4()
    })
  let session_stringified = session |> uuid.to_string
  witness.add_process_fields([
    witness.string("session cookie", session_stringified),
  ])
  then(session_stringified)
  |> response.set_cookie(
    "session-set",
    crypto.sign_message(
      session |> uuid.to_bit_array,
      globals.secrets.cookie_secret,
      crypto.Sha512,
    ),
    cookie.Attributes(
      ..cookie.defaults(req.scheme),
      http_only: True,
      same_site: Some(cookie.Lax),
      path: Some("/"),
    ),
  )
}

fn csrf_token(session_id: String, session_store: SessionsStore) {
  case data.get_csrf_for_session(session_store, session_id) {
    Ok(token) -> token
    Error(Nil) -> {
      let new_token = uuid.v4_string()
      assert Ok(Nil)
        == data.csrf_create_session(session_store, session_id, new_token)
        as "Could not insert session. Was a uuid non-unique or did data get corrupted?"
      new_token
    }
  }
}

@external(erlang, "filename", "absname_join")
fn absname_join(dir: String, file: String) -> String

fn try_404(over: Result(a, _), body: fn(a) -> Response) {
  case over {
    Ok(a) -> body(a)
    Error(_) -> not_found(Nil)
  }
}
