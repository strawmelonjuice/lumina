import gleam/bool
import gleam/dict
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/time/calendar
import gleam/time/timestamp
import lumina_client/dom
import lumina_client/message_type.{type Msg, CloseModal, Logout, SetModal}
import lumina_client/model_type.{type CachedTimeline, type Model, CachedTimeline}
import lumina_client/view/common_view_parts.{common_view_parts}
import lustre/attribute.{attribute}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

fn closemodal_not_for_modal_box() {
  use target <- decode.field("target", decode.dynamic)
  case bool.negate(dom.classfoundintree(target, "modal-box")) {
    True -> decode.success(CloseModal)
    False -> decode.failure(CloseModal, "Clicked inside modal-box, ignoring")
  }
}

pub fn view(model: model_type.Model) {
  // Dissect the model
  let assert model_type.Model(
    page: model_type.HomeTimeline(timeline_name:, modal:),
    user:,
    ws: _,
    token: _,
    status: _,
    cache: _,
    ticks: _,
  ) = model

  let timeline_name = option.unwrap(timeline_name, "global")
  let modal_element = case
    modal |> option.map(modal_by_id(_, model)) |> option.unwrap(NoModal)
  {
    CentralBig(mod) ->
      html.div(
        [
          attribute.class(
            "modal modal-open fixed inset-0 flex items-center justify-center z-50 bg-black bg-opacity-50 w-screen h-screen",
          ),
          event.on("click", closemodal_not_for_modal_box()),
        ],
        [
          html.div(
            [
              attribute.class(
                "modal-box w-[80vw] max-w-[unset] h-[80vh] flex flex-col justify-center items-center bg-base-100 shadow-2xl relative",
              ),
            ],
            [
              html.button(
                [
                  attribute.class(
                    "btn btn-circle btn-primary absolute top-4 right-4 text-2xl",
                  ),

                  event.on_click(CloseModal),
                ],
                [
                  element.text(
                    // &times;
                    "×",
                  ),
                ],
              ),
              mod,
              html.div([attribute.class("modal-action")], []),
            ],
          ),
        ],
      )
    CentralSmall(mod) ->
      html.div(
        [
          attribute.class(
            "modal modal-open fixed inset-0 flex items-center justify-center z-50 bg-black bg-opacity-50 w-screen h-screen",
          ),
          event.on("click", closemodal_not_for_modal_box()),
        ],
        [
          html.div(
            [
              attribute.class(
                "modal-box w-[32rem] max-w-[90vw] h-[32rem] max-h-[90vh] flex flex-col justify-center items-center bg-base-100 shadow-2xl relative",
              ),
            ],
            [
              html.button(
                [
                  attribute.class(
                    "btn btn-circle btn-primary absolute top-4 right-4 text-2xl",
                  ),
                  event.on_click(CloseModal),
                ],
                [element.text("×")],
              ),
              mod,
              html.div([attribute.class("modal-action")], []),
            ],
          ),
        ],
      )
    SideOrCentral(Right, mod) ->
      html.div(
        [
          attribute.class(
            "modal modal-open fixed top-[4rem] right-0 left-0 bottom-0 flex items-end justify-end z-50 bg-black bg-opacity-50 w-screen max-h-[calc(100vh-4rem)]",
          ),
          event.on("click", closemodal_not_for_modal_box()),
        ],
        [
          html.div(
            [
              attribute.class(
                "modal-box w-[24rem] lg:h-full lg:max-h-[calc(100vh-4rem)] flex flex-col justify-start items-center bg-base-100 shadow-2xl relative rounded-xl md:h-full md:max-h-[calc(100vh-4rem)] h-[60vh] max-h-[60vh] mb-[20vh] lg:top-[10rem]",
              ),
            ],
            [
              html.button(
                [
                  attribute.class(
                    "btn btn-circle btn-primary absolute top-4 right-4 text-2xl",
                  ),
                  event.on_click(CloseModal),
                ],
                [element.text("×")],
              ),
              mod,
              html.div([attribute.class("modal-action")], []),
            ],
          ),
        ],
      )
    SideOrCentral(Left, mod) ->
      html.div(
        [
          attribute.class(
            "modal modal-open fixed top-[4rem] right-0 left-0 bottom-0 flex items-end justify-start z-50 bg-black bg-opacity-50 w-screen max-h-[calc(100vh-4rem)]",
          ),
          event.on("click", closemodal_not_for_modal_box()),
        ],
        [
          html.div(
            [
              attribute.class(
                "modal-box w-[24rem] lg:h-full lg:max-h-[calc(100vh-4rem)] flex flex-col justify-start items-center bg-base-100 shadow-2xl relative rounded-xl md:h-full md:max-h-[calc(100vh-4rem)] h-[60vh] max-h-[60vh] mb-[20vh] lg:top-[10rem]",
              ),
            ],
            [
              html.button(
                [
                  attribute.class(
                    "btn btn-circle btn-primary absolute top-4 right-4 text-2xl",
                  ),
                  event.on_click(CloseModal),
                ],
                [element.text("×")],
              ),
              mod,
              html.div([attribute.class("modal-action")], []),
            ],
          ),
        ],
      )
    NoModal -> element.none()
    SideOrCentral(Bottom, _) -> todo
    SideOrCentral(Top, _) -> todo
  }
  [
    modal_element,
    html.div(
      [attribute.class("drawer lg:drawer-open max-h-[calc(100vh-4rem)]")],
      [
        html.input([
          attribute.class("drawer-toggle"),
          attribute.type_("checkbox"),
          attribute.id("my-drawer-2"),
        ]),
        html.main(
          [
            attribute.class(
              "drawer-content items-center flex flex-col bg-neutral text-neutral-content h-screen max-h-[calc(100vh-4rem)] overflow-y-auto"
              <> {
                let rn = timestamp.system_time()
                let #(calendar.Date(year, month, day), _) =
                  timestamp.to_calendar(rn, calendar.local_offset())
                " "
                <> {
                  // Year
                  "yearclass-" <> int.to_string(year)
                }
                <> " "
                <> {
                  // Month
                  case month {
                    calendar.January -> "monthclass-1"
                    calendar.February -> "monthclass-2"
                    calendar.March -> "monthclass-3"
                    calendar.April -> "monthclass-4"
                    calendar.May -> "monthclass-5"
                    calendar.June -> "monthclass-6"
                    calendar.July -> "monthclass-7"
                    calendar.August -> "monthclass-8"
                    calendar.September -> "monthclass-9"
                    calendar.October -> "monthclass-10"
                    calendar.November -> "monthclass-11"
                    calendar.December -> "monthclass-12"
                  }
                }
                <> " "
                <> {
                  // Day
                  "dayclass-" <> int.to_string(day)
                }
              },
            ),
          ],
          [timeline(model)],
        ),
        html.div([attribute.class("drawer-side")], [
          html.label(
            [
              attribute.class("drawer-overlay"),
              attribute("aria-label", "close sidebar"),
              attribute.for("my-drawer-2"),
            ],
            [],
          ),
          html.ul(
            [
              attribute.class(
                "menu bg-base-200 bg-opacity-75 text-base-content h-screen lg:max-h-[calc(100vh-4rem)] w-80 p-4",
              ),
            ],
            [
              html.li([attribute.class("menu-title")], [
                element.text("Timeline"),
              ]),
              html.ul([], [
                html.li([], [
                  html.a(
                    [
                      bool.lazy_guard(
                        when: timeline_name == "global",
                        return: fn() { attribute.class("menu-active") },
                        otherwise: fn() { attribute.none() },
                      ),
                      event.on_click(message_type.TimeLineTo("global")),
                    ],
                    [element.text("🌐 Global")],
                  ),
                ]),
                html.li([], [
                  html.a(
                    [
                      bool.lazy_guard(
                        when: timeline_name == "following",
                        return: fn() { attribute.class("menu-active") },
                        otherwise: fn() { attribute.none() },
                      ),
                      event.on_click(message_type.TimeLineTo("following")),
                    ],
                    [element.text("👋 Following")],
                  ),
                ]),
                html.li([], [
                  html.a(
                    [
                      bool.lazy_guard(
                        when: timeline_name == "mutuals",
                        return: fn() { attribute.class("menu-active") },
                        otherwise: fn() { attribute.none() },
                      ),
                      event.on_click(message_type.TimeLineTo("mutuals")),
                    ],
                    [element.text("🤝 Mutuals")],
                  ),
                ]),
              ]),
            ],
          ),
        ]),
      ],
    ),
  ]
  |> common_view_parts(with_menu: [
    html.li([attribute.class("hidden md:flex")], [
      html.button([attribute.class("btn md:btn-neutral btn-ghost")], [
        element.text("Settings"),
      ]),
    ]),
    html.li([attribute.class("lg:hidden ")], [
      html.label(
        [
          attribute.class("drawer-button btn md:btn-neutral btn-ghost"),
          attribute.for("my-drawer-2"),
        ],
        [element.text("Switch timeline")],
      ),
    ]),
    case user {
      Some(user) -> {
        html.li([], [
          html.button(
            [
              attribute.class("btn md:btn-neutral btn-ghost"),
              event.on_click(SetModal("selfmenu")),
            ],
            [
              html.div([attribute.class("avatar")], [
                html.div([attribute.class("h-8 w-8 mask-squircle mask")], [
                  html.img([
                    attribute.src(user.avatar),
                    attribute.alt(user.username),
                  ]),
                ]),
              ]),
              html.span([attribute.class("hidden md:inline")], [
                element.text("@" <> user.username),
              ]),
            ],
          ),
        ])
      }
      None -> element.none()
    },
  ])
}

