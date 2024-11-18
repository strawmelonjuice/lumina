import gleam/string
import lumina/data/context.{type Context}
import lumina/users
import lumina/web/pages/style
import lumina_rsffi
import lustre/attribute.{attribute}
import lustre/element.{text}
import lustre/element/html
import lustre/element/svg
import simplifile as fs

fn replaceable(html: String, ctx: Context) -> String {
  html
  // instance ID
  |> string.replace(
    each: "{{iid}}",
    with: ctx.config.lumina_synchronisation_iid,
  )
  // month of the year class
  |> string.replace(each: "monthclass-month", with: style.monthclass())
  // day of the month class
  |> string.replace(each: "dayclass-day", with: style.dayclass())
}

pub fn index(ctx: Context) {
  // read the markdown file
  let assert Ok(md) = fs.read(ctx.priv_directory <> "/static/markdown/intro.md")
  let md_html =
    {
      let assert Ok(html) = lumina_rsffi.md_render_to_html(md)
      html
    }
    |> replaceable(ctx)

  // render the page
  html.html([attribute("lang", "en")], [
    html.head([], [
      html.title(
        [],
        "Welcome - Lumina(@" <> ctx.config.lumina_synchronisation_iid <> ")",
      ),
      html.meta([attribute("charset", "UTF-8")]),
      html.style([], style.sheet(ctx)),
      html.script([attribute.type_("module"), attribute.src("/app.js")], ""),
      html.meta([
        attribute("content", "width=device-width, initial-scale=1.0"),
        attribute.name("viewport"),
      ]),
    ]),
    html.body([attribute.class("bg-brown-100 dark:bg-neutral-500")], [
      html.nav([attribute.class("bg-emerald-200 dark:bg-teal-800")], [
        html.div([attribute.class("px-2 mx-auto max-w-7xl sm:px-6 lg:px-8")], [
          html.div(
            [attribute.class("flex relative justify-between items-center h-16")],
            [
              html.div(
                [
                  attribute.class(
                    "flex absolute inset-y-0 left-0 items-center sm:hidden",
                  ),
                ],
                [
                  html.button(
                    [
                      attribute.id("btn-mobile-menu"),
                      attribute("aria-expanded", "false"),
                      attribute("aria-controls", "mobile-menu"),
                      attribute.class(
                        "inline-flex relative justify-center items-center p-2 text-gray-400 rounded-md hover:text-white hover:bg-gray-700 focus:ring-2 focus:ring-inset focus:ring-white focus:outline-none",
                      ),
                      attribute.type_("button"),
                    ],
                    [
                      html.span([attribute.class("absolute -inset-0.5")], []),
                      html.span([attribute.class("sr-only")], [
                        html.text("Open main menu"),
                      ]),
                      svg.svg(
                        [
                          attribute.id("btn-mobile-menu-open"),
                          attribute("aria-hidden", "true"),
                          attribute("stroke", "currentColor"),
                          attribute("stroke-width", "1.5"),
                          attribute("viewBox", "0 0 24 24"),
                          attribute("fill", "none"),
                          attribute.class("block w-6 h-6"),
                        ],
                        [
                          svg.path([
                            attribute(
                              "d",
                              "M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5",
                            ),
                            attribute("stroke-linejoin", "round"),
                            attribute("stroke-linecap", "round"),
                          ]),
                        ],
                      ),
                      svg.svg(
                        [
                          attribute.id("btn-mobile-menu-close"),
                          attribute("aria-hidden", "true"),
                          attribute("stroke", "currentColor"),
                          attribute("stroke-width", "1.5"),
                          attribute("viewBox", "0 0 24 24"),
                          attribute("fill", "none"),
                          attribute.class("w-6 h-6"),
                        ],
                        [
                          svg.path([
                            attribute("d", "M6 18L18 6M6 6l12 12"),
                            attribute("stroke-linejoin", "round"),
                            attribute("stroke-linecap", "round"),
                          ]),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              html.div(
                [
                  attribute.class(
                    "flex flex-1 justify-center items-center sm:justify-start sm:items-stretch",
                  ),
                ],
                [
                  html.div(
                    [attribute.class("flex flex-shrink-0 items-center")],
                    [
                      html.img([
                        attribute.alt("Lumina Instance"),
                        attribute.src("/logo.svg"),
                        attribute.class(
                          "w-auto h-10 bg-opacity-60 rounded-md border-amber-600 bg-stone-100 dark:bg-stone-100",
                        ),
                      ]),
                    ],
                  ),
                ],
              ),
              html.div(
                [
                  attribute.class(
                    "flex absolute inset-y-0 right-0 items-center pr-2 sm:static sm:inset-auto sm:pr-0 sm:ml-6",
                  ),
                ],
                [
                  html.div([attribute.class("hidden sm:block sm:ml-6")], [
                    html.div([attribute.class("flex space-x-4")], [
                      html.a(
                        [
                          attribute.id("signup-nav"),
                          attribute("aria-current", "page"),
                          attribute.class(
                            "py-2 px-3 text-sm font-medium text-white bg-gray-900 rounded-md border-2",
                          ),
                          attribute.href("/signup"),
                        ],
                        [text("Sign-up")],
                      ),
                      html.a(
                        [
                          attribute.id("login-nav"),
                          attribute.class(
                            "py-2 px-3 text-sm font-medium bg-orange-200 rounded-md border-2 border-emerald-600 dark:text-orange-200 dark:bg-yellow-700 hover:text-white hover:bg-gray-700 text-brown-800 dark:border-zinc-400",
                          ),
                          attribute.href("/home"),
                        ],
                        [text("Log in")],
                      ),
                    ]),
                  ]),
                ],
              ),
              html.div(
                [
                  attribute.class(
                    "flex absolute inset-y-0 right-0 items-center pr-2 sm:static sm:inset-auto sm:pr-0 sm:ml-6",
                  ),
                ],
                [],
              ),
            ],
          ),
        ]),
        html.div([attribute.id("mobile-menu"), attribute.class("sm:hidden")], [
          html.div([attribute.class("px-2 pt-2 pb-3 space-y-1")], [
            html.a(
              [
                attribute.id("mobile-login-nav"),
                attribute.class(
                  "block py-2 px-3 text-base font-medium text-white bg-red-400 rounded-md dark:bg-red-900",
                ),
                attribute.href("/home"),
              ],
              [text("Log in")],
            ),
            html.a(
              [
                attribute.id("mobile-signup-nav"),
                attribute.class(
                  "block py-2 px-3 text-base font-medium text-gray-300 rounded-md hover:text-white hover:bg-gray-700",
                ),
                attribute.href("/signup"),
              ],
              [text("Sign up")],
            ),
          ]),
        ]),
      ]),
      html.main(
        [
          attribute.class(
            style.monthclass()
            <> " "
            <> style.dayclass()
            <> " "
            <> "text-fuchsia-900 dark:text-violet-200",
          ),
        ],
        [html.div([attribute("dangerous-unescaped-html", md_html)], [])],
      ),
    ]),
  ])
}

pub fn login(ctx: Context) {
  html.html([attribute("lang", "en")], [
    html.head([], [
      html.title(
        [],
        "Login - Lumina(@" <> ctx.config.lumina_synchronisation_iid <> ")",
      ),
      html.style([], style.sheet(ctx)),
      html.link([
        attribute.type_("image/png"),
        attribute.rel("icon"),
        attribute.href("/logo.png"),
      ]),
      html.script([attribute.type_("module"), attribute.src("/app.js")], ""),
      html.meta([
        attribute("content", "width=device-width, initial-scale=1.0"),
        attribute.name("viewport"),
      ]),
    ]),
    html.body([attribute.class("bg-brown-100 dark:bg-neutral-500")], [
      html.nav([attribute.class("bg-emerald-200 dark:bg-teal-800")], [
        html.div([attribute.class("px-2 mx-auto max-w-7xl sm:px-6 lg:px-8")], [
          html.div(
            [attribute.class("flex relative justify-between items-center h-16")],
            [
              html.div(
                [
                  attribute.class(
                    "flex absolute inset-y-0 left-0 items-center sm:hidden",
                  ),
                ],
                [
                  html.button(
                    [
                      attribute.id("btn-mobile-menu"),
                      attribute("aria-expanded", "false"),
                      attribute("aria-controls", "mobile-menu"),
                      attribute.class(
                        "inline-flex relative justify-center items-center p-2 text-gray-400 rounded-md hover:text-white hover:bg-gray-700 focus:ring-2 focus:ring-inset focus:ring-white focus:outline-none",
                      ),
                      attribute.type_("button"),
                    ],
                    [
                      html.span([attribute.class("absolute -inset-0.5")], []),
                      html.span([attribute.class("sr-only")], [
                        html.text("Open main menu"),
                      ]),
                      svg.svg(
                        [
                          attribute.id("btn-mobile-menu-open"),
                          attribute("aria-hidden", "true"),
                          attribute("stroke", "currentColor"),
                          attribute("stroke-width", "1.5"),
                          attribute("viewBox", "0 0 24 24"),
                          attribute("fill", "none"),
                          attribute.class("block w-6 h-6"),
                        ],
                        [
                          svg.path([
                            attribute(
                              "d",
                              "M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5",
                            ),
                            attribute("stroke-linejoin", "round"),
                            attribute("stroke-linecap", "round"),
                          ]),
                        ],
                      ),
                      svg.svg(
                        [
                          attribute.id("btn-mobile-menu-close"),
                          attribute("aria-hidden", "true"),
                          attribute("stroke", "currentColor"),
                          attribute("stroke-width", "1.5"),
                          attribute("viewBox", "0 0 24 24"),
                          attribute("fill", "none"),
                          attribute.class("w-6 h-6"),
                        ],
                        [
                          svg.path([
                            attribute("d", "M6 18L18 6M6 6l12 12"),
                            attribute("stroke-linejoin", "round"),
                            attribute("stroke-linecap", "round"),
                          ]),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              html.div(
                [
                  attribute.class(
                    "flex flex-1 justify-center items-center sm:justify-start sm:items-stretch",
                  ),
                ],
                [
                  html.div(
                    [attribute.class("flex flex-shrink-0 items-center")],
                    [
                      html.img([
                        attribute.alt("Lumina Instance"),
                        attribute.src("/logo.svg"),
                        attribute.class(
                          "w-auto h-10 bg-opacity-60 rounded-md border-amber-600 bg-stone-100 dark:bg-stone-100",
                        ),
                      ]),
                    ],
                  ),
                ],
              ),
              html.div(
                [
                  attribute.class(
                    "flex absolute inset-y-0 right-0 items-center pr-2 sm:static sm:inset-auto sm:pr-0 sm:ml-6",
                  ),
                ],
                [
                  html.div([attribute.class("hidden sm:block sm:ml-6")], [
                    html.div([attribute.class("flex space-x-4")], [
                      html.a(
                        [
                          attribute.id("signup-nav"),
                          attribute.class(
                            "py-2 px-3 text-sm font-medium bg-orange-200 rounded-md border-2 border-emerald-600 dark:text-orange-200 dark:bg-yellow-700 hover:text-white hover:bg-gray-700 text-brown-800 dark:border-zinc-400",
                          ),
                          attribute.href("/signup"),
                        ],
                        [html.text("Sign-up")],
                      ),
                      html.a(
                        [
                          attribute("aria-current", "page"),
                          attribute.id("login-nav"),
                          attribute.class(
                            "py-2 px-3 text-sm font-medium text-white bg-gray-900 rounded-md border-2",
                          ),
                          attribute.href("/home"),
                        ],
                        [html.text("Log in")],
                      ),
                    ]),
                  ]),
                ],
              ),
              html.div(
                [
                  attribute.class(
                    "flex absolute inset-y-0 right-0 items-center pr-2 sm:static sm:inset-auto sm:pr-0 sm:ml-6",
                  ),
                ],
                [],
              ),
            ],
          ),
        ]),
        html.div([attribute.id("mobile-menu"), attribute.class("sm:hidden")], [
          html.div([attribute.class("px-2 pt-2 pb-3 space-y-1")], [
            html.a(
              [
                attribute.id("mobile-login-nav"),
                attribute.class(
                  "bg-red-400 dark:bg-red-900 text-white block rounded-md px-3 py-2 text-base font-medium",
                ),
                attribute.href("/home"),
              ],
              [html.text("Log in")],
            ),
            html.a(
              [
                attribute.id("mobile-signup-nav"),
                attribute.class(
                  "block rounded-md px-3 py-2 text-base font-medium bg-orange-200 text-brown-800 dark:text-orange-200 border-emerald-600 dark:bg-yellow-700 dark:border-zinc-400 hover:bg-gray-700 hover:text-white",
                ),
                attribute.href("/signup"),
              ],
              [html.text("Sign up")],
            ),
          ]),
        ]),
      ]),
      html.div(
        [
          attribute.class(
            "grid place-items-center h-screen leading-snug ring-offset-rose-950 text-slate-600 monthclass-month dayclass-day",
          ),
        ],
        [
          html.form(
            [
              attribute.id("loginform"),
              attribute.name("login"),
              attribute.class(
                "self-center w-5/12 ring-offset-rose-950 text-slate-600",
              ),
              attribute.action("javascript:void(0);"),
            ],
            [
              html.div([attribute.class("mb-4")], [
                html.label(
                  [
                    attribute.for("username"),
                    attribute.class(
                      "block mb-2 text-sm font-semibold text-slate-600 dark:text-slate-200",
                    ),
                  ],
                  [html.text("Username or email")],
                ),
                html.input([
                  attribute.type_("text"),
                  attribute.required(True),
                  attribute.placeholder("strawberrygrapes233"),
                  attribute.id("username"),
                  attribute.class(
                    "py-2 px-4 w-full rounded-lg border focus:ring-blue-500 form-input text-slate-600",
                  ),
                ]),
              ]),
              html.div([attribute.class("mb-6")], [
                html.label(
                  [
                    attribute.for("password"),
                    attribute.class(
                      "block mb-2 text-sm font-semibold text-slate-600 dark:text-slate-200",
                    ),
                  ],
                  [
                    html.text(
                      "Password
						",
                    ),
                    html.input([
                      attribute.type_("password"),
                      attribute.required(True),
                      attribute.placeholder(
                        "••••••••••••",
                      ),
                      attribute.id("password"),
                      attribute.class(
                        "py-2 px-4 w-full rounded-lg border focus:ring-blue-500 form-input text-slate-600",
                      ),
                    ]),
                    html.span(
                      [
                        attribute.class(
                          "mt-1 text-xs text-slate-600 dark:text-slate-200",
                        ),
                      ],
                      [
                        html.text(
                          "Forgot password? There's no way we can help you for
							now.
						",
                        ),
                      ],
                    ),
                  ],
                ),
                html.div([attribute.class("form-group")], [
                  html.label([attribute.for("autologin")], [
                    html.input([
                      attribute.type_("checkbox"),
                      attribute.id("autologin"),
                    ]),
                    html.text(" "),
                    html.text("Stay logged in"),
                    html.br([]),
                    html.small([attribute("style", "font-size: 8px")], [
                      html.text("Let cookies do the job for you"),
                    ]),
                  ]),
                ]),
              ]),
              html.button(
                [
                  attribute.type_("submit"),
                  attribute.id("submitbutton"),
                  attribute.class(
                    "grid content-center place-items-center p-4 py-2 px-4 w-full bg-orange-200 rounded-lg border-amber-600 border-opacity-100 ring-rose-300 dark:text-orange-200 dark:bg-yellow-700 focus:ring-2 focus:ring-rose-500 focus:ring-opacity-50 focus:outline-none text-brown-800 dark:hover:bg-sky-900 hover:bg-sky-600",
                  ),
                ],
                [
                  html.text(
                    "Authorize
				",
                  ),
                ],
              ),
              html.p(
                [
                  attribute.class(
                    "mt-4 text-xs text-center text-slate-600 dark:text-slate-200",
                  ),
                ],
                [
                  html.span([attribute.id("Aaa1")], [
                    html.text(
                      "Do you not have an account on this instance yet?
					",
                    ),
                  ]),
                  html.a(
                    [
                      attribute.href("/signup"),
                      attribute.class(
                        "text-blue-500 hover:underline refertohomesite",
                      ),
                    ],
                    [html.text("Sign up")],
                  ),
                  html.text(
                    ".
				",
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ]),
  ])
}

pub fn dash(ctx: Context, _user: users.SafeUser) {
  html.html([attribute("lang", "en")], [
    html.head([], [
      html.title(
        [],
        "Dashboard - Lumina(@" <> ctx.config.lumina_synchronisation_iid <> ")",
      ),
      html.meta([attribute("charset", "UTF-8")]),
      html.style([], style.sheet(ctx)),
      html.script([attribute.type_("module"), attribute.src("/app.js")], ""),
      html.meta([
        attribute("content", "width=device-width, initial-scale=1.0"),
        attribute.name("viewport"),
      ]),
    ]),
    html.body(
      [
        attribute.class(
          "p-0 m-0 w-screen h-screen overflow-clip max-h-[10VH] bg-brown-100 dark:bg-neutral-700",
        ),
      ],
      [
        html.nav(
          [
            attribute.class(
              "rounded-b-lg bg-emerald-200 lg:rounded-b-none dark:bg-teal-800",
            ),
          ],
          [
            html.div(
              [attribute.class("px-2 mx-auto max-w-7xl sm:px-6 lg:px-8")],
              [
                html.div(
                  [
                    attribute.class(
                      "relative flex items-center justify-between h-16",
                    ),
                  ],
                  [
                    html.div(
                      [
                        attribute.class(
                          "absolute inset-y-0 left-0 flex items-center sm:hidden",
                        ),
                      ],
                      [
                        html.button(
                          [
                            attribute.id("btn-mobile-menu"),
                            attribute("aria-expanded", "false"),
                            attribute("aria-controls", "mobile-menu"),
                            attribute.class(
                              "relative inline-flex items-center justify-center p-2 text-gray-400 rounded-md hover:text-white hover:bg-gray-700 focus:ring-2 focus:ring-inset focus:ring-white focus:outline-none",
                            ),
                            attribute.type_("button"),
                          ],
                          [
                            html.span(
                              [attribute.class("absolute -inset-0.5")],
                              [],
                            ),
                            html.span([attribute.class("sr-only")], [
                              html.text("Open main menu"),
                            ]),
                            svg.svg(
                              [
                                attribute.id("btn-mobile-menu-open"),
                                attribute("aria-hidden", "true"),
                                attribute("stroke", "currentColor"),
                                attribute("stroke-width", "1.5"),
                                attribute("viewBox", "0 0 24 24"),
                                attribute("fill", "none"),
                                attribute.class("block w-6 h-6"),
                              ],
                              [
                                svg.path([
                                  attribute(
                                    "d",
                                    "M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5",
                                  ),
                                  attribute("stroke-linejoin", "round"),
                                  attribute("stroke-linecap", "round"),
                                ]),
                              ],
                            ),
                            svg.svg(
                              [
                                attribute.id("btn-mobile-menu-close"),
                                attribute("aria-hidden", "true"),
                                attribute("stroke", "currentColor"),
                                attribute("stroke-width", "1.5"),
                                attribute("viewBox", "0 0 24 24"),
                                attribute("fill", "none"),
                                attribute.class("w-6 h-6"),
                              ],
                              [
                                svg.path([
                                  attribute("d", "M6 18L18 6M6 6l12 12"),
                                  attribute("stroke-linejoin", "round"),
                                  attribute("stroke-linecap", "round"),
                                ]),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    html.div(
                      [
                        attribute.class(
                          "flex items-center justify-center flex-1 sm:justify-start sm:items-stretch",
                        ),
                      ],
                      [
                        html.div(
                          [attribute.class("flex items-center flex-shrink-0")],
                          [
                            html.img([
                              attribute.alt("Lumina Instance"),
                              attribute.src("/logo.svg"),
                              attribute.class(
                                "w-auto h-10 rounded-md bg-opacity-60 border-amber-600 bg-stone-100 dark:bg-stone-100",
                              ),
                            ]),
                          ],
                        ),
                        html.div([attribute.class("hidden sm:block sm:ml-6")], [
                          html.div([attribute.class("flex space-x-4")], [
                            html.a(
                              [
                                attribute.id("home-nav"),
                                attribute("aria-current", "page"),
                                attribute.class(
                                  "px-3 py-2 text-sm font-medium text-white bg-gray-900 border-2 rounded-md",
                                ),
                                attribute.href("javascript:void(0)"),
                              ],
                              [html.text("Home")],
                            ),
                            html.a(
                              [
                                attribute.id("test-nav"),
                                attribute.class(
                                  "px-3 py-2 text-sm font-medium bg-orange-200 border-2 rounded-md border-emerald-600 dark:text-orange-200 dark:bg-yellow-700 hover:text-white hover:bg-gray-700 text-brown-800 dark:border-zinc-400",
                                ),
                                attribute.href("javascript:void(0)"),
                              ],
                              [html.text("Tests for post rendering")],
                            ),
                            html.a(
                              [
                                attribute.id("notifications-nav"),
                                attribute.class(
                                  "px-3 py-2 text-sm font-medium bg-orange-200 border-2 rounded-md border-emerald-600 dark:text-orange-200 dark:bg-yellow-700 hover:text-white hover:bg-gray-700 text-brown-800 dark:border-zinc-400",
                                ),
                                attribute.href("javascript:void(0)"),
                              ],
                              [
                                svg.svg(
                                  [
                                    attribute("viewBox", "0 0 24 24"),
                                    attribute.class("inline w-6 h-6"),
                                    attribute("aria-hidden", "true"),
                                    attribute("stroke-width", "1.5"),
                                    attribute("stroke", "currentColor"),
                                    attribute("fill", "none"),
                                    attribute.id("svg1"),
                                    attribute(
                                      "xmlns",
                                      "http://www.w3.org/2000/svg",
                                    ),
                                  ],
                                  [
                                    svg.path([
                                      attribute(
                                        "d",
                                        "M14.857 17.082a23.848 23.848 0 005.454-1.31A8.967 8.967 0 0118 9.75v-.7V9A6 6 0 006 9v.75a8.967 8.967 0 01-2.312 6.022c1.733.64 3.56 1.085 5.455 1.31m5.714 0a24.255 24.255 0 01-5.714 0m5.714 0a3 3 0 11-5.714 0",
                                      ),
                                      attribute("stroke-linejoin", "round"),
                                      attribute("stroke-linecap", "round"),
                                      attribute.id("path1"),
                                    ]),
                                    svg.ellipse([
                                      attribute("ry", "1.817"),
                                      attribute("rx", "1.919"),
                                      attribute.class("svg_activenotification"),
                                      attribute("cy", "19.078"),
                                      attribute("cx", "16.526"),
                                      attribute.id("path2"),
                                      attribute(
                                        "style",
                                        "
												stroke-opacity: 1;
												stroke-dasharray: none;
												stroke-width: 0.9;
												stroke: #000;
												fill-rule: evenodd;
												fill: red;
											",
                                      ),
                                    ]),
                                  ],
                                ),
                                html.text(" Notifications"),
                              ],
                            ),
                          ]),
                        ]),
                      ],
                    ),
                    html.div(
                      [
                        attribute.class(
                          "absolute inset-y-0 right-0 flex items-center pr-2 sm:static sm:inset-auto sm:pr-0 sm:ml-6",
                        ),
                      ],
                      [
                        html.button(
                          [
                            attribute.id("switchpageNotificationsTrigger"),
                            attribute.class(
                              "relative p-1 text-gray-400 bg-red-400 rounded-full lg:hidden dark:bg-red-900 hover:text-white focus:ring-2 focus:ring-white focus:ring-offset-2 focus:ring-offset-gray-800 focus:outline-none",
                            ),
                            attribute.type_("button"),
                          ],
                          [
                            html.span(
                              [attribute.class("absolute -inset-1.5")],
                              [],
                            ),
                            html.span([attribute.class("sr-only")], [
                              html.text("View notifications"),
                            ]),
                            svg.svg(
                              [
                                attribute("viewBox", "0 0 24 24"),
                                attribute.class("inline w-6 h-6"),
                                attribute("aria-hidden", "true"),
                                attribute("stroke-width", "1.5"),
                                attribute("stroke", "currentColor"),
                                attribute("fill", "none"),
                                attribute.id("svg1"),
                                attribute("xmlns", "http://www.w3.org/2000/svg"),
                              ],
                              [
                                svg.path([
                                  attribute(
                                    "d",
                                    "M14.857 17.082a23.848 23.848 0 005.454-1.31A8.967 8.967 0 0118 9.75v-.7V9A6 6 0 006 9v.75a8.967 8.967 0 01-2.312 6.022c1.733.64 3.56 1.085 5.455 1.31m5.714 0a24.255 24.255 0 01-5.714 0m5.714 0a3 3 0 11-5.714 0",
                                  ),
                                  attribute("stroke-linejoin", "round"),
                                  attribute("stroke-linecap", "round"),
                                  attribute.id("path1"),
                                ]),
                                svg.ellipse([
                                  attribute("ry", "1.817"),
                                  attribute("rx", "1.919"),
                                  attribute.class("svg_activenotification"),
                                  attribute("cy", "19.078"),
                                  attribute("cx", "16.526"),
                                  attribute.id("path2"),
                                  attribute(
                                    "style",
                                    "
										stroke-opacity: 1;
										stroke-dasharray: none;
										stroke-width: 0.9;
										stroke: #000;
										fill-rule: evenodd;
										fill: red;
									",
                                  ),
                                ]),
                              ],
                            ),
                          ],
                        ),
                        html.div([attribute.class("relative ml-3")], [
                          html.div([], [
                            html.button(
                              [
                                attribute("aria-haspopup", "true"),
                                attribute("aria-expanded", "false"),
                                attribute.id("user-menu-button"),
                                attribute.class(
                                  "relative flex text-sm bg-red-400 rounded-full dark:bg-red-900 focus:ring-2 focus:ring-white focus:ring-offset-2 focus:ring-offset-gray-800 focus:outline-none",
                                ),
                                attribute.type_("button"),
                              ],
                              [
                                html.span(
                                  [attribute.class("absolute -inset-1.5")],
                                  [],
                                ),
                                html.span([attribute.class("sr-only")], [
                                  html.text("Open user menu"),
                                ]),
                                html.img([
                                  attribute.alt(""),
                                  attribute.id("userimg"),
                                  attribute.src(""),
                                  attribute.class(
                                    "w-8 h-8 rounded-full ownuseravatarsrc",
                                  ),
                                ]),
                              ],
                            ),
                          ]),
                          html.div(
                            [
                              attribute("tabindex", "-1"),
                              attribute.id("user-menu"),
                              attribute("aria-labelledby", "user-menu-button"),
                              attribute("aria-orientation", "vertical"),
                              attribute.role("menu"),
                              attribute.class(
                                "absolute right-0 z-10 w-48 py-1 mt-2 origin-top-right bg-white rounded-md shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none",
                              ),
                            ],
                            [
                              html.div(
                                [
                                  attribute.class(
                                    "block px-4 py-2 text-sm text-gray-700",
                                  ),
                                ],
                                [
                                  html.text(
                                    "Hi,
									",
                                  ),
                                  html.span(
                                    [
                                      attribute(
                                        "style",
                                        "
											overflow: hidden;
											white-space: nowrap;
										",
                                      ),
                                      attribute.class(
                                        "p-1 text-sm italic bg-orange-700 rounded-md bg-opacity-20 settodisplayname",
                                      ),
                                    ],
                                    [html.text("unset")],
                                  ),
                                ],
                              ),
                              html.hr([]),
                              html.a(
                                [
                                  attribute.id("user-menu-item-0"),
                                  attribute("tabindex", "-1"),
                                  attribute.role("menuitem"),
                                  attribute.class(
                                    "block px-4 py-2 text-sm text-gray-700",
                                  ),
                                  attribute.href("javascript:void(0)"),
                                ],
                                [html.text("User settings")],
                              ),
                              html.a(
                                [
                                  attribute.id("user-menu-item-1"),
                                  attribute("tabindex", "-1"),
                                  attribute.role("menuitem"),
                                  attribute.class(
                                    "block px-4 py-2 text-sm text-gray-700",
                                  ),
                                  attribute.href("javascript:void(0)"),
                                ],
                                [html.text("Contact instance support")],
                              ),
                              html.a(
                                [
                                  attribute.id("user-menu-item-2"),
                                  attribute("tabindex", "-1"),
                                  attribute.role("menuitem"),
                                  attribute.class(
                                    "block px-4 py-2 text-sm text-gray-700 cursor-pointer logoutbutton",
                                  ),
                                ],
                                [html.text("Sign out")],
                              ),
                            ],
                          ),
                        ]),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            html.div(
              [attribute.id("mobile-menu"), attribute.class("z-50 sm:hidden")],
              [
                html.div([attribute.class("px-2 pt-2 pb-4 space-y-1")], [
                  html.a(
                    [
                      attribute.id("mobile-home-nav"),
                      attribute("aria-current", "page"),
                      attribute.class(""),
                      attribute.href("javascript:void(0)"),
                    ],
                    [html.text("Home")],
                  ),
                  html.a(
                    [
                      attribute.id("mobile-test-nav"),
                      attribute.class(""),
                      attribute.href("javascript:void(0)"),
                    ],
                    [html.text("Tests for post rendering")],
                  ),
                  html.a(
                    [
                      attribute.id("mobile-notifications-nav"),
                      attribute("style", "display: none"),
                      attribute.class("hidden"),
                      attribute.href("javascript:void(0)"),
                    ],
                    [],
                  ),
                ]),
              ],
            ),
          ],
        ),
        html.main(
          [
            attribute.class(
              "monthclass-month dayclass-day w-screen h-screen text-fuchsia-900 lg:grid lg:grid-cols-5 lg:grid-flow-col dark:text-violet-200 not:max-h-[89VH] overflow-clip",
            ),
          ],
          [
            html.div(
              [
                attribute.class(
                  "hidden h-full lg:block bg-brown-200 overflow-clip dark:bg-neutral-600",
                ),
                attribute.id("mainleft"),
              ],
              [],
            ),
            html.div(
              [
                attribute.class(
                  "h-full col-span-4 overflow-auto contentkeeper no:lg:p-12 bg-brown-100 dark:bg-neutral-700",
                ),
              ],
              [
                html.div(
                  [
                    attribute.class(
                      "w-full p-4 rounded-md lg:p-8 lg:w-11/12 bg-brown-200 dark:bg-neutral-600 disabled:lg:h-10/12 lg:m-12",
                    ),
                    attribute.id("mainright"),
                  ],
                  [],
                ),
              ],
            ),
            html.div(
              [
                attribute.id("editorTrigger"),
                attribute.class(
                  "fixed flex items-center justify-center w-12 h-12 p-0 text-sm bg-red-400 rounded-full shadow-2xl cursor-pointer bottom-3 lg:bottom-6 right-3 dark:bg-red-900 lg:w-20 lg:h-20 z-[70]",
                ),
              ],
              [
                svg.svg(
                  [
                    attribute("xmlns", "http://www.w3.org/2000/svg"),
                    attribute("xml:space", "preserve"),
                    attribute("viewBox", "0 0 120 120"),
                    attribute("version", "1.1"),
                    attribute("height", "120"),
                    attribute("width", "120"),
                  ],
                  [
                    svg.g(
                      [
                        attribute("stroke-width", "1.5"),
                        attribute("stroke", "#1c274c"),
                        attribute("fill", "none"),
                        attribute("display", "none"),
                        attribute(
                          "transform",
                          "matrix(3.0862 0 0 3.0862 24.842 20.186)",
                        ),
                      ],
                      [
                        svg.path([
                          attribute(
                            "d",
                            "m15.287 3.1518-0.9268 0.92688-8.5213 8.5212h-1e-5c-0.57715 0.5772-0.86573 0.8657-1.1139 1.1839-0.29277 0.3754-0.54376 0.7815-0.74856 1.2112-0.17361 0.3643-0.30266 0.7515-0.56078 1.5258l-1.3611 4.0834c-0.12702 0.381-0.02785 0.8011 0.25618 1.0852 0.28403 0.284 0.70415 0.3832 1.0852 0.2562l0.80208-0.2674 3.2813-1.0938h1e-5c0.77434-0.2581 1.1615-0.3871 1.5258-0.5607 0.42971-0.2048 0.83584-0.4558 1.2112-0.7486 0.3182-0.2482 0.6067-0.5368 1.1839-1.1139l8.5212-8.5213 0.9269-0.92687c1.5357-1.5357 1.5357-4.0256 0-5.5613-1.5357-1.5357-4.0256-1.5357-5.5613 0z",
                          ),
                        ]),
                        svg.path([
                          attribute("opacity", ".5"),
                          attribute(
                            "d",
                            "m14.36 4.0781s0.1159 1.9696 1.8538 3.7075 3.7075 1.8538 3.7075 1.8538m-15.723 12.038-1.8761-1.8762",
                          ),
                        ]),
                      ],
                    ),
                    svg.g(
                      [
                        attribute("stroke-linejoin", "round"),
                        attribute("stroke-linecap", "round"),
                      ],
                      [
                        svg.ellipse([
                          attribute("stroke-width", "2.8898"),
                          attribute("stroke", "currentColor"),
                          attribute("opacity", ".854"),
                          attribute("fill-opacity", ".098814"),
                          attribute("ry", "53.18"),
                          attribute("rx", "53.378"),
                          attribute("cy", "59.218"),
                          attribute("cx", "60.481"),
                        ]),
                        svg.g([attribute("stroke", "currentColor")], [
                          svg.path([
                            attribute("stroke-width", "2.7789"),
                            attribute(
                              "d",
                              "m23.999 84.377 8.5638-61.703 49.155 38.268z",
                            ),
                            attribute(
                              "transform",
                              "matrix(.18738 .032737 -.032737 .18738 32.779 64.063)",
                            ),
                          ]),
                          svg.path([
                            attribute("stroke-width", "2.7789"),
                            attribute(
                              "d",
                              "m24.951 75.234c-2.5778-3.0222-0.16522-33.42 2.857-35.998 3.0222-2.5778 33.42-0.16522 35.998 2.857 2.5778 3.0222 0.16522 33.42-2.857 35.998s-33.42 0.16522-35.998-2.857z",
                            ),
                            attribute(
                              "transform",
                              "matrix(.43357 .44112 -.79833 .78466 94.362 -13.574)",
                            ),
                          ]),
                          svg.path([
                            attribute("stroke-width", "2.2881"),
                            attribute("d", "m44.869 57.785-6.2376 12.805"),
                          ]),
                          svg.path([
                            attribute("stroke-width", "2.2881"),
                            attribute("d", "m44.009 77.824 13.937-2.9366"),
                          ]),
                        ]),
                      ],
                    ),
                    svg.ellipse([
                      attribute("stroke-width", "2.7789"),
                      attribute("stroke-linejoin", "round"),
                      attribute("stroke-linecap", "round"),
                      attribute("stroke", "currentColor"),
                      attribute("opacity", ".85"),
                      attribute("ry", "10.761"),
                      attribute("rx", "5.2378"),
                      attribute("cy", "77.102"),
                      attribute("cx", "46.958"),
                      attribute("transform", "rotate(-33.998)"),
                    ]),
                  ],
                ),
              ],
            ),
          ],
        ),
        html.div(
          [
            attribute.class(
              "fixed inset-y-0 z-10 block w-12 h-12 p-1 mt-auto mb-auto text-sm bg-red-400 rounded-full left-1 lg:hidden dark:bg-red-900 focus:ring-2 focus:ring-white focus:ring-offset-2 focus:ring-offset-gray-800 focus:outline-none",
            ),
            attribute.id("mobiletimelineswitcher"),
          ],
          [
            html.button([], [
              svg.svg(
                [
                  attribute("xmlns", "http://www.w3.org/2000/svg"),
                  attribute("viewBox", "0 0 50 50"),
                  attribute("stroke-miterlimit", "10"),
                  attribute("stroke-linecap", "square"),
                  attribute("stroke", "none"),
                  attribute("fill", "none"),
                  attribute("height", "50"),
                  attribute("width", "50"),
                  attribute.id("arrowright"),
                  attribute.class("w-10 h-10"),
                ],
                [
                  svg.defs([attribute.id("defs20")], [
                    svg.clip_path([], [
                      svg.path([
                        attribute("clip-rule", "nonzero"),
                        attribute("d", "M 0,0 H 960 V 720 H 0 Z"),
                      ]),
                    ]),
                    svg.clip_path([attribute.id("p.0-1-4")], [
                      svg.path([
                        attribute("clip-rule", "nonzero"),
                        attribute("d", "M 0,0 H 960 V 720 H 0 Z"),
                        attribute.id("path1-2-0"),
                      ]),
                    ]),
                  ]),
                  svg.clip_path([attribute.id("p.0")], [
                    svg.path([
                      attribute("clip-rule", "nonzero"),
                      attribute("d", "M 0,0 H 960 V 720 H 0 Z"),
                      attribute.id("path1"),
                    ]),
                  ]),
                  svg.path([
                    attribute(
                      "d",
                      "m 30.152807,9.1863138 a 7.7145349,0.13753011 41.944235 0 0 5.615234,5.2304682 7.7145349,0.13753011 41.944235 0 0 5.859375,5.082031 7.7145349,0.13753011 41.944235 0 0 -5.613281,-5.230468 7.7145349,0.13753011 41.944235 0 0 -5.861328,-5.0820312 z M 45.035619,22.438267 a 0.42024437,0.94349396 0 0 0 -0.419922,0.943359 0.42024437,0.94349396 0 0 0 0.419922,0.945313 0.42024437,0.94349396 0 0 0 0.419922,-0.945313 0.42024437,0.94349396 0 0 0 -0.419922,-0.943359 z M 18.87351,23.049595 A 14.878937,0.26167485 0 0 0 3.9946033,23.311313 14.878937,0.26167485 0 0 0 18.87351,23.573032 14.878937,0.26167485 0 0 0 33.752416,23.311313 14.878937,0.26167485 0 0 0 18.87351,23.049595 Z m 22.796875,4.263672 a 0.13753011,7.7145349 48.055765 0 0 -5.859375,5.082031 0.13753011,7.7145349 48.055765 0 0 -5.615234,5.230469 0.13753011,7.7145349 48.055765 0 0 5.859374,-5.082032 0.13753011,7.7145349 48.055765 0 0 5.615235,-5.230468 z",
                    ),
                    attribute(
                      "style",
                      "
							fill: currentColor;
							fill-opacity: 1;
							stroke: currentColor;
							stroke-width: 2.848;
							stroke-linecap: round;
							stroke-linejoin: round;
							stroke-dasharray: none;
							paint-order: fill markers stroke;
						",
                    ),
                  ]),
                ],
              ),
            ]),
          ],
        ),
        html.div(
          [
            attribute("style", "backdrop-filter: blur(8px)"),
            attribute.id("posteditor"),
            attribute.class(
              "fixed w-screen md:w-[85VH] lg:w-[70VH] h-[70VH] top-[15VH] bottom-[15VH] right-0 left-0 lg:right-[calc(50VW-30VH)] lg:left-[calc(50VW-30VH)] z-[60] resize backdrop-blur-sm",
            ),
          ],
          [
            html.p(
              [
                attribute.class(
                  "w-full h-full text-black bg-white dark:text-white dark:bg-black",
                ),
              ],
              [
                html.text(
                  "Failed to load post editor.
			",
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ])
}

pub fn signup(ctx: context.Context) {
  html.html([attribute("lang", "en")], [
    html.head([], [
      html.title(
        [],
        "Sign up - Lumina(@" <> ctx.config.lumina_synchronisation_iid <> ")",
      ),
      html.meta([attribute("charset", "UTF-8")]),
      html.style([], style.sheet(ctx)),
      html.link([
        attribute.type_("image/png"),
        attribute.rel("icon"),
        attribute.href("/logo.png"),
      ]),
      html.script([attribute.type_("module"), attribute.src("/app.js")], ""),
      html.meta([
        attribute("content", "width=device-width, initial-scale=1.0"),
        attribute.name("viewport"),
      ]),
    ]),
    html.body([attribute.class("bg-brown-100 dark:bg-neutral-500")], [
      html.nav([attribute.class("bg-emerald-200 dark:bg-teal-800")], [
        html.div([attribute.class("px-2 mx-auto max-w-7xl sm:px-6 lg:px-8")], [
          html.div(
            [attribute.class("flex relative justify-between items-center h-16")],
            [
              html.div(
                [
                  attribute.class(
                    "flex absolute inset-y-0 left-0 items-center sm:hidden",
                  ),
                ],
                [
                  html.button(
                    [
                      attribute.id("btn-mobile-menu"),
                      attribute("aria-expanded", "false"),
                      attribute("aria-controls", "mobile-menu"),
                      attribute.class(
                        "inline-flex relative justify-center items-center p-2 text-gray-400 rounded-md hover:text-white hover:bg-gray-700 focus:ring-2 focus:ring-inset focus:ring-white focus:outline-none",
                      ),
                      attribute.type_("button"),
                    ],
                    [
                      html.span([attribute.class("absolute -inset-0.5")], []),
                      html.span([attribute.class("sr-only")], [
                        html.text("Open main menu"),
                      ]),
                      svg.svg(
                        [
                          attribute.id("btn-mobile-menu-open"),
                          attribute("aria-hidden", "true"),
                          attribute("stroke", "currentColor"),
                          attribute("stroke-width", "1.5"),
                          attribute("viewBox", "0 0 24 24"),
                          attribute("fill", "none"),
                          attribute.class("block w-6 h-6"),
                        ],
                        [
                          svg.path([
                            attribute(
                              "d",
                              "M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5",
                            ),
                            attribute("stroke-linejoin", "round"),
                            attribute("stroke-linecap", "round"),
                          ]),
                        ],
                      ),
                      svg.svg(
                        [
                          attribute.id("btn-mobile-menu-close"),
                          attribute("aria-hidden", "true"),
                          attribute("stroke", "currentColor"),
                          attribute("stroke-width", "1.5"),
                          attribute("viewBox", "0 0 24 24"),
                          attribute("fill", "none"),
                          attribute.class("w-6 h-6"),
                        ],
                        [
                          svg.path([
                            attribute("d", "M6 18L18 6M6 6l12 12"),
                            attribute("stroke-linejoin", "round"),
                            attribute("stroke-linecap", "round"),
                          ]),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              html.div(
                [
                  attribute.class(
                    "flex flex-1 justify-center items-center sm:justify-start sm:items-stretch",
                  ),
                ],
                [
                  html.div(
                    [attribute.class("flex flex-shrink-0 items-center")],
                    [
                      html.img([
                        attribute.alt("Lumina Instance"),
                        attribute.src("/logo.svg"),
                        attribute.class(
                          "w-auto h-10 bg-opacity-60 rounded-md border-amber-600 bg-stone-100 dark:bg-stone-100",
                        ),
                      ]),
                    ],
                  ),
                ],
              ),
              html.div(
                [
                  attribute.class(
                    "flex absolute inset-y-0 right-0 items-center pr-2 sm:static sm:inset-auto sm:pr-0 sm:ml-6",
                  ),
                ],
                [
                  html.div([attribute.class("hidden sm:block sm:ml-6")], [
                    html.div([attribute.class("flex space-x-4")], [
                      html.a(
                        [
                          attribute.id("signup-nav"),
                          attribute("aria-current", "page"),
                          attribute.class(
                            "py-2 px-3 text-sm font-medium text-white bg-gray-900 rounded-md border-2",
                          ),
                          attribute.href("/signup"),
                        ],
                        [html.text("Sign-up")],
                      ),
                      html.a(
                        [
                          attribute.id("login-nav"),
                          attribute.class(
                            "py-2 px-3 text-sm font-medium bg-orange-200 rounded-md border-2 border-emerald-600 dark:text-orange-200 dark:bg-yellow-700 hover:text-white hover:bg-gray-700 text-brown-800 dark:border-zinc-400",
                          ),
                          attribute.href("/home"),
                        ],
                        [html.text("Log in")],
                      ),
                    ]),
                  ]),
                ],
              ),
              html.div(
                [
                  attribute.class(
                    "flex absolute inset-y-0 right-0 items-center pr-2 sm:static sm:inset-auto sm:pr-0 sm:ml-6",
                  ),
                ],
                [],
              ),
            ],
          ),
        ]),
        html.div([attribute.id("mobile-menu"), attribute.class("sm:hidden")], [
          html.div([attribute.class("px-2 pt-2 pb-3 space-y-1")], [
            html.a(
              [
                attribute.id("mobile-login-nav"),
                attribute.class(
                  "block rounded-md px-3 py-2 text-base font-medium bg-orange-200 text-brown-800 dark:text-orange-200 border-emerald-600 dark:bg-yellow-700 dark:border-zinc-400 hover:bg-gray-700 hover:text-white",
                ),
                attribute.href("/home"),
              ],
              [html.text("Log in")],
            ),
            html.a(
              [
                attribute.id("mobile-signup-nav"),
                attribute.class(
                  "bg-red-400 dark:bg-red-900 text-white block rounded-md px-3 py-2 text-base font-medium",
                ),
                attribute.href("/signup"),
              ],
              [html.text("Sign up")],
            ),
          ]),
        ]),
      ]),
      html.div(
        [
          attribute.class(
            "grid place-items-center h-screen leading-snug ring-offset-rose-950 text-slate-600 monthclass-month dayclass-day",
          ),
        ],
        [
          html.form(
            [
              attribute.id("registrationform"),
              attribute.name("signup"),
              attribute.class(
                "self-center w-5/12 ring-offset-rose-950 text-slate-600",
              ),
              attribute.action("javascript:void(0);"),
            ],
            [
              html.div([attribute.class("mb-4")], [
                html.label(
                  [
                    attribute.for("username"),
                    attribute.class(
                      "block mb-2 text-sm font-semibold text-slate-600 dark:text-slate-200",
                    ),
                    attribute.id("usernameLabel"),
                  ],
                  [html.text("Username")],
                ),
                html.input([
                  attribute.type_("text"),
                  attribute.required(True),
                  attribute.placeholder("strawberrygrapes233"),
                  attribute.id("username"),
                  attribute.class(
                    "py-2 px-4 w-full rounded-lg border focus:ring-blue-500 form-input text-slate-600",
                  ),
                ]),
              ]),
              html.div([attribute.class("mb-4")], [
                html.label(
                  [
                    attribute.for("email"),
                    attribute.class(
                      "block mb-2 text-sm font-semibold text-slate-600 dark:text-slate-200",
                    ),
                  ],
                  [html.text("Email")],
                ),
                html.input([
                  attribute.type_("email"),
                  attribute.required(True),
                  attribute.placeholder("strawberrygrapes233@example.com"),
                  attribute.id("email"),
                  attribute.class(
                    "py-2 px-4 w-full rounded-lg border focus:ring-blue-500 form-input text-slate-600",
                  ),
                ]),
                html.small([attribute("style", "font-size: 8px")], [
                  html.text(
                    "This email may be the only way to get back in to your
						account if you're locked out!",
                  ),
                ]),
              ]),
              html.div([attribute.class("mb-6")], [
                html.label(
                  [
                    attribute.for("password"),
                    attribute.class(
                      "block mb-2 text-sm font-semibold text-slate-600 dark:text-slate-200",
                    ),
                  ],
                  [html.text("Password")],
                ),
                html.input([
                  attribute.type_("password"),
                  attribute.required(True),
                  attribute.placeholder("••••••••••••"),
                  attribute.id("password"),
                  attribute.class(
                    "py-2 px-4 w-full rounded-lg border focus:ring-blue-500 form-input text-slate-600",
                  ),
                ]),
                html.label(
                  [
                    attribute.for("password2"),
                    attribute.class(
                      "block mb-2 text-sm font-semibold text-slate-600 dark:text-slate-200",
                    ),
                  ],
                  [html.text("Repeat password")],
                ),
                html.input([
                  attribute.type_("password"),
                  attribute.required(True),
                  attribute.placeholder("••••••••••••"),
                  attribute.id("password2"),
                  attribute.class(
                    "py-2 px-4 w-full rounded-lg border focus:ring-blue-500 form-input text-slate-600",
                  ),
                ]),
              ]),
              html.button(
                [
                  attribute.type_("submit"),
                  attribute.id("submitbutton"),
                  attribute.class(
                    "grid content-center place-items-center p-4 py-2 px-4 w-full bg-orange-200 rounded-lg border-amber-600 border-opacity-100 ring-rose-300 dark:text-orange-200 dark:bg-yellow-700 focus:ring-2 focus:ring-rose-500 focus:ring-opacity-50 focus:outline-none text-brown-800 dark:hover:bg-sky-900 hover:bg-sky-600",
                  ),
                ],
                [
                  html.text(
                    "Register
				",
                  ),
                ],
              ),
              html.p(
                [
                  attribute.class(
                    "mt-4 text-xs text-center text-slate-600 dark:text-slate-200",
                  ),
                ],
                [
                  html.span([attribute.id("Aaa1")], [
                    html.text("Do you already have an account? "),
                  ]),
                  html.a(
                    [
                      attribute.href("/login"),
                      attribute.class(
                        "text-blue-500 hover:underline refertohomesite",
                      ),
                    ],
                    [html.text("Log in")],
                  ),
                  html.text(
                    ".
				",
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ]),
  ])
}

pub fn editor(_ctx: Context) {
  html.div(
    [
      attribute.class(
        "relative w-full h-full border-2 rounded-lg bg-emerald-200 bg-opacity-60 dark:bg-teal-800 overflow-clip border-fuchsia-900 dark:border-violet-200",
      ),
      attribute.id("editorwindow"),
    ],
    [
      html.div(
        [
          attribute.class(
            "absolute top-0 w-full h-12 bg-teal-800 dark:bg-emerald-200 cursor-move md:h-[2cm]",
          ),
          attribute.id("editorwindowh"),
        ],
        [
          html.header(
            [
              attribute.class(
                "absolute top-0 flex items-center justify-center w-full text-orange-100 special h-1/2 dark:text-neutral-800",
              ),
            ],
            [
              html.text(
                "Post editor
		",
              ),
            ],
          ),
          html.nav(
            [
              attribute.class(
                "absolute h-1/2 bottom-0 grid grid-flow-col justify-stretch w-[calc(90%-2.25rem)] lg:w-[calc(90%-1cm)] pl-1",
              ),
              attribute.id("editormodepicker"),
            ],
            [
              html.div(
                [
                  attribute("data-mode-opener", "short"),
                  attribute.class(
                    "editor-switcher flex items-center justify-center p-0 bg-orange-100 border-2 border-b-0 rounded-md rounded-b-none cursor-default border-emerald-600 dark:text-orange-100 dark:bg-neutral-800 text-brown-800 dark:border-zinc-400",
                  ),
                ],
                [
                  html.text(
                    "Text post mode
			",
                  ),
                ],
              ),
              html.div(
                [
                  attribute("data-mode-opener", "long"),
                  attribute.class(
                    "editor-switcher flex items-center justify-center p-0 border-2 rounded-md cursor-pointer bg-emerald-200 dark:bg-teal-800 border-emerald-600 dark:text-orange-100 hover:text-white hover:bg-gray-700 text-brown-800 dark:border-zinc-400",
                  ),
                ],
                [
                  html.text(
                    "Article mode
			",
                  ),
                ],
              ),
              html.div(
                [
                  attribute("data-mode-opener", "embed"),
                  attribute.class(
                    "editor-switcher flex items-center justify-center p-0 border-2 rounded-md cursor-pointer bg-emerald-200 dark:bg-teal-800 border-emerald-600 dark:text-orange-100 hover:text-white hover:bg-gray-700 text-brown-800 dark:border-zinc-400",
                  ),
                ],
                [
                  html.text(
                    "Embed mode
			",
                  ),
                ],
              ),
            ],
          ),
          html.div(
            [
              attribute.class(
                "absolute top-0.5 right-0.5 w-9 h-9 lg:top-1 lg:right-1 lg:h-[1cm] lg:w-[1cm] flex justify-center items-center",
              ),
            ],
            [
              html.button(
                [
                  attribute.id("bttn_closeeditor"),
                  attribute.class(
                    "flex items-center justify-center w-full h-full text-3xl text-center text-white bg-red-600 rounded-full hover:text-black hover:bg-red-400",
                  ),
                ],
                [
                  html.text(
                    "×
			",
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      html.div(
        [
          attribute.class(
            "top-12 h-[calc(100%-2.5rem)] md:top-[2cm] absolute w-full md:h-[calc(100%-2cm)] bg-orange-100 dark:bg-neutral-800 dark:text-orange-100 text-brown-800",
          ),
          attribute.id("editorwindowm"),
        ],
        [
          html.div(
            [
              attribute.class("block h-[inherit] w-[inherit]"),
              attribute("data-mode-field", "short"),
            ],
            [
              html.label([attribute.for("editor-short-input")], [
                html.text("Mode: Post"),
              ]),
              html.div(
                [
                  attribute.class(
                    "w-11/12 ml-auto mr-auto text-black lg:w-9/12 min-h-10 h-14 editor-container bg-slate-50 dark:bg-slate-600 dark:text-slate-100 outline-cyan-50 focus-within:outline-cyan-100 outline-2",
                  ),
                  attribute.id("editor-short-container"),
                  attribute("title", "Enter text here!"),
                  attribute("tabindex", "1"),
                ],
                [
                  html.div(
                    [
                      attribute.class(
                        "w-full h-full p-0 overflow-auto leading-[3.5rem] whitespace-pre-wrap",
                      ),
                      attribute.id("editor-short-preview"),
                    ],
                    [],
                  ),
                  html.input([
                    attribute.value("Enter markdown like *italic* or **bold**"),
                    attribute.class(
                      "hidden w-full h-full p-1 overflow-auto overflow-x-auto leading-3 resize-none font-inherit text-black",
                    ),
                    attribute.id("editor-short-input"),
                    attribute.type_("text"),
                  ]),
                ],
              ),
              html.details([], [
                html.summary([], [
                  html.text("The post editor supports "),
                  html.em([], [html.text("simple MarkDown")]),
                ]),
                html.blockquote(
                  [
                    attribute.class(
                      "p-0 [&>*]:pl-2 ml-3 mr-3 border-gray-300 border-s-4 bg-gray-50 dark:border-gray-500 dark:bg-gray-800",
                    ),
                  ],
                  [
                    html.ul([], [
                      html.li([], [html.text("Use * or _ to make text italic")]),
                      html.li([], [html.text("Use ** to make text bold")]),
                      html.li([], [html.text("Use ` to use a code block")]),
                    ]),
                    html.p([], [
                      html.text(
                        "The article editor supports more advanced MarkDown.",
                      ),
                    ]),
                  ],
                ),
              ]),
            ],
          ),
          html.div(
            [
              attribute.class("hidden h-[inherit] w-[inherit]"),
              attribute("data-mode-field", "long"),
            ],
            [
              html.label([attribute.for("editor-long-input")], [
                html.text("Mode: Article"),
              ]),
              html.button(
                [
                  attribute("onclick", "document.activeElement.blur()"),
                  attribute.class(
                    "absolute px-3 py-2 text-sm font-medium bg-orange-200 border-2 rounded-md top-1 right-1 border-emerald-600 dark:text-orange-200 dark:bg-yellow-700 hover:text-white hover:bg-gray-700 text-brown-800 dark:border-zinc-400 outline-cyan-50 focus-within:outline-cyan-100 outline-2",
                  ),
                ],
                [
                  html.text(
                    "Preview
			",
                  ),
                ],
              ),
              html.div(
                [
                  attribute.class(
                    "w-11/12 h-full ml-auto mr-auto text-black leading-2 lg:w-9/12 editor-container bg-slate-50 dark:bg-slate-600 dark:text-slate-100",
                  ),
                  attribute.id("editor-long-container"),
                  attribute("title", "Enter text here!"),
                  attribute("tabindex", "1"),
                ],
                [
                  html.div(
                    [
                      attribute.class(
                        "w-full h-full p-1 overflow-auto whitespace-pre-wrap leading-2",
                      ),
                      attribute.id("editor-long-preview"),
                    ],
                    [],
                  ),
                  html.textarea(
                    [
                      attribute.placeholder(
                        "Enter markdown like _italic_ or *bold*!",
                      ),
                      attribute.class(
                        "hidden w-full h-full p-1 overflow-auto overflow-x-auto resize-none bg-inherit text-inherit font-inherit",
                      ),
                      attribute.rows(10),
                      attribute.cols(30),
                      attribute.id("editor-long-input"),
                      attribute.name(""),
                    ],
                    "",
                  ),
                ],
              ),
              html.p([], [
                html.text(
                  "The article editor supports
				",
                ),
                html.a(
                  [
                    attribute.class("text-blue-300 dark:text-blue-200"),
                    attribute.target("_blank"),
                    attribute.href("https://github.github.com/gfm/"),
                  ],
                  [html.text("GitHub-flavoured MarkDown")],
                ),
                html.text(
                  ". See the
				",
                ),
                html.a(
                  [
                    attribute.class("text-blue-300 dark:text-blue-200"),
                    attribute.target("_blank"),
                    attribute.href(
                      "https://gist.github.com/roshith-balendran/d50b32f8f7d900c34a7dc00766bcfb9c",
                    ),
                  ],
                  [html.text("cheatsheet")],
                ),
                html.text(
                  "for help.
			",
                ),
              ]),
            ],
          ),
          html.div(
            [
              attribute.class("hidden h-[inherit]"),
              attribute("data-mode-field", "embed"),
            ],
            [
              html.text(
                "Mode: Embed
		",
              ),
            ],
          ),
        ],
      ),
    ],
  )
}
