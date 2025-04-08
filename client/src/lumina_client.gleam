import gleam/dynamic/decode
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
  SubmitLogin
  ToRegisterPage
  SubmitSignup
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
        page: model.Register(
          fields: model.RegisterPageFields("", "", "", ""),
          ready: None,
        ),
      ),
      effect.none(),
    )
    ToLandingPage -> #(Model(model.Landing, None, None), effect.none())
    UpdateEmailField(new_email) -> {
      case model_.page {
        model.Register(fields, ready) -> #(
          Model(
            ..model_,
            page: model.Register(
              fields: model.RegisterPageFields(..fields, emailfield: new_email),
              ready:,
            ),
          ),
          {
            // This block emits an effect to send RegisterPrecheck message to the server
            let assert Some(socket) = model_.ws as "Socket not connected"
            encode_ws_msg(RegisterPrecheck(
              fields.emailfield,
              fields.usernamefield,
              fields.passwordfield,
            ))
            |> json.to_string()
            |> lustre_websocket.send(socket, _)
          },
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
        model.Register(fields, ready) -> #(
          Model(
            ..model_,
            page: model.Register(
              model.RegisterPageFields(..fields, passwordfield: new_password),
              ready:,
            ),
          ),
          {
            // This block emits an effect to send RegisterPrecheck message to the server
            let assert Some(socket) = model_.ws as "Socket not connected"
            encode_ws_msg(RegisterPrecheck(
              fields.emailfield,
              fields.usernamefield,
              fields.passwordfield,
            ))
            |> json.to_string()
            |> lustre_websocket.send(socket, _)
          },
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
        model.Register(fields, ready) -> #(
          Model(
            ..model_,
            page: model.Register(
              fields: model.RegisterPageFields(
                ..fields,
                passwordconfirmfield: new_password_confirmation,
              ),
              ready:,
            ),
          ),
          {
            // This block emits an effect to send RegisterPrecheck message to the server
            let assert Some(socket) = model_.ws as "Socket not connected"
            encode_ws_msg(RegisterPrecheck(
              fields.emailfield,
              fields.usernamefield,
              fields.passwordfield,
            ))
            |> json.to_string()
            |> lustre_websocket.send(socket, _)
          },
        )
        _ -> #(model_, effect.none())
      }
    }
    UpdateUsernameField(new_username) -> {
      case model_.page {
        model.Register(fields, ready) -> #(
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
              ready:,
            ),
          ),
          {
            let assert Some(socket) = model_.ws as "Socket not connected"
            encode_ws_msg(RegisterPrecheck(
              fields.emailfield,
              fields.usernamefield,
              fields.passwordfield,
            ))
            |> json.to_string()
            |> lustre_websocket.send(socket, _)
          },
        )
        _ -> #(model_, effect.none())
      }
    }
    SubmitLogin -> {
      let assert model.Login(fields) = model_.page
      let values_ok = login_view_checker(fields)
      case values_ok {
        True -> {
          console.log("Submitting login form")
          let json =
            encode_ws_msg(LoginAuthenticationRequest(
              fields.emailfield,
              fields.passwordfield,
            ))
            |> json.to_string()
          let assert Some(socket) = model_.ws as "Socket not connected"
          #(
            Model(..model_, ws: Some(socket)),
            lustre_websocket.send(socket, json),
          )
        }
        False -> {
          console.error("Form not ready to submit")
          #(model_, effect.none())
        }
      }
    }
    SubmitSignup -> {
      let assert model.Register(fields, ready) = model_.page

      case
        {
          { ready |> option.is_some() }
          && { ready |> option.unwrap(Error("")) |> result.is_ok() }
          && { fields.passwordfield == fields.passwordconfirmfield }
        }
      {
        True -> {
          console.log("Submitting signup form")
          let json =
            encode_ws_msg(RegisterRequest(
              fields.emailfield,
              fields.usernamefield,
              fields.passwordfield,
            ))
            |> json.to_string()
          let assert Some(socket) = model_.ws as "Socket not connected"
          #(
            Model(..model_, ws: Some(socket)),
            lustre_websocket.send(socket, json),
          )
        }
        False -> {
          console.error("Form not ready to submit")
          #(model_, effect.none())
        }
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
        Ok(RegisterPrecheckResponse(ok, why)) -> {
          console.log("Register precheck response: " <> string.inspect(ok))
          let ready =
            case ok {
              True -> Ok(Nil)
              False -> Error(why)
            }
            |> Some

          case model_.page {
            model.Register(fields, _) -> #(
              Model(..model_, page: model.Register(fields:, ready:)),
              effect.none(),
            )
            _ -> #(model_, effect.none())
          }
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
    lustre_websocket.OnBinaryMessage(_msg) -> {
      // Ignore this. We don't expect binary messages, as we cannot tag them. We only expect text messages, with base64-encoded bitarrays in their fields. This makes it easier to handle them in the decoder.
      // So, continue with the model as is:
      #(model_, effect.none())
    }
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
            attribute.src("/static/logo.svg"),
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

  let values_ok = login_view_checker(fieldvalues)
  [
    html.div([attribute.class("navbar bg-base-100 shadow-sm")], [
      html.div([attribute.class("flex-none")], [
        html.button([attribute.class("btn btn-square btn-ghost")], [
          html.img([
            attribute.src("/static/logo.svg"),
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
                html.form(
                  [
                    attribute.class("card-body m-4"),
                    event.on_submit(SubmitLogin),
                  ],
                  [
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
                          True -> [
                            attribute.class("btn btn-base-400 mt-4"),
                            attribute.type_("submit"),
                          ]
                          False -> [
                            attribute.class(
                              "btn btn-base-400 mt-4 btn-disabled",
                            ),
                            attribute.disabled(True),
                          ]
                        },
                        [html.text("Login")],
                      ),
                    ]),
                  ],
                ),
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
  let assert model.Register(fieldvalues, ready): model.Page = model_.page

  // Check if the password and password confirmation fields match and if the email and username fields are not empty
  [
    html.div([attribute.class("navbar bg-base-100 shadow-sm")], [
      html.div([attribute.class("flex-none")], [
        html.button([attribute.class("btn btn-square btn-ghost")], [
          html.img([
            attribute.src("/static/logo.svg"),
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
                html.form(
                  [
                    attribute.class("card-body  m-4"),
                    event.on_submit(SubmitSignup),
                  ],
                  [
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
                        attribute.type_("string"),
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
                        [
                          attribute.class(case ready |> option.is_some() {
                            True -> "bg-base-200 card shadow-md p-4 w-full"
                            False -> "hidden"
                          }),
                        ],
                        [
                          case
                            ready |> option.unwrap(Ok(Nil)),
                            fieldvalues.passwordfield
                            == fieldvalues.passwordconfirmfield
                          {
                            Error(why), _ ->
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
                                html.text(" " <> why),
                              ])
                            Ok(_), True ->
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
                            Ok(_), False ->
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
                                html.text(" Passwords don't match!"),
                              ])
                          },
                        ],
                      ),
                      html.button(
                        case
                          ready |> option.is_some()
                          && ready |> option.unwrap(Error("")) |> result.is_ok()
                          && fieldvalues.passwordfield
                          == fieldvalues.passwordconfirmfield
                        {
                          True -> [
                            attribute.class("btn btn-base-400 mt-4"),
                            attribute.type_("submit"),
                          ]
                          False -> [
                            attribute.class("btn btn-sucess mt-4 btn-disabled"),
                            // attribute.title(values_ok.1),
                            attribute.disabled(True),
                          ]
                        },
                        [html.text("Sign up")],
                      ),
                    ]),
                  ],
                ),
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

fn login_view_checker(fieldvalues: model.LoginFields) {
  [{ fieldvalues.passwordfield != "" }, { fieldvalues.emailfield != "" }]
  |> list.all(fn(x) { x })
}

// WS Message decoding ---------------------------------------------------------

type WsMsg {
  Greeting(greeting: String)
  RegisterPrecheck(
    email: String,
    username: String,
    // Password only once? Yes, the equal password check is done in the view.
    password: String,
  )
  RegisterPrecheckResponse(ok: Bool, why: String)
  RegisterRequest(email: String, username: String, password: String)
  LoginAuthenticationRequest(email_username: String, password: String)
  Undecodable
}

fn encode_ws_msg(message: WsMsg) -> json.Json {
  case message {
    LoginAuthenticationRequest(email_username, password) ->
      json.object([
        #("type", json.string("login_authentication_request")),
        #("email_username", json.string(email_username)),
        #("password", json.string(password)),
      ])
    RegisterRequest(email, username, password) ->
      json.object([
        #("type", json.string("register_request")),
        #("email", json.string(email)),
        #("username", json.string(username)),
        #("password", json.string(password)),
      ])
    RegisterPrecheck(email, username, password) ->
      json.object([
        #("type", json.string("register_precheck")),
        #("email", json.string(email)),
        #("username", json.string(username)),
        #("password", json.string(password)),
      ])
    RegisterPrecheckResponse(ok, why) ->
      json.object([
        #("type", json.string("register_precheck_response")),
        #("ok", json.bool(ok)),
        #("why", json.string(why)),
      ])
    Greeting(_) | Undecodable ->
      json.object([#("type", json.string("unknown"))])
  }
}

fn ws_msg_decoder(variant: String) -> decode.Decoder(WsMsg) {
  case variant {
    "unknown" -> decode.success(Undecodable)
    "login_authentication_request" -> {
      use email_username <- decode.field("email_username", decode.string)
      use password <- decode.field("password", decode.string)
      decode.success(LoginAuthenticationRequest(email_username, password))
    }
    "register_request" -> {
      use email <- decode.field("email", decode.string)
      use username <- decode.field("username", decode.string)
      use password <- decode.field("password", decode.string)
      decode.success(RegisterRequest(email, username, password))
    }
    "register_precheck" -> {
      use email <- decode.field("email", decode.string)
      use username <- decode.field("username", decode.string)
      use password <- decode.field("password", decode.string)
      decode.success(RegisterPrecheck(email, username, password))
    }
    "register_precheck_response" -> {
      use ok <- decode.field("ok", decode.bool)
      use why <- decode.field("why", decode.string)
      decode.success(RegisterPrecheckResponse(ok, why))
    }
    "greeting" -> {
      use greeting <- decode.field("greeting", decode.string)
      decode.success(Greeting(greeting:))
    }
    g -> {
      console.error("Unknown message type: " <> g)
      decode.failure(Undecodable, g)
    }
  }
}

fn ws_msg_typedefiner() -> decode.Decoder(String) {
  use variant <- decode.field("type", decode.string)
  decode.success(variant)
}
