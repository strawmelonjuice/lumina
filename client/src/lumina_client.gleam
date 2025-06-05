import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleamy_lights/console
import gleamy_lights/premixed
import lumina_client/helpers.{login_view_checker, model_local_storage_key}
import lumina_client/message_type.{
  type Msg, FocusLostEmailField, SubmitLogin, SubmitSignup, ToLandingPage,
  ToLoginPage, ToRegisterPage, UpdateEmailField, UpdatePasswordConfirmField,
  UpdatePasswordField, UpdateUsernameField, WSTryReconnect, WsWrapper,
}
import lumina_client/model_type.{
  type Model, Landing, Login, LoginFields, Model, Register, RegisterPageFields,
}
import lumina_client/view.{view}
import lustre
import lustre/effect.{type Effect}
import lustre_websocket
import plinth/javascript/storage

// MAIN ------------------------------------------------------------------------

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", False)
}

// INIT ------------------------------------------------------------------------

fn init(reconnection: Bool) -> #(Model, Effect(Msg)) {
  let assert Ok(localstorage) = storage.local()
    as "localstorage should be available on ALL major browsers."
  let empty_model =
    Model(page: Landing, user: None, ws: None, token: None, status: Ok(Nil))
  #(
    case storage.get_item(localstorage, model_local_storage_key) {
      Ok(l) -> {
        case model_type.deserialize_serializable_model(l) {
          Ok(loadable_model) -> {
            Model(
              page: loadable_model.page,
              user: None,
              ws: {
                case reconnection {
                  True -> Some(None)
                  False -> None
                }
              },
              token: loadable_model.token,
              status: Ok(Nil),
            )
          }
          Error(_) -> {
            console.error("Could not deserialise last saved model.")
            empty_model
          }
        }
      }
      Error(_) -> {
        console.log("No model to restore")
        empty_model
      }
    },
    lustre_websocket.init("/connection", WsWrapper),
  )
}

