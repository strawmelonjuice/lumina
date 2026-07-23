//// **Lumina > Server > Web components >**
//// # Signup
////
//// Main component for the register page

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
import friendly_id
import gleam/bool
import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import lumina_server/data
import lumina_server/server/components/shared.{
  type ComponentInitialisation, type ControlledInput, type GlobalMessage,
  type SessionMessage, ControlledInput, subscribe,
} as lumina_server_components
import lustre.{type App}
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event
import lustre/server_component

// Main ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
pub fn component() -> App(ComponentInitialisation, Model, Message) {
  lustre.application(init, update, view)
}

// Model ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
pub opaque type Model {
  Model(
    global_context: data.Globals,
    session_id: String,
    page_status: Result(Bool, String),
    field_username: ControlledInput(String),
    field_displayname: ControlledInput(String),
    field_email: ControlledInput(String),
    field_password: ControlledInput(String),
    field_password_re: ControlledInput(String),
    // This depends on config we haven't specified well enough yet!
    field_invite_code: Option(#(ControlledInput(String), List(String))),
  )
}

fn init(initialisationdata: ComponentInitialisation) {
  let lumina_server_components.ComponentInitialisation(
    session_id:,
    global_context:,
  ) = initialisationdata
  let model =
    Model(
      global_context:,
      field_username: ControlledInput(
        True,
        value: "",
        validity: Error("Cannot be empty!"),
      ),
      field_email: ControlledInput(
        True,
        value: "",
        validity: Error("Cannot be empty!"),
      ),
      field_displayname: ControlledInput(
        True,
        value: "",
        validity: Error("Cannot be empty!"),
      ),
      field_password: ControlledInput(
        True,
        value: "",
        validity: Error("Cannot be empty!"),
      ),
      field_password_re: ControlledInput(
        True,
        value: "",
        validity: Error("Be sure to enter your password again!"),
      ),
      field_invite_code: None,
      page_status: Ok(False),
      session_id:,
    )
  #(
    model,
    effect.batch([
      effect.from(fn(return) {
        // This depends on config we haven't specified well enough yet!
        // What this effect is supposed to do is ask config if this instance requires invite codes.
        // For now, we just go and say no, which is done by doing...
        return(ConfigFetchedInviteOnly(Error(Nil)))
        // If we'd say yes there, it'd mean a trip to the database to fetch the currently valid invite keys.
        // This allows our input field to immediately tell someone they're entering a wrong key, so that the data module
        // later has less work declining invalid invites :)
      }),
      subscribe(
        on_global_message: AppReceivedGlobalBroadcast,
        on_session_message: AppReceivedSessionMessage,
        session_id:,
        global_message_registry_name: model.global_context.global_app_registry_name,
        session_message_registry_name: model.global_context.session_app_registry_name,
      ),
    ]),
  )
}

// Update ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

pub opaque type Message {
  AppReceivedGlobalBroadcast(GlobalMessage)
  AppReceivedSessionMessage(SessionMessage)
  UserChangedInputUsername(now: String)
  UserChangedInputPassword(now: String)
  UserClickedSubmit
  RegistrationAttemptResult(
    Result(data.UserSession, data.UserRegistrationError),
  )
  UserChangedInputEmail(now: String)
  UserChangedInputPasswordRetype(now: String)
  ConfigFetchedInviteOnly(Result(List(String), Nil))
}

