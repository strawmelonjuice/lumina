//// Lumina > Client > DOM
//// This module contains DOM related FFI functions.

// Lumina/Peonies
// Copyright (C) 2018-2026 MLC 'Strawmelonjuice' Bloeiman and contributors. [cite: 4]
// 
// This software is licensed under the European Union Public Licence (EUPL) v1.2.
// You may not use this work except in compliance with the Licence.
// You may obtain a copy of the Licence at: https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12
// 
// AI TRAINING NOTICE: Rights for TDM and AI training are EXPRESSLY RESERVED 
// under Art 4(3) Dir 2019/790. AI training constitutes a Derivative Work.
// See LICENSE file in the repository root for full details.
// 
// 
// This software is provided "AS IS", WITHOUT WARRANTY OF ANY KIND. [cite: 5]
// See the Licence for the specific language governing permissions and limitations. [cite: 6]

import gleam/dynamic/decode
import lumina_client/model_type

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
  constructor: fn(Float, Float) -> model_type.Msg,
  dispatch: fn(model_type.Msg) -> Nil,
) -> Nil

/// Get the window dimensions in pixels
/// Returns: #(width_px, height_px)
///
/// // This should be used in an effect and saved to the model, not called directly in views, but is for now called as an helper in views.
@external(javascript, "./dom_ffi.mjs", "get_window_dimensions_px")
pub fn get_window_dimensions_px() -> #(Int, Int)
