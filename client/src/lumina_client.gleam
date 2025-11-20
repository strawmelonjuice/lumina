//	Lumina/Peonies
//	Copyright (C) 2018-2026 MLC 'Strawmelonjuice'  Bloeiman and contributors.
//
//	This program is free software: you can redistribute it and/or modify
//	it under the terms of the GNU Affero General Public License as published
//	by the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	This program is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU Affero General Public License for more details.
//
//	You should have received a copy of the GNU Affero General Public License
//	along with this program.  If not, see <https://www.gnu.org/licenses/>.

import gleam/bool
import gleam/dict
import gleam/dynamic/decode
import gleam/float
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleam/time/timestamp
import gleamy_lights/console
import gleamy_lights/premixed
import lumina_client/helpers.{login_view_checker, model_local_storage_key}
import lumina_client/message_type.{
  type Msg, FocusLostEmailField, Logout, SubmitLogin, SubmitSignup, TickUp,
  ToLandingPage, ToLoginPage, ToRegisterPage, UpdateEmailField,
  UpdatePasswordConfirmField, UpdatePasswordField, UpdateUsernameField,
  WSTryReconnect, WsDisconnectDefinitive, WsWrapper,
}
import lumina_client/model_type.{
  type Model, HomeTimeline, Landing, Login, LoginFields, Model, Register,
  RegisterPageFields,
}
import lumina_client/view.{view}
import lumina_client/view/homepage
import lustre
import lustre/effect.{type Effect}
import lustre_websocket
import plinth/javascript/storage

// HELPER FUNCTIONS ------------------------------------------------------------

/// Get posts for display from a timeline cache
/// Returns a list of all cached posts in order, or empty list if timeline not found
pub fn get_timeline_posts_for_display(
  model: Model,
  timeline_name: String,
) -> List(String) {
  case model.cache.cached_timelines |> dict.get(timeline_name) {
    Ok(timeline) -> homepage.get_all_posts(timeline)
    Error(_) -> []
  }
}

/// Check if a timeline needs more data to be loaded
pub fn timeline_needs_more_data(
  model: Model,
  timeline_name: String,
  position: Int,
) -> Bool {
  case model.cache.cached_timelines |> dict.get(timeline_name) {
    Ok(timeline) -> homepage.should_load_more(timeline, position, 10)
    Error(_) -> True
    // If no timeline cached, we definitely need data
  }
}

/// Request next page for a timeline
pub fn request_next_timeline_page(
  model: Model,
  timeline_name: String,
) -> Effect(Msg) {
  let assert model_type.WsConnectionConnected(socket) = model.ws
    as "Socket not connected"

  case model.cache.cached_timelines |> dict.get(timeline_name) {
    Ok(timeline) -> {
      case homepage.get_next_page_to_load(timeline) {
        Some(next_page) ->
          TimeLineRequest(timeline_name, next_page)
          |> encode_ws_msg
          |> json.to_string
          |> lustre_websocket.send(socket, _)
        None -> effect.none()
      }
    }
    Error(_) ->
      TimeLineRequest(timeline_name, 0)
      |> encode_ws_msg
      |> json.to_string
      |> lustre_websocket.send(socket, _)
  }
}

// MAIN ------------------------------------------------------------------------

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", 0)
}

// INIT ------------------------------------------------------------------------

