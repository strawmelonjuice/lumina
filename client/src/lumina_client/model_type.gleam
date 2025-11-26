//// Lumina > Client > Model
//// Lumina's model is the central source of truth for the client application state.

//	Lumina/Peonies
//	Copyright (C) 2018-2026 MLC 'Strawmelonjuice'  Bloeiman and contributors.
//
//	This program is free software: you can redistribute it and/or modify
//	it under the terms of the GNU Affero General Public License as published
//	by the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	This program is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU Affero General Public License for more details.
//
//	You should have received a copy of the GNU Affero General Public License
//	along with this program.  If not, see <https://www.gnu.org/licenses/>.

import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre_websocket

/// # Model
///
pub type Model {
  Model(
    /// Page currently browsing.
    page: Page,
    /// User, if known
    user: Option(User),
    /// WebSocket connection
    ws: WsConnectionStatus,
    /// Used to restore sessions
    token: Option(String),
    /// Used to show error screens on unrecoverable errors
    status: Result(Nil, String),
    /// To keep the client going while navigating, the websocket just requests certain data and then stores it in the model so that view can update once it's there
    /// Displaying some loading screen in between.
    /// Once it is there, this is where it's stored:
    cache: Cached,
    // /// Ticks are upped by one every 50ms since initialisation.
    // ticks: Int,
    /// Replaces ticks: Tracks if the client has been running for over 150ms
    has_been_running_for_150ms: Bool,
    /// Last time send_refresh_request was called, in unix timestamp seconds.
    /// If send_refresh_request(), it will update this value. If the last refresh request was over 30 seconds ago,
    /// the client will send a new refresh request to the server.
    last_refresh_request_time: Int,
  )
}

