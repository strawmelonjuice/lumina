//// Helper functions

import lumina_client/message_type.{type Msg}
import lustre/attribute

import gleam/list
import lumina_client/dom
import lumina_client/model_type.{type LoginFields}

pub fn get_color_scheme(_model_) -> attribute.Attribute(Msg) {
  // Will get overwritten by model later
  // For now, just return system default
  case dom.get_color_scheme() {
    "dark" -> attribute.attribute("data-theme", "lumina-dark")
    _ -> attribute.attribute("data-theme", "lumina-light")
  }
}

/// Under which key the model is stored in local storage.
pub const model_local_storage_key = "luminaModelJSOB"

pub fn login_view_checker(fieldvalues: LoginFields) {
  [{ fieldvalues.passwordfield != "" }, { fieldvalues.emailfield != "" }]
  |> list.all(fn(x) { x })
}
