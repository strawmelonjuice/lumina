//// **Lumina >**
//// # Web client
////
//// Initialising and routing SPA for Lumina on the web.

// Imports ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

import gleam/bit_array
import gleam/bool
import gleam/dynamic/decode
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/uri.{type Uri}
import lustre
import lustre/attribute.{type Attribute}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/element/keyed
import lustre/event
import lustre/server_component
import modem
import rsvp
import witness

// Main ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

pub fn main() {
  witness.new("Lumina SPA")
  |> witness.with_console(witness.Debug, witness.Text)
  |> witness.configure
  witness.this(witness.Info, "Hello from lumina_spa!", [])

  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "body", Nil)

  Nil
}

// Model ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

type Model {
  Model(
    route: Route,
    user_authenticated: Option(MyUser),
    session_id: Option(String),
  )
}

pub type MyUser {
  MyUser(
    /// User ID (uuid)
    user_did: String,
    /// Username
    user_name: String,
    /// Email
    user_email: Option(String),
    /// Avatar as uri string, either a full URL or a base64-encoded 'data:'-string. If set to none, the user's display
    /// name initials are used instead.
    user_avatar: Option(String),
    /// Notifications
    notifs: List(
      // This should be something more specific than a string, but for now it's not.
      String,
    ),
  )
}

/// Available route for Lumina!
type Route {
  Index
  Login
  Register
  Timeline(id: String)
  Post(id: String)
  About
  NotFound(uri: Uri)
  External(location: String)
}

/// Used to turn a uri into a Route
fn parse_route(uri: Uri) -> Route {
  case uri.path_segments(uri.path |> string.remove_prefix("/app")) {
    [] | [""] -> Index
    ["login"] -> Login
    ["signup"] -> Register
    ["post", post_id] -> Post(id: post_id)
    ["browse", tl_id] -> Timeline(id: tl_id)
    ["browse"] -> Timeline("global")
    ["about"] -> About
    ["out", location] -> {
      bit_array.base64_url_decode(location)
      |> result.map(bit_array.to_string)
      |> result.flatten
      |> result.map(External)
      |> result.unwrap(NotFound(uri:))
    }
    _ -> NotFound(uri:)
  }
}

/// Used to turn a Route into an attribute.href Attribute
fn href(route: Route) -> Attribute(Message) {
  let url =
    "/app"
    <> case route {
      Index -> "/"
      About -> "/about"
      Login -> "/login"
      Post(post_id) -> "/post/" <> post_id
      NotFound(_) -> "/404"
      Register -> "/signup"
      Timeline(id:) if id == "global" -> "/browse/"
      Timeline(id:) -> "/browse/" <> id
      External(location:) ->
        "/out/"
        <> bit_array.from_string(location) |> bit_array.base64_url_encode(True)
    }

  attribute.href(url)
}

fn init(_) -> #(Model, Effect(Message)) {
  let route = case modem.initial_uri() {
    Ok(uri) -> parse_route(uri)
    Error(_) -> Index
  }

  let model = Model(route:, user_authenticated: None, session_id: None)

  let effect =
    effect.batch([
      modem.init(fn(uri) { UserNavigatedTo(parse_route(uri)) }),

      case get_session_revive_key() {
        Ok(key) -> try_session_revive(key)
        _ -> {
          witness.this(witness.Info, "No past sessions to revive!", [])
          check_auth_status()
        }
      },
    ])

  #(model, effect)
}

fn try_session_revive(key: String) -> Effect(Message) {
  // TODO: Implement this
  // For now:
  effect.none()
}

@external(javascript, "./lumina_spa_ffi", "with_timeout")
fn set_timeout(_delay: Int, _cb: fn() -> a) -> Nil {
  Nil
}

fn wait_message(message: Message, delay: Int) {
  use dispatch <- effect.from()
  use <- set_timeout(delay)
  dispatch(message)
}

fn check_auth_status() {
  let url = "/api/3.1/session/auth-status/"
  let decoder = {
    use authenticated <- decode.then(decode.at(["authenticated"], decode.bool))
    case authenticated {
      False ->
        None
        |> decode.success
      True -> {
        use user_did <- decode.field("user_did", decode.string)
        use user_name <- decode.field("user_name", decode.string)
        use user_email <- decode.field(
          "user_email",
          decode.optional(decode.string),
        )
        use session_id <- decode.field("session_id", decode.string)
        use session_revive_key <- decode.field(
          "session_revive-key",
          decode.string,
        )

        todo
      }
    }
  }
  let handler =
    rsvp.expect_json(
      decoder,
      fn(returned: Result(Option(MyUser), rsvp.Error(String))) -> Message {
        let returned = result.unwrap(returned, None)
        AuthenticationCheckResponse(returned)
      },
    )

  rsvp.get(url, handler)
}