pub fn create_cache_inventory(model: Model) -> CacheInventory {
  let cache = model.cache
  let timelines =
    cache.cached_timelines
    |> dict.to_list()
    |> list.map(fn(timeline) {
      let timeline = timeline.1
      #(timeline.id, timeline.last_updated)
    })
  let users =
    cache.cached_users
    |> dict.to_list()
    |> list.map(fn(user) { #(user.0, { user.1 }.last_updated) })
  let posts =
    cache.cached_posts
    |> dict.to_list()
    |> list.map(fn(post) { #(post.0, { post.1 }.last_updated) })
  CacheInventory(timelines:, users:, posts:)
}

pub type CacheInventory {
  CacheInventory(
    /// Timelines by #(id, last_updated)
    timelines: List(#(String, Int)),
    /// Users by #(id, last_updated)
    users: List(#(String, Int)),
    /// Posts by #(id, last_updated)
    posts: List(#(String, Int)),
  )
}

pub type WsConnectionStatus {
  /// Before connection is created
  WsConnectionInitial
  /// An established socket
  WsConnectionConnected(lustre_websocket.WebSocket)
  /// A disconnected socket
  WsConnectionDisconnected
  /// A non-connected socket, may also occur while connecting.
  /// This'll either turn into a `WsConnectionConnected` or an `WsConnectionDisconnected`.
  WsConnectionDisconnecting
  /// Retrying to connect.
  WsConnectionRetrying
}

pub type Cached {
  Cached(
    /// Posts are requested if nonexistent in the dict, and a loading screen can be displayed immediately
    /// The server will afterwards send all corresponding comments, which can also be stored and, if deemed
    /// necessary by the Lustre runtime, also update the DOM.
    ///
    /// Commnents under a post are in fact stored as a timeline and possess the exact same capabilities.
    ///
    /// `Dict(post_uuid, CachedPost)`
    cached_posts: dict.Dict(String, CachedPost),
    /// Users received:
    cached_users: Dict(String, CachedUser),
    /// Cached timelines with pagination support
    /// `Dict(timeline_id, CachedTimeline)`
    cached_timelines: Dict(String, CachedTimeline),
  )
}

pub type CachedUser {
  CachedUser(
    /// Source instance. 'local' by default, hostname if external.
    source_instance: String,
    /// Username
    username: String,
    /// Avatar as uri string, either a full URL or a base64-encoded 'data:'-string
    avatar: String,
    /// Last updated timestamp (seconds) to help with cache invalidation
    last_updated: Int,
  )
}

pub type CachedTimeline {
  CachedTimeline(
    /// Timeline ID, as given by the server
    id: String,
    /// Post IDs for all loaded pages, organized by page number
    pages: Dict(Int, List(String)),
    /// Total number of posts in the timeline
    total_count: Int,
    /// Current page being displayed
    current_page: Int,
    /// Whether there are more pages available
    has_more: Bool,
    /// Last updated timestamp (seconds) to help with cache invalidation
    last_updated: Int,
  )
}

pub type CachedPost {
  CachedPost(
    /// Post ID -- taken from the current instance, we don't have to deal with remote IDs here.
    id: String,
    /// Source instance. 'local' by default, hostname if external.
    source_instance: String,
    /// User id of poster, which is why the source_instance matters.
    /// This means that client will do a lookup and stores the user once it gets it.
    author_id: String,
    /// Unix timestamp of the moment of posting
    timestamp: Int,
    /// Last updated timestamp (seconds) to help with cache invalidation
    last_updated: Int,
    /// Cached post interior
    interior: CachedPostInterior,
  )
}

pub type CachedPostInterior {
  /// A media post, embedded is either webp or mp4.
  CachedMediaPost(
    /// Media description
    description: String,
    /// Media files as base64-encoded 'data:'-strings
    /// Try matching on the substring of content-type
    /// to determine the valid HTML embed element to put it in.
    medias: List(String),
  )
  /// The 'default', bluesky-like post, contains markdown and not much else.
  CachedTextualPost(
    /// Markdown content.
    content: String,
  )
  /// Article posts
  CachedArticlePost(
    /// Title of the article post
    title: String,
    /// Markdown content
    content: String,
  )
}

/// # Page
///
/// Lumina has always been an SPA behind the login page, splitting the three "main" pages: Login, Signup, and Home from "subpages". Home contained subpages like Dashboard, Profile, and Settings, etc.
/// In this model, Login and Dashboard would be equal. The model keeps track of the current page and the user's authentication status.
/// The Page type is, pretty explanatory, an enum of all the pages in the app. Nested if needed, to track fields like the current tab in the Dashboard or the username form field in the login page.
pub type Page {
  Landing
  Register(fields: RegisterPageFields, ready: Option(Result(Nil, String)))
  Login(fields: LoginFields, success: Option(Bool))
  HomeTimeline(
    timeline_name: Option(String),
    modal: Option(#(String, Dict(String, String))),
  )
}

fn encode_page(page: Page) -> json.Json {
  case page {
    Landing -> json.object([#("type", json.string("landing"))])
    Register(fields:, ready:) ->
      json.object([
        #("type", json.string("register")),
        #("fields", {
          let RegisterPageFields(
            usernamefield:,
            emailfield:,
            passwordfield:,
            passwordconfirmfield:,
          ) = fields
          json.object([
            #("usernamefield", json.string(usernamefield)),
            #("emailfield", json.string(emailfield)),
            #("passwordfield", json.string(passwordfield)),
            #("passwordconfirmfield", json.string(passwordconfirmfield)),
          ])
        }),
        #("ready", {
          let _ = ready
          json.null()
        }),
      ])
    Login(fields:, success: _) ->
      json.object([
        #("type", json.string("login")),
        #("fields", {
          let LoginFields(emailfield:, passwordfield:) = fields
          json.object([
            #("emailfield", json.string(emailfield)),
            #("passwordfield", json.string(passwordfield)),
          ])
        }),
      ])
    HomeTimeline(timeline_name:, modal:) ->
      json.object(
        [#("type", json.string("home_timeline"))]
        |> list.append(case timeline_name {
          None -> []
          Some(i) -> [#("timeline_name", json.string(i))]
        })
        |> list.append(case modal {
          None -> []
          Some(i) -> [#("modal", json.string(i.0))]
        }),
      )
  }
}

fn page_decoder() -> decode.Decoder(Page) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "landing" -> decode.success(Landing)
    "register" -> {
      use fields <- decode.field("fields", {
        use usernamefield <- decode.field("usernamefield", decode.string)
        use emailfield <- decode.field("emailfield", decode.string)
        use passwordfield <- decode.field("passwordfield", decode.string)
        use passwordconfirmfield <- decode.field(
          "passwordconfirmfield",
          decode.string,
        )
        decode.success(RegisterPageFields(
          usernamefield:,
          emailfield:,
          passwordfield:,
          passwordconfirmfield:,
        ))
      })
      let ready = None
      decode.success(Register(fields:, ready:))
    }
    "login" -> {
      use fields <- decode.field("fields", {
        use emailfield <- decode.field("emailfield", decode.string)
        use passwordfield <- decode.field("passwordfield", decode.string)
        decode.success(LoginFields(emailfield:, passwordfield:))
      })
      decode.success(Login(fields:, success: None))
    }
    "home_timeline" -> {
      use timeline_name: Option(String) <- decode.optional_field(
        "timeline_name",
        None,
        decode.optional(decode.string),
      )
      use modal_n <- decode.optional_field(
        "modal",
        None,
        decode.optional(decode.string),
      )
      let modal = modal_n |> option.map(fn(m) { #(m, dict.new()) })
      decode.success(HomeTimeline(timeline_name:, modal:))
    }
    _ -> decode.failure(Landing, "Page")
  }
}

pub type RegisterPageFields {
  RegisterPageFields(
    usernamefield: String,
    emailfield: String,
    passwordfield: String,
    passwordconfirmfield: String,
  )
}

pub type LoginFields {
  LoginFields(emailfield: String, passwordfield: String)
}

/// # User
///
/// The User type is a struct that holds the user's data. It's an Option in the Model because the user might not be logged in.
/// Authentication STATUS is not stored in the Model, but in the websocket connection (the token is). The user is only stored in the Model for the UI to easy displaying the user's data.
pub type User {
  User(username: String, email: String, avatar: String)
}

pub type SerializableModel {
  SerializableModel(
    // Only storing page name for now. Maybe I'll do full Page type, so that fields can be stored as well some day.
    // Oh, nevermind
    page: Page,
    /// Token, so that sessions can be revived.
    token: Option(String),
  )
}

pub fn serialize_serializable_model(
  serializable_model: SerializableModel,
) -> json.Json {
  let SerializableModel(page:, token:) = serializable_model
  json.object([
    #("page", encode_page(page)),
    #("token", case token {
      option.None -> json.null()
      Some(value) -> json.string(value)
    }),
  ])
}

pub fn deserialize_serializable_model(jsod: String) {
  json.parse(jsod, serializable_model_decoder())
}

fn serializable_model_decoder() -> decode.Decoder(SerializableModel) {
  use page <- decode.field("page", page_decoder())
  use token <- decode.field("token", decode.optional(decode.string))
  decode.success(SerializableModel(page:, token:))
}

pub fn serialize(normal_model: Model) {
  let Model(page, _, _, token, _, _, _, _): Model = normal_model
  SerializableModel(page:, token:)
  |> serialize_serializable_model
  |> json.to_string
}
