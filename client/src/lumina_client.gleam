//// For now, as you may see, I am compiling examples from Lustre packages into a single file.
//// Once I get time to work on the actual project, I'll adapt them further to original code fitting the project's needs.

import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleamy_lights/console
import gleamy_lights/premixed
import lumina_client/dom
import lumina_client/model.{type Model, Model}
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import lustre_websocket

// MAIN ------------------------------------------------------------------------

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
}

// INIT ------------------------------------------------------------------------

fn init(_flags: a) -> #(Model, Effect(Msg)) {
  #(
    Model(model.Landing, None, None),
    lustre_websocket.init("/connection", WsWrapper),
  )
}

// UPDATE ----------------------------------------------------------------------

pub opaque type Msg {
  WsWrapper(lustre_websocket.WebSocketEvent)
  ToLoginPage
  ToRegisterPage
  ToLandingPage
  // Can be re-used for both login and register pages
  UpdateEmailField(String)
  UpdatePasswordField(String)
  // Register page
  UpdateUsernameField(String)
  UpdatePasswordConfirmField(String)
}

fn update(model_: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    WsWrapper(event) -> update_ws(model_, event)
    ToLoginPage -> #(
      Model(..model_, page: model.Login(fields: model.LoginFields("", ""))),
      effect.none(),
    )
    ToRegisterPage -> #(
      Model(
        ..model_,
        page: model.Register(fields: model.RegisterPageFields("", "", "", "")),
      ),
      effect.none(),
    )
    ToLandingPage -> #(Model(model.Landing, None, None), effect.none())
    UpdateEmailField(new_email) -> {
      case model_.page {
        model.Register(fields) -> #(
          Model(
            ..model_,
            page: model.Register(
              fields: model.RegisterPageFields(..fields, emailfield: new_email),
            ),
          ),
          effect.none(),
        )
        model.Login(fields) -> #(
          Model(
            ..model_,
            page: model.Login(
              fields: model.LoginFields(..fields, emailfield: new_email),
            ),
          ),
          effect.none(),
        )
        _ -> #(model_, effect.none())
      }
    }
    UpdatePasswordField(new_password) -> {
      case model_.page {
        model.Register(fields) -> #(
          Model(
            ..model_,
            page: model.Register(
              model.RegisterPageFields(..fields, passwordfield: new_password),
            ),
          ),
          effect.none(),
        )
        model.Login(fields) -> #(
          Model(
            ..model_,
            page: model.Login(
              fields: model.LoginFields(..fields, passwordfield: new_password),
            ),
          ),
          effect.none(),
        )
        _ -> #(model_, effect.none())
      }
    }
    UpdatePasswordConfirmField(new_password_confirmation) -> {
      case model_.page {
        model.Register(fields) -> #(
          Model(
            ..model_,
            page: model.Register(
              fields: model.RegisterPageFields(
                ..fields,
                passwordconfirmfield: new_password_confirmation,
              ),
            ),
          ),
          effect.none(),
        )
        _ -> #(model_, effect.none())
      }
    }
    UpdateUsernameField(new_username) -> {
      case model_.page {
        model.Register(fields) -> #(
          Model(
            ..model_,
            page: model.Register(
              fields: model.RegisterPageFields(..fields, usernamefield: {
                new_username
                |> string.trim()
                |> string.replace(" ", "")
                |> string.lowercase()
                |> string.replace("@", "")
                |> string.replace(".", "")
              }),
            ),
          ),
          effect.none(),
        )
        _ -> #(model_, effect.none())
      }
    }
  }
}