fn init(initial_ticks: Int) -> #(Model, Effect(Msg)) {
  let assert Ok(localstorage) = storage.local()
    as "localstorage should be available on ALL major browsers."
  let empty_model =
    Model(
      page: Landing,
      user: None,
      ws: model_type.WsConnectionInitial,
      token: None,
      status: Ok(Nil),
      cache: model_type.Cached(
        cached_posts: dict.new(),
        cached_timelines: dict.new(),
        cached_users: dict.new(),
      ),
      ticks: initial_ticks,
    )
  #(
    case storage.get_item(localstorage, model_local_storage_key) {
      Ok(l) -> {
        case model_type.deserialize_serializable_model(l) {
          Ok(loadable_model) -> {
            Model(
              page: loadable_model.page,
              user: None,
              ws: {
                case initial_ticks != 0 {
                  True -> model_type.WsConnectionRetrying
                  False -> model_type.WsConnectionInitial
                }
              },
              token: loadable_model.token,
              status: Ok(Nil),
              cache: model_type.Cached(
                cached_posts: dict.new(),
                cached_timelines: dict.new(),
                cached_users: dict.new(),
              ),
              ticks: initial_ticks,
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
    effect.batch([
      lustre_websocket.init("/connection", WsWrapper),
      up_next_tick(),
    ]),
  )
}

pub fn up_next_tick() {
  use dispatch <- effect.from
  use <- helpers.set_timeout_nilled(50)
  dispatch(TickUp)
}

fn let_definitely_disconnect(model: Model) {
  use dispatch <- effect.from
  case model.ws, model.ticks > 3 {
    model_type.WsConnectionDisconnecting, False
    | model_type.WsConnectionDisconnected, _
    | model_type.WsConnectionInitial, _
    | model_type.WsConnectionRetrying, _
    | model_type.WsConnectionConnected(..), _
    -> Nil
    model_type.WsConnectionDisconnecting, True ->
      dispatch(WsDisconnectDefinitive)
  }
}

// UPDATE ----------------------------------------------------------------------

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    TickUp -> {
      let ticks = model.ticks + 1
      let s = case ticks |> int.to_string() |> string.ends_with("00") {
        True -> send_refresh_request(model)
        False -> effect.none()
      }
      #(
        Model(..model, ticks:),
        effect.batch([up_next_tick(), let_definitely_disconnect(model), s]),
      )
    }
    WSTryReconnect -> {
      case model.ws {
        model_type.WsConnectionDisconnected -> init(model.ticks)
        _ -> #(model, effect.none())
      }
    }
    WsDisconnectDefinitive -> {
      let timed_trigger_to_retry_connect = fn(h) {
        use dispatch <- effect.from
        use <- helpers.set_timeout_nilled(h)
        dispatch(WSTryReconnect)
      }
      #(
        Model(..model, ws: model_type.WsConnectionDisconnected),
        effect.batch([
          timed_trigger_to_retry_connect(1500),
          timed_trigger_to_retry_connect(3000),
          timed_trigger_to_retry_connect(6000),
          timed_trigger_to_retry_connect(12_000),
          timed_trigger_to_retry_connect(24_000),
        ]),
      )
    }
    // Catch other Ws Events in a different function, since that is generally very different stuff.
    WsWrapper(event) -> update_ws(model, event)
    ToLoginPage -> #(
      Model(..model, page: Login(fields: LoginFields("", ""), success: None)),
      effect.none(),
    )
    ToRegisterPage -> #(
      Model(
        ..model,
        page: Register(fields: RegisterPageFields("", "", "", ""), ready: None),
      ),
      effect.none(),
    )
    ToLandingPage -> #(Model(..model, page: Landing), effect.none())
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
            let assert model_type.WsConnectionConnected(socket) = model.ws
              as "Socket not connected"
            encode_ws_msg(RegisterPrecheck(
              fields.emailfield,
              fields.usernamefield,
              fields.passwordfield,
            ))
            |> json.to_string()
            |> lustre_websocket.send(socket, _)
          },
        )
        Login(fields, _) -> #(
          Model(
            ..model,
            page: Login(
              fields: LoginFields(..fields, emailfield: new_email),
              success: None,
            ),
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
            let assert model_type.WsConnectionConnected(socket) = model.ws
              as "Socket not connected"
            encode_ws_msg(RegisterPrecheck(
              fields.emailfield,
              fields.usernamefield,
              fields.passwordfield,
            ))
            |> json.to_string()
            |> lustre_websocket.send(socket, _)
          },
        )
        Login(fields, _success) -> {
          let username_email = case string.starts_with(fields.emailfield, "@") {
            True -> string.drop_start(fields.emailfield, 1)
            False -> fields.emailfield
          }
          let new_username_email = case string.contains(username_email, "@") {
            True -> {
              // Is an email, what now!
              username_email
            }
            False -> {
              string.trim(username_email)
              |> string.replace(" ", "")
              |> string.lowercase()
              |> string.replace("@", "")
              |> string.replace(".", "")
            }
          }
          #(
            Model(
              ..model,
              page: Login(
                fields: LoginFields(
                  passwordfield: new_password,
                  emailfield: new_username_email,
                ),
                success: None,
              ),
            ),
            effect.none(),
          )
        }
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
            let assert model_type.WsConnectionConnected(socket) = model.ws
              as "Socket not connected"
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
            let assert model_type.WsConnectionConnected(socket) = model.ws
              as "Socket not connected"
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
    FocusLostEmailField -> {
      // This handles the login username/email field value once the user seems to be done typing.
      let assert Login(fields, _success) = model.page
      let value = case string.starts_with(fields.emailfield, "@") {
        True -> string.drop_start(fields.emailfield, 1)
        False -> fields.emailfield
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
          page: Login(
            fields: LoginFields(..fields, emailfield: new_value),
            success: None,
          ),
        ),
        effect.none(),
      )
    }
    Logout -> session_destroy()
    SubmitLogin(_) -> {
      let assert Login(fields, _) = model.page
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
          let assert model_type.WsConnectionConnected(socket) = model.ws
            as "Socket not connected"
          #(
            Model(..model, ws: model_type.WsConnectionConnected(socket)),
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
          let assert model_type.WsConnectionConnected(socket) = model.ws
            as "Socket not connected"
          #(
            Model(..model, ws: model_type.WsConnectionConnected(socket)),
            lustre_websocket.send(socket, json),
          )
        }
        False -> {
          console.error("Form not ready to submit")
          #(model, effect.none())
        }
      }
    }
    message_type.TimeLineTo(tid) -> {
      let assert model_type.WsConnectionConnected(socket) = model.ws
        as "Socket not connected"
      let model = case model.page {
        HomeTimeline(timeline_name: _, modal:) -> {
          model_type.Model(..model, page: HomeTimeline(Some(tid), modal:))
        }
        _ -> model
      }
      // Request unless cached or load next page if needed.
      let requ = case model.cache.cached_timelines |> dict.get(tid) {
        Error(..) ->
          TimeLineRequest(tid, 0)
          |> encode_ws_msg
          |> json.to_string
          |> lustre_websocket.send(socket, _)
        Ok(timeline) -> {
          // Check if we need to load more pages
          case homepage.should_load_more(timeline, 20, 10) {
            True -> {
              case homepage.get_next_page_to_load(timeline) {
                Some(next_page) ->
                  TimeLineRequest(tid, next_page)
                  |> encode_ws_msg
                  |> json.to_string
                  |> lustre_websocket.send(socket, _)
                None -> effect.none()
              }
            }
            False -> effect.none()
          }
        }
      }
      #(model, requ)
    }
    message_type.LoadMorePosts(timeline_name) -> {
      let effect = request_next_timeline_page(model, timeline_name)
      #(model, effect)
    }
    message_type.SetModal(to) -> {
      case model.page {
        HomeTimeline(timeline_name:, modal: _) -> #(
          Model(..model, page: HomeTimeline(timeline_name:, modal: Some(to))),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }
    }
    message_type.CloseModal -> {
      case model.page {
        HomeTimeline(timeline_name:, modal: _) -> #(
          Model(..model, page: HomeTimeline(timeline_name:, modal: None)),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }
    }
  }
}

