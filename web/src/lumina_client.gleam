//// Lumina > Client
//// Main entry point for Lumina's web frontend. This module contains all side-effects, the update function. Lustre initialisation and more.
////
//// It'll also contain one of the two update() function implementations, the websocket one. Since the Gleam backend
//// now consumes this frontend as a server component, the websocket is implemented as a 'plug-in' solution.
//// returning the server's (json) String response, which is then parseable on the Gleam end.

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

// Imports ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

import gleam/option.{None}
import gleam/result
import gleam/string
import lumina_client/model_type.{
  type Model, type Msg as Message, type Route, Model,
}
import lumina_client/view
import lustre
import lustre/effect
import off_topic

// Entrypoints ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/// Entry point for mainly the Rust backend, which doesn't use server-components and does a server-client based
/// approach instead.
pub fn main() -> Result(lustre.Runtime(Message), lustre.Error) {
  // This module was a mess, and the lustre_websocket package is outdated.
  // Good reason for me to throw it all out amidst a refactor!
  // - Mar
  // let assert Ok(_) = lustre.start(app(api_based_updates), "#app", Nil)
  todo as "The api wrapper should kick in here."
}

/// Main entry of the lumina_client, meant to be consumed as a server component
pub fn app() {
  off_topic.component(
    init:,
    update:,
    view: view.view,
    subscriptions:,
    options: [],
  )
}

// Common functionality ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

/// Init function
fn init(_) -> #(Model, effect.Effect(Message)) {
  let initial_route = model_type.Landing
  #(
    Model(page: initial_route, user: None, token: None, status: Ok(Nil)),
    effect.none(),
  )
  |> echo as "Init output"
}

// Event handling ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

/// Subscriptions
fn subscriptions(_model: Model) -> off_topic.Subscription(Message) {
  off_topic.batch([])
}

/// Update function used mainly with the Rust backend
fn update(model: Model, message: Message) -> #(Model, effect.Effect(Message)) {
  echo message as "Received message"
  case message {
    model_type.UserNavigatedToLoginPage -> #(
      Model(
        ..model,
        page: model_type.Login(
          fields: model_type.LoginFields("", ""),
          success: None,
        ),
      ),
      effect.none(),
    )
    model_type.UserNavigatedToRegisterPage -> #(
      Model(
        ..model,
        page: model_type.Register(
          fields: model_type.RegisterPageFields("", "", "", ""),
          ready: None,
        ),
      ),
      effect.none(),
    )
    model_type.UserNavigatedToLandingPage -> #(
      Model(..model, page: model_type.Landing),
      effect.none(),
    )
    model_type.UserUpdatedControlledEmailField(new_email) -> {
      case model.page {
        model_type.Register(fields, ready) -> #(
          Model(
            ..model,
            page: model_type.Register(
              fields: model_type.RegisterPageFields(
                ..fields,
                emailfield: new_email,
              ),
              ready:,
            ),
          ),
          {
            // This block emits an effect to send RegisterPrecheck message to the server
            todo as "RegisterPrecheck(
              fields.emailfield,
              fields.usernamefield,
              fields.passwordfield,
            )"
          },
        )
        model_type.Login(fields, _) -> #(
          Model(
            ..model,
            page: model_type.Login(
              fields: model_type.LoginFields(..fields, emailfield: new_email),
              success: None,
            ),
          ),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }
    }
    model_type.UserUpdatedControlledPasswordField(new_password) -> {
      case model.page {
        model_type.Register(fields, ready) -> #(
          Model(
            ..model,
            page: model_type.Register(
              model_type.RegisterPageFields(
                ..fields,
                passwordfield: new_password,
              ),
              ready:,
            ),
          ),
          {
            // This block emits an effect to send RegisterPrecheck message to the server
            todo as "RegisterPrecheck(
              fields.emailfield,
              fields.usernamefield,
              fields.passwordfield,
            )"
          },
        )
        model_type.Login(fields, _success) -> {
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
              page: model_type.Login(
                fields: model_type.LoginFields(
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
    model_type.UserUpdatedControlledPasswordConfirmField(
      new_password_confirmation,
    ) -> {
      case model.page {
        model_type.Register(fields, ready) -> #(
          Model(
            ..model,
            page: model_type.Register(
              fields: model_type.RegisterPageFields(
                ..fields,
                passwordconfirmfield: new_password_confirmation,
              ),
              ready:,
            ),
          ),
          {
            // This block emits an effect to send RegisterPrecheck message to the server
            todo as "RegisterPrecheck(
              fields.emailfield,
              fields.usernamefield,
              fields.passwordfield,
            )"
          },
        )
        _ -> #(model, effect.none())
      }
    }
    model_type.UserUpdatedControlledUsernameField(new_username) -> {
      case model.page {
        model_type.Register(fields, ready) -> #(
          Model(
            ..model,
            page: model_type.Register(
              fields: model_type.RegisterPageFields(..fields, usernamefield: {
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
            todo as "RegisterPrecheck(
              fields.emailfield,
              fields.usernamefield,
              fields.passwordfield,
            )"
          },
        )
        _ -> #(model, effect.none())
      }
    }
    model_type.EmailFieldLostFocus -> {
      // This handles the login username/email field value once the user seems to be done typing.
      let assert model_type.Login(fields, _success) = model.page
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
          page: model_type.Login(
            fields: model_type.LoginFields(..fields, emailfield: new_value),
            success: None,
          ),
        ),
        effect.none(),
      )
    }
    model_type.UserClickedLogout -> todo as "session should be destroyed here"
    model_type.UserSubmittedLogin(_) -> {
      // let assert model_type.Login(fields, _) = model.page
      todo as "LoginAuthenticationRequest(
              fields.emailfield,
              fields.passwordfield,
            )"
    }
    model_type.UserSubmittedSignup(_) -> {
      let assert model_type.Register(fields, ready) = model.page

      case
        {
          { ready |> option.is_some() }
          && { ready |> option.unwrap(Error("")) |> result.is_ok() }
          && { fields.passwordfield == fields.passwordconfirmfield }
        }
      {
        True -> {
          // console.log("Submitting signup form")
          let effect =
            todo as "RegisterRequest(
              fields.emailfield,
              fields.usernamefield,
              fields.passwordfield,
            )"
          #(model, effect)
        }
        False -> {
          // console.error("Form not ready to submit")
          #(model, effect.none())
        }
      }
    }
    model_type.UserSwitchedTimeLineTo(tid) -> todo

    model_type.LoadMorePosts(timeline_name) -> todo

    model_type.UserClosedModal -> todo

    model_type.StartDraggingModalBox(x, y) -> todo

    model_type.MoveModalBoxTo(x, y) -> todo

    model_type.UpdateLastRefreshRequestTime(_) -> todo
    model_type.ModemChangePage(_) -> todo
    model_type.SetModal(_) -> todo
  }
}
