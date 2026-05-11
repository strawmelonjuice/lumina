//// Lumina > Client > View > Application/Homepage > Post Editor
//// This module contains the post editor.

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

import gleam/dict
import lumina_client/model_type.{type Msg}
import lumina_client/view/common_view_parts/svgs
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

/// Post editor's exposed view function.
/// Parameters:
///  params - dict of String to String, these are params specific to the post editor modal, and also exist in the wider model, beit behind a wrapped option.
///  model - the full application model, in case the post editor needs to read from it
pub fn main(
  params: dict.Dict(String, String),
  model: model_type.Model,
) -> Element(Msg) {
  // Placeholder implementation
  html.div([attribute.class("tabs tabs-lift h-full")], [
    html.label([attribute.class("tab")], [
      html.input([attribute.name("editortypeswitch"), attribute.type_("radio")]),
      svgs.camera("class size-4 me-2"),

      html.text(" Snap "),
    ]),
    html.label([attribute.class("tab")], [
      html.input([
        attribute.name("editortypeswitch"),
        attribute.type_("radio"),
        attribute.checked(True),
      ]),
      svgs.pen("class size-4 me-2"),
      html.text(" Jot "),
    ]),
    html.div([attribute.class("tab-content bg-base-100 border-base-300 p-6")], [
      text_post_editor(params, model),
    ]),
    html.div([attribute.class("tab-content bg-base-100 border-base-300 p-6")], [
      media_post_editor(params, model),
    ]),
    html.label([attribute.class("tab")], [
      html.input([attribute.name("editortypeswitch"), attribute.type_("radio")]),
      svgs.pen_paper("class size-4 me-2"),

      html.text(" Compose "),
    ]),
    html.div([attribute.class("tab-content bg-base-100 border-base-300 p-6")], [
      article_post_editor(params, model),
    ]),
  ])
}

fn text_post_editor(
  params: dict.Dict(String, String),
  _model: model_type.Model,
) -> Element(Msg) {
  html.div([], [
    html.text("This is the text post editor!"),
  ])
}

fn media_post_editor(
  params: dict.Dict(String, String),
  _model: model_type.Model,
) -> Element(Msg) {
  html.div([], [
    html.text("This is the media post editor!"),
  ])
}

fn article_post_editor(
  params: dict.Dict(String, String),
  _model: model_type.Model,
) -> Element(Msg) {
  html.div([], [
    html.text("This is the article post editor!"),
  ])
}