fn update_ws(model: Model, wsevent: lustre_websocket.WebSocketEvent) {
  echo wsevent
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
          #(model, effect.none())
        }
        Ok(RegisterPrecheckResponse(ok, why)) -> {
          console.log("Register precheck response: " <> string.inspect(ok))
          let ready =
            case ok {
              True -> Ok(Nil)
              False -> Error(why)
            }
            |> Some

          case model.page {
            Register(fields, _) -> #(
              Model(..model, page: Register(fields:, ready:)),
              effect.none(),
            )
            _ -> #(model, effect.none())
          }
        }
        Ok(OwnUserInformationResponse(username:, email:, avatar:, uuid:)) -> {
          // avatar is Option(#(String, String)) == Option((mime, base64))
          let avatar_string = case avatar {
            Some(#(mime, b64)) -> "data:" <> mime <> ";base64," <> b64
            None -> ""
          }
          let new_users =
            model.cache.cached_users
            |> dict.insert(
              uuid,
              model_type.CachedUser(
                username:,
                source_instance: "local",
                avatar: avatar_string,
                last_updated: float.truncate(
                  timestamp.to_unix_seconds(timestamp.system_time()),
                ),
              ),
            )
          #(
            Model(
              ..model,
              cache: model_type.Cached(..model.cache, cached_users: new_users),
              user: Some(model_type.User(username, email, avatar_string)),
            ),
            effect.none(),
          )
        }
        Ok(AuthenticationSuccess(_username, token:)) -> {
          let assert model_type.WsConnectionConnected(socket) = model.ws
            as "Socket not connected"
          #(
            Model(
              ..model,
              // Global is default until user information says otherwise, however, we can't set it here, for that'd make it impossible to know if it's set by user or by default.
              page: HomeTimeline(None, None),
              token: Some(token),
            ),
            effect.batch([
              OwnUserInformationRequest
                |> encode_ws_msg
                |> json.to_string
                |> lustre_websocket.send(socket, _),
              // Even though 'officially' we don't show the global timeline, this should be the one requested firstly.
              TimeLineRequest("global", 0)
                |> encode_ws_msg
                |> json.to_string
                |> lustre_websocket.send(socket, _),
            ]),
          )
        }
        Ok(AuthenticationFailure) -> {
          case model.page {
            model_type.Landing | HomeTimeline(..) -> session_destroy()
            Login(fields:, success: _) -> #(
              Model(..model, page: Login(fields:, success: Some(False))),
              effect.none(),
            )
            // If on register page, do nothing.
            Register(..) -> #(model, effect.none())
          }
        }
        // Ws messages we can't receive
        Ok(RegisterPrecheck(..))
        | Ok(Undecodable)
        | Ok(LoginAuthenticationRequest(..))
        | Ok(OwnUserInformationRequest)
        | Ok(TimeLineRequest(..))
        | Ok(RegisterRequest(..)) -> {
          #(model, effect.none())
        }
        Ok(TimeLineResponse(
          timeline_name:,
          timeline_id:,
          items:,
          total_count:,
          page:,
          has_more:,
        )) -> {
          console.log(
            "Received timeline response for "
            <> timeline_name
            <> " (id: "
            <> timeline_id
            <> ")"
            <> " with "
            <> int.to_string(list.length(items))
            <> " items (page "
            <> int.to_string(page)
            <> " of "
            <> int.to_string(total_count)
            <> " total, has_more: "
            <> bool.to_string(has_more)
            <> ").",
          )
          let assert model_type.WsConnectionConnected(_socket) = model.ws
            as "Socket not connected"

          // Create or update timeline cache using utilities
          let cached_timeline = case
            model.cache.cached_timelines |> dict.get(timeline_name)
          {
            Ok(existing) -> {
              homepage.add_page_to_timeline(
                existing,
                timeline_id,
                page,
                items,
                total_count,
                has_more,
              )
            }
            Error(..) -> {
              homepage.create_empty_timeline()
              |> homepage.add_page_to_timeline(
                page:,
                timeline_id:,
                items:,
                count: total_count,
                has_more:,
              )
            }
          }

          console.log(homepage.timeline_info_string(
            cached_timeline,
            timeline_name,
          ))

          let cached_timelines =
            model.cache.cached_timelines
            |> dict.insert(timeline_name, cached_timeline)

          #(
            Model(
              ..model,
              cache: model_type.Cached(..model.cache, cached_timelines:),
            ),
            effect.none(),
          )
        }
        Error(err) -> {
          console.error(
            "Message could not be parsed:"
            <> premixed.text_error_red(string.inspect(err))
            <> "\nin:\n"
            <> premixed.text_error_red(notice),
          )
          #(model, effect.none())
        }
      }
    lustre_websocket.OnBinaryMessage(msg) -> {
      console.warn(
        "Received unexpected: " <> premixed.text_cyan(string.inspect(msg)),
      )
      // Ignore this. We don't expect binary messages, as we cannot tag them with how the decoder works right now. We only expect text messages, with base64-encoded bitarrays in their fields if so needed.
      // So, continue with the model as is:
      #(model, effect.none())
    }
    lustre_websocket.OnClose(reason) -> {
      console.warn(
        "Given close reason: "
        <> premixed.text_cyan({
          case reason {
            lustre_websocket.AbnormalClose -> "Abnormal close"
            lustre_websocket.FailedExtensionNegotation ->
              "Failed extension negotation"
            lustre_websocket.FailedTLSHandshake -> "Failed TLS handshake"
            lustre_websocket.GoingAway -> "Going away"
            lustre_websocket.IncomprehensibleFrame -> "Incomprehensible frame"
            lustre_websocket.MessageTooBig -> "Message was too big"
            lustre_websocket.NoCodeFromServer -> "No code from server"
            lustre_websocket.Normal -> "Normal close"
            lustre_websocket.OtherCloseReason -> "Other close reason (unknown)"
            lustre_websocket.PolicyViolated -> "Policy violation"
            lustre_websocket.ProtocolError -> "Protocol error"
            lustre_websocket.UnexpectedFailure -> "Unexpected faillure"
            lustre_websocket.UnexpectedTypeOfData -> "Unexpected type of data"
          }
        }),
      )
      case model.ws {
        model_type.WsConnectionInitial -> #(model, effect.none())
        model_type.WsConnectionRetrying -> #(
          Model(..model, ws: model_type.WsConnectionDisconnected),
          effect.none(),
        )
        _ -> {
          echo "Falling into disconnection mode at tick #"
            <> int.to_string(model.ticks)
            <> ". Current status: "
            <> case model.ws {
              model_type.WsConnectionConnected(_) -> "connected"
              model_type.WsConnectionDisconnected -> "disconnected"
              model_type.WsConnectionInitial -> "initial"
              model_type.WsConnectionRetrying -> "retrying"
              model_type.WsConnectionDisconnecting -> "disconnecting"
            }
          let new_model =
            Model(..model, ws: model_type.WsConnectionDisconnecting)
          #(new_model, let_definitely_disconnect(new_model))
        }
      }
    }
    lustre_websocket.OnOpen(socket) -> #(
      Model(..model, ws: model_type.WsConnectionConnected(socket)),
      lustre_websocket.send(
        socket,
        {
          let x = [
            #("type", json.string("introduction")),
            #("client_kind", json.string("web")),
          ]
          json.object(case model.user, model.token {
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
    // Password only once? Yes, the equal password check is done in the view/update themselves.
    password: String,
  )
  RegisterPrecheckResponse(ok: Bool, why: String)
  RegisterRequest(email: String, username: String, password: String)
  LoginAuthenticationRequest(email_username: String, password: String)
  AuthenticationSuccess(username: String, token: String)
  AuthenticationFailure
  OwnUserInformationRequest
  TimeLineRequest(timeline_name: String, page: Int)
  TimeLineResponse(
    timeline_name: String,
    timeline_id: String,
    /// List of post ids as string.
    items: List(String),
    /// Total number of posts in timeline
    total_count: Int,
    /// Current page number
    page: Int,
    /// Whether there are more pages available
    has_more: Bool,
  )
  OwnUserInformationResponse(
    username: String,
    email: String,
    // Optional field populated with mime type and base64 of a profile picture.
    avatar: option.Option(#(String, String)),
    uuid: String,
  )
  Undecodable
}

fn encode_ws_msg(message: WsMsg) -> json.Json {
  case message {
    OwnUserInformationRequest ->
      json.object([#("type", json.string("own_user_information_request"))])
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
    TimeLineRequest(timeline_name:, page:) ->
      json.object([
        #("type", json.string("timeline_request")),
        #("by_name", json.string(timeline_name)),
        #("page", json.int(page)),
      ])
    // And the client should never have to encode the next few:
    Greeting(..)
    | Undecodable
    | RegisterPrecheckResponse(..)
    | AuthenticationFailure
    | AuthenticationSuccess(..)
    | TimeLineResponse(..)
    | OwnUserInformationResponse(..) ->
      json.object([#("type", json.string("unknown"))])
  }
}

fn send_refresh_request(model: model_type.Model) -> Effect(Msg) {
  let inventory = model |> model_type.create_cache_inventory()
  // Todo: send this to server to get updates on cached items.
  console.log(
    "Would send cache inventory to server: \n"
    <> string.inspect(inventory)
    <> "\n\nNot yet implemented.",
  )
  effect.none()
}

fn ws_msg_decoder(variant: String) -> decode.Decoder(WsMsg) {
  case variant {
    "auth_success" -> {
      use username <- decode.field("username", decode.string)
      use token <- decode.field("token", decode.string)
      decode.success(AuthenticationSuccess(username:, token:))
    }
    "auth_failure" -> {
      decode.success(AuthenticationFailure)
    }
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
    "timeline_response" -> {
      console.log("Decoding timeline response: " <> variant)
      use timeline_name <- decode.field("timeline_name", decode.string)
      use timeline_id <- decode.field("timeline_id", decode.string)
      use items <- decode.field("post_ids", decode.list(decode.string))
      use total_count <- decode.field("total_count", decode.int)
      use page <- decode.field("page", decode.int)
      use has_more <- decode.field("has_more", decode.bool)
      decode.success(TimeLineResponse(
        timeline_name:,
        timeline_id:,
        items:,
        total_count:,
        page:,
        has_more:,
      ))
    }
    "own_user_information_response" -> {
      use username <- decode.field("username", decode.string)
      use email <- decode.field("email", decode.string)
      // avatar may be null or an array [mime, base64]
      use avatar_list_opt <- decode.field(
        "avatar",
        decode.optional(decode.list(decode.string)),
      )
      let avatar = case avatar_list_opt {
        Some(list) ->
          case list {
            [mime, b64] -> Some(#(mime, b64))
            _ -> None
          }
        None -> None
      }
      use uuid <- decode.field("uuid", decode.string)
      decode.success(OwnUserInformationResponse(
        username:,
        email:,
        avatar:,
        uuid:,
      ))
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

fn session_destroy() -> #(Model, Effect(Msg)) {
  console.info("Destroying session.")
  let assert Ok(s) = storage.local()
  storage.clear(s)
  console.info("Recreating model.")
  init(0)
}
