//// Module containing the view function and it's splits

import gleam/dynamic/decode
import gleam/option
import gleam/result
import gleam/string
import lumina_client/helpers.{
  get_color_scheme, login_view_checker, model_local_storage_key,
}
import lumina_client/message_type.{
  type Msg, SubmitLogin, SubmitSignup, ToLandingPage, ToLoginPage,
  ToRegisterPage, UpdateEmailField, UpdatePasswordConfirmField,
  UpdatePasswordField, UpdateUsernameField, WSTryReconnect,
}
import lumina_client/model_type.{
  type Model, HomeTimeline, Landing, Login, Register,
}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import plinth/javascript/storage

pub fn view(model: Model) -> Element(Msg) {
  let assert Ok(localstorage) = storage.local()
    as "localstorage should be available on ALL major browsers."
  let _ =
    storage.set_item(
      localstorage,
      model_local_storage_key,
      model_type.serialize(model),
    )
  html.div([get_color_scheme(model), attribute.class("w-screen h-screen")], [
    case model.ws {
      model_type.WsConnectionInitial ->
        html.div(
          [
            attribute.attribute("open", ""),
            attribute.class("modal modal-bottom sm:modal-middle"),
          ],
          [
            html.div([attribute.class("modal-box")], [
              html.text("Connecting to server..."),
              html.div([attribute.class("float-right")], [
                html.span(
                  [attribute.class("loading loading-spinner loading-xl")],
                  [],
                ),
              ]),
            ]),
          ],
        )
      model_type.WsConnectionDisconnected ->
        html.div(
          [
            attribute.attribute("open", ""),
            attribute.class("toast toast-top toast-center"),
          ],
          [
            html.div([attribute.class("alert alert-info")], [
              html.text("Connection to server ended! "),
              html.button(
                [
                  attribute.class("btn btn-primary"),
                  event.on_click(WSTryReconnect),
                ],
                [element.text("Reconnect")],
              ),
            ]),
          ],
        )

      model_type.WsConnectionRetrying ->
        html.div(
          [
            attribute.attribute("open", ""),
            attribute.class("toast toast-top toast-center"),
          ],
          [
            html.div([attribute.class("alert alert-info")], [
              html.text("Connection to server ended! Reconnecting..."),
              html.div([attribute.class("float-right")], [
                html.span(
                  [attribute.class("loading loading-spinner loading-lg")],
                  [],
                ),
              ]),
            ]),
          ],
        )

      model_type.WsConnectionConnected(..)
      | model_type.WsConnectionDisconnecting -> element.none()
    },
    case model.page {
      Landing -> view_landing()
      Register(..) -> view_register(model)
      Login(..) -> view_login(model)
      HomeTimeline(..) -> view_homepage(model)
    },
    // html.div([attribute.class("absolute left-0 bottom-0 text-xs")], [
  //   element.text(int.to_string(model.ticks)),
  // ]),
  ])
}

fn view_landing() -> Element(Msg) {
  [
    html.div([attribute.class("hero h-screen max-h-[calc(100vh-4rem)]")], [
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
    ]),
  ]
  |> common_view_parts(with_menu: [])
}

