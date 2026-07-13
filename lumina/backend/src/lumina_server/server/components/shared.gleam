//// **Lumina > Server >**
//// # Web components - Shared
////
//// Shared parts related to and used by the server components

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
import gleam/erlang/process
import gleam/list
import group_registry.{type GroupRegistry}
import lumina_server/data
import lustre/effect.{type Effect}
import lustre/server_component

// Shared types ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Re-exports
/// Messages sent between either server components or from the server to it's components.
pub type GlobalMessage =
  data.GlobalMessage

/// Messages sent between components --or sent from the server to it's components-- within a specific session.
pub type SessionMessage =
  data.SessionMessage

/// Represents a controlled input field value and an error message if invalid.
/// First value is True when the value is set as initial value, and should be set to False after any update.
pub type ControlledInput(d) {
  ControlledInput(initial: Bool, value: d, validity: Result(Nil, String))
}

/// Default data from which a component is initialised.
pub type ComponentInitialisation {
  ComponentInitialisation(global_context: data.Globals, session_id: String)
}

// Shared functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

/// Allows a component to receive messages, both to the global topic and to it's session topic.
@internal
pub fn subscribe(
  global_app_registry global_app_registry: GroupRegistry(GlobalMessage),
  session_app_registry session_app_registry: GroupRegistry(SessionMessage),
  session_id session_id: String,
  on_global_message handle_global_message: fn(GlobalMessage) -> message,
  on_session_message handle_session_message: fn(SessionMessage) -> message,
) -> Effect(message) {
  use _, _ <- server_component.select
  let global_subject =
    group_registry.join(global_app_registry, "global", process.self())
  let session_subject =
    group_registry.join(session_app_registry, session_id, process.self())

  let selector =
    process.merge_selector(
      process.new_selector()
        |> process.select_map(session_subject, handle_session_message),
      process.new_selector()
        |> process.select_map(global_subject, handle_global_message),
    )
  selector
}

/// Broadcasts a message from a component to the session topic.
@internal
pub fn broadcast_sessionwide(
  registry: GroupRegistry(SessionMessage),
  session_id: String,
  message: SessionMessage,
) -> Effect(any) {
  use _ <- effect.from
  use member <- list.each(group_registry.members(registry, session_id))
  process.send(member, message)
}

/// Broadcasts a message from a component to the global topic.
@internal
pub fn broadcast_globally(
  registry: GroupRegistry(GlobalMessage),
  message: GlobalMessage,
) -> Effect(any) {
  use _ <- effect.from
  use member <- list.each(group_registry.members(registry, "global"))
  process.send(member, message)
}