fn update(model: Model, message: Message) -> #(Model, effect.Effect(Message)) {
  case message {
    AppReceivedGlobalBroadcast(data.NewUser(..)) -> #(model, effect.none())
    AppReceivedSessionMessage(data.SessionAuthorized(..)) -> {
      // This was likely this application's own call
      #(model, effect.none())
    }

    UserChangedInputEmail(now:) -> #(
      Model(..model, field_email: {
        ControlledInput(False, value: now, validity: {
          use <- bool.guard(now == "", Error("Cannot be empty!"))
          use <- bool.guard(
            !string.contains(now, "@"),
            Error("Not a valid email address."),
          )
          use <- bool.guard(
            string.starts_with(now, "@"),
            Error("Not a valid email address."),
          )
          Ok(Nil)
        })
      }),
      effect.none(),
    )
    UserChangedInputUsername(now:) -> #(
      Model(..model, field_username: {
        let now =
          now
          |> string.remove_prefix("@")
          |> string.lowercase
        ControlledInput(False, value: now, validity: {
          use <- bool.guard(now == "", Error("Cannot be empty!"))
          let length = string.length(now)
          let minimum = 3
          use <- bool.guard(
            length <= { minimum - 1 },
            Error(
              "At least "
              <> int.to_string(int.absolute_value(length - minimum))
              <> " characters more!",
            ),
          )
          Ok(Nil)
        })
      }),
      effect.none(),
    )

    UserChangedInputPassword(now:) -> #(
      Model(..model, field_password: {
        // Of course, we cannot really expose the password ("Another user with this password...", remember the meme)
        // What we can do, is uphold the password to length requirements.
        ControlledInput(False, value: now, validity: {
          use <- bool.guard(now == "", Error("Cannot be empty!"))
          let length = string.length(now)
          let minimum = 8
          use <- bool.guard(
            length <= { minimum - 1 },
            Error(
              "At least "
              <> int.to_string(int.absolute_value(length - minimum))
              <> " characters more!",
            ),
          )
          Ok(Nil)
        })
      }),
      effect.none(),
    )

    UserChangedInputPasswordRetype(now:) -> #(
      Model(..model, field_password_re: {
        // Of course, we cannot really expose the password ("Another user with this password...", remember the meme)
        // What we can do, is uphold the password to length requirements.
        ControlledInput(False, value: now, validity: {
          use <- bool.guard(
            now != model.field_password.value,
            Error("Passwords should match."),
          )
          Ok(Nil)
        })
      }),
      effect.none(),
    )

    UserClickedSubmit
      if {
        model.field_password.validity == Ok(Nil)
        && model.field_password_re.validity == Ok(Nil)
        && model.field_email.validity == Ok(Nil)
        && model.field_username.validity == Ok(Nil)
      }
    -> {
      #(Model(..model, page_status: Ok(True)), {
        use disp <- effect.from()
        data.user_register_and_authorise(
          postgres_pool_name: model.global_context.postgres_pool_name,
          session_id: model.session_id,
          password: model.field_password.value,
          email: model.field_email.value,
          username: model.field_username.value,
          display_name: model.field_displayname.value,
          invite_code: { None },
        )
        |> echo as "Attempted:"
        |> RegistrationAttemptResult
        |> disp
      })
    }

    UserClickedSubmit -> {
      // Invalid form submission
      #(
        Model(
          ..model,
          field_password: ControlledInput(
            ..model.field_password,
            initial: False,
          ),
          field_username: ControlledInput(
            ..model.field_username,
            initial: False,
          ),
        ),
        effect.none(),
      )
    }

    RegistrationAttemptResult(Ok(data.UserSession(
      user_id:,
      session_uuid:,
      revival_key:,
      username:,
      email:,
    ))) -> todo

    RegistrationAttemptResult(Error(_)) -> todo
    ConfigFetchedInviteOnly(Ok(valid_invites)) -> {
      #(
        Model(
          ..model,
          field_invite_code: Some(#(
            ControlledInput(
              True,
              value: "",
              validity: Error("Cannot be empty!"),
            ),
            valid_invites,
          )),
        ),
        effect.none(),
      )
    }
    ConfigFetchedInviteOnly(Error(Nil)) -> #(
      Model(..model, field_invite_code: None),
      effect.none(),
    )
  }
}

