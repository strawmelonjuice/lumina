//// Lumina > Web API types and decoders/encoders for server-client communication.

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
import gleam/json
import gleam/option.{None, Some}

/// Message types for websocket communication from server to client.
pub type WsMsgFromServer {
  Greeting(greeting: String)
  RegisterPrecheckResponse(ok: Bool, why: String)
  AuthenticationSuccess(username: String, token: String)
  AuthenticationFailure
  TimeLineResponse(
    timeline_name: String,
    timeline_id: String,
    /// List of post ids as string.
    items: List(String),
    /// Total number of posts in timeline
    total_count: Int,
    /// Current page number
    page: Int,
    /// Whether there are more pages available
    has_more: Bool,
  )
  OwnUserInformationResponse(
    username: String,
    email: String,
    // Optional field populated with mime type and base64 of a profile picture.
    avatar: option.Option(#(String, String)),
    uuid: String,
    /// Number of unread notifications, a timeline request for "notifications" can be used to get the actual notifications and fill the cache.
    unread_notifications: Int,
  )
  Undecodable
}

pub fn ws_msg_from_server_decoder() -> decode.Decoder(WsMsgFromServer) {
  use variant <- decode.field("type", decode.string)

  case variant {
    "auth_success" -> {
      use username <- decode.field("username", decode.string)
      use token <- decode.field("token", decode.string)
      decode.success(AuthenticationSuccess(username:, token:))
    }
    "auth_failure" -> {
      decode.success(AuthenticationFailure)
    }
    "unknown" -> decode.success(Undecodable)
    "register_precheck_response" -> {
      use ok <- decode.field("ok", decode.bool)
      use why <- decode.field("why", decode.string)
      decode.success(RegisterPrecheckResponse(ok, why))
    }
    "greeting" -> {
      use greeting <- decode.field("greeting", decode.string)
      decode.success(Greeting(greeting:))
    }
    "timeline_response" -> {
      echo "Decoding timeline response: " <> variant
      use timeline_name <- decode.field("timeline_name", decode.string)
      use timeline_id <- decode.field("timeline_id", decode.string)
      use items <- decode.field("post_ids", decode.list(decode.string))
      use total_count <- decode.field("total_count", decode.int)
      use page <- decode.field("page", decode.int)
      use has_more <- decode.field("has_more", decode.bool)
      decode.success(TimeLineResponse(
        timeline_name:,
        timeline_id:,
        items:,
        total_count:,
        page:,
        has_more:,
      ))
    }
    "own_user_information_response" -> {
      use username <- decode.field("username", decode.string)
      use email <- decode.field("email", decode.string)
      use unread_notifications <- decode.field(
        "unread_notifications",
        decode.int,
      )
      // avatar may be null or an array [mime, base64]
      use avatar_list_opt <- decode.field(
        "avatar",
        decode.optional(decode.list(decode.string)),
      )
      let avatar = case avatar_list_opt {
        Some(list) ->
          case list {
            [mime, b64] -> Some(#(mime, b64))
            _ -> None
          }
        None -> None
      }
      use uuid <- decode.field("uuid", decode.string)
      decode.success(OwnUserInformationResponse(
        username:,
        email:,
        avatar:,
        uuid:,
        unread_notifications:,
      ))
    }
    g -> {
      decode.failure(Undecodable, g)
    }
  }
}

pub fn encode_ws_msg_from_server(
  ws_msg_from_server: WsMsgFromServer,
) -> json.Json {
  case ws_msg_from_server {
    Greeting(greeting:) ->
      json.object([
        #("type", json.string("greeting")),
        #("greeting", json.string(greeting)),
      ])
    RegisterPrecheckResponse(ok:, why:) ->
      json.object([
        #("type", json.string("register_precheck_response")),
        #("ok", json.bool(ok)),
        #("why", json.string(why)),
      ])
    AuthenticationSuccess(username:, token:) ->
      json.object([
        #("type", json.string("authentication_success")),
        #("username", json.string(username)),
        #("token", json.string(token)),
      ])
    AuthenticationFailure ->
      json.object([
        #("type", json.string("authentication_failure")),
      ])
    TimeLineResponse(
      timeline_name:,
      timeline_id:,
      items:,
      total_count:,
      page:,
      has_more:,
    ) ->
      json.object([
        #("type", json.string("time_line_response")),
        #("timeline_name", json.string(timeline_name)),
        #("timeline_id", json.string(timeline_id)),
        #("items", json.array(items, json.string)),
        #("total_count", json.int(total_count)),
        #("page", json.int(page)),
        #("has_more", json.bool(has_more)),
      ])
    OwnUserInformationResponse(
      username:,
      email:,
      avatar:,
      uuid:,
      unread_notifications:,
    ) ->
      json.object([
        #("type", json.string("own_user_information_response")),
        #("username", json.string(username)),
        #("email", json.string(email)),
        #("avatar", case avatar {
          None -> json.null()
          Some(value) ->
            json.preprocessed_array([
              json.string(value.0),
              json.string(value.1),
            ])
        }),
        #("uuid", json.string(uuid)),
        #("unread_notifications", json.int(unread_notifications)),
      ])
    Undecodable ->
      json.object([
        #("type", json.string("undecodable")),
      ])
  }
}

