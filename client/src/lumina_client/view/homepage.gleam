import gleam/bool
import gleam/dict
import gleam/dynamic/decode
import gleam/option.{None, Some}
import gleam/result
import gleam/list
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
import lustre/attribute.{attribute}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import plinth/javascript/storage

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
        Ok(post_ids) -> {
          let posts: List(String) = post_ids
          html.div([],{
          case posts {
          	[] ->
           [
           html.div([attribute.class("justify-center p-4")], [
           element.text( "This timeline is empty! Make sure to fill it!")
           ])
           ]

           _ -> {list.map(posts, fn(post_id) {
             html.div([], [
               element.text( "This should show post from id: " <>post_id),
               html.div([attribute.class("skeleton h-32 w-full")], []),
               html.div([attribute.class("skeleton h-4 w-28")], []),
               html.div([attribute.class("skeleton h-4 w-full")], []),
             ])
           })}
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
