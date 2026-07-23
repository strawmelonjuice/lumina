//// **Lumina > Backend > HTTP Server >**
//// # Component websockets
////
//// Deals with the websockets between server components and the browser, receiving user events and sending out DOM patches.

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
import ewe
import gleam/erlang/process.{type Subject}
import gleam/json
import lumina_server/server/component/login
import lumina_server/server/component/signup
import lumina_server/server/components/shared as lumina_server_components
import lustre
import lustre/server_component

// Login component ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
pub fn login(
  from: lumina_server_components.ComponentInitialisation,
  websocket: fn(
    fn(
      ewe.WebsocketConnection,
      process.Selector(server_component.ClientMessage(login.Message)),
    ) ->
      #(
        #(
          Subject(server_component.ClientMessage(login.Message)),
          lustre.Runtime(login.Message),
        ),
        process.Selector(server_component.ClientMessage(login.Message)),
      ),
    fn(
      ewe.WebsocketConnection,
      #(
        Subject(server_component.ClientMessage(login.Message)),
        lustre.Runtime(login.Message),
      ),
      ewe.WebsocketMessage(server_component.ClientMessage(login.Message)),
    ) ->
      ewe.WebsocketNext(
        #(
          Subject(server_component.ClientMessage(login.Message)),
          lustre.Runtime(login.Message),
        ),
        server_component.ClientMessage(login.Message),
      ),
    fn(
      ewe.WebsocketConnection,
      #(
        Subject(server_component.ClientMessage(login.Message)),
        lustre.Runtime(login.Message),
      ),
    ) -> Nil,
  ) -> response,
) -> response {
  websocket(
    fn(
      _: ewe.WebsocketConnection,
      _: process.Selector(server_component.ClientMessage(login.Message)),
    ) -> #(
      #(
        Subject(server_component.ClientMessage(login.Message)),
        lustre.Runtime(login.Message),
      ),
      process.Selector(server_component.ClientMessage(login.Message)),
    ) {
      let component = login.component()
      let assert Ok(component) = lustre.start_server_component(component, from)

      let self = process.new_subject()
      let selector =
        process.new_selector()
        |> process.select(self)
      let selector = process.select(selector, self)

      server_component.register_subject(self)
      |> lustre.send(to: component)
      #(#(self, component), selector)
    },
    fn(
      connection: ewe.WebsocketConnection,
      state: #(
        Subject(server_component.ClientMessage(login.Message)),
        lustre.Runtime(login.Message),
      ),
      message: ewe.WebsocketMessage(
        server_component.ClientMessage(login.Message),
      ),
    ) {
      case message {
        ewe.Text(json) -> {
          case json.parse(json, server_component.runtime_message_decoder()) {
            Ok(runtime_message) -> lustre.send(state.1, runtime_message)
            Error(_) -> Nil
          }

          ewe.websocket_continue(state)
        }

        ewe.Binary(_) -> {
          ewe.websocket_continue(state)
        }

        ewe.User(client_message) -> {
          let json = server_component.client_message_to_json(client_message)
          let assert Ok(_) =
            ewe.send_text_frame(connection, json.to_string(json))

          ewe.websocket_continue(state)
        }
      }
    },
    fn(
      _,
      state: #(
        Subject(server_component.ClientMessage(login.Message)),
        lustre.Runtime(login.Message),
      ),
    ) -> Nil {
      lustre.shutdown()
      |> lustre.send(to: state.1)
    },
  )
}

// Register ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
pub fn signup(
  from: lumina_server_components.ComponentInitialisation,
  websocket: fn(
    fn(
      ewe.WebsocketConnection,
      process.Selector(server_component.ClientMessage(signup.Message)),
    ) ->
      #(
        #(
          Subject(server_component.ClientMessage(signup.Message)),
          lustre.Runtime(signup.Message),
        ),
        process.Selector(server_component.ClientMessage(signup.Message)),
      ),
    fn(
      ewe.WebsocketConnection,
      #(
        Subject(server_component.ClientMessage(signup.Message)),
        lustre.Runtime(signup.Message),
      ),
      ewe.WebsocketMessage(server_component.ClientMessage(signup.Message)),
    ) ->
      ewe.WebsocketNext(
        #(
          Subject(server_component.ClientMessage(signup.Message)),
          lustre.Runtime(signup.Message),
        ),
        server_component.ClientMessage(signup.Message),
      ),
    fn(
      ewe.WebsocketConnection,
      #(
        Subject(server_component.ClientMessage(signup.Message)),
        lustre.Runtime(signup.Message),
      ),
    ) -> Nil,
  ) -> response,
) -> response {
  websocket(
    fn(
      _: ewe.WebsocketConnection,
      _: process.Selector(server_component.ClientMessage(signup.Message)),
    ) -> #(
      #(
        Subject(server_component.ClientMessage(signup.Message)),
        lustre.Runtime(signup.Message),
      ),
      process.Selector(server_component.ClientMessage(signup.Message)),
    ) {
      let component = signup.component()
      //TODO: Investigate how to also supervise these
      let assert Ok(component) = lustre.start_server_component(component, from)

      let self = process.new_subject()
      let selector =
        process.new_selector()
        |> process.select(self)
      let selector = process.select(selector, self)

      server_component.register_subject(self)
      |> lustre.send(to: component)
      #(#(self, component), selector)
    },
    fn(
      connection: ewe.WebsocketConnection,
      state: #(
        Subject(server_component.ClientMessage(signup.Message)),
        lustre.Runtime(signup.Message),
      ),
      message: ewe.WebsocketMessage(
        server_component.ClientMessage(signup.Message),
      ),
    ) {
      case message {
        ewe.Text(json) -> {
          case json.parse(json, server_component.runtime_message_decoder()) {
            Ok(runtime_message) -> lustre.send(state.1, runtime_message)
            Error(_) -> Nil
          }

          ewe.websocket_continue(state)
        }

        ewe.Binary(_) -> {
          ewe.websocket_continue(state)
        }

        ewe.User(client_message) -> {
          let json = server_component.client_message_to_json(client_message)
          let assert Ok(_) =
            ewe.send_text_frame(connection, json.to_string(json))

          ewe.websocket_continue(state)
        }
      }
    },
    fn(
      _,
      state: #(
        Subject(server_component.ClientMessage(signup.Message)),
        lustre.Runtime(signup.Message),
      ),
    ) -> Nil {
      lustre.shutdown()
      |> lustre.send(to: state.1)
    },
  )
}