fn update_ws(model_: Model, wsevent: lustre_websocket.WebSocketEvent) {
  case wsevent {
    lustre_websocket.InvalidUrl -> panic
    lustre_websocket.OnTextMessage(notice) ->
      case
        json.parse(notice, {
          ws_msg_decoder(
            json.parse(notice, ws_msg_typedefiner())
            |> result.unwrap("Unparsable message"),
          )
        })
      {
        Ok(Greeting(m)) -> {
          console.log("The server says hi! '" <> m <> "'")
          #(model_, effect.none())
        }
        Ok(f) -> {
          console.error("Unhandled message: " <> string.inspect(f))
          #(model_, effect.none())
        }
        Error(err) -> {
          console.error(
            "Message could not be parsed:"
            <> premixed.text_error_red(string.inspect(err)),
          )
          #(model_, effect.none())
        }
      }
    lustre_websocket.OnBinaryMessage(_msg) ->
      todo as "bitarray incoming, what to do?"
    lustre_websocket.OnClose(_reason) -> #(
      Model(..model_, ws: None),
      effect.none(),
    )
    lustre_websocket.OnOpen(socket) -> #(
      Model(..model_, ws: Some(socket)),
      lustre_websocket.send(socket, "client-init"),
    )
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model_: Model) -> Element(Msg) {
  html.div(
    [get_color_scheme(model_), attribute.class("w-screen h-screen")],
    case model_.page {
      model.Landing -> view_landing()
      model.Register(..) -> view_register(model_)
      model.Login(..) -> view_login(model_)
      model.HomeTimeline(timeline_id) ->
        todo as "HomeTimeline page not yet implemented"
    },
  )
}

fn view_landing() -> List(Element(Msg)) {
  [
    html.div([attribute.class("navbar bg-base-100 shadow-sm")], [
      html.div([attribute.class("flex-none")], [
        html.button([attribute.class("btn btn-square btn-ghost")], [
          html.img([
            attribute.src("https://lumina.app/assets/logo.svg"),
            attribute.alt("Lumina logo"),
            attribute.class("h-8"),
          ]),
        ]),
      ]),
      html.div([attribute.class("flex-1")], [
        html.a([attribute.class("btn btn-ghost text-xl")], [html.text("Lumina")]),
      ]),
    ]),
    html.div(
      [attribute.class("hero bg-base-200 h-screen max-h-[calc(100vh-4rem)]")],
      [
        html.div([attribute.class("hero-content text-center")], [
          html.div([attribute.class("max-w-md")], [
            html.h1([attribute.class("text-5xl font-bold")], [
              html.text("Welcome to Lumina!"),
            ]),
            html.p([attribute.class("py-6")], [
              html.text(
                "This should be a nice landing page, but I don't know what to put here right now. Go away! Skram!",
              ),
            ]),
            html.button(
              [attribute.class("btn btn-primary"), event.on_click(ToLoginPage)],
              [html.text("Login")],
            ),
            html.button(
              [
                attribute.class("btn btn-secondary"),
                event.on_click(ToRegisterPage),
              ],
              [html.text("Register")],
            ),
          ]),
        ]),
      ],
    ),
  ]
}