// UPDATE ----------------------------------------------------------------------

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    WSTryReconnect -> {
      init(True)
    }

    // Catch other Ws Events in a different function, since that is generally very different stuff.
    WsWrapper(event) -> update_ws(model, event)
    ToLoginPage -> #(
      Model(..model, page: Login(fields: LoginFields("", ""))),
      effect.none(),
    )
    ToRegisterPage -> #(
      Model(
        ..model,
        page: Register(fields: RegisterPageFields("", "", "", ""), ready: None),
      ),
      effect.none(),
    )
    ToLandingPage -> #(Model(Landing, None, None, None, Ok(Nil)), effect.none())
    UpdateEmailField(new_email) -> {
      case model.page {
        Register(fields, ready) -> #(
          Model(
            ..model,
            page: Register(
              fields: RegisterPageFields(..fields, emailfield: new_email),
              ready:,
            ),
          ),
          {
            // This block emits an effect to send RegisterPrecheck message to the server
            let assert Some(Some(socket)) = model.ws as "Socket not connected"
            encode_ws_msg(RegisterPrecheck(
              fields.emailfield,
              fields.usernamefield,
              fields.passwordfield,
            ))
            |> json.to_string()
            |> lustre_websocket.send(socket, _)
          },
        )
        Login(fields) -> #(
          Model(
            ..model,
            page: Login(fields: LoginFields(..fields, emailfield: new_email)),
          ),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }
    }
    UpdatePasswordField(new_password) -> {
      case model.page {
        Register(fields, ready) -> #(
          Model(
            ..model,
            page: Register(
              RegisterPageFields(..fields, passwordfield: new_password),
              ready:,
            ),
          ),
          {
            // This block emits an effect to send RegisterPrecheck message to the server
            let assert Some(Some(socket)) = model.ws as "Socket not connected"
            encode_ws_msg(RegisterPrecheck(
              fields.emailfield,
              fields.usernamefield,
              fields.passwordfield,
            ))
            |> json.to_string()
            |> lustre_websocket.send(socket, _)
          },
        )
        Login(fields) -> #(
          Model(
            ..model,
            page: Login(
              fields: LoginFields(..fields, passwordfield: new_password),
            ),
          ),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }
    }
    UpdatePasswordConfirmField(new_password_confirmation) -> {
      case model.page {
        Register(fields, ready) -> #(
          Model(
            ..model,
            page: Register(
              fields: RegisterPageFields(
                ..fields,
                passwordconfirmfield: new_password_confirmation,
              ),
              ready:,
            ),
          ),
          {
            // This block emits an effect to send RegisterPrecheck message to the server
            let assert Some(Some(socket)) = model.ws as "Socket not connected"
            encode_ws_msg(RegisterPrecheck(
              fields.emailfield,
              fields.usernamefield,
              fields.passwordfield,
            ))
            |> json.to_string()
            |> lustre_websocket.send(socket, _)
          },
        )
        _ -> #(model, effect.none())
      }
    }
    UpdateUsernameField(new_username) -> {
      case model.page {
        Register(fields, ready) -> #(
          Model(
            ..model,
            page: Register(
              fields: RegisterPageFields(..fields, usernamefield: {
                case string.starts_with(new_username, "@") {
                  True -> string.drop_start(new_username, 1)
                  False -> new_username
                }
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
            let assert Some(Some(socket)) = model.ws as "Socket not connected"
            encode_ws_msg(RegisterPrecheck(
              fields.emailfield,
              fields.usernamefield,
              fields.passwordfield,
            ))
            |> json.to_string()
            |> lustre_websocket.send(socket, _)
          },
        )
        _ -> #(model, effect.none())
      }
    }
    FocusLostEmailField(value) -> {
      // This handles the login username/email field value once the user seems to be done typing.
      let assert Login(fields) = model.page
      let value = case string.starts_with(value, "@") {
        True -> string.drop_start(value, 1)
        False -> value
      }
      let new_value = case string.contains(value, "@") {
        True -> {
          // Is an email, what now!
          value
        }
        False -> {
          string.trim(value)
          |> string.replace(" ", "")
          |> string.lowercase()
          |> string.replace("@", "")
          |> string.replace(".", "")
        }
      }
      #(
        Model(
          ..model,
          page: Login(fields: LoginFields(..fields, emailfield: new_value)),
        ),
        effect.none(),
      )
    }
    SubmitLogin(_) -> {
      let assert Login(fields) = model.page
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
          let assert Some(Some(socket)) = model.ws as "Socket not connected"
          #(
            Model(..model, ws: Some(Some(socket))),
            lustre_websocket.send(socket, json),
          )
        }
        False -> {
          console.error("Form not ready to submit")
          #(model, effect.none())
        }
      }
    }
    SubmitSignup(_) -> {
      let assert Register(fields, ready) = model.page

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
          let assert Some(Some(socket)) = model.ws as "Socket not connected"
          #(
            Model(..model, ws: Some(Some(socket))),
            lustre_websocket.send(socket, json),
          )
        }
        False -> {
          console.error("Form not ready to submit")
          #(model, effect.none())
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
            Register(fields, _) -> #(
              Model(..model_, page: Register(fields:, ready:)),
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
    lustre_websocket.OnBinaryMessage(msg) -> {
      msg
      // Ignore this. We don't expect binary messages, as we cannot tag them with how the decoder works right now. We only expect text messages, with base64-encoded bitarrays in their fields if so needed.
      // So, continue with the model as is:
      #(model_, effect.none())
    }
    lustre_websocket.OnClose(reason) -> {
      reason
      #(Model(..model_, ws: Some(None)), effect.none())
    }
    lustre_websocket.OnOpen(socket) -> #(
      Model(..model_, ws: Some(Some(socket))),
      lustre_websocket.send(
        socket,
        {
          let x = [
            #("type", json.string("introduction")),
            #("client_kind", json.string("web")),
          ]
          json.object(case model_.user, model_.token {
            None, Some(token) -> {
              // traversing x is okay.
              list.append(x, [#("try_revive", json.string(token))])
            }
            _, _ -> x
          })
        }
          |> json.to_string(),
      ),
    )
  }
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
