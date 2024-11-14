// Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
// Licensed under the BSD 3-Clause License. See the LICENSE file for more info.

import gleam/fetch.{type FetchError}
import gleam/http/request
import gleam/http/response.{type Response}
import gleam/javascript/promise
import gleam/string
import gleamy_lights/helper as web_io
import gleamy_lights/premixed
import gleamy_lights/premixed/gleam_colours
import plinth/browser/window

pub fn home_render() {
  web_io.println("Home page")
}

pub fn index_render() {
  web_io.println("Index page")
}
