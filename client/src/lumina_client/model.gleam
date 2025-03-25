//// Branched out the Model into a module.
//// The Model is about to be huge, I'm just preselecting for that.

import gleam/option.{type Option}
import lustre_websocket

/// # Model
/// blablabla
pub type Model {
  Model(page: Page, user: Option(User), ws: Option(lustre_websocket.WebSocket))
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
/// Authentication is not stored in the Model, but in the websocket connection. The user is only stored in the Model for the UI to easy displaying the user's data.
pub type User {
  User(username: String, email: String, avatar: String)
}
