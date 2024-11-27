// Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
// Licensed under the BSD 3-Clause License. See the LICENSE file for more info.

import frontend/other/fejson
import gleam/bool
import gleam/dynamic
import gleam/fetch.{type FetchError}
import gleam/http/request
import gleam/http/response.{type Response}
import gleam/int
import gleam/javascript/promise
import gleam/json
import gleam/list
import gleam/string
import gleamy_lights/helper as web_io
import gleamy_lights/premixed
import gleamy_lights/premixed/gleam_colours
import lumina/shared/shared_fejsonobject
import lumina/shared/shared_users
import plinth/browser/document
import plinth/browser/window
import plinth/javascript/global

// Page modules
import frontend/page/login
import frontend/page/signup
import frontend/page/site

const fejsontimeout = 30_000

pub fn main() {
  window.add_event_listener("load", fn(_) {
    let path = window.pathname()
    case path {
      "/" | "" -> site.index_render()
      "/home" | "/home/" -> site.home_render()
      "/login" | "/login/" -> login.render()
      "/signup" | "/signup/" -> signup.render()
      _ -> web_io.println("404: Page not found")
    }
  })
  web_io.println(
    "Hello from the "
    <> gleam_colours.text_faff_pink("Gleam")
    <> " frontend rewrite!",
  )
  document.add_event_listener("DOMContentLoaded", fn(_) {
    // window.mobileMenuToggle = () => {
    // 	const mobilemenu = document.getElementById("mobile-menu");
    // 	if (mobilemenu.classList.contains("hidden")) {
    // 		mobilemenu.classList.remove("hidden");
    // 		document
    // 			.getElementById("btn-mobile-menu-open")
    // 			.classList.add("hidden");
    // 		document
    // 			.getElementById("btn-mobile-menu-close")
    // 			.classList.remove("hidden");
    // 	} else {
    // 		mobilemenu.classList.add("hidden");
    // 		document
    // 			.getElementById("btn-mobile-menu-open")
    // 			.classList.remove("hidden");
    // 		document
    // 			.getElementById("btn-mobile-menu-close")
    // 			.classList.add("hidden");
    // 	}
    // };
    //
    // window.mobileMenuToggle();
    // document
    // 	.getElementById("btn-mobile-menu")
    // 	.setAttribute("onClick", "window.mobileMenuToggle()");
    //
    // })
    //  global.set_interval(4000, update_fejson)
    //  global.set_timeout(80, fn() {
    //    global.set_interval(80, fn() { run_fejson_functions() })
    todo
  })
}

fn update_fejson() {
  let origi = fejson.get()
  use <- bool.guard(
    when: {
      { fejson.timestamp() - origi.pulled } |> int.absolute_value
      > fejsontimeout
    }
      |> bool.negate,
    return: promise.resolve(Nil),
  )
  shared_fejsonobject.FEJSonObj(
    pulled: fejson.timestamp(),
    instance: origi.instance,
    user: origi.user,
  )
  |> fejson.set
  let f = fn(then: fn(shared_fejsonobject.FEJSonObj) -> Nil) {
    {
      let assert Ok(req) = request.to(window.origin() <> "/api/fe/update")
      use resp <- promise.try_await(fetch.send(req))
      use resp <- promise.try_await(fetch.read_text_body(resp))
      promise.resolve(Ok(resp))
    }
    |> promise.await(fn(a: Result(Response(String), FetchError)) {
      case a {
        Ok(b) -> {
          let now = fn(_) { fejson.timestamp() |> Ok() }
          case
            json.decode(
              from: b.body,
              using: dynamic.decode3(
                shared_fejsonobject.FEJSonObj,
                now,
                dynamic.field(
                  "instance",
                  dynamic.decode2(
                    shared_fejsonobject.FEJsonObjInstanceInfo,
                    dynamic.field("iid", dynamic.string),
                    dynamic.field("last_sync", dynamic.int),
                  ),
                ),
                dynamic.field(
                  "user",
                  dynamic.decode3(
                    shared_users.SafeUser,
                    dynamic.field("id", dynamic.int),
                    dynamic.field("username", dynamic.string),
                    dynamic.field("email", dynamic.string),
                  ),
                ),
              ),
            )
          {
            Ok(c) -> then(c)
            Error(e) ->
              web_io.println(
                premixed.text_lightblue("FEJson fetch ")
                <> premixed.text_error_red(" decoding failed")
                <> ", error:\n"
                <> string.inspect(e)
                <> "\n"
                <> "JSON:\n"
                <> premixed.text_red(b.body),
              )
          }
        }
        Error(e) ->
          web_io.println(
            premixed.text_lightblue("FEJson fetch ")
            <> premixed.text_error_red(" fetch failed")
            <> ", error:\n"
            <> string.inspect(e),
          )
      }
      promise.resolve(Nil)
    })
  }
  use data <- f()
  fejson.set(data)
  run_fejson_functions()
}

/// FE json usually updates every 30 seconds, that means some stuff might change. These functions are ran periodically as well, to keep the frontend in sync with the backend.
/// They'll be fetched from the window object using FFI. Then ran here.
fn run_fejson_functions() {
  use <-
    bool.guard(when: { fejson.get().pulled == 0 }, return: Nil, otherwise: _)
  fetch_fejson_functions()
  |> list.each(fn(f) { f() })

  Nil
}

@external(javascript, "./fejson_ffi.ts", "getQueuedFejsonFunctions")
fn fetch_fejson_functions() -> List(fn() -> Nil)
