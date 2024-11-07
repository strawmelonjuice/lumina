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

pub fn main() {
  web_io.println(
    "Hello from the "
    <> gleam_colours.text_faff_pink("Gleam")
    <> " frontend rewrite!",
  )
  test_fetch()
  |> promise.await(fn(a: Result(Response(String), FetchError)) {
    case a {
      Ok(b) -> {
        let c = b.body
        web_io.println(
          premixed.text_lightblue("Fetch test")
          <> premixed.text_ok_green(" succes")
          <> ", response:\n"
          <> premixed.text_orange(c),
        )
      }
      Error(e) ->
        web_io.println(
          premixed.text_lightblue("Fetch test")
          <> premixed.text_error_red(" failed")
          <> ", error:\n"
          <> string.inspect(e),
        )
    }
    promise.resolve(Nil)
  })
}

fn test_fetch() {
  let assert Ok(req) = request.to(window.origin() <> "/api/test/")
  use resp <- promise.try_await(fetch.send(req))
  use resp <- promise.try_await(fetch.read_text_body(resp))

  promise.resolve(Ok(resp))
}
