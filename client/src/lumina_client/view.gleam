//// Lumina > Client > View
//// Module containing the view function and it's splits

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

import gleam/dynamic/decode
import gleam/option.{None, Some}
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
import lumina_client/view/common_view_parts.{common_view_parts}
import lumina_client/view/common_view_parts/svgs
import lumina_client/view/homepage.{view as view_homepage}
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
  html.div(
    [get_color_scheme(model), attribute.class("w-screen h-screen content")],
    [
      case model.ws {
        model_type.WsConnectionInitial ->
          html.div(
            [
              attribute.attribute("open", ""),
              attribute.class("modal modal-bottom sm:modal-middle"),
            ],
            [
              html.div([attribute.class("modal-box")], [
                element.text("Connecting to server..."),
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
              attribute.class("toast toast-top toast-center z-100"),
            ],
            [
              html.div([attribute.class("alert alert-info")], [
                element.text("Connection to server ended! "),
                html.button(
                  [
                    attribute.class("btn btn-primary font-menuitems"),
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
              attribute.class("toast toast-top toast-center z-100"),
            ],
            [
              html.div([attribute.class("alert alert-info")], [
                element.text("Connection to server ended! Reconnecting..."),
                html.div([attribute.class("float-right")], [
                  html.span(
                    [attribute.class("loading loading-spinner loading-lg")],
                    [],
                  ),
                ]),
              ]),
            ],
          )

        model_type.WsConnectionConnected(..) | model_type.WsConnectionUnsure ->
          element.none()
      },
      case model.page {
        Landing -> view_landing()
        Register(..) -> view_register(model)
        Login(..) -> view_login(model)
        HomeTimeline(..) -> view_homepage(model)
      },
    ],
  )
}

fn view_landing() -> Element(Msg) {
  [
    html.div(
      [attribute.class("hero h-screen max-h-[calc(100vh-4rem)] overflow-auto")],
      [
        html.div([attribute.class("hero-content text-center")], [
          html.div([attribute.class("max-w-md")], [
            html.h1([attribute.class("text-5xl font-bold")], [
              element.text("Welcome to Lumina!"),
            ]),
            html.p([attribute.class("py-6")], [
              element.text(
                "This should be a nice landing page, but I don't know what to put here right now. Go away! Skram!",
              ),
            ]),
            html.button(
              [
                attribute.class("btn btn-primary font-menuitems"),
                event.on_click(ToLoginPage),
              ],
              [element.text("Login")],
            ),
            html.button(
              [
                attribute.class("btn btn-secondary font-menuitems"),
                event.on_click(ToRegisterPage),
              ],
              [element.text("Register")],
            ),
          ]),
        ]),
      ],
    ),
    html.input([
      attribute.class("modal-toggle"),
      attribute.id("landing-attributions-show"),
      attribute.type_("checkbox"),
    ]),
    html.div([attribute.role("dialog"), attribute.class("modal")], [
      html.div([attribute.class("modal-box max-h-[70VH] overflow-y-clip")], [
        html.h3([attribute.class("text-lg font-bold")], [
          html.text("Attributions"),
        ]),
        html.p([attribute.class("py-4")], [
          attributions(),
        ]),
        html.div([attribute.class("modal-action")], [
          html.label(
            [
              attribute.class("btn btn-error font-menuitems"),
              attribute.for("landing-attributions-show"),
            ],
            [
              html.text("Close"),
            ],
          ),
        ]),
      ]),
    ]),
    html.footer(
      [
        attribute.class(
          "absolute footer footer-center p-4 bg-base-300 text-base-content bottom-0",
        ),
      ],
      [
        html.div([], [
          html.p([], [
            element.text(
              "The Lumina/Peonies project, by MLC 'Strawmelonjuice' Bloeiman and contributors. ",
            ),
            html.a(
              [
                attribute.href("/licence"),
                attribute.class("link link-neutral-content"),
              ],
              [
                element.text(
                  "Licensed under the GNU Affero General Public License v3 or later",
                ),
              ],
            ),
            element.text("."),
          ]),
          html.p([], [
            element.text("Also uses some CC-BY and other open-source assets, "),
            html.label(
              [
                attribute.class("link link-neutral-content"),
                attribute.for("landing-attributions-show"),
              ],
              [
                html.text("see attributions"),
              ],
            ),
            element.text("."),
          ]),
        ]),
      ],
    ),
  ]
  |> common_view_parts(with_menu: [])
}

fn attributions() -> Element(Msg) {
  html.div(
    [
      attribute.class("overflow-y-auto max-h-[45vh]"),
    ],
    [
      html.ul([], [
        html.li(
          [
            attribute.class("card block bg-neutral p-4 mb-4 rounded-lg"),
          ],
          [
            html.h4([attribute.class("text-lg font-bold mb-2")], [
              html.text("Icons from SVGrepo.com"),
            ]),
            html.h5([attribute.class("text-[1.100rem] font-bold mb-2")], [
              html.text("Solar Linear icon set"),
            ]),
            html.div([attribute.class("flex flex-row items-center w-full")], [
              html.a(
                [attribute.href("https://www.svgrepo.com/svg/524520/earth")],
                [svgs.globe("w-6 h-6 me-2")],
              ),
              html.a(
                [attribute.href("https://www.svgrepo.com/svg/524793/pen-2")],
                [svgs.pen("w-6 h-6 me-2")],
              ),
              html.a(
                [attribute.href("https://www.svgrepo.com/svg/524361/camera")],
                [svgs.camera("w-6 h-6 me-2")],
              ),
              html.a(
                [
                  attribute.href(
                    "https://www.svgrepo.com/svg/524800/pen-new-square",
                  ),
                ],
                [svgs.pen_paper("w-6 h-6 me-2")],
              ),
            ]),
            html.text("Vectors and icons by "),
            html.a(
              [
                attribute.target("_blank"),
                attribute.class("link"),
                attribute.href(
                  "https://www.figma.com/community/file/1166831539721848736?ref=svgrepo.com",
                ),
              ],
              [html.text("Solar Icons")],
            ),
            html.text(" in CC Attribution License via "),
            html.a(
              [
                attribute.class("link"),
                attribute.target("_blank"),
                attribute.href("https://www.svgrepo.com/"),
              ],
              [html.text("SVG Repo")],
            ),
          ],
        ),
        html.li([attribute.class("card block bg-neutral p-4 mb-4 rounded-lg")], [
          html.h4([attribute.class("text-lg font-bold mb-2")], [
            html.img([
              attribute.src("https://gleam.run/images/lucy/lucy.svg"),
              attribute.class("inline-block w-5 h-auto ms-2 align-middle"),
            ]),
            html.text("Gleam"),
          ]),
          element.text("Much thanks to the "),
          html.a(
            [
              attribute.href("https://gleam.run/"),
              attribute.class("link "),
            ],
            [
              html.text("Gleam programming language"),
            ],
          ),
          element.text(" and its community!"),
        ]),
        html.li([attribute.class("card block bg-neutral p-4 mb-4 rounded-lg")], [
          html.h4([attribute.class("text-lg font-bold mb-2")], [
            html.text("Fonts used"),
          ]),
          html.ul([attribute.class("list-disc list-inside")], [
            {
              html.li([], [
                html.span([], [
                  html.a(
                    [
                      attribute.href(
                        "https://fonts.google.com/specimen/Vend+Sans",
                      ),
                      attribute.class("link font-sans"),
                    ],
                    [
                      html.text("Vend Sans"),
                    ],
                  ),
                  element.text("  "),
                  html.span(
                    [
                      attribute.class(
                        "badge badge-xs badge-soft badge-secondary text-xs",
                      ),
                    ],
                    [element.text("font-sans")],
                  ),
                ]),
                html.p([attribute.class("text-xs")], [
                  element.text(
                    "Designed by Bloom Type Foundry and Baptiste Guesnon under SIL Open Font License.",
                  ),
                ]),
              ])
            },
            {
              html.li([], [
                html.span([], [
                  html.a(
                    [
                      attribute.href(
                        "https://fonts.google.com/specimen/Gantari",
                      ),
                      attribute.class("link  font-logo"),
                    ],
                    [
                      html.text("Gantari"),
                    ],
                  ),
                  element.text("  "),

                  html.span(
                    [
                      attribute.class(
                        "badge badge-xs badge-soft badge-secondary text-xs",
                      ),
                    ],
                    [element.text("font-logo")],
                  ),
                ]),
                html.p([attribute.class("text-xs")], [
                  element.text("Designed by Lafontype"),
                ]),
              ])
            },
            {
              html.li([], [
                html.span([], [
                  html.a(
                    [
                      attribute.href(
                        "https://fonts.google.com/specimen/Elms+Sans",
                      ),
                      attribute.class("link  font-content"),
                    ],
                    [
                      html.text("Elms Sans"),
                    ],
                  ),
                  element.text("  "),

                  html.span(
                    [
                      attribute.class(
                        "badge badge-xs badge-soft badge-secondary text-xs",
                      ),
                    ],
                    [element.text("font-content")],
                  ),
                ]),
                html.p([attribute.class("text-xs")], [
                  element.text(
                    "Designed by Amarachi Nwauwa under SIL Open Font License",
                  ),
                ]),
              ])
            },

            {
              html.li([], [
                html.span([], [
                  html.a(
                    [
                      attribute.href(
                        "https://fonts.google.com/specimen/Josefin+Sans",
                      ),
                      attribute.class("link  font-menuitems"),
                    ],
                    [
                      html.text("Josefin Sans"),
                    ],
                  ),
                  element.text("  "),

                  html.span(
                    [
                      attribute.class(
                        "badge badge-xs badge-soft badge-secondary text-xs",
                      ),
                    ],
                    [element.text("font-menuitems")],
                  ),
                ]),
                html.p([attribute.class("text-xs")], [
                  element.text(
                    "Designed by Santiago Orozco under SIL Open Font License",
                  ),
                ]),
              ])
            },
            {
              html.li([], [
                html.span([], [
                  html.a(
                    [
                      attribute.href(
                        "https://fonts.google.com/specimen/DM+Mono",
                      ),
                      attribute.class("link  font-script"),
                    ],
                    [
                      html.text("DM Mono"),
                    ],
                  ),
                  element.text("  "),

                  html.span(
                    [
                      attribute.class(
                        "badge badge-xs badge-soft badge-secondary text-xs",
                      ),
                    ],
                    [element.text("font-script")],
                  ),
                ]),
                html.p([attribute.class("text-xs")], [
                  element.text(
                    "Designed by Colophon Foundry under SIL Open Font License",
                  ),
                ]),
              ])
            },
          ]),
        ]),
      ]),
    ],
  )
}

fn view_login(model: Model) -> Element(Msg) {
  // We know that the model is a Login page, so we can safely unwrap it
  let assert Login(fieldvalues, successful) = model.page
  let values_ok = login_view_checker(fieldvalues)
  [
    html.div(
      [attribute.class("hero h-screen max-h-[calc(100vh-4rem)] overflow-auto")],
      [
        html.div(
          [attribute.class("hero-content flex-col lg:flex-row-reverse")],
          [
            html.div([attribute.class("text-center lg:text-left")], [
              html.h1([attribute.class("text-5xl font-bold")], [
                element.text("Log in to Lumina!"),
              ]),
              html.p([attribute.class("py-6")], [
                element.text(
                  "And we have boiling water. I REALLY don't know what to put here right now.",
                ),
              ]),
            ]),
            html.div(
              [
                attribute.class(
                  "card w-full max-w-sm shrink-0 shadow-2xl transition-colors bg-neutral",
                ),
              ],
              [
                html.form(
                  [
                    attribute.class(
                      "card-body m-4 transition-[height] duration-300 ease-in-out transition",
                    ),
                    event.on_submit(SubmitLogin),
                  ],
                  [
                    html.fieldset([attribute.class("fieldset")], [
                      html.label([attribute.class("fieldset-label")], [
                        element.text("Email or username"),
                      ]),
                      html.input([
                        attribute.placeholder("me@mymail.com"),
                        attribute.class(
                          "input input-primary bg-primary font-content",
                        ),
                        attribute.type_("text"),
                        attribute.value(fieldvalues.emailfield),
                        event.on_input(UpdateEmailField),
                        event.on("focusout", {
                          decode.success(message_type.FocusLostEmailField)
                        }),
                      ]),
                      html.label([attribute.class("fieldset-label")], [
                        element.text("Password"),
                      ]),
                      html.input([
                        attribute.value(fieldvalues.passwordfield),
                        event.on_input(UpdatePasswordField),
                        attribute.placeholder("Password"),
                        attribute.class(
                          "input input-primary bg-primary font-content",
                        ),
                        attribute.type_("password"),
                      ]),
                      html.div([], [
                        html.a([attribute.class("link link-hover")], [
                          element.text("Forgot password?"),
                        ]),
                      ]),
                      case successful {
                        Some(False) ->
                          html.div(
                            [
                              attribute.class(
                                "text-error-content bg-error p-3 rounded-lg",
                              ),
                            ],
                            [
                              element.text(
                                "Incorrect password and/or username!",
                              ),
                            ],
                          )
                        _ -> element.none()
                      },
                      html.button(
                        case values_ok {
                          True -> [
                            attribute.class(
                              "btn btn-accent w-full mt-4 font-menuitems",
                            ),
                            attribute.type_("submit"),
                          ]
                          False -> [
                            attribute.class(
                              "btn btn-accent w-full mt-4 btn-disabled font-menuitems bg-accent hidden",
                            ),
                            attribute.disabled(True),
                          ]
                        },
                        [element.text("Login")],
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
  |> common_view_parts(with_menu: [
    html.li([event.on_click(ToLandingPage)], [
      html.a([], [element.text("Back")]),
    ]),
    html.li([event.on_click(ToRegisterPage)], [
      html.a([], [element.text("Register")]),
    ]),
    html.li([event.on_click(ToLoginPage)], [
      html.a([attribute.class("bg-primary text-primary-content")], [
        element.text("Login"),
      ]),
    ]),
  ])
}

fn view_register(model_: Model) -> Element(Msg) {
  // We know that the model is a Login page, so we can safely unwrap it
  let assert Register(fieldvalues, ready): model_type.Page = model_.page
  // Check if the password and password confirmation fields match and if the email and username fields are not empty
  [
    html.div(
      [
        attribute.class("hero h-screen max-h-[calc(100vh-4rem)] overflow-auto"),
      ],
      [
        html.div(
          [attribute.class("hero-content flex-col lg:flex-row-reverse")],
          [
            html.div(
              [
                attribute.class(
                  "card bg-neutral w-full max-w-sm shrink-0 shadow-2xl",
                ),
              ],
              [
                html.form(
                  [
                    attribute.class(
                      "card-body m-4 delay-150 duration-300 ease-in-out transition-[height]",
                    ),
                    event.on_submit(SubmitSignup),
                  ],
                  [
                    html.fieldset([attribute.class("fieldset")], [
                      html.label([attribute.class("fieldset-label")], [
                        element.text("Email"),
                      ]),
                      html.input([
                        attribute.placeholder("Email"),
                        attribute.class(
                          "input input-primary bg-primary font-content",
                        ),
                        attribute.type_("email"),
                        attribute.value(fieldvalues.emailfield),
                        event.on_input(UpdateEmailField),
                      ]),
                      html.label([attribute.class("fieldset-label")], [
                        element.text("Username"),
                      ]),
                      html.input([
                        attribute.placeholder("Username"),
                        attribute.class(
                          "input input-primary bg-primary font-content",
                        ),
                        attribute.type_("string"),
                        attribute.value(fieldvalues.usernamefield),
                        event.on_input(UpdateUsernameField),
                      ]),
                      html.label([attribute.class("fieldset-label")], [
                        element.text("Password"),
                      ]),
                      html.input([
                        attribute.value(fieldvalues.passwordfield),
                        event.on_input(UpdatePasswordField),
                        attribute.placeholder("Password"),
                        attribute.class(
                          "input input-primary bg-primary font-content",
                        ),
                        attribute.type_("password"),
                      ]),
                      html.label([attribute.class("fieldset-label")], [
                        element.text("Confirm Password"),
                      ]),
                      html.input([
                        attribute.value(fieldvalues.passwordconfirmfield),
                        event.on_input(UpdatePasswordConfirmField),
                        attribute.placeholder("Re-type password"),
                        attribute.class(
                          "input input-primary bg-primary font-content",
                        ),
                        attribute.type_("password"),
                      ]),

                      case
                        ready |> option.is_some()
                        && ready |> option.unwrap(Error("")) |> result.is_ok()
                        && fieldvalues.passwordfield
                        == fieldvalues.passwordconfirmfield
                      {
                        True ->
                          html.button(
                            [
                              attribute.class(
                                "btn btn-accent font-menuitems w-full m-0 p-0 mt-2",
                              ),
                              attribute.type_("submit"),
                            ],
                            [
                              html.text(
                                case
                                  ready |> option.is_some()
                                  && ready
                                  |> option.unwrap(Error(""))
                                  |> result.is_ok()
                                {
                                  True ->
                                    "Sign up as " <> fieldvalues.usernamefield
                                  False -> "Sign up"
                                },
                              ),
                            ],
                          )
                        False ->
                          html.div(
                            [
                              attribute.class(case ready |> option.is_some() {
                                True ->
                                  "btn bg-base-200 hover:bg-base-200 text-warning-content font-menuitems w-full m-0 p-0 rounded-lg mt-2 opacity-80 hover:opacity-80 cursor-default no-animation disabled"
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
                                  html.div([attribute.class("")], [
                                    html.span(
                                      [],
                                      case string.contains(why, "in use") {
                                        True -> [
                                          element.text(
                                            " " <> why <> ", do you want to ",
                                          ),
                                          html.a(
                                            [
                                              event.on_click(ToLoginPage),
                                              attribute.class(
                                                "link link-primary",
                                              ),
                                            ],
                                            [element.text("log in instead")],
                                          ),
                                          element.text("?"),
                                        ]
                                        False -> [element.text(" " <> why)]
                                      },
                                    ),
                                  ])
                                Ok(_), True -> element.none()
                                Ok(_), False ->
                                  html.div([attribute.class("")], [
                                    element.text("Passwords don't match!"),
                                  ])
                              },
                            ],
                          )
                      },
                    ]),
                  ],
                ),
              ],
            ),
            html.div([attribute.class("text-center lg:text-left")], [
              html.h1([attribute.class("text-5xl font-bold")], [
                element.text("Sign up for Lumina!"),
              ]),
              html.p([attribute.class("py-6")], [
                element.text(
                  "We have real good food, I don't know what to put here right now.",
                ),
              ]),
            ]),
          ],
        ),
      ],
    ),
  ]
  |> common_view_parts(with_menu: [
    html.li([event.on_click(ToLandingPage)], [
      html.a([], [element.text("Back")]),
    ]),
    html.li([event.on_click(ToRegisterPage)], [
      html.a([attribute.class("bg-primary text-primary-content")], [
        element.text("Register"),
      ]),
    ]),
    html.li([event.on_click(ToLoginPage)], [html.a([], [element.text("Login")])]),
  ])
}