fn view_login(model: Model) -> Element(Msg) {
  // We know that the model is a Login page, so we can safely unwrap it
  let assert Login(fieldvalues, successful) = model.page
  let values_ok = login_view_checker(fieldvalues)
  [
    html.div([attribute.class("hero h-screen max-h-[calc(100vh-4rem)]")], [
      html.div([attribute.class("hero-content flex-col lg:flex-row-reverse")], [
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
              "card delay-150 duration-300 ease-in-out w-full max-w-sm shrink-0 shadow-2xl transition-colors ",
            ),
            attribute.class(case successful {
              option.None -> "bg-base-100"
              option.Some(False) -> "bg-error/50"
              // If this is actually the case, we'll be on another page!
              // This shouldn't generally ever be actually constructed in the Login view.
              option.Some(True) -> "bg-success"
            }),
          ],
          [
            html.form(
              [attribute.class("card-body m-4"), event.on_submit(SubmitLogin)],
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
                    event.on("focusout", {
                      decode.success(message_type.FocusLostEmailField)
                    }),
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
                  case successful {
                    option.Some(False) ->
                      html.div(
                        [
                          attribute.class(
                            "text-error-content bg-error p-3 rounded-lg",
                          ),
                        ],
                        [element.text("Incorrect password and/or username!")],
                      )
                    _ -> element.none()
                  },
                  html.button(
                    case values_ok {
                      True -> [
                        attribute.class("btn btn-base-400 mt-4"),
                        attribute.type_("submit"),
                      ]
                      False -> [
                        attribute.class("btn btn-base-400 mt-4 btn-disabled"),
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
      ]),
    ]),
  ]
  |> common_view_parts(with_menu: [
    html.li([event.on_click(ToLandingPage)], [html.a([], [html.text("Back")])]),
    html.li([event.on_click(ToRegisterPage)], [
      html.a([], [html.text("Register")]),
    ]),
    html.li([event.on_click(ToLoginPage)], [
      html.a([attribute.class("bg-primary text-primary-content")], [
        html.text("Login"),
      ]),
    ]),
  ])
}

fn view_register(model_: Model) -> Element(Msg) {
  // We know that the model is a Login page, so we can safely unwrap it
  let assert Register(fieldvalues, ready): model_type.Page = model_.page
  // Check if the password and password confirmation fields match and if the email and username fields are not empty
  [
    html.div([attribute.class("hero h-screen max-h-[calc(100vh-4rem)]")], [
      html.div([attribute.class("hero-content flex-col lg:flex-row-reverse")], [
        html.div(
          [
            attribute.class(
              "card bg-base-100 w-full max-w-sm shrink-0 shadow-2xl",
            ),
          ],
          [
            html.form(
              [attribute.class("card-body  m-4"), event.on_submit(SubmitSignup)],
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
                              [attribute.class("inline-grid *:[grid-area:1/1]")],
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
                            html.span([], case string.contains(why, "in use") {
                              True -> [
                                html.text(" " <> why <> ", do you want to "),
                                html.a(
                                  [
                                    event.on_click(ToLoginPage),
                                    attribute.class("link link-primary"),
                                  ],
                                  [element.text("log in instead")],
                                ),
                                element.text("?"),
                              ]
                              False -> [element.text(" " <> why)]
                            }),
                          ])
                        Ok(_), True ->
                          html.div([attribute.class("w-full")], [
                            html.div(
                              [attribute.class("inline-grid *:[grid-area:1/1]")],
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
                              [attribute.class("inline-grid *:[grid-area:1/1]")],
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
        html.div([attribute.class("text-center lg:text-left")], [
          html.h1([attribute.class("text-5xl font-bold")], [
            html.text("Sign up for Lumina!"),
          ]),
          html.p([attribute.class("py-6")], [
            html.text(
              "We have real good food, I don't know what to put here right now.",
            ),
          ]),
        ]),
      ]),
    ]),
  ]
  |> common_view_parts(with_menu: [
    html.li([event.on_click(ToLandingPage)], [html.a([], [html.text("Back")])]),
    html.li([event.on_click(ToRegisterPage)], [
      html.a([attribute.class("bg-primary text-primary-content")], [
        html.text("Register"),
      ]),
    ]),
    html.li([event.on_click(ToLoginPage)], [html.a([], [html.text("Login")])]),
  ])
}

fn view_homepage(model: model_type.Model) {
  [
    html.div(
      [
        attribute.class(
          "tabs tabs-box h-screen max-h-[calc(100vh-4rem)] bg-neutral text-neutral-content",
        ),
      ],
      [
        html.input([
          attribute.attribute("aria-label", "Tab 1"),
          attribute.class("tab"),
          attribute.name("my_tabs_6"),
          attribute.type_("radio"),
        ]),
        html.div(
          [attribute.class("tab-content bg-base-200 border-base-300 p-6")],
          [html.text("Tab content 1")],
        ),
        html.input([
          attribute.checked(True),
          attribute.attribute("aria-label", "Tab 2"),
          attribute.class("tab"),
          attribute.name("my_tabs_6"),
          attribute.type_("radio"),
        ]),
        html.div(
          [attribute.class("tab-content bg-base-200 border-base-300 p-6")],
          [html.text("Still, I've to put something on here innit?")],
        ),
        html.input([
          attribute.attribute("aria-label", "Tab 3"),
          attribute.class("tab"),
          attribute.name("my_tabs_6"),
          attribute.type_("radio"),
        ]),
        html.div(
          [attribute.class("tab-content bg-base-200 border-base-300 p-6")],
          [html.text("Tab content 3")],
        ),
      ],
    ),
  ]
  |> common_view_parts(with_menu: [])
}

fn common_view_parts(
  main_body: List(Element(Msg)),
  with_menu menuitems: List(Element(Msg)),
) {
  html.div([], [
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
        html.ul([attribute.class("menu menu-horizontal px-1")], menuitems),
      ]),
    ]),
    html.div(
      [attribute.class("bg-base-200 h-screen max-h-[calc(100vh-4rem)]")],
      main_body,
    ),
  ])
}
