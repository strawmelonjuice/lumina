//// Lumina > Client > Helper functions
//// This module contains helper functions used across the Lumina client.

// Lumina/Peonies
// Copyright (C) 2018-2026 MLC 'Strawmelonjuice' Bloeiman and contributors.
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
// This software is provided "AS IS", WITHOUT WARRANTY OF ANY KIND.
// See the Licence for the specific language governing permissions and limitations.

import gleam/int
import gleam/list
import lumina_client/dom
import lumina_client/model_type.{type LoginFields, type Msg}
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

/// Get centered position for modal box in px
pub fn get_center_positioned_style_px() -> #(Float, Float) {
  let #(window_w, window_h) = dom.get_window_dimensions_px() |> echo
  let x_int = window_h / 2
  let y_int = window_w / 2
  let x = int.to_float(x_int)
  let y = int.to_float(y_int)
  #(x, y)
}
