// Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
// Licensed under the BSD 3-Clause License. See the LICENSE file for more info.

import frontend/other/element_actions
import frontend/other/formdata
import gleam/dynamic.{field}
import gleam/fetch
import gleam/http.{Post}
import gleam/http/request
import gleam/http/response
import gleam/javascript/promise
import gleamy_lights/helper as web_io
import gleamy_lights/premixed
import plinth/browser/document
import plinth/browser/element
import plinth/browser/window
import plinth/javascript/global

pub fn render() -> Nil {
  web_io.println(
    "Detected you are on the " <> premixed.text_lilac("signup page") <> ".",
  )
  let assert Ok(usernamebox) = document.get_element_by_id("username")
  usernamebox
  |> element.add_event_listener("change", fn(_) { checkusername(usernamebox) })

  let assert Ok(passwordbox) = document.get_element_by_id("password")
  passwordbox
  |> element.add_event_listener("change", fn(_) { checkusername(passwordbox) })
  let assert Ok(submitbutton) = document.get_element_by_id("submitbutton")
  element.add_event_listener(submitbutton, "click", fn(_) {
    try_signup(submitbutton)
    Nil
  })

  Nil
}

fn checkusername(usernamebox) -> Nil {
  let assert Ok(entered_username) = usernamebox |> element.value()
  // This is not yet implemented in the backend
  web_io.println(
    "Checking if the username " <> entered_username <> " is available...",
  )
  web_io.println(premixed.text_error_red(
    "Username check feature is not yet implemented. Also see <https://github.com/strawmelonjuice/lumina/issues/48> for this.",
  ))
  Nil
}

fn try_signup(submitbutton: element.Element) {
  web_io.println("Trying registration...")
  submitbutton
  |> element.set_inner_html(
    "<div style=\"background-image: url('/spinner.svg'); background-repeat: no-repeat; background-size: cover;\" class=\"relative w-10 h-10 pl-max pr-max\"></div>",
  )
  submitbutton |> element_actions.disable_element
  global.set_timeout(9600, fn() {
    submitbutton |> element.set_inner_text("Retry")
    submitbutton |> element_actions.enable_element
  })
  {
    let assert Ok(d) = document.get_element_by_id("Aaa1")
    d
  }
  |> element.set_inner_text("Checking credentials...")

  // timeout to allow spinner to show up
  global.set_timeout(500, fn() {
    let username = {
      let assert Ok(d) = document.get_element_by_id("username")
      let assert Ok(v) = d |> element.value
      v
    }
    let password = {
      let assert Ok(d) = document.get_element_by_id("password")
      let assert Ok(v) = d |> element.value
      v
    }
    let email = {
      let assert Ok(d) = document.get_element_by_id("email")
      let assert Ok(v) = d |> element.value
      v
    }
    registration_request(username, email, password)
  })
}

fn registration_request(username: String, email: String, password: String) {
  let req =
    request.new()
    |> request.set_method(Post)
    |> request.set_scheme({
      let origin = window.origin()
      case origin {
        "http://" <> _ -> http.Http
        "https://" <> _ -> http.Https
        _ -> http.Https
      }
    })
    |> request.set_host(element_actions.get_window_host())
    |> request.set_path("/api/fe/auth-create/")
    |> formdata.encode([
      #("username", username),
      #("email", email),
      #("password", password),
    ])
  // |> request.prepend_header("accept", "application/vnd.hmrc.1.0+json")

  fetch.send(req)
  |> promise.try_await(fetch.read_json_body)
  |> promise.await(fn(resp) {
    let assert Ok(resp) = resp
    // We don't care about the status code, we just want to know if the request was successful.
    // let assert 200 = resp.status
    let assert Ok("application/json; charset=utf-8") =
      response.get_header(resp, "content-type")
    let assert Ok(registration_response) =
      resp.body
      |> dynamic.decode2(
        RegistrationResponse,
        field("Ok", of: dynamic.bool),
        field("Errorvalue", of: dynamic.string),
      )
    registration_response |> continue_after_signup()
    promise.resolve(Ok(Nil))
  })
}

type RegistrationResponse {
  RegistrationResponse(ok: Bool, error_value: String)
}

fn continue_after_signup(registration_response) {
  case registration_response {
    RegistrationResponse(True, _) -> {
      let assert Ok(d) = document.get_element_by_id("Aaa1")
      d
      |> element.set_inner_text(
        "Sign-up successful! You will be forwarded now.",
      )

      global.set_timeout(3000, fn() {
        window.set_location(
          window.self(),
          "/home/"
            <> {
            case window.get_hash() {
              // const loginPageList = ["home", "notifications", "test"];
              Ok("home") -> "#home"
              Ok("notifications") -> "#notifications"
              Ok("test") -> "#test"
              _ -> ""
            }
          },
        )
      })
    }
    RegistrationResponse(False, _) -> {
      let assert Ok(d) = document.get_element_by_id("Aaa1")
      d
      |> element.set_inner_text(
        "<div style=\"background-image: url('/red-cross.svg'); background-repeat: no-repeat; background-size: cover;\" class=\"relative w-10 h-10 pl-max pr-max\"></div>",
      )
      let assert Ok(submitbutton) = document.get_element_by_id("submitbutton")
      submitbutton |> element.set_inner_text("Sign up")
      submitbutton |> element_actions.enable_element
    }
  }
}
