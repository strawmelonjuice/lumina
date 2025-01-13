// Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
// Licensed under the BSD 3-Clause License. See the LICENSE file for more info.

import frontend/other/element_actions
import frontend/other/funnyrandomusername.{funnyrandomusername}
import gleam/dynamic.{field}
import gleam/fetch
import gleam/http.{Post}
import gleam/http/request
import gleam/javascript/array
import gleam/javascript/promise
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import gleamy_lights/console
import gleamy_lights/premixed
import plinth/browser/document
import plinth/browser/element
import plinth/browser/window
import plinth/javascript/global
import plinth/javascript/storage
import pprint

// import plinth/browser/event.{type Event}

pub fn render() {
  console.log(
    "Detected you are on the " <> premixed.text_lime("login page") <> ".",
  )
  let assert Ok(submitbutton) = document.get_element_by_id("submitbutton")
  element.add_event_listener(submitbutton, "click", fn(_) {
    try_login(submitbutton)
    Nil
  })
  let assert Ok(local_storage) = storage.local()
  case storage.get_item(local_storage, "AutologinUsername") {
    Ok(username) -> {
      case storage.get_item(local_storage, "AutologinPassword") {
        Ok(password) -> {
          let assert Ok(d) = document.get_element_by_id("Aaa1")
          d
          |> element.set_inner_text("Logging in automatically...")
          authentication_request(username, password, True)
          Nil
        }
        _ -> Nil
      }
    }
    _ -> Nil
  }
  document.query_selector_all("#username")
  |> array.to_list()
  |> list.each(fn(e) {
    e |> element.set_attribute("placeholder", funnyrandomusername())
  })
  Nil
}

fn try_login(submitbutton: element.Element) {
  console.log("Trying authentication...")
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
    authentication_request(username, password, False)
  })
}

fn authentication_request(
  username: String,
  password: String,
  is_autologin: Bool,
) {
  let req =
    element_actions.phone_home()
    |> request.set_method(Post)
    |> request.set_path("/api/fe/auth/")
    |> request.set_body(
      json.object([
        #("username", json.string(username)),
        #("password", json.string(password)),
      ])
      |> json.to_string,
    )
    |> request.set_header("Content-Type", "application/json")

  // |> formdata.encode([#("username", username), #("password", password)])
  // |> request.prepend_header("accept", "application/vnd.hmrc.1.0+json")

  fetch.send(req)
  |> promise.try_await(fetch.read_json_body)
  |> promise.await(fn(resp) {
    let assert Ok(resp) = resp
    // We don't care about the status code, we just want to know if the request was successful.
    // let assert 200 = resp.status
    // let assert Ok("application/json; charset=utf-8") =
    //   response.get_header(resp, "content-type")
    case
      resp.body
      |> dynamic.decode2(
        AuthResponse,
        field("Ok", of: dynamic.bool),
        field("Errorvalue", of: dynamic.string),
      )
    {
      Error(e) -> {
        console.error(
          "Error decoding server auth response: "
          <> string.inspect(e)
          <> "\n\nGot: "
          <> pprint.format(resp.body),
        )
        panic
      }
      Ok(authorisation_response) -> {
        continue_after_login(authorisation_response, is_autologin)
      }
    }
    promise.resolve(Ok(Nil))
  })
}

/// This function is called after the user has send a login request. It checks if the login was successful and continues the user to the next page.
/// If the login was not successful, it will show an error message.
/// If the user checked the "Remember me" checkbox, it will save the login data in the local storage.
fn continue_after_login(
  authorisation_response: AuthResponse,
  is_autologin: Bool,
) {
  console.log("Login answer was received, let's unpack it.")
  case authorisation_response {
    AuthResponse(True, _) -> {
      console.info("Spoiler alert: Login is succesful.")
      let timeout = case is_autologin {
        True -> {
          0
        }
        False -> {
          let assert Ok(d) = document.get_element_by_id("Aaa1")
          d
          |> element.set_inner_text(
            "Login successful, you will be forwarded now.",
          )
          2000
        }
      }

      case
        {
          let assert Ok(autologincheckbox) =
            document.get_element_by_id("autologin")
          autologincheckbox |> element.get_checked
        }
      {
        True -> {
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
          let assert Ok(storage) = storage.local()
          let assert Ok(_) =
            [
              storage.set_item(storage, "AutologinUsername", username),
              storage.set_item(storage, "AutologinPassword", password),
            ]
            |> result.all()
          Nil
        }
        False -> {
          Nil
        }
      }
      global.set_timeout(timeout, fn() {
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
    AuthResponse(False, error) -> {
      let assert Ok(d) = document.get_element_by_id("Aaa1")
      d |> element.set_inner_text("Login failed: " <> error)
      let assert Ok(submitbutton) = document.get_element_by_id("submitbutton")
      submitbutton |> element.set_inner_text("Retry")
      submitbutton |> element_actions.enable_element
    }
  }
}

type AuthResponse {
  AuthResponse(ok: Bool, error_value: String)
}