pub fn timeline(model: Model) -> Element(Msg) {
  // Dissect the model
  let assert model_type.Model(
    page: model_type.HomeTimeline(timeline_name:, modal: _),
    user: _,
    ws: _,
    token: _,
    status: _,
    cache:,
    ticks: _,
  ) = model
  let timeline_name = option.unwrap(timeline_name, "global")
  // case timeline_name {
  //   Some(timeline_name) -> {
  let timeline_posts = dict.get(cache.cached_timelines, timeline_name)
  case timeline_posts {
    Ok(cached_timeline) -> {
      let posts: List(String) = get_all_posts(cached_timeline)
      let show_load_more = cached_timeline.has_more
      html.div([], {
        case posts {
          [] -> [
            html.div([attribute.class("justify-center p-4")], [
              element.text("This timeline is empty! Make sure to fill it!"),
            ]),
          ]

          _ -> {
            let post_elements =
              list.map(posts, fn(post_id) {
                html.div([], [
                  element.text("This should show post from id: " <> post_id),
                  html.div([attribute.class("skeleton h-32 w-full")], []),
                  html.div([attribute.class("skeleton h-4 w-28")], []),
                  html.div([attribute.class("skeleton h-4 w-full")], []),
                ])
              })

            case show_load_more {
              True ->
                list.append(post_elements, [
                  html.div([attribute.class("flex justify-center p-4")], [
                    html.button(
                      [
                        attribute.class("btn btn-primary"),
                        event.on_click(message_type.LoadMorePosts(timeline_name)),
                      ],
                      [element.text("Load More Posts")],
                    ),
                  ]),
                ])
              False -> post_elements
            }
          }
        }
      })
    }
    Error(..) ->
      html.div([attribute.class("flex w-4/6 flex-col gap-4 items-start")], [
        element.text("Loading timeline \"" <> timeline_name <> "\" ..."),
        html.div([attribute.class("skeleton h-32 w-full")], []),
        html.div([attribute.class("skeleton h-4 w-28")], []),
        html.div([attribute.class("skeleton h-4 w-full")], []),
        html.div([attribute.class("skeleton h-32 w-full")], []),
        html.div([attribute.class("skeleton h-4 w-28")], []),
        html.div([attribute.class("skeleton h-4 w-full")], []),
        html.div([attribute.class("skeleton h-4 w-full")], []),
        html.div([attribute.class("skeleton h-32 w-full")], []),
        html.div([attribute.class("skeleton h-4 w-28")], []),
        html.div([attribute.class("skeleton h-4 w-full")], []),
        html.div([attribute.class("skeleton h-32 w-full")], []),
        html.div([attribute.class("skeleton h-4 w-28")], []),
        html.div([attribute.class("skeleton h-4 w-full")], []),
        element.text(
          "Skeleton should be remodeled after the actual post view later.",
        ),
      ])
  }
  //   }
  //   None ->
  //     html.div([attribute.class("")], [
  //       html.div([attribute.class("justify-center p-4")], [
  //         element.text("Still, I've to put something on here innit?"),
  //       ]),
  //     ])
  // }
}

