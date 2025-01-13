import gleam/bool
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/result
import lumina/shared/shared_fepage_com.{
  type FEPageServeResponse, FEPageServeResponse,
}
import lustre/attribute.{attribute}
import lustre/element.{text}
import lustre/element/html
import lustre/element/svg

type HomePageData {
  HomePageData(username: String, instance_name: String)
}

fn home_page_data_decoder() -> decode.Decoder(HomePageData) {
  use username <- decode.field("username", decode.string)
  use instance_name <- decode.field("instance_name", decode.string)
  decode.success(HomePageData(username:, instance_name:))
}

type NotificationsPageData {
  NotificationsPageData(notifs: List(Notification), unread_count: Int)
}

fn notifications_page_data_decoder() -> decode.Decoder(NotificationsPageData) {
  use notifs <- decode.field("notifs", decode.list(notification_decoder()))
  use unread_count <- decode.field("unread_count", decode.int)
  decode.success(NotificationsPageData(notifs:, unread_count:))
}

type Notification {
  Notification(
    title: String,
    content: String,
    time: String,
    recently_read: Bool,
    kind: String,
  )
}

fn notification_decoder() -> decode.Decoder(Notification) {
  use title <- decode.field("title", decode.string)
  use content <- decode.field("content", decode.string)
  use time <- decode.field("time", decode.string)
  use recently_read <- decode.field("recently_read", decode.bool)
  use kind <- decode.field("kind", decode.string)
  decode.success(Notification(title:, content:, time:, recently_read:, kind:))
}

/// This module handles rendering of sub-pages, doing this through checking if a code 899 is present in the messages, and if so.
/// Rendering the data from the `FEPageServeResponse` into, for example, Lustre templates.
/// If the code 899 is not present, the HTML is already rendered into the data fields. Render will just return.
pub fn renders(source: FEPageServeResponse) -> FEPageServeResponse {
  // If the message does not contain the code 899, that means the HTML is already rendered into the data fields.
  use <- bool.guard(list.contains(source.message, 899) |> bool.negate, source)
  // Okay, 899 means we have to decode the data before rendering it.
  rendermatcher(source, source)
}

fn rendermatcher(
  source: FEPageServeResponse,
  osource: FEPageServeResponse,
) -> FEPageServeResponse {
  case source.message {
    // If the message is empty, we just return the source. This might need to change to display an error message some point in the future, as it might be a sign of a bug or at least discrepancy between the client and server.
    [] -> osource
    [901, ..] -> {
      // Home page/timeline page!
      // We have to decode the data before rendering it.
      let data =
        json.parse(from: source.main, using: home_page_data_decoder())
        |> result.unwrap(HomePageData("", "&gt;error&lt;"))
      let right =
        html.div([], [
          html.h1([], [
            html.text("welcome to instance "),
            html.code([], [html.text(data.instance_name)]),
          ]),
          html.p([], [
            html.text(
              "as you can see, there is no such thing as a homepage. lumina is
				not ready for anything yet.
			",
            ),
          ]),
        ])
        |> element.to_string()
      let left =
        html.div([attribute.class("lg:p-0.5")], [
          html.div(
            [
              attribute.class(
                "flex flex-col p-4 m-4 space-y-4 border-gray-500 rounded-md border-1 bg-brown-100 dark:bg-neutral-700",
              ),
            ],
            [
              html.h3([attribute.class("underline")], [html.text("Timelines")]),
              html.a(
                [attribute("onclick", ""), attribute.href("javascript:void(0)")],
                [
                  html.button(
                    [
                      attribute.class(
                        "px-3 py-2 text-sm font-medium bg-orange-200 border-2 rounded-md border-emerald-600 dark:text-orange-200 dark:bg-yellow-700 hover:text-white hover:bg-gray-700 text-brown-800 dark:border-zinc-400",
                      ),
                    ],
                    [html.text("🌐 Global timeline")],
                  ),
                ],
              ),
              html.a(
                [attribute("onclick", ""), attribute.href("javascript:void(0)")],
                [
                  html.button(
                    [
                      attribute.class(
                        "px-3 py-2 text-sm font-medium bg-orange-200 border-2 rounded-md border-emerald-600 dark:text-orange-200 dark:bg-yellow-700 hover:text-white hover:bg-gray-700 text-brown-800 dark:border-zinc-400",
                      ),
                    ],
                    [html.text("🙋 Followed timeline")],
                  ),
                ],
              ),
            ],
          ),
          html.div(
            [
              attribute.class(
                "flex flex-col p-4 m-4 space-y-4 border-gray-500 rounded-md border-1 bg-brown-100 dark:bg-neutral-700",
              ),
            ],
            [html.h3([attribute.class("underline")], [html.text("Bubbles")])],
          ),
        ])
        |> element.to_string()
      FEPageServeResponse(right, left, osource.message)
    }
    [909, ..] -> {
      // Notifications page!
      // We have to decode the data before rendering it.
      let data =
        json.parse(from: source.main, using: notifications_page_data_decoder())
        |> result.unwrap(NotificationsPageData([], 0))

      let right =
        html.html([attribute("lang", "en")], [
          html.head([], [
            html.meta([attribute("charset", "UTF-8")]),
            html.title([], "Notifications"),
            html.meta([
              attribute("content", "width=device-width, initial-scale=1.0"),
              attribute.name("viewport"),
            ]),
          ]),
          html.body([], []),
        ])
        |> element.to_string()
      let left = ""

      FEPageServeResponse(right, left, osource.message)
    }

    [_, ..rest] -> {
      // More luck next loop!
      rendermatcher(
        { FEPageServeResponse(source.main, source.side, rest) },
        osource,
      )
    }
  }
}