fn view_login(model_: Model) -> List(Element(Msg)) {
  // We know that the model is a Login page, so we can safely unwrap it
  let assert model.Login(fieldvalues) = model_.page

  let values_ok = {
    [{ fieldvalues.passwordfield != "" }, { fieldvalues.emailfield != "" }]
    |> list.all(fn(x) { x })
  }
  [
    html.div([attribute.class("navbar bg-base-100 shadow-sm")], [
      html.div([attribute.class("flex-none")], [
        html.button([attribute.class("btn btn-square btn-ghost")], [
          html.img([
            attribute.src("https://lumina.app/assets/logo.svg"),
            attribute.alt("Lumina logo"),
            attribute.class("h-8"),
          ]),
        ]),
      ]),
      html.div([attribute.class("flex-1")], [
        html.a([attribute.class("btn btn-ghost text-xl")], [html.text("Lumina")]),
      ]),
      html.div([attribute.class("flex-none")], [
        html.ul([attribute.class("menu menu-horizontal px-1")], [
          html.li([event.on_click(ToLandingPage)], [
            html.a([], [html.text("Back")]),
          ]),
          html.li([event.on_click(ToRegisterPage)], [
            html.a([], [html.text("Register")]),
          ]),
          html.li([event.on_click(ToLoginPage)], [
            html.a([attribute.class("bg-primary text-primary-content")], [
              html.text("Login"),
            ]),
          ]),
        ]),
      ]),
    ]),
    html.div(
      [attribute.class("hero bg-base-200 h-screen max-h-[calc(100vh-4rem)]")],
      [
        html.div(
          [attribute.class("hero-content flex-col lg:flex-row-reverse")],
          [
            html.div([attribute.class("text-center lg:text-left")], [
              html.h1([attribute.class("text-5xl font-bold")], [
                html.text("Log in to Lumina!"),
              ]),
              html.p([attribute.class("py-6")], [
                html.text(
                  "And we have boiling water. I REALLY don't know what to put here right now.",
                ),
              ]),
            ]),
            html.div(
              [
                attribute.class(
                  "card bg-base-100 w-full max-w-sm shrink-0 shadow-2xl",
                ),
              ],
              [
                html.div([attribute.class("card-body m-4")], [
                  html.fieldset([attribute.class("fieldset")], [
                    html.label([attribute.class("fieldset-label")], [
                      html.text("Email or username"),
                    ]),
                    html.input([
                      attribute.placeholder("me@mymail.com"),
                      attribute.class("input input-primary bg-primary"),
                      attribute.type_("text"),
                      attribute.value(fieldvalues.emailfield),
                      event.on_input(UpdateEmailField),
                    ]),
                    html.label([attribute.class("fieldset-label")], [
                      html.text("Password"),
                    ]),
                    html.input([
                      attribute.value(fieldvalues.passwordfield),
                      event.on_input(UpdatePasswordField),
                      attribute.placeholder("Password"),
                      attribute.class("input input-primary bg-primary"),
                      attribute.type_("password"),
                    ]),
                    html.div([], [
                      html.a([attribute.class("link link-hover")], [
                        html.text("Forgot password?"),
                      ]),
                    ]),
                    html.button(
                      case values_ok {
                        True -> [attribute.class("btn btn-base-400 mt-4")]
                        False -> [
                          attribute.class("btn btn-base-400 mt-4 btn-disabled"),
                          attribute.disabled(True),
                        ]
                      },
                      [html.text("Login")],
                    ),
                  ]),
                ]),
              ],
            ),
          ],
        ),
      ],
    ),
  ]
}

