import gleam/bool
import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import lumina_client/message_type.{type Msg}
import lumina_client/model_type.{type CachedTimeline, type Model, CachedTimeline}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn timeline(model: Model) -> Element(Msg) {
  // Dissect the model
  let assert model_type.Model(
    page: model_type.HomeTimeline(timeline_name:, pop_up: _),
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
pub fn clear_timeline_cache(timeline: CachedTimeline) -> CachedTimeline {
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
