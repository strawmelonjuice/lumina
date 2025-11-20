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

//// Helper functions

import lumina_client/message_type.{type Msg}
import lustre/attribute
import plinth/javascript/global

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

pub fn set_timeout_nilled(delay: Int, cb: fn() -> a) -> Nil {
  global.set_timeout(delay, cb)
  Nil
}
