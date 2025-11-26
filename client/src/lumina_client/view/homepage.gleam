//// Lumina > Client > View > Application/Homepage
//// This module focuses on the main application, mostly layout and modals.
//// It's children shape the content inside the main application layout.

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
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/result
import gleam/time/calendar
import gleam/time/timestamp
import lumina_client/dom
import lumina_client/helpers
import lumina_client/message_type.{
  type Msg, CloseModal, Logout, SetModal, StartDraggingModalBox,
}
import lumina_client/model_type.{type CachedTimeline, type Model, CachedTimeline}
import lumina_client/view/common_view_parts.{common_view_parts}
import lumina_client/view/homepage/post_editor
import lumina_client/view/homepage/posts
import lustre/attribute.{attribute}
import lustre/element.{type Element}
import lustre/element/html
import lustre/element/svg
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
    ..,
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
                "modal-box w-[99vw] lg:w-[80vw] max-w-[unset] h-[80lvh] flex flex-col justify-center items-center bg-base-100 shadow-2xl relative",
              ),
            ],
            [
              html.button(
                [
                  attribute.class(
                    "btn btn-circle btn-error absolute top-4 right-4 text-2xl",
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
    CentralSmall(id, title, mod, closable, params) -> {
      let def_x = helpers.get_center_positioned_style_px().0
      let def_y = helpers.get_center_positioned_style_px().1
      let x = dict.get(params, "pos_x")
      let y = dict.get(params, "pos_y")
      let pos_x = case x {
        Ok(v) -> float.parse(v) |> result.unwrap(def_x)
        Error(_) -> def_x
      }
      let pos_y = case y {
        Ok(v) -> float.parse(v) |> result.unwrap(def_y)
        Error(_) -> def_y
      }
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
              attribute.id(id),

              attribute.class(
                "modal-box w-[32rem] max-w-[99vw] not:h-[32rem] h-[80lvh] max-h-[90vh] flex flex-col justify-center items-center bg-base-100 shadow-2xl absolute",
              ),
              // Positioning styles from left to right
              attribute.style("left", pos_x |> float.to_string() <> "px"),
              // Positioning styles from top to bottom
              attribute.style("top", pos_y |> float.to_string() <> "px"),
              // Centering transform
              attribute.style("transform", "translate(-50%, -50%)"),
            ],
            [
              // Title bar
              html.section(
                [
                  attribute.class(
                    "w-full h-10 absolute top-0 left-0 bg-transparent cursor-move bg-info text-info-content rounded-t-xl flex items-center justify-center",
                  ),
                  event.on_mouse_down(StartDraggingModalBox(pos_x, pos_y)),
                ],
                [element.text(title)],
              ),
              // Close button on the title bar, if closable
              case closable {
                True ->
                  html.button(
                    [
                      attribute.class(
                        "btn btn-circle btn-error absolute top-0 right-4 text-2xl",
                      ),
                      event.on_click(CloseModal),
                    ],
                    [element.text("×")],
                  )
                False -> element.none()
              },

              html.div([attribute.class("w-full h-full mt-10")], [
                mod,
              ]),
            ],
          ),
        ],
      )
    }
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
                "modal-box w-[24rem]  lg:max-h-[calc(100vh-4rem)] flex flex-col justify-start items-center bg-base-100 shadow-2xl relative rounded-xl md:max-h-[calc(100vh-4rem)] h-[60vh] max-h-[60vh] mb-[20vh]",
              ),
            ],
            [
              html.button(
                [
                  attribute.class(
                    "btn btn-circle btn-error absolute top-4 right-4 text-2xl",
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
                "modal-box w-[24rem] lg:max-h-[calc(100vh-4rem)] flex flex-col justify-start items-center bg-base-100 shadow-2xl relative rounded-xl md:max-h-[calc(100vh-4rem)] h-[60vh] max-h-[60vh] mb-[20vh]",
              ),
            ],
            [
              html.button(
                [
                  attribute.class(
                    "btn btn-circle btn-error absolute top-4 right-4 text-2xl",
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
    NoModal -> {
      // Floating items and such to be rendered when no modal is open
      html.div([attribute.class("items")], [
        html.div([attribute.class("absolute bottom-4 right-4 p-4 z-50")], [
          html.button(
            [
              attribute.class("btn btn-circle btn-success btn-lg text-3xl"),
              attribute.id("btn-new-post"),
              event.on_click(SetModal("mdl-postedit")),
            ],
            [element.text("+")],
          ),
        ]),
      ])
    }
    // SideOrCentral(Bottom, _) -> todo
    // SideOrCentral(Top, _) -> todo
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
        html.div([attribute.class("drawer-side font-menuitems")], [
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
              html.li([attribute.class("menu-title font-sans")], [
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
                    [
                      // Replaced the globe emoji with svg for better accessibility and consistency
                      // element.text("🌐 Global")
                      html.svg(
                        [
                          attribute.class("inline h-5 w-5 mr-2"),
                          attribute.attribute("fill", "none"),
                          attribute.attribute("stroke", "currentColor"),
                          attribute.attribute("viewBox", "0 0 24 24"),
                          attribute.attribute(
                            "xmlns",
                            "http://www.w3.org/2000/svg",
                          ),
                        ],
                        [
                          svg.circle([
                            attribute.attribute("cx", "12"),
                            attribute.attribute("cy", "12"),
                            attribute.attribute("opacity", "0.6"),
                            attribute.attribute("r", "9"),
                            attribute.attribute("stroke-width", "2"),
                          ]),
                          // Equator
                          svg.path([
                            attribute.attribute("stroke-linecap", "round"),
                            attribute.attribute("stroke-linejoin", "round"),
                            attribute.attribute("opacity", "0.6"),
                            attribute.attribute("stroke-width", "2"),
                            attribute.attribute("d", "M3 12h18"),
                          ]),
                          // Prime meridian
                          svg.path([
                            attribute.attribute("opacity", "0.6"),
                            attribute.attribute("stroke-linecap", "round"),
                            attribute.attribute("stroke-linejoin", "round"),
                            attribute.attribute("stroke-width", "2"),
                            attribute.attribute("d", "M12 3a9 9 0 0 1 0 18"),
                          ]),
                          // Longitude lines
                          svg.path([
                            attribute.attribute("stroke-linecap", "round"),
                            attribute.attribute("stroke-linejoin", "round"),
                            attribute.attribute("opacity", "0.6"),
                            attribute.attribute("stroke-width", "2"),
                            attribute.attribute(
                              "d",
                              "M6.6 6.6a9 9 0 0 1 0 10.8",
                            ),
                          ]),
                          svg.path([
                            attribute.attribute("stroke-linecap", "round"),
                            attribute.attribute("opacity", "0.6"),
                            attribute.attribute("stroke-linejoin", "round"),
                            attribute.attribute("stroke-width", "2"),
                            attribute.attribute(
                              "d",
                              "M17.4 6.6a9 9 0 0 0 0 10.8",
                            ),
                          ]),
                          // Additional latitude lines
                          svg.path([
                            attribute.attribute("stroke-linecap", "round"),
                            attribute.attribute("stroke-linejoin", "round"),
                            attribute.attribute("opacity", "0.4"),
                            attribute.attribute("stroke-width", "1.5"),
                            attribute.attribute("d", "M4.5 8.5a9 9 0 0 1 15 0"),
                          ]),
                          svg.path([
                            attribute.attribute("stroke-linecap", "round"),
                            attribute.attribute("stroke-linejoin", "round"),
                            attribute.attribute("opacity", "0.4"),
                            attribute.attribute("stroke-width", "1.5"),
                            attribute.attribute("d", "M4.5 15.5a9 9 0 0 0 15 0"),
                          ]),
                          // Additional longitude lines
                          svg.path([
                            attribute.attribute("stroke-linecap", "round"),
                            attribute.attribute("stroke-linejoin", "round"),
                            attribute.attribute("opacity", "0.4"),
                            attribute.attribute("stroke-width", "1.5"),
                            attribute.attribute("d", "M8.5 4.5a9 9 0 0 1 0 15"),
                          ]),
                          svg.path([
                            attribute.attribute("stroke-linecap", "round"),
                            attribute.attribute("stroke-linejoin", "round"),
                            attribute.attribute("opacity", "0.4"),
                            attribute.attribute("stroke-width", "1.5"),
                            attribute.attribute("d", "M15.5 4.5a9 9 0 0 0 0 15"),
                          ]),
                        ],
                      ),
                      element.text("Global"),
                    ],
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
                    [
                      // SVG: Two user silhouettes for 'Following'
                      html.svg(
                        [
                          attribute.class("inline h-5 w-5 mr-2"),
                          attribute.attribute("fill", "none"),
                          attribute.attribute("stroke", "currentColor"),
                          attribute.attribute("viewBox", "0 0 24 24"),
                          attribute.attribute(
                            "xmlns",
                            "http://www.w3.org/2000/svg",
                          ),
                        ],
                        [
                          svg.circle([
                            attribute.attribute("cx", "8"),
                            attribute.attribute("cy", "8"),
                            attribute.attribute("r", "3"),
                            attribute.attribute("opacity", "0.6"),
                            attribute.attribute("stroke-width", "2"),
                          ]),
                          svg.circle([
                            attribute.attribute("cx", "16"),
                            attribute.attribute("cy", "8"),
                            attribute.attribute("r", "3"),
                            attribute.attribute("opacity", "0.6"),
                            attribute.attribute("stroke-width", "2"),
                          ]),
                          svg.path([
                            attribute.attribute("stroke-width", "2"),
                            attribute.attribute("stroke-linecap", "round"),
                            attribute.attribute("opacity", "0.6"),
                            attribute.attribute("stroke-linejoin", "round"),
                            attribute.attribute(
                              "d",
                              "M2 20v-1a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v1",
                            ),
                          ]),
                          svg.path([
                            attribute.attribute("stroke-width", "2"),
                            attribute.attribute("opacity", "0.6"),
                            attribute.attribute("stroke-linecap", "round"),
                            attribute.attribute("stroke-linejoin", "round"),
                            attribute.attribute(
                              "d",
                              "M14 20v-1a4 4 0 0 1 4-4h0a4 4 0 0 1 4 4v1",
                            ),
                          ]),
                        ],
                      ),
                      element.text("Following"),
                    ],
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
                    [
                      // SVG: Heart and star overlapping for 'Mutuals'
                      html.svg(
                        [
                          attribute.class("inline h-5 w-5 mr-2"),
                          attribute.attribute("fill", "none"),
                          attribute.attribute("stroke", "currentColor"),
                          attribute.attribute("viewBox", "0 0 24 24"),
                          attribute.attribute(
                            "xmlns",
                            "http://www.w3.org/2000/svg",
                          ),
                        ],
                        [
                          // Heart shape, offset to the left, with classic 'v' top and reduced opacity
                          svg.path([
                            attribute.attribute("stroke-width", "2"),
                            attribute.attribute("stroke-linecap", "round"),
                            attribute.attribute("stroke-linejoin", "round"),
                            attribute.attribute(
                              "d",
                              "M9 19C5 15 2 12.5 2 9.5C2 7 4 5 6.5 5C8 5 9 6.5 9 6.5C9 6.5 10 5 11.5 5C14 5 16 7 16 9.5C16 12.5 13 15 9 19Z",
                            ),
                            attribute.attribute("opacity", "0.6"),
                          ]),
                          // Star shape, offset to the right and overlapping, with reduced opacity
                          svg.path([
                            attribute.attribute("stroke-width", "2"),
                            attribute.attribute("stroke-linecap", "round"),
                            attribute.attribute("stroke-linejoin", "round"),
                            attribute.attribute(
                              "d",
                              "M15 4.5l2.09 4.24 4.68.68-3.39 3.3.8 4.63L15 15.77l-4.18 2.18.8-4.63-3.39-3.3 4.68-.68L15 4.5z",
                            ),
                            attribute.attribute("opacity", "0.6"),
                          ]),
                        ],
                      ),
                      element.text("Mutuals"),
                    ],
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
    html.li(
      [
        attribute.class("hidden md:flex"),
        event.on_click(SetModal("selfsettings")),
      ],
      [
        html.button([attribute.class("btn md:btn-neutral btn-ghost")], [
          element.text("Settings"),
        ]),
      ],
    ),
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
              html.span([attribute.class("hidden md:inline")], [
                element.text("@" <> user.username),
              ]),
              html.div([attribute.class("avatar")], [
                html.div([attribute.class("h-8 w-8 mask-squircle mask")], [
                  html.img([
                    attribute.src(user.avatar),
                    attribute.alt(user.username),
                  ]),
                ]),
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
    cache:,
    ..,
  ) = model
  let timeline_name = option.unwrap(timeline_name, "global")
  // case timeline_name {
  //   Some(timeline_name) -> {
  let timeline_posts = dict.get(cache.cached_timelines, timeline_name)
  case timeline_posts {
    Ok(cached_timeline) -> {
      let post_ids: List(String) = get_all_posts(cached_timeline)
      let show_load_more = cached_timeline.has_more
      html.div([attribute.class("flex w-4/6 flex-col gap-4 items-start")], {
        case post_ids {
          [] -> [
            html.div([attribute.class("justify-center p-4")], [
              element.text("This timeline is empty! Make sure to fill it!"),
            ]),
          ]

          _ -> {
            let post_elements =
              list.map(post_ids, posts.element_from_id(model, _))

            case show_load_more {
              True ->
                list.append(post_elements, [
                  html.div([attribute.class("flex justify-center p-4")], [
                    html.button(
                      [
                        attribute.class("btn btn-primary font-menuitems"),
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
    id: "",
    total_count: 0,
    current_page: 0,
    has_more: False,
    last_updated: 0,
  )
}

/// Add a page of posts to a timeline cache
pub fn add_page_to_timeline(
  to_timeline timeline: CachedTimeline,
  timeline_id tlid: String,
  page page: Int,
  items posts: List(String),
  count total_count: Int,
  has_more has_more: Bool,
) -> CachedTimeline {
  CachedTimeline(
    pages: timeline.pages |> dict.insert(page, posts),
    id: tlid,
    total_count: total_count,
    current_page: page,
    has_more: has_more,
    last_updated: float.truncate(
      timestamp.to_unix_seconds(timestamp.system_time()),
    ),
  )
}

/// Clear all cached pages (useful for timeline refresh)
pub fn clear_timeline_cache(old: CachedTimeline) -> CachedTimeline {
  CachedTimeline(
    pages: dict.new(),
    id: old.id,
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
    id: new.id,
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
  // Bottom
  // Top
}

type ModalWithShape {
  /// Central takes up most of the screen space, and is used for things like a settings screen.
  CentralBig(Element(Msg))
  /// Takes up less of the screen space, and is used for things like a 'write a post' editor. On wide screens it can be moved around (following Lumina-peonies pre-25 design concepts.)
  /// On wide screens it also shows an empty title bar (draggable) containing a close button. This button will always be shown but can be disabled.
  CentralSmall(
    /// Just the #id.
    id: String,
    /// Title on the modal.
    title: String,
    /// Content of the modal, this one makes sense.
    containing: Element(Msg),
    /// Let the title bar [x] close this modal.
    closeable: Bool,
    /// Additional parameters, for example position.
    params: dict.Dict(String, String),
  )
  /// Side or central takes up a little less screen space, looks roughly the same as Central(Big) on mobile screens but tries to out-center itself if possible.
  /// Used for for example the user menu.
  SideOrCentral(ModalSide, Element(Msg))
  NoModal
}

// TODO: Think about different VARIANTS of modals, like for the user menu a right-side one for example.
fn modal_by_id(
  f: #(String, dict.Dict(String, String)),
  model: Model,
) -> ModalWithShape {
  let #(id, params) = f
  let assert model_type.Model(
    page: model_type.HomeTimeline(timeline_name: _, modal: _),
    user: Some(user),
    ..,
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
                  attribute.class("btn btn-info font-menuitems"),
                  event.on_click(SetModal("selfsettings")),
                ],
                [
                  element.text("Settings"),
                ],
              ),
            ]),
            html.li([], [
              html.a(
                [
                  attribute.class("btn btn-warn font-menuitems"),
                  event.on_click(Logout),
                ],
                [
                  element.text("Log out"),
                ],
              ),
            ]),
          ],
        ),
      )
    "selfsettings" ->
      CentralBig(
        html.div([], [
          element.text("User settings will be here eventually."),
        ]),
      )
    "mdl-postedit" -> {
      CentralSmall(
        "mdl-postedit",
        "New Post",
        post_editor.main(params, model),
        True,
        params:,
      )
    }
    _ -> NoModal
  }
}
