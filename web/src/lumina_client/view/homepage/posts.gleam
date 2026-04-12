//// Lumina > Client > View > Application/Homepage > Posts
//// This module contains the homepage timeline posts view as well as handling the rendering of posts on their own.

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

import gleam/dict
import gleam/list
import lumina_client/model_type.{
  type CachedTimeline, type Model, type Msg, CachedTimeline,
}
import lustre/attribute.{attribute}
import lustre/element.{type Element}
import lustre/element/html

pub fn element_from_id(model: Model, post_id: String) -> Element(Msg) {
  let post = dict.get(model.cache.cached_posts, post_id)

  html.div(
    [
      attribute.class(
        "flex flex-col gap-2 p-4 m-8 bg-base-300 text-base-300-content rounded-md w-full bg-opacity-25 font-content",
        // Other candidates were:
      // // "flex flex-col gap-2 p-4 m-8 bg-secondary text-secondary-content rounded-md w-full",
      // // "flex flex-col gap-2 p-4 m-8 bg-info text-info-content rounded-md w-full bg-opacity-25",
      ),
    ],
    case post {
      Ok(_) -> todo as "Post rendering not yet implemented"
      _ -> [
        html.p([], [
          element.text("Loading post..."),
          html.span(
            [
              attribute.class("loading loading-spinner loading-md float-right"),
            ],
            [],
          ),
        ]),
      ]
    }
      |> list.append([
        html.small([attribute.class("opacity-50 text-xs font-script")], [
          element.text("ID:" <> post_id),
        ]),
      ]),
  )
}
