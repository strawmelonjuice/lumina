//// Lumina > Client > Helper functions
//// This module contains helper functions used across the Lumina client.

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

import gleam/float
import gleam/int
import gleam/list
import gleam/result
import lumina_client/dom
import lumina_client/message_type.{type Msg}
import lumina_client/model_type.{type LoginFields}
import lustre/attribute
import plinth/javascript/global

pub fn get_color_scheme(_model_) -> attribute.Attribute(Msg) {
  // Will get overruled by model later
  // For now, just return system default
  attribute.none()
  // case dom.get_color_scheme() {
  // "dark" -> attribute.attribute("data-theme", "lumina-dark")
  // _ -> attribute.attribute("data-theme", "lumina-light")
  // }
}

/// Under which key the model is stored in local storage.
pub const model_local_storage_key = "luminaModelJSOB"

pub fn login_view_checker(fieldvalues: LoginFields) {
  [{ fieldvalues.passwordfield != "" }, { fieldvalues.emailfield != "" }]
  |> list.all(fn(x) { x })
}

pub fn set_timeout_nilled(delay: Int, cb: fn() -> a) -> Nil {
  global.set_timeout(delay, cb)
  Nil
}

/// Get centered position for modal box in px
pub fn get_center_positioned_style_px() -> #(Float, Float) {
  let #(window_w, window_h) = dom.get_window_dimensions_px()
  let pos_x = window_h |> int.to_float()
  let pos_y = window_w |> int.to_float()
  let x = case pos_x |> float.divide(2.0) {
    Ok(v) -> v
    Error(Nil) -> {
      pos_x -. 1.0 |> float.divide(2.0) |> result.unwrap(0.0)
    }
  }
  let y = case pos_y |> float.divide(2.0) {
    Ok(v) -> v
    Error(Nil) -> {
      pos_y -. 1.0 |> float.divide(2.0) |> result.unwrap(0.0)
    }
  }
  #(x, y)
}
