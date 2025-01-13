// Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
// Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
import gleam/string
import plinth/browser/element.{type Element}
import plinth/browser/window
import gleam/http/request.{type Request}
import gleam/http

@external(javascript, "../../elementactions_ffi.ts", "disableElement")
pub fn disable_element(a: Element) -> nil

@external(javascript, "../../elementactions_ffi.ts", "enableElement")
pub fn enable_element(a: Element) -> nil

@external(javascript, "../../elementactions_ffi.ts", "hideElement")
pub fn hide_element(a: Element) -> nil

@external(javascript, "../../elementactions_ffi.ts", "unHideElement")
pub fn show_element(a: Element) -> nil

@external(javascript, "../../elementactions_ffi.ts", "elementHidden")
pub fn element_hidden(a: Element) -> bool

@external(javascript, "../../elementactions_ffi.ts", "getWindowHost")
pub fn get_window_host() -> String

@external(javascript, "../../elementactions_ffi.ts", "goWindowBack")
pub fn go_back() -> nil

@external(javascript, "../../elementactions_ffi.ts", "setWindowLocationHash")
pub fn set_window_location_hash(new: String) -> nil

@external(javascript, "../../elementactions_ffi.ts", "getWindowLocationHash")
fn int_get_window_location_hash() -> String

pub fn get_window_location_hash() -> String {
  // Remove the leading '#' from the hash if it exists

  let s = int_get_window_location_hash()
  case string.starts_with(s, "#") {
    True -> s |> string.drop_start(1)
    False -> s
  }
}

pub fn phone_home() -> Request(String) {
	request.new()
    |> request.set_scheme({
      let origin = window.origin()
      case origin {
        "http://" <> _ -> http.Http
        "https://" <> _ -> http.Https
        _ -> http.Https
      }
    })
    
    |> request.set_host(get_window_host())
}
