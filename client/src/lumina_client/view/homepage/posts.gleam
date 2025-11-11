import gleam/dict
import gleam/list
import lumina_client/message_type.{type Msg}
import lumina_client/model_type.{type CachedTimeline, type Model, CachedTimeline}
import lustre/attribute.{attribute}
import lustre/element.{type Element}
import lustre/element/html

pub fn element_from_id(model: Model, post_id: String) -> Element(Msg) {
  let post = dict.get(model.cache.cached_posts, post_id)

  html.div(
    [
      attribute.class(
        "flex flex-col gap-2 p-4 m-8 bg-base-300 text-base-300-content rounded-md w-full bg-opacity-25 font-content",
        // Other candidates were:
      // // "flex flex-col gap-2 p-4 m-8 bg-secondary text-secondary-content rounded-md w-full",
      // // "flex flex-col gap-2 p-4 m-8 bg-info text-info-content rounded-md w-full bg-opacity-25",
      ),
    ],
    case post {
      Ok(_) -> todo
      _ -> [
        html.p([], [
          element.text("Loading post..."),
          html.span(
            [
              attribute.class("loading loading-spinner loading-md float-right"),
            ],
            [],
          ),
        ]),
      ]
    }
      |> list.append([
        html.small([attribute.class("opacity-50 text-xs font-script")], [
          element.text("ID:" <> post_id),
        ]),
      ]),
  )
}