/// Get all post IDs from a cached timeline in order (page 0, page 1, etc.)
pub fn get_all_posts(timeline: CachedTimeline) -> List(String) {
  timeline.pages
  |> dict.to_list
  |> list.sort(fn(a, b) {
    let #(page_a, _) = a
    let #(page_b, _) = b
    case page_a < page_b {
      True -> order.Lt
      False ->
        case page_a == page_b {
          True -> order.Eq
          False -> order.Gt
        }
    }
  })
  |> list.map(fn(x) {
    let #(_, posts) = x
    posts
  })
  |> list.flatten
}

/// Get posts for a specific page
pub fn get_page_posts(
  timeline: CachedTimeline,
  page: Int,
) -> Option(List(String)) {
  case { timeline.pages |> dict.get(page) } {
    Ok(c) -> option.Some(c)
    _ -> option.None
  }
}

/// Check if a specific page is cached
pub fn has_page_cached(timeline: CachedTimeline, page: Int) -> Bool {
  case timeline.pages |> dict.get(page) {
    Ok(_) -> True
    Error(_) -> False
  }
}

/// Get the highest cached page number
pub fn get_highest_cached_page(timeline: CachedTimeline) -> Int {
  timeline.pages
  |> dict.keys
  |> list.fold(0, fn(max, page) {
    case page > max {
      True -> page
      False -> max
    }
  })
}

