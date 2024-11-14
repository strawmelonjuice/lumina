// Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
// Licensed under the BSD 3-Clause License. See the LICENSE file for more info.

import gleamy_lights/helper as web_io
import gleamy_lights/premixed
import plinth/browser/document
import plinth/browser/element

// import plinth/browser/event.{type Event}

pub fn render() {
  web_io.println(
    "Detected you are on the " <> premixed.text_lime("login page") <> ".",
  )
  let assert Ok(submitbutton) = document.get_element_by_id("submitbutton")
  element.add_event_listener(submitbutton, "click", try_login)
  // Just to show we now can use the element.
  element.set_attribute(submitbutton, "data-identified-as", "Login")
}

fn try_login(_a) {
  web_io.println("Trying to login...")
}
