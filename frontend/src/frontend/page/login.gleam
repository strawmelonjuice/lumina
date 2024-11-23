// Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
// Licensed under the BSD 3-Clause License. See the LICENSE file for more info.

import frontend/other/element_actions
import frontend/other/formdata
import gleam/dynamic
import gleam/fetch.{type FetchError}
import gleam/http.{Post}
import gleam/http/request
import gleam/http/response.{type Response, Response}
import gleam/io
import gleam/javascript/promise
import gleam/string
import gleamy_lights/helper as web_io
import gleamy_lights/premixed
import plinth/browser/document
import plinth/browser/element
import plinth/browser/window
import plinth/javascript/global

// import plinth/browser/event.{type Event}

pub fn render() {
  web_io.println(
    "Detected you are on the " <> premixed.text_lime("login page") <> ".",
  )
  let assert Ok(submitbutton) = document.get_element_by_id("submitbutton")
  element.add_event_listener(submitbutton, "click", fn(_) {
    try_login(submitbutton)
    Nil
  })
  // Just to show we now can use the element.
  Nil
}

fn try_login(submitbutton: element.Element) {
  //
  //
  //
  web_io.println("Trying authentication...")
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
    // Translate the following to Gleam:
    // > let body_form_data = new FormData();
    // > bodyFormData.set("username", document.forms[0]["username"].value);
    // > bodyFormData.set("password", document.forms[0]["password"].value);
    // > axios({
    // > method: "post",
    // > url: "",
    // > data: bodyFormData,
    // > headers: { "Content-Type": "multipart/form-data" },
    // > })
    // > .then(c)
    // > .catch((error) => {
    // > console.log(error);
    // > });
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
    let data =
      formdata.encode([#("username", username), #("password", password)])
    let data_body = case data {
      #(data_body, _) -> {
        data_body
      }
    }

    let data_boundary = case data {
      #(_, boundary) -> {
        boundary
      }
    }

    let req =
      request.new()
      |> request.set_method(Post)
      // |> request.set_host(window.origin())
      |> request.set_scheme({
        let origin = window.origin()
        case origin {
          "http://" <> _ -> http.Http
          "https://" <> _ -> http.Https
          _ -> http.Http
        }
      })
      |> request.set_host(element_actions.get_window_host())
      |> request.set_path("/api/fe/auth/")
      // |> request.prepend_header("accept", "application/vnd.hmrc.1.0+json")
      |> request.prepend_header(
        "content-type",
        "multipart/form-data; boundary=" <> data_boundary,
      )
      |> request.set_body(data_body)

    fetch.send(req)
    |> promise.try_await(fetch.read_json_body)
    |> promise.await(fn(resp) {
      let assert Ok(resp) = resp
      let assert 200 = resp.status
      let assert Ok("application/json") =
        response.get_header(resp, "content-type")
      let body = dynamic.string(resp.body)
      io.println(string.inspect(body))
      promise.resolve(Ok(Nil))
    })
  })
}
