//// Lumina > Client
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

import gleam/option.{None}
import lumina_client/model_type
import lumina_client/view
import lustre
import lustre/effect

// Entrypoints ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/// Entry point for mainly the Rust backend, which doesn't use server-components and does a server-client based
/// approach instead.
pub fn main() -> Result(lustre.Runtime(model_type.Msg), lustre.Error) {
  // This module was a mess, and the lustre_websocket package is outdated.
  // Good reason for me to throw it all out amidst a refactor!
  // - Mar
  let assert Ok(_) =
    lustre.start(
      app(websocket_based_updates),
      "#app",
      receives_websocket_messages(),
    )
}

/// Entrypoint to interface directly, usable in server components
pub fn app(
  update: fn(model_type.Model, model_type.Msg) ->
    #(model_type.Model, effect.Effect(model_type.Msg)),
) -> lustre.App(effect.Effect(model_type.Msg), model_type.Model, model_type.Msg) {
  lustre.application(init:, update:, view: view.view)
}

// Common functionality ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

/// Init function
/// Inherits effects, because these depend on where the init is ran from.
fn init(
  with_effect: effect.Effect(model_type.Msg),
) -> #(model_type.Model, effect.Effect(model_type.Msg)) {
  #(
    model_type.Model(
      page: model_type.Landing,
      user: None,
      token: None,
      status: Ok(Nil),
    ),
    with_effect,
  )
}

// Websockets ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

/// Update function used mainly with the Rust backend
fn websocket_based_updates(
  model: model_type.Model,
  msg: model_type.Msg,
) -> #(model_type.Model, effect.Effect(model_type.Msg)) {
  #(model, effect.none())
}

fn receives_websocket_messages() -> effect.Effect(model_type.Msg) {
  use dispatch <- effect.from
  let message_parser = fn(incoming) {
    case incoming {
      _ -> todo
    }
    |> dispatch
  }
  let assert Ok(Nil) = self_restoring_websocket(message_parser)
    as "The self-restoring-websocket could not connect, this may be because you are running this code outside of a browser."
  Nil
}

/// This creates a browser-to-server websocket connection using js FFI, which is then stored in `window.connection`, this means
/// no Gleam can touch it.
/// Storing it in `window` also means it's implementation stays there where it's used: In the browser.
///
/// If the websocket experiences a disconnect, it'll modify the DOM to display a reconnection modal over #app,
/// if it still fails, it'll replace the entire body with an error screen, thereby crashing the Lustre runtime.
///
/// Since this implementation depends entirely on the browser, it'll always return an error when not running in a browser.
///
/// Any messages of type (json-)String that the websocket receives, are send into the callback function.
///
/// The `./lumina_client/websocket_ffi.mjs` file also contains a simple function, taking in a (json) String, and
/// sending it to the server.
@external(javascript, "./lumina_client/websocket_ffi.mjs", "createSelfRestoringWebsocket")
fn self_restoring_websocket(_on_message: fn(String) -> Nil) -> Result(Nil, Nil) {
  Error(Nil)
}