pub type ClientKind {
  WebClient
  NativeImplementation(String)
}

/// Message types for websocket communication from client to server.
pub type WsMsgFromClient {
  Introduction(client_kind: ClientKind, try_revive: option.Option(String))
  OwnUserInformationRequest
  LoginAuthenticationRequest(email_username: String, password: String)
  RegisterRequest(email: String, username: String, password: String)
  TimeLineRequest(timeline_name: String, page: Int)
  RegisterPrecheck(
    email: String,
    username: String,
    // Password only once? Yes, the equal password check is done in the view/update themselves.
    password: String,
  )
  PostContentRequest(post_id: String)
}

pub fn encode_ws_msg_from_client(message: WsMsgFromClient) -> json.Json {
  case message {
    Introduction(client_kind:, try_revive:) ->
      json.object([
        #("type", json.string("introduction")),
        #(
          "client_kind",
          json.string(case client_kind {
            WebClient -> "web"
            NativeImplementation(implname) -> "client:" <> implname
          }),
        ),
        #("try_revive", case try_revive {
          None -> json.null()
          Some(token) -> json.string(token)
        }),
      ])
    OwnUserInformationRequest ->
      json.object([#("type", json.string("own_user_information_request"))])
    LoginAuthenticationRequest(email_username, password) ->
      json.object([
        #("type", json.string("login_authentication_request")),
        #("email_username", json.string(email_username)),
        #("password", json.string(password)),
      ])

    RegisterRequest(email, username, password) ->
      json.object([
        #("type", json.string("register_request")),
        #("email", json.string(email)),
        #("username", json.string(username)),
        #("password", json.string(password)),
      ])
    RegisterPrecheck(email, username, password) ->
      json.object([
        #("type", json.string("register_precheck")),
        #("email", json.string(email)),
        #("username", json.string(username)),
        #("password", json.string(password)),
      ])
    TimeLineRequest(timeline_name:, page:) ->
      json.object([
        #("type", json.string("timeline_request")),
        #("by_name", json.string(timeline_name)),
        #("page", json.int(page)),
      ])
    PostContentRequest(post_id:) -> {
      json.object([
        #("type", json.string("post_view_request")),
        #("post_id", json.string(post_id)),
      ])
    }
  }
}

pub fn ws_msg_from_client_decoder() -> decode.Decoder(WsMsgFromClient) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "introduction" -> {
      use client_kind <- decode.field(
        "client_kind",
        decode.then(decode.string, fn(client_kind_string) {
          case client_kind_string {
            "client:" <> implementation ->
              decode.success(NativeImplementation(implementation))
            "web" -> decode.success(WebClient)
            _ -> decode.failure(WebClient, expected: "Client kind")
          }
        }),
      )
      use try_revive <- decode.optional_field(
        "try_revive",
        None,
        decode.optional(decode.string),
      )
      decode.success(Introduction(client_kind:, try_revive:))
    }
    "own_user_information_request" -> decode.success(OwnUserInformationRequest)
    "login_authentication_request" -> {
      use email_username <- decode.field("email_username", decode.string)
      use password <- decode.field("password", decode.string)
      decode.success(LoginAuthenticationRequest(email_username:, password:))
    }
    "register_request" -> {
      use email <- decode.field("email", decode.string)
      use username <- decode.field("username", decode.string)
      use password <- decode.field("password", decode.string)
      decode.success(RegisterRequest(email:, username:, password:))
    }
    "time_line_request" -> {
      use timeline_name <- decode.field("timeline_name", decode.string)
      use page <- decode.field("page", decode.int)
      decode.success(TimeLineRequest(timeline_name:, page:))
    }
    "register_precheck" -> {
      use email <- decode.field("email", decode.string)
      use username <- decode.field("username", decode.string)
      use password <- decode.field("password", decode.string)
      decode.success(RegisterPrecheck(email:, username:, password:))
    }
    "post_content_request" -> {
      use post_id <- decode.field("post_id", decode.string)
      decode.success(PostContentRequest(post_id:))
    }
    _ -> decode.failure(OwnUserInformationRequest, "WsMsgFromClient")
  }
}