@external(javascript, "./lumina_spa_ffi", "getSessionRevivekey")
fn get_session_revive_key() -> Result(String, Nil)

@external(javascript, "./lumina_spa_ffi", "storeSessionRevivekey")
fn store_session_revive_key(_: String) -> Nil

// Update ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

type Message {
  UserNavigatedTo(route: Route)
  AuthenticationCheckResponse(Option(MyUser))
  RetryAuthenticationCheck
  UserNavigatedBack(by: Int)
  NewUserSession(
    user_did: String,
    user_name: String,
    user_email: Option(String),
    user_avatar: Option(String),
    session_id: String,
    session_revive_key: String,
  )
}

fn update(model: Model, message: Message) -> #(Model, Effect(Message)) {
  case message {
    UserNavigatedBack(by:) -> #(model, modem.back(by))

    UserNavigatedTo(route:) -> #(Model(..model, route:), effect.none())

    AuthenticationCheckResponse(None) -> #(
      model,
      wait_message(RetryAuthenticationCheck, 1200),
    )
    RetryAuthenticationCheck -> {
      #(model, {
        case model.user_authenticated {
          Some(..) -> effect.none()
          None -> check_auth_status()
        }
      })
    }

    AuthenticationCheckResponse(_) -> todo
    NewUserSession(
      user_did:,
      user_name:,
      user_email:,
      user_avatar:,
      session_id:,
      session_revive_key:,
    ) -> {
      #(
        Model(
          ..model,
          session_id: Some(session_id),
          user_authenticated: Some(
            MyUser(user_did:, user_name:, user_email:, user_avatar:, notifs: []),
          ),
        ),
        effect.batch([
          wait_message(UserNavigatedTo(route: Timeline("global")), 300),
          effect.from(fn(_) { store_session_revive_key(session_revive_key) }),
        ]),
      )
    }
  }
}

// View ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

