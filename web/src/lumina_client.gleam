//// Lumina > Web-end
//// Main entry point for Lumina's web frontend. This module contains all side-effects, the update function. Lustre initialisation and more.
////
//// It'll also contain one of the two update() function implementations, the websocket one. Since the Gleam backend
//// now consumes this frontend as a server component, the websocket is implemented as a 'plug-in' solution.
//// returning the server's (json) String response, which is then parseable on the Gleam end.

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

// Imports ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

import lumina_client/message.{type Message}
import lumina_client/model_type
import lumina_client/view
import lustre/effect
import off_topic

// Entrypoints ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

pub fn main() {
  panic as "Currently, running the frontend as a js bundle is unsupported, as focus is on server components."
}

/// Entrypoint to interface directly, usable in server components
pub fn app(
  update: fn(model_type.Model, Message) ->
    #(model_type.Model, effect.Effect(Message)),
) {
  off_topic.application(init:, update:, view: view.view, subscriptions:)
}

fn subscriptions(_model: model_type.Model) -> off_topic.Subscription(Message) {
  // for now
  off_topic.none()
}

// Common functionality ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

/// Init function
/// Inherits effects, because these depend on where the init is ran from.
fn init(_) -> #(model_type.Model, effect.Effect(Message)) {
  todo
}
