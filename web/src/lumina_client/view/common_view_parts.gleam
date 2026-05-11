//// Lumina > Client > View > Application/Homepage > Common View Parts
//// This module contains common view parts used across Lumina client views.

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

import gleam/option.{Some}
import lumina_client/model_type.{type Msg, type Page}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn common_view_parts(
  main_body: List(Element(Msg)),
  with_menu menuitems: List(Element(Msg)),
) {
  html.div([attribute.class("font-sans")], [
    html.div([attribute.class("navbar bg-base-200 shadow-sm")], [
      html.div([attribute.class("flex-none")], [
        html.button([attribute.class("")], [
          html.img([
            attribute.src("/static/logo.svg"),
            attribute.alt("Lumina logo"),
            attribute.class("h-8"),
          ]),
        ]),
      ]),
      html.div([attribute.class("flex-1")], [
        html.a([attribute.class("btn btn-ghost text-xl font-logo")], [
          element.text("Lumina"),
        ]),
      ]),
      html.div([attribute.class("flex-none")], [
        html.ul(
          [attribute.class("menu menu-horizontal px-1 font-menuitems")],
          menuitems,
        ),
      ]),
    ]),
    html.div(
      [attribute.class("bg-base-100 h-screen max-h-[calc(100vh-4rem)]")],
      main_body,
    ),
  ])
}

pub fn href(route: Page) -> attribute.Attribute(Msg) {
  case route {
    model_type.Landing -> "/"
    model_type.Register(_, _) -> "/signup/"
    model_type.Login(_, _) -> "/login/"
    model_type.HomeTimeline(timeline_name: Some(m), modal:) ->
      "/timeline/" <> m <> "/"
    model_type.HomeTimeline(timeline_name: option.None, modal:) -> "/home/"
    model_type.Licence -> "/licence"
    model_type.NotFound(_) -> "/404"
  }
  |> attribute.href()
}