// View ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
fn view(model: Model) -> element.Element(Message) {
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
          attribute.data("spinner", "large overlay"),
          attribute.aria_busy(model.page_status |> result.unwrap(False)),
          attribute.class("card"),
        ],
        [
          case model.page_status {
            Ok(_) -> element.none()
            Error(msg) -> {
              html.div(
                [attribute.data("variant", "error"), attribute.role("alert")],
                [
                  html.strong([], [html.text("Error!")]),
                  html.text(" " <> msg <> " "),
                ],
              )
            }
          },
          html.form([], [
            html.fieldset([attribute.class("vstack")], [
              html.div([attribute.data("field", "")], [
                html.label([attribute.for("field-email")], [
                  html.text(" Email "),
                ]),
                html.input([
                  attribute.value(model.field_email.value),
                  event.on_input(UserChangedInputEmail)
                    |> server_component.include(["target.value"]),
                  attribute.autocomplete("off"),
                  attribute.placeholder(
                    friendly_id.new_generator()
                    |> friendly_id.set_generator_separator("-")
                    |> friendly_id.generate
                    <> "@example.com",
                  ),
                  attribute.id("field-email"),
                  attribute.aria_describedby("field-email-status"),
                  attribute.aria_invalid({
                    case model.field_email {
                      ControlledInput(value: _, validity: _, initial: True)
                      | ControlledInput(value: _, validity: Ok(Nil), initial: _) ->
                        False
                      ControlledInput(value: _, validity: _, initial: False) ->
                        True
                    }
                    |> bool.to_string
                    |> string.lowercase
                  }),
                  attribute.type_("text"),
                ]),
                case model.field_email {
                  ControlledInput(False, _, validity: Error(message)) -> {
                    html.div(
                      [
                        attribute.role("status"),
                        attribute.class("error"),
                        attribute.id("field-email-status"),
                      ],
                      [element.text(message)],
                    )
                  }
                  ControlledInput(value: _, validity: _, initial: True)
                  | ControlledInput(value: _, validity: Ok(Nil), initial: _) ->
                    html.div(
                      [
                        attribute.role("status"),
                        attribute.class("hidden"),
                        attribute.id("field-email-status"),
                      ],
                      [],
                    )
                },
              ]),
              html.div([attribute.data("field", "")], [
                html.label([attribute.for("field-id")], [
                  html.text(" Username "),
                ]),
                html.input([
                  attribute.value(model.field_username.value),
                  event.on_input(UserChangedInputUsername)
                    |> server_component.include(["target.value"]),
                  attribute.autocomplete("off"),
                  attribute.placeholder(
                    friendly_id.new_generator()
                    |> friendly_id.set_generator_separator("-")
                    |> friendly_id.generate,
                  ),
                  attribute.id("field-id"),
                  attribute.aria_describedby("field-id-status"),
                  attribute.aria_invalid({
                    case model.field_username {
                      ControlledInput(value: _, validity: _, initial: True)
                      | ControlledInput(value: _, validity: Ok(Nil), initial: _) ->
                        False
                      ControlledInput(value: _, validity: _, initial: False) ->
                        True
                    }
                    |> bool.to_string
                    |> string.lowercase
                  }),
                  attribute.type_("text"),
                ]),
                case model.field_username {
                  ControlledInput(False, _, validity: Error(message)) -> {
                    html.div(
                      [
                        attribute.role("status"),
                        attribute.class("error"),
                        attribute.id("field-id-status"),
                      ],
                      [element.text(message)],
                    )
                  }
                  ControlledInput(value: _, validity: _, initial: True)
                  | ControlledInput(value: _, validity: Ok(Nil), initial: _) ->
                    html.div(
                      [
                        attribute.role("status"),
                        attribute.class("hidden"),
                        attribute.id("field-id-status"),
                      ],
                      [],
                    )
                },
              ]),
              html.label(
                [attribute.aria_invalid("true"), attribute.data("field", "")],
                [
                  html.text(" Password "),
                  html.input([
                    attribute.value(model.field_password.value),
                    event.on_input(UserChangedInputPassword)
                      |> server_component.include(["target.value"]),
                    attribute.placeholder("•••••••••••••••"),
                    attribute.aria_describedby("field-password-status"),
                    attribute.id("field-password"),
                    attribute.aria_invalid({
                      case model.field_password {
                        ControlledInput(value: _, validity: _, initial: True)
                        | ControlledInput(
                            value: _,
                            validity: Ok(Nil),
                            initial: _,
                          ) -> False
                        ControlledInput(value: _, validity: _, initial: False) ->
                          True
                      }
                      |> bool.to_string
                      |> string.lowercase
                    }),
                    attribute.type_("password"),
                  ]),
                  case model.field_password {
                    ControlledInput(_, _, initial: True)
                    | ControlledInput(_, _, validity: Ok(Nil)) ->
                      html.div(
                        [
                          attribute.role("status"),
                          attribute.id("field-password-status"),
                          attribute.class("hidden"),
                        ],
                        [],
                      )
                    ControlledInput(_, validity: Error(message), initial: False) -> {
                      html.div(
                        [
                          attribute.role("status"),
                          attribute.class("error"),
                          attribute.id("field-password-status"),
                        ],
                        [element.text(message)],
                      )
                    }
                  },
                ],
              ),
            ]),
          ]),
          html.div(
            [
              attribute.class("items-center justify-center flex"),
              attribute.styles([#("width", "100%")]),
            ],
            [
              html.input([
                attribute.type_("submit"),
                event.on_click(UserClickedSubmit) |> event.prevent_default(),
                attribute.disabled(
                  bool.negate({
                    model.field_password.validity == Ok(Nil)
                    && model.field_username.validity == Ok(Nil)
                  }),
                ),
                attribute.value("Sign up"),
              ]),
            ],
          ),
        ],
      ),
    ],
  )
}