/// Calculate total number of cached posts
pub fn get_cached_posts_count(timeline: CachedTimeline) -> Int {
  timeline.pages
  |> dict.values
  |> list.map(list.length)
  |> list.fold(0, fn(acc, count) { acc + count })
}

/// Check if we need to load more pages for a given position
/// Returns True if the position is near the end of cached content
pub fn should_load_more(
  timeline: CachedTimeline,
  position: Int,
  lookahead: Int,
) -> Bool {
  let cached_count = get_cached_posts_count(timeline)
  let needs_more = position + lookahead >= cached_count
  needs_more && timeline.has_more
}

/// Create a new empty cached timeline
pub fn create_empty_timeline() -> CachedTimeline {
  CachedTimeline(
    pages: dict.new(),
    total_count: 0,
    current_page: 0,
    has_more: False,
    last_updated: 0,
  )
}

/// Add a page of posts to a timeline cache
pub fn add_page_to_timeline(
  timeline: CachedTimeline,
  page: Int,
  posts: List(String),
  total_count: Int,
  has_more: Bool,
) -> CachedTimeline {
  CachedTimeline(
    pages: timeline.pages |> dict.insert(page, posts),
    total_count: total_count,
    current_page: page,
    has_more: has_more,
    last_updated: 0,
    // TODO: Add proper timestamp when available
  )
}

