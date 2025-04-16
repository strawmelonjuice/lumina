//// Branched out the Model into a module.
//// The Model is about to be huge, I'm just preselecting for that.

import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}
import lustre_websocket

/// # Model
/// blablabla
pub type Model {
  Model(
    page: Page,
    user: Option(User),
    ws: Option(lustre_websocket.WebSocket),
    token: Option(String),
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
  Login(fields: LoginFields)
  HomeTimeline(timeline_id: String)
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
    Login(fields:) ->
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
    HomeTimeline(timeline_id:) ->
      json.object([
        #("type", json.string("home_timeline")),
        #("timeline_id", json.string(timeline_id)),
      ])
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
      let ready = option.None
      decode.success(Register(fields:, ready:))
    }
    "login" -> {
      use fields <- decode.field("fields", {
        use emailfield <- decode.field("emailfield", decode.string)
        use passwordfield <- decode.field("passwordfield", decode.string)
        decode.success(LoginFields(emailfield:, passwordfield:))
      })
      decode.success(Login(fields:))
    }
    "home_timeline" -> {
      use timeline_id <- decode.field("timeline_id", decode.string)
      decode.success(HomeTimeline(timeline_id:))
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
      option.Some(value) -> json.string(value)
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
  let Model(page, _, _, token): Model = normal_model
  SerializableModel(page:, token:)
  |> serialize_serializable_model
  |> json.to_string
}
