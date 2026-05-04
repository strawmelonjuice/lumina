//// Lumina > Client
//// Main entry point for Lumina client. This module contains all side-effects, the update function. Lustre initialisation and more.

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

import gleam/bool
import gleam/dict
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
import lumina_client/dom
import lumina_client/helpers.{login_view_checker, model_local_storage_key}
import lumina_client/model_type.{
  type Model, type Msg, EffectPast150ms, EmailFieldLostFocus, HomeTimeline,
  Landing, Licence, Login, LoginFields, Model, NotFound, Register,
  RegisterPageFields, UpdateLastRefreshRequestTime, UserClickedLogout,
  UserNavigatedToLandingPage, UserNavigatedToLoginPage,
  UserNavigatedToRegisterPage, UserSubmittedLogin, UserSubmittedSignup,
  UserUpdatedControlledEmailField, UserUpdatedControlledPasswordConfirmField,
  UserUpdatedControlledPasswordField, UserUpdatedControlledUsernameField,
  WSTryReconnect, WebSocketIncomingMessage, WsDisconnectDefinitive,
}
import lumina_client/view.{view}
import lumina_client/view/homepage
import lustre
import lustre/effect.{type Effect}
import lustre_websocket
import plinth/javascript/storage
import webapi.{
  LoginAuthenticationRequest, RegisterPrecheck, RegisterRequest,
  encode_ws_msg_from_client as encode_ws_msg,
}

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
          webapi.TimeLineRequest(timeline_name, next_page)
          |> encode_ws_msg
          |> json.to_string
          |> lustre_websocket.send(socket, _)
        None -> effect.none()
      }
    }
    Error(_) ->
      webapi.TimeLineRequest(timeline_name, 0)
      |> encode_ws_msg
      |> json.to_string
      |> lustre_websocket.send(socket, _)
  }
}

// MAIN ------------------------------------------------------------------------

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", False)
}

// INIT ------------------------------------------------------------------------

fn init(rerun: Bool) -> #(Model, Effect(Msg)) {
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
      has_been_running_for_150ms: rerun,
      last_refresh_request_time: float.truncate(
        timestamp.to_unix_seconds(timestamp.system_time()),
      ),
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
                case rerun {
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
              has_been_running_for_150ms: rerun,
              last_refresh_request_time: float.truncate(
                timestamp.to_unix_seconds(timestamp.system_time()),
              ),
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
      lustre_websocket.init("/connection", WebSocketIncomingMessage),
      count_to_150(),
    ]),
  )
}

pub fn start_tracking_mouse_movements(x: Float, y: Float) {
  use dispatcher <- effect.from
  dom.start_dragging_modal_box(x, y, model_type.MoveModalBoxTo, dispatcher)
}

pub fn count_to_150() {
  use dispatch <- effect.from
  use <- helpers.set_timeout_nilled(150)
  dispatch(EffectPast150ms)
}

fn let_definitely_disconnect(model: Model) {
  use dispatch <- effect.from
  case model.ws, model.has_been_running_for_150ms {
    model_type.WsConnectionUnsure, False
    | model_type.WsConnectionDisconnected, _
    | model_type.WsConnectionInitial, _
    | model_type.WsConnectionRetrying, _
    | model_type.WsConnectionConnected(..), _
    -> Nil
    model_type.WsConnectionUnsure, True -> dispatch(WsDisconnectDefinitive)
  }
}

