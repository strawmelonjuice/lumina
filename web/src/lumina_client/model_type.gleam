//// Lumina > Client > Model
//// Lumina's model is the central source of truth for the client application state.

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

import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/uri.{type Uri}


pub type Msg {
  UpdateLastRefreshRequestTime(Int)
  UserNavigatedToLoginPage
  UserNavigatedToRegisterPage
  UserNavigatedToLandingPage
  UserSubmittedLogin(List(#(String, String)))
  UserSubmittedSignup(List(#(String, String)))
  // Can be re-used for both login and register pages
  UserUpdatedControlledEmailField(String)
  UserUpdatedControlledPasswordField(String)
  /// Register page
  UserUpdatedControlledUsernameField(String)
  UserUpdatedControlledPasswordConfirmField(String)
  EmailFieldLostFocus
  /// Travel to a different timeline.
  UserSwitchedTimeLineTo(String)
  /// Load more posts for the current timeline
  LoadMorePosts(String)
  /// Log the user out (destroys session and recreates model)
  UserClickedLogout
  /// Close current modal
  UserClosedModal
  /// Browse modal to different page
  SetModal(String)
  /// Start dragging the modal box
  /// Parameters: the event, current mouse x and y positions
  /// Starts a sideffect that tracks mouse movements and sends MoveModalBoxTo messages
  StartDraggingModalBox(Float, Float)
  /// Move the modal box to a new position
  /// Parameters: new x and y positions
  MoveModalBoxTo(Float, Float)
}

pub type Page = Route


pub fn parse_route(uri: Uri) -> Page {
  case uri.path_segments(uri.path) {
    [] | [""] -> Landing
    ["login"] -> Login(fields: LoginFields("", ""), success: None)
    ["signup"] ->
      Register(fields: RegisterPageFields("", "", "", ""), ready: None)
    ["publication", _post_id] -> {
      todo as "We don't have a publication zoom Page variant yet."
    }
    ["home"] | ["timeline"] -> HomeTimeline(None, None)
    ["timeline", tid] -> HomeTimeline(Some(tid), None)
    ["licence"] | ["license"] -> Licence

    _ -> NotFound(uri:)
  }
}

/// # Page
///
/// Lumina has always been an SPA behind the login page, splitting the three "main" pages: Login, Signup, and Home from "subpages". Home contained subpages like Dashboard, Profile, and Settings, etc.
/// In this model, Login and Dashboard would be equal. The model keeps track of the current page and the user's authentication status.
/// The Page type is, pretty explanatory, an enum of all the pages in the app. Nested if needed, to track fields like the current tab in the Dashboard or the username form field in the login page.
pub type Route {
  Landing
  Register(fields: RegisterPageFields, ready: Option(Result(Nil, String)))
  Login(fields: LoginFields, success: Option(Bool))
  HomeTimeline(
    timeline_name: Option(String),
    modal: Option(#(String, Dict(String, String))),
  )
  Licence
  NotFound(uri: Uri)
}

/// # Model
///
pub type Model {
  Model(
    /// Page currently browsing.
    /// This is synced to the url through modem, but can contain more context.
    page: Page,
    /// User, if known
    user: Option(UserSubmodel),
    /// Used to restore sessions
    token: Option(String),
    /// Used to show error screens on unrecoverable errors
    status: Result(Nil, String),
  )
}

pub type NotificationsSubModel {
  NotificationsSubModel(
    /// Unread notifications count, calculated by the server based on the last time the user checked notifications
    unread_count: Int,
    /// Cached notifications
    cached_notifications: List(Nil),
  )
}

pub type WsConnectionStatus

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
    NotFound(_) -> json.object([#("type", json.string("landing"))])

    Licence -> json.object([#("type", json.string("licence"))])
  }
}

fn page_decoder() -> decode.Decoder(Page) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "landing" -> decode.success(Landing)
    "licence" -> decode.success(Licence)
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

/// # User submodel
///
/// The User type is a struct that holds the user's data. It's an Option in the Model because the user might not be logged in.
/// Authentication STATUS is not stored in the Model, but in the websocket connection (the token is). The user is only stored in the Model for the UI to easy displaying the user's data.
pub type UserSubmodel {
  UserSubmodel(
    /// User ID (uuid)
    uid: String,
    /// Username
    username: String,
    /// Email
    email: String,
    /// Avatar as uri string, either a full URL or a base64-encoded 'data:'-string
    avatar: String,
    /// Notifications
    notifs: NotificationsSubModel,
  )
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
  let Model(page:, token:, ..): Model = normal_model
  SerializableModel(page:, token:)
  |> serialize_serializable_model
  |> json.to_string
}