fn view_register(model_: Model) -> List(Element(Msg)) {
  // We know that the model is a Login page, so we can safely unwrap it
  let assert model.Register(fieldvalues): model.Page = model_.page
  // Check if the password and password confirmation fields match and if the email and username fields are not empty
  let values_ok: #(Bool, String) = {
    [
      #({ fieldvalues.emailfield != "" }, "Email field cannot be empty"),
      #(
        {
          [
            fieldvalues.emailfield |> string.contains("@"),
            {
              let f = fieldvalues.emailfield |> string.split("@")
              case f {
                [a, b] -> { string.length(a) > 3 } && { string.length(b) > 5 }
                _ -> False
              }
            },
            fieldvalues.emailfield |> string.contains("."),
            {
              case fieldvalues.emailfield |> string.split("@") {
                [_, c] ->
                  case string.split(c, ".") {
                    [a, b] ->
                      { string.length(a) > 1 } && { string.length(b) > 1 }
                    [a, "co", "uk"] -> {
                      string.length(a) > 1
                    }
                    _ -> False
                  }
                _ -> False
              }
            },
          ]
          |> list.all(fn(x) { x })
        },
        "Must be a valid email address",
      ),
      #({ fieldvalues.usernamefield != "" }, "Username field cannot be empty"),
      #(
        { fieldvalues.passwordfield |> string.length() > 7 },
        "Password must be at least 8 characters, are "
          <> fieldvalues.passwordfield |> string.length() |> int.to_string(),
      ),
      #(
        {
          [
            { fieldvalues.passwordfield |> string.contains("0") },
            { fieldvalues.passwordfield |> string.contains("1") },
            { fieldvalues.passwordfield |> string.contains("2") },
            { fieldvalues.passwordfield |> string.contains("3") },
            { fieldvalues.passwordfield |> string.contains("4") },
            { fieldvalues.passwordfield |> string.contains("5") },
            { fieldvalues.passwordfield |> string.contains("6") },
            { fieldvalues.passwordfield |> string.contains("7") },
            { fieldvalues.passwordfield |> string.contains("8") },
            { fieldvalues.passwordfield |> string.contains("9") },
          ]
          |> list.any(fn(x) { x })
        },
        "Password must contain at least one number",
      ),
      #(
        {
          [
            { fieldvalues.passwordfield |> string.contains("!") },
            { fieldvalues.passwordfield |> string.contains("@") },
            { fieldvalues.passwordfield |> string.contains("#") },
            { fieldvalues.passwordfield |> string.contains("$") },
            { fieldvalues.passwordfield |> string.contains("%") },
            { fieldvalues.passwordfield |> string.contains("^") },
            { fieldvalues.passwordfield |> string.contains("&") },
            { fieldvalues.passwordfield |> string.contains("*") },
            { fieldvalues.passwordfield |> string.contains("(") },
            { fieldvalues.passwordfield |> string.contains(")") },
            { fieldvalues.passwordfield |> string.contains("-") },
            { fieldvalues.passwordfield |> string.contains("_") },
            { fieldvalues.passwordfield |> string.contains("=") },
            { fieldvalues.passwordfield |> string.contains("+") },
            { fieldvalues.passwordfield |> string.contains("[") },
            { fieldvalues.passwordfield |> string.contains("]") },
            { fieldvalues.passwordfield |> string.contains("{") },
            { fieldvalues.passwordfield |> string.contains("}") },
            { fieldvalues.passwordfield |> string.contains(":") },
            { fieldvalues.passwordfield |> string.contains(";") },
            { fieldvalues.passwordfield |> string.contains("<") },
            { fieldvalues.passwordfield |> string.contains(">") },
            { fieldvalues.passwordfield |> string.contains(",") },
            { fieldvalues.passwordfield |> string.contains(".") },
            { fieldvalues.passwordfield |> string.contains("?") },
            { fieldvalues.passwordfield |> string.contains("/") },
            { fieldvalues.passwordfield |> string.contains("|") },
            { fieldvalues.passwordfield |> string.contains("`") },
            { fieldvalues.passwordfield |> string.contains("~") },
            { fieldvalues.passwordfield |> string.contains("\"") },
            { fieldvalues.passwordfield |> string.contains("'") },
            { fieldvalues.passwordfield |> string.contains("\\") },
            { fieldvalues.passwordfield |> string.contains(" ") },
          ]
          |> list.any(fn(x) { x })
        },
        "Password must contain at least one special character",
      ),
      #(
        { fieldvalues.passwordfield == fieldvalues.passwordconfirmfield },
        "Passwords do not match",
      ),
    ]
    |> list.find(fn(x) { x.0 == False })
    |> result.unwrap(#(True, ""))
  }
  [
    html.div([attribute.class("navbar bg-base-100 shadow-sm")], [
      html.div([attribute.class("flex-none")], [
        html.button([attribute.class("btn btn-square btn-ghost")], [
          html.img([
            attribute.src("/assets/logo.svg"),
            attribute.alt("Lumina logo"),
            attribute.class("h-8"),
          ]),
        ]),
      ]),
      html.div([attribute.class("flex-1")], [
        html.a([attribute.class("btn btn-ghost text-xl")], [html.text("Lumina")]),
      ]),
      html.div([attribute.class("flex-none")], [
        html.ul([attribute.class("menu menu-horizontal px-1")], [
          html.li([event.on_click(ToLandingPage)], [
            html.a([], [html.text("Back")]),
          ]),
          html.li([event.on_click(ToRegisterPage)], [
            html.a([attribute.class("bg-primary text-primary-content")], [
              html.text("Register"),
            ]),
          ]),
          html.li([event.on_click(ToLoginPage)], [
            html.a([], [html.text("Login")]),
          ]),
        ]),
      ]),
    ]),
    html.div(
      [attribute.class("hero bg-base-200 h-screen max-h-[calc(100vh-4rem)]")],
      [
        html.div(
          [attribute.class("hero-content flex-col lg:flex-row-reverse")],
          [
            html.div(
              [
                attribute.class(
                  "card bg-base-100 w-full max-w-sm shrink-0 shadow-2xl",
                ),
              ],
              [
                html.div([attribute.class("card-body  m-4")], [
                  html.fieldset([attribute.class("fieldset")], [
                    html.label([attribute.class("fieldset-label")], [
                      html.text("Email"),
                    ]),
                    html.input([
                      attribute.placeholder("Email"),
                      attribute.class("input input-primary bg-primary"),
                      attribute.type_("email"),
                      attribute.value(fieldvalues.emailfield),
                      event.on_input(UpdateEmailField),
                    ]),
                    html.label([attribute.class("fieldset-label")], [
                      html.text("Username"),
                    ]),
                    html.input([
                      attribute.placeholder("Username"),
                      attribute.class("input input-primary bg-primary"),
                      attribute.type_("email"),
                      attribute.value(fieldvalues.usernamefield),
                      event.on_input(UpdateUsernameField),
                    ]),
                    html.label([attribute.class("fieldset-label")], [
                      html.text("Password"),
                    ]),
                    html.input([
                      attribute.value(fieldvalues.passwordfield),
                      event.on_input(UpdatePasswordField),
                      attribute.placeholder("Password"),
                      attribute.class("input input-primary bg-primary"),
                      attribute.type_("password"),
                    ]),
                    html.label([attribute.class("fieldset-label")], [
                      html.text("Confirm Password"),
                    ]),
                    html.input([
                      attribute.value(fieldvalues.passwordconfirmfield),
                      event.on_input(UpdatePasswordConfirmField),
                      attribute.placeholder("Re-type password"),
                      attribute.class("input input-primary bg-primary"),
                      attribute.type_("password"),
                    ]),
                    html.br([]),
                    html.div(
                      [attribute.class("bg-base-200 card shadow-md p-4 w-full")],
                      [
                        case values_ok.0 {
                          False ->
                            html.div([attribute.class("w-full")], [
                              html.div(
                                [
                                  attribute.class(
                                    "inline-grid *:[grid-area:1/1]",
                                  ),
                                ],
                                [
                                  html.div(
                                    [
                                      attribute.class(
                                        "status status-error animate-ping",
                                      ),
                                    ],
                                    [],
                                  ),
                                  html.div(
                                    [attribute.class("status status-error")],
                                    [],
                                  ),
                                ],
                              ),
                              html.text(" " <> values_ok.1),
                            ])
                          True ->
                            html.div([attribute.class("w-full")], [
                              html.div(
                                [
                                  attribute.class(
                                    "inline-grid *:[grid-area:1/1]",
                                  ),
                                ],
                                [
                                  html.div(
                                    [
                                      attribute.class(
                                        "status status-success animate-ping",
                                      ),
                                    ],
                                    [],
                                  ),
                                  html.div(
                                    [attribute.class("status status-success")],
                                    [],
                                  ),
                                ],
                              ),
                              html.text(" Ready to go!"),
                            ])
                        },
                      ],
                    ),
                    html.button(
                      case values_ok.0 {
                        True -> [attribute.class("btn btn-base-400 mt-4")]
                        False -> [
                          attribute.class("btn btn-sucess mt-4 btn-disabled"),
                          // attribute.title(values_ok.1),
                          attribute.disabled(True),
                        ]
                      },
                      [html.text("Sign up")],
                    ),
                  ]),
                ]),
              ],
            ),
            html.div([attribute.class("text-center lg:text-right")], [
              html.h1([attribute.class("text-5xl font-bold")], [
                html.text("Sign up for Lumina!"),
              ]),
              html.p([attribute.class("py-6")], [
                html.text(
                  "We have real good food, I don't know what to put here right now.",
                ),
              ]),
            ]),
          ],
        ),
      ],
    ),
  ]
}

// HELPER FUNCTIONS ------------------------------------------------------------
fn get_color_scheme(_model_) -> attribute.Attribute(Msg) {
  // Will get overwritten by model later
  // For now, just return system default
  case dom.get_color_scheme() {
    "dark" -> attribute.attribute("data-theme", "lumina-dark")
    _ -> attribute.attribute("data-theme", "lumina-light")
  }
}

// WS Message decoding ---------------------------------------------------------

type WsMsg {
  Greeting(greeting: String)
  Undecodable
}

fn ws_msg_decoder(variant: String) -> decode.Decoder(WsMsg) {
  case variant {
    "greeting" -> {
      use greeting <- decode.field("greeting", decode.string)
      decode.success(Greeting(greeting:))
    }
    _ -> decode.failure(Undecodable, "Unknown message type")
  }
}

fn ws_msg_typedefiner() -> decode.Decoder(String) {
  use variant <- decode.field("type", decode.string)
  decode.success(variant)
}
