//// **Lumina > Server > Web components >**
//// # Login
////
//// Main component for the login page

// Lumina/Peonies
// Copyright (C) 2018-2026 MLC 'Strawmelonjuice' Bloeiman and contributors.
//
// This software is licensed under the European Union Public Licence (EUPL) v1.2.
// You may not use this work except in compliance with the Licence.
// You may obtain a copy of the Licence at: https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12
//
// AI TRAINING NOTICE: Rights for TDM and AI training are EXPRESSLY RESERVED
// under Art 4(3) Dir 2019/790. AI training constitutes a Derivative Work.
// See LICENCE file in the repository root for full details.
//
//
// This software is provided "AS IS", WITHOUT WARRANTY OF ANY KIND.
// See the Licence for the specific language governing permissions and limitations.

// Imports ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
import group_registry.{type GroupRegistry}
import lumina_server/server/components/shared.{
  type ComponentInitialisation, type GlobalMessage, type SessionMessage,
  subscribe,
} as lumina_server_components
import lustre.{type App}
import lustre/effect
import lustre/element
import lustre/element/html

// Main ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
pub fn component() -> App(ComponentInitialisation, Model, Message) {
  lustre.application(init, update, view)
}

// Model ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
pub opaque type Model {
  Model(
    global_app_registry: GroupRegistry(GlobalMessage),
    session_app_registry: GroupRegistry(SessionMessage),
  )
}

fn init(initialisationdata: ComponentInitialisation) {
  let lumina_server_components.ComponentInitialisation(
    global_app_registry:,
    session_app_registry:,
    session_id:,
  ) = initialisationdata
  let model = Model(global_app_registry:, session_app_registry:)
  #(
    model,
    subscribe(
      on_global_message: AppReceivedGlobalBroadcast,
      on_session_message: AppReceivedSessionMessage,
      global_app_registry:,
      session_app_registry:,
      session_id:,
    ),
  )
}

// Update ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

pub opaque type Message {
  AppReceivedGlobalBroadcast(GlobalMessage)
  AppReceivedSessionMessage(SessionMessage)
}

fn update(model: Model, message: Message) -> #(Model, effect.Effect(Message)) {
  case message {
    AppReceivedGlobalBroadcast(_) -> todo
    AppReceivedSessionMessage(_) -> todo
  }
}

// View ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
fn view(model: Model) -> element.Element(Message) {
  html.text("Hello")
}
