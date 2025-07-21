import gleam/bool
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
import lustre/attribute.{attribute}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import plinth/javascript/storage

fn timeline(model: Model) -> Element(Msg) {
	// Dissect the model
	let assert model_type.Model(
    page: model_type.HomeTimeline(timeline_id:),
    user:,
    ws: _,
    token:,
    status:,
    cache:,
    ticks:,
  ) = model
  todo as "Oky, the update function should have created a side effect to fetch this timeline and add it to the cache, now this function should look into the cache and return the timeline if it exists, otherwise show a skeleton."
}