/// Clear all cached pages (useful for timeline refresh)
pub fn clear_timeline_cache() -> CachedTimeline {
  CachedTimeline(
    pages: dict.new(),
    total_count: 0,
    current_page: 0,
    has_more: False,
    last_updated: 0,
  )
}

/// Get the next page number that should be loaded
pub fn get_next_page_to_load(timeline: CachedTimeline) -> Option(Int) {
  case timeline.has_more {
    False -> None
    True -> {
      let highest_page = get_highest_cached_page(timeline)
      Some(highest_page + 1)
    }
  }
}

/// Check if timeline is empty (no pages cached)
pub fn is_timeline_empty(timeline: CachedTimeline) -> Bool {
  dict.size(timeline.pages) == 0
}

/// Get pagination info as a readable string (for debugging/logging)
pub fn timeline_info_string(
  timeline: CachedTimeline,
  timeline_name: String,
) -> String {
  let cached_count = get_cached_posts_count(timeline)
  let highest_page = get_highest_cached_page(timeline)

  "Timeline '"
  <> timeline_name
  <> "': "
  <> int.to_string(cached_count)
  <> "/"
  <> int.to_string(timeline.total_count)
  <> " posts cached, pages 0-"
  <> int.to_string(highest_page)
  <> ", has_more: "
  <> bool.to_string(timeline.has_more)
}

/// Merge two timeline caches (useful when updating with new data)
pub fn merge_timelines(
  old: CachedTimeline,
  new: CachedTimeline,
) -> CachedTimeline {
  // Merge pages, preferring new data for conflicts
  let merged_pages =
    dict.fold(new.pages, old.pages, fn(acc, page, posts) {
      dict.insert(acc, page, posts)
    })

  CachedTimeline(
    pages: merged_pages,
    total_count: new.total_count,
    // Use new total count
    current_page: new.current_page,
    has_more: new.has_more,
    last_updated: new.last_updated,
  )
}

type ModalSide {
  Right
  Left
  Bottom
  Top
}

type ModalWithShape {
  /// Central takes up most of the screen space, and is used for things like a settings screen.
  CentralBig(Element(Msg))
  /// Central takes up less of the screen space, and is used for things like a 'write a post' editor.
  CentralSmall(Element(Msg))
  /// Side or central takes up a little less screen space, looks roughly the same as Central(Big) on mobile screens but tries to out-center itself if possible.
  /// Used for for example the user menu.
  SideOrCentral(ModalSide, Element(Msg))
  NoModal
}

// TODO: Think about different VARIANTS of modals, like for the user menu a right-side one for example.
fn modal_by_id(id: String, model: Model) -> ModalWithShape {
  let assert model_type.Model(
    page: model_type.HomeTimeline(timeline_name: _, modal: _),
    user: Some(user),
    ws: _,
    token: _,
    status: _,
    cache: _,
    ticks: _,
  ): Model = model
  case id {
    "test" ->
      CentralBig(
        html.div([], [
          element.text("Welcome to Lumina! This is a test modal screen."),
        ]),
      )
    "selfmenu" ->
      SideOrCentral(
        Right,
        html.ul(
          [
            attribute.class(
              "menu menu-xl rounded-box w-2/3 justify-center text-center items-center space-y-4",
            ),
          ],
          [
            html.li([attribute.class("menu-title")], [
              element.text("Hi, @" <> user.username),
            ]),
            html.li([], [
              element.text("There's not much in this menu as of yet."),
            ]),
            html.li([attribute.class("md:hidden")], [
              html.a(
                [
                  attribute.class("btn btn-info"),
                  event.on_click(SetModal("selfsettings")),
                ],
                [
                  element.text("Settings"),
                ],
              ),
            ]),
            html.li([], [
              html.a([attribute.class("btn btn-warn"), event.on_click(Logout)], [
                element.text("Log out"),
              ]),
            ]),
          ],
        ),
      )

    _ -> NoModal
  }
}