// UPDATE ----------------------------------------------------------------------

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    EffectPast150ms -> {
      #(Model(..model, has_been_running_for_150ms: True), effect.none())
    }
    UpdateLastRefreshRequestTime(new_time) -> {
      #(Model(..model, last_refresh_request_time: new_time), effect.none())
    }
    WSTryReconnect -> {
      case model.ws {
        model_type.WsConnectionDisconnected ->
          init(model.has_been_running_for_150ms)
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
    WebSocketIncomingMessage(event) -> update_ws(model, event)
    UserNavigatedToLoginPage -> #(
      Model(..model, page: Login(fields: LoginFields("", ""), success: None)),
      effect.none(),
    )
    UserNavigatedToRegisterPage -> #(
      Model(
        ..model,
        page: Register(fields: RegisterPageFields("", "", "", ""), ready: None),
      ),
      effect.none(),
    )
    UserNavigatedToLandingPage -> #(
      Model(..model, page: Landing),
      effect.none(),
    )
    UserUpdatedControlledEmailField(new_email) -> {
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
    UserUpdatedControlledPasswordField(new_password) -> {
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
    UserUpdatedControlledPasswordConfirmField(new_password_confirmation) -> {
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
    UserUpdatedControlledUsernameField(new_username) -> {
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
    EmailFieldLostFocus -> {
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
    UserClickedLogout -> session_destroy()
    UserSubmittedLogin(_) -> {
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
    UserSubmittedSignup(_) -> {
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
    model_type.UserSwitchedTimeLineTo(tid) -> {
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
          webapi.TimeLineRequest(tid, 0)
          |> encode_ws_msg
          |> json.to_string
          |> lustre_websocket.send(socket, _)
        Ok(timeline) -> {
          // Check if we need to load more pages
          case homepage.should_load_more(timeline, 20, 10) {
            True -> {
              case homepage.get_next_page_to_load(timeline) {
                Some(next_page) ->
                  webapi.TimeLineRequest(tid, next_page)
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
    model_type.LoadMorePosts(timeline_name) -> {
      let effect = request_next_timeline_page(model, timeline_name)
      #(model, effect)
    }
    model_type.SetModal(to) -> {
      case model.page {
        HomeTimeline(timeline_name:, modal: _) -> #(
          Model(
            ..model,
            page: HomeTimeline(timeline_name:, modal: Some(#(to, dict.new()))),
          ),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }
    }
    model_type.UserClosedModal -> {
      case model.page {
        HomeTimeline(timeline_name:, modal: _) -> #(
          Model(..model, page: HomeTimeline(timeline_name:, modal: None)),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }
    }
    model_type.StartDraggingModalBox(x, y) -> {
      // Start a sideffect that tracks mouse movements and sends MoveModalBoxTo messages
      #(model, start_tracking_mouse_movements(x, y))
    }
    model_type.MoveModalBoxTo(x, y) -> {
      case model.page {
        HomeTimeline(timeline_name:, modal: Some(#("mdl-postedit", params))) -> {
          let new_params =
            params
            |> dict.insert("pos_x", float.to_string(x))
            |> dict.insert("pos_y", float.to_string(y))
          #(
            Model(
              ..model,
              page: HomeTimeline(
                timeline_name:,
                modal: Some(#("mdl-postedit", new_params)),
              ),
            ),
            effect.none(),
          )
        }
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
      case json.parse(notice, webapi.ws_msg_from_server_decoder()) {
        Ok(webapi.Greeting(m)) -> {
          console.log("The server says hi! '" <> m <> "'")
          #(model, effect.none())
        }
        Ok(webapi.RegisterPrecheckResponse(ok, why)) -> {
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
        Ok(webapi.OwnUserInformationResponse(
          username:,
          email:,
          avatar:,
          uuid:,
          unread_notifications:,
        )) -> {
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
              user: Some(model_type.UserSubmodel(
                uid: uuid,
                username:,
                email:,
                avatar: avatar_string,
                notifs: model_type.NotificationsSubModel(
                  unread_count: unread_notifications,
                  cached_notifications: [],
                ),
              )),
            ),
            effect.none(),
          )
        }
        Ok(webapi.AuthenticationSuccess(_username, token:)) -> {
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
              webapi.OwnUserInformationRequest
                |> encode_ws_msg
                |> json.to_string
                |> lustre_websocket.send(socket, _),
              // Even though 'officially' we don't show the global timeline, this should be the one requested firstly.
              webapi.TimeLineRequest("global", 0)
                |> encode_ws_msg
                |> json.to_string
                |> lustre_websocket.send(socket, _),
            ]),
          )
        }
        Ok(webapi.AuthenticationFailure) -> {
          case model.page {
            model_type.Landing | HomeTimeline(..) | NotFound(..) | Licence ->
              session_destroy()
            Login(fields:, success: _) -> #(
              Model(..model, page: Login(fields:, success: Some(False))),
              effect.none(),
            )
            // If on register page, do nothing.
            Register(..) -> #(model, effect.none())
          }
        }
        Ok(webapi.TimeLineResponse(
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
          let assert model_type.WsConnectionConnected(socket) = model.ws
            as "Socket not connected"
          let posts_fetches =
            effect.batch(
              list.map(items, fn(post_id) {
                webapi.PostContentRequest(post_id:)
                |> encode_ws_msg
                |> json.to_string
                |> lustre_websocket.send(socket, _)
              }),
            )

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
            posts_fetches,
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
        Ok(webapi.Undecodable) ->
          panic as "Received message that was explicitly marked as undecodable, this should not happen
	as the decoder should have returned an error instead of Undecodable. Check the decoder implementation and the logs
	for the raw message."
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
            lustre_websocket.AbnormalClose ->
              "Abnormal close (no close frame was received)"
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
          let new_model = Model(..model, ws: model_type.WsConnectionUnsure)
          #(new_model, let_definitely_disconnect(new_model))
        }
      }
    }
    lustre_websocket.OnOpen(socket) -> #(
      Model(..model, ws: model_type.WsConnectionConnected(socket)),
      lustre_websocket.send(
        socket,
        webapi.Introduction(webapi.WebClient, case model.user, model.token {
          None, Some(token) -> Some(token)
          _, _ -> None
        })
          |> encode_ws_msg
          |> json.to_string,
      ),
    )
  }
}

fn send_refresh_request(model: model_type.Model) -> Effect(Msg) {
  let current_time =
    timestamp.system_time()
    |> timestamp.to_unix_seconds
    |> float.truncate
  use dispatcher <- effect.from
  dispatcher(model_type.UpdateLastRefreshRequestTime(current_time))
  case model.last_refresh_request_time - current_time < 30 {
    True -> {
      Nil
    }
    False -> {
      let inventory = model |> model_type.create_cache_inventory()

      // Todo: send this to server to get updates on cached items.
      console.log(
        "Would send cache inventory to server: \n"
        <> string.inspect(inventory)
        <> "\n\nNot yet implemented.",
      )
    }
  }
}

fn session_destroy() -> #(Model, Effect(Msg)) {
  console.info("Destroying session.")
  let assert Ok(s) = storage.local()
  storage.clear(s)
  console.info("Recreating model.")
  init(False)
}
