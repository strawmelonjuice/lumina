// Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
// Licensed under the BSD 3-Clause License. See the LICENSE file for more info.

import frontend/other/element_actions
import gleamy_lights/helper as web_io
import gleamy_lights/premixed
import plinth/browser/document
import plinth/browser/element
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
  element.set_attribute(submitbutton, "data-identified-as", "Login")
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
    // > url: "/api/fe/auth/",
    // > data: bodyFormData,
    // > headers: { "Content-Type": "multipart/form-data" },
    // > })
    // > .then(c)
    // > .catch((error) => {
    // > console.log(error);
    // > });
    todo
  })
}