fn view(model: Model) -> Element(Message) {
  let #(sidebar_content, main_page_content) = {
    case model.route {
      Index -> view_index(model)
      Login -> {
        #(view_default_sidebar(model), [
          keyed.div([], [
            #(
              "logincomponent",
              server_component.element(
                [
                  server_component.route("/ws/web/login"),
                  event.on("update", {
                    decode.field(
                      "details",
                      {
                        use user_did <- decode.field("user_did", decode.string)
                        use user_name <- decode.field(
                          "user_name",
                          decode.string,
                        )
                        use user_email <- decode.field(
                          "user_email",
                          decode.optional(decode.string),
                        )
                        use user_avatar <- decode.field(
                          "user_avatar",
                          decode.optional(decode.string),
                        )
                        use session_id <- decode.field(
                          "session_id",
                          decode.string,
                        )
                        use session_revive_key <- decode.field(
                          "session_revive-key",
                          decode.string,
                        )

                        decode.success(NewUserSession(
                          user_did:,
                          user_name:,
                          user_email:,
                          user_avatar:,
                          session_id:,
                          session_revive_key:,
                        ))
                      },
                      decode.success,
                    )
                  }),
                ],
                [],
              ),
            ),
          ]),
        ])
      }

      Post(post_id) -> #(view_default_sidebar(model), [
        html.div([], [
          server_component.element(
            [server_component.route("/ws/web/postrender/" <> post_id)],
            [],
          ),
        ]),
      ])

      About -> view_about(model)
      NotFound(_) -> view_not_found()
      Register -> #(view_default_sidebar(model), [
        keyed.div([], [
          #(
            "registercomponent",
            server_component.element(
              [
                server_component.route("/ws/web/register"),
              ],
              [],
            ),
          ),
        ]),
      ])
      Timeline(id:) -> #(
        [
          server_component.element(
            [server_component.route("/ws/web/timeline/" <> id <> "/aside")],
            [],
          ),
        ],
        [
          server_component.element(
            [server_component.route("/ws/web/timeline/" <> id <> "/main")],
            [],
          ),
        ],
      )
      External(location:) -> view_external(location)
    }
  }

  html.div([attribute.data("sidebar-layout", "")], [
    html.nav(
      [
        attribute.data("topnav", ""),
        attribute.styles([
          #("background-color", "var(--accent)"),
          #("color", "var(--accent-foreground)"),
          #("justify-content", "space-between"),
        ]),
      ],
      [
        html.button(
          [
            // attribute.class("outline"),
            attribute.attribute("aria-label", "Toggle menu"),
            attribute.data("sidebar-toggle", ""),
            attribute.data("variant", "primary"),
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
            html.a(
              [
                attribute.class("logo"),
                href(Index),
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
        html.nav(
          [
            attribute.class("hstack flex align-right"),
            attribute.styles([
              #("font-family", "var(--font-menuitems)"),
              #("justify-content", "flex-end"),
            ]),
          ],
          [
            view_header_button(
              current: model.route,
              show_on: list.append(if_unauthenticated([Index, About], model), [
                Register,
                Login,
              ]),
              to: Login,
              label: "Login",
            ),
            view_header_button(
              current: model.route,
              show_on: list.append(if_unauthenticated([Index, About], model), [
                Register,
                Login,
              ]),
              to: Register,
              label: "Sign up",
            ),
            case model.user_authenticated {
              Some(user) ->
                element.element("ot-dropdown", [], [
                  html.button(
                    [
                      attribute.attribute("popovertarget", "self-menu"),
                      attribute.class("unstyled"),
                      attribute.styles([#("padding", "0")]),
                    ],
                    [
                      html.figure(
                        [
                          attribute.attribute("aria-label", "Oat"),
                          attribute.attribute("data-variant", "avatar"),
                        ],
                        [
                          html.abbr([attribute.attribute("title", "Jane Doe")], [
                            html.text("OT"),
                          ]),
                        ],
                      ),
                    ],
                  ),
                  html.menu(
                    [
                      attribute.id("self-menu"),
                      attribute.attribute("popover", ""),
                    ],
                    [
                      html.button(
                        [attribute.class("ghost"), attribute.role("menuitem")],
                        [html.text("Profile")],
                      ),
                      html.button(
                        [attribute.class("ghost"), attribute.role("menuitem")],
                        [html.text("Help")],
                      ),
                      html.a(
                        [
                          attribute.role("menuitem"),
                          attribute.href("#"),
                        ],
                        [html.text("Link")],
                      ),
                      html.hr([]),
                      html.button(
                        [attribute.class("ghost"), attribute.role("menuitem")],
                        [html.text("Logout")],
                      ),
                    ],
                  ),
                ])
              None -> element.none()
            },
          ],
        ),
      ],
    ),
    html.aside(
      [
        attribute.data("sidebar", ""),
      ],
      sidebar_content,
    ),
    html.main(
      [
        attribute.class("p-4"),
        attribute.styles([
          #("background-color", "var(--muted)"),
          #("color", "var(--muted-foreground)"),
        ]),
      ],
      main_page_content,
    ),
  ])
}

// Page views ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
fn view_index(
  model: Model,
) -> #(List(Element(Message)), List(Element(Message))) {
  #(
    [
      html.header([], [element.text("Hai")]),
      html.nav(
        [
          attribute.styles([
            #("font-family", "var(--font-menuitems)"),
          ]),
        ],
        [
          html.text("on-page navigation"),
        ],
      ),
      html.footer([], [
        html.text("Actions"),
        html.nav(
          [
            attribute.styles([
              #("font-family", "var(--font-menuitems)"),
            ]),
          ],
          [
            view_sidebar_button(
              current: model.route,
              show_on: [],
              to: About,
              label: "About Lumina",
            ),
          ],
        ),
      ]),
    ],
    [
      html.div([attribute.class("align-center justify-center p-4")], [
        html.h1([], [
          html.text("Welcome to Lumina!"),
        ]),
        leading("It's ... running?"),
        paragraph("There is not much going on at the moment still yet though!"),
        link(
          External("https://tangled.org/strawmelonjuice.com/Lumina"),
          "Visit Lumina's source code",
        ),
      ]),
    ],
  )
}

fn view_default_sidebar(model: Model) -> List(Element(Message)) {
  [
    html.header([], [element.text("Hai")]),
    html.nav(
      [
        attribute.styles([
          #("font-family", "var(--font-menuitems)"),
        ]),
      ],
      [
        html.text("on-page navigation"),
      ],
    ),
    html.footer([], [
      html.text("Actions"),
      html.nav(
        [
          attribute.styles([
            #("font-family", "var(--font-menuitems)"),
          ]),
        ],
        [
          view_sidebar_button(
            current: model.route,
            show_on: [],
            to: About,
            label: "About Lumina",
          ),
        ],
      ),
    ]),
  ]
}

fn view_about(
  model: Model,
) -> #(List(Element(Message)), List(Element(Message))) {
  #(
    [
      html.header([], [element.text("Go...")]),
      html.nav(
        [
          attribute.styles([
            #("font-family", "var(--font-menuitems)"),
          ]),
        ],
        [
          view_menu_link(
            current: model.route,
            show_on: [],
            to: Index,
            label: "Back home",
          ),
          view_menu_link(
            current: model.route,
            show_on: [],
            to: External("https://tangled.org/strawmelonjuice.com/Lumina"),
            label: "View source code",
          ),
        ],
      ),
      html.footer([], []),
    ],
    [
      html.h1([], [html.text("About Lumina")]),
      leading("Lumina/Peonies "),
    ],
  )
}

fn view_external(
  location: String,
) -> #(List(Element(Message)), List(Element(Message))) {
  #([], [
    html.div(
      [
        attribute.class("items-center justify-center flex"),
        attribute.styles([
          #("position", "fixed"),
          #("top", "0"),
          #("left", "0"),
          #("height", "100dVH"),
          #("width", "100dVW"),
        ]),
      ],
      [
        html.article(
          [
            attribute.class("card"),
          ],
          [
            html.header([], [
              html.h3([], [html.text("Leaving Lumina")]),
              leading("You are about to go to an external site."),
            ]),
            html.p([], [
              element.text("Do you trust "),
              html.code(
                [
                  attribute.styles([
                    #("user-select", "text"),
                    #("-webkit-user-select", "text"),
                  ]),
                ],
                [element.text(location)],
              ),
              element.text("?"),
            ]),
            html.footer([attribute.class("hstack")], [
              html.button(
                [
                  attribute.class("outline"),
                  event.on_click(UserNavigatedBack(by: 1)),
                ],
                [html.text("Cancel")],
              ),
              html.a([attribute.href(location)], [
                html.button(
                  [
                    attribute.data("variant", "danger"),
                    attribute.class("outline"),
                  ],
                  [
                    html.text("Yes, take me there!"),
                  ],
                ),
              ]),
            ]),
          ],
        ),
      ],
    ),
  ])
}

