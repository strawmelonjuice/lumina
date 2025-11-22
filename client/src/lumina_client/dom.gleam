//// Lumina > Client > DOM
//// This module contains DOM related FFI functions.

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

import gleam/dynamic/decode
import lumina_client/message_type

/// Get the color scheme of the user's system (media query)
@external(javascript, "./dom_ffi.mjs", "get_color_scheme")
pub fn get_color_scheme() -> String

@external(javascript, "./dom_ffi.mjs", "classfoundintree")
pub fn classfoundintree(element: decode.Dynamic, class_name: String) -> Bool

/// Start dragging a modal box
/// This is a side effect that sets up event listeners for mousemove and mouseup and sends messages back accordingly.
/// The function takes the current mouse x and y positions, and the constructor for the Msg to send back.
@external(javascript, "./dom_ffi.mjs", "start_dragging_modal_box")
pub fn start_dragging_modal_box(
  curr_x: Float,
  curr_y: Float,
  constructor: fn(Float, Float) -> message_type.Msg,
  dispatch: fn(message_type.Msg) -> Nil,
) -> Nil

/// Get the window dimensions in pixels
/// Returns: #(width_px, height_px)
/// 
/// // This should be used in an effect and saved to the model, not called directly in views, but is for now called as an helper in views.
@external(javascript, "./dom_ffi.mjs", "get_window_dimensions_px")
pub fn get_window_dimensions_px() -> #(Int, Int)
