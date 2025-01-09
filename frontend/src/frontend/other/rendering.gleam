import gleam/bool
import gleam/dynamic/decode
import gleam/json
import gleam/list
import lumina/shared/shared_fepage_com.{
  type FEPageServeResponse, FEPageServeResponse,
}
import lustre/attribute.{attribute}
import lustre/element.{text}
import lustre/element/html
import lustre/element/svg

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
      let assert Ok(data) =
        json.parse(from: source.main, using: home_page_data_decoder())
      source.main
      let right =
        html.html([attribute("lang", "en")], [
          html.head([], [
            html.meta([attribute("charset", "UTF-8")]),
            html.title(
              [],
              "Home - " <> data.username <> "@" <> data.instance_name,
            ),
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
    [909, ..] -> {
      // Notifications page!
      // We have to decode the data before rendering it.
      let assert Ok(data) =
        json.parse(from: source.main, using: notifications_page_data_decoder())
      source.main
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
  use notifs <- decode.field(
    "notifs",
    decode.list(todo as "Decoder for Notification"),
  )
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