fn view_not_found() -> #(List(Element(Message)), List(Element(Message))) {
  #(
    [
      html.nav(
        [
          attribute.styles([
            #("font-family", "var(--font-menuitems)"),
          ]),
        ],
        [
          html.li([], [
            html.a([attribute.href("/app/")], [html.text("Back home")]),
          ]),
        ],
      ),
    ],
    [
      html.h1([], [html.text("Not found")]),
      paragraph(
        "You glimpse into the void and see -- nothing?
       Well that was somewhat expected.",
      ),
    ],
  )
}

// View helpers

fn leading(text: String) -> Element(Message) {
  html.p(
    [
      attribute.class("text-light"),
      attribute.styles([
        #("padding-top", "0"),
        #("font-weight", "var(--font-bold)"),
        #("margin-block-start", "0"),
        #("margin-bottom", "var(--space-8)"),
      ]),
    ],
    [html.text(text)],
  )
}

fn paragraph(text: String) -> Element(Message) {
  html.p([attribute.class("mt-3")], [html.text(text)])
}

fn link(target: Route, title: String) -> Element(Message) {
  html.a(
    [
      href(target),
    ],
    [html.text(title)],
  )
}

fn if_unauthenticated(on: List(Route), model: Model) -> List(Route) {
  case model.user_authenticated {
    None -> on
    Some(..) -> []
  }
}

fn view_header_button(
  to target: Route,
  current current: Route,
  show_on show_on: List(Route),
  label text: String,
) -> Element(Message) {
  use <- bool.guard(
    !bool.or(list.contains(show_on, current), list.is_empty(show_on)),
    element.none(),
  )
  let is_active = case current, target {
    Post(_), Login -> True
    _, _ -> current == target
  }
  html.a(
    case is_active {
      True -> [attribute.aria_current("page"), href(target)]
      False -> [href(target)]
    },
    [html.button([attribute.class("small")], [html.text(text)])],
  )
}

fn view_sidebar_button(
  to target: Route,
  current current: Route,
  show_on show_on: List(Route),
  label text: String,
) -> Element(Message) {
  use <- bool.guard(
    !bool.or(list.contains(show_on, current), list.is_empty(show_on)),
    element.none(),
  )
  let is_active = case current, target {
    Post(_), Login -> True
    _, _ -> current == target
  }
  html.a(
    case is_active {
      True -> [attribute.aria_current("page"), href(target)]
      False -> [href(target)]
    },
    [
      html.button(
        [
          attribute.class("outline small"),
          attribute.styles([#("width", "100%")]),
        ],
        [html.text(text)],
      ),
    ],
  )
}

fn view_menu_link(
  to target: Route,
  current current: Route,
  show_on show_on: List(Route),
  label text: String,
) -> Element(Message) {
  use <- bool.guard(
    !bool.or(list.contains(show_on, current), list.is_empty(show_on)),
    element.none(),
  )
  let is_active = case current, target {
    Post(_), Login -> True
    _, _ -> current == target
  }
  html.li([], [
    html.a(
      case is_active {
        True -> [attribute.aria_current("page"), href(target)]
        False -> [href(target)]
      },
      [html.text(text)],
    ),
  ])
}
