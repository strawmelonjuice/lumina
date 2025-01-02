// Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
// Licensed under the BSD 3-Clause License. See the LICENSE file for more info.

import frontend/other/element_actions
import frontend/other/fejson
import gleam/bool
import gleam/dynamic
import gleam/fetch.{type FetchError}
import gleam/http/request
import gleam/http/response.{type Response}
import gleam/int
import gleam/javascript/array.{type Array}
import gleam/javascript/promise
import gleam/json
import gleam/list
import gleam/string
import gleamy_lights/console
import gleamy_lights/premixed
import gleamy_lights/premixed/gleam_colours
import lumina/shared/shared_fejsonobject
import lumina/shared/shared_users
import plinth/browser/document
import plinth/browser/element
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
      _ -> console.error("404: Page not found")
    }
  })
  console.log(
    "Hello from the "
    <> gleam_colours.text_faff_pink("Gleam")
    <> " frontend rewrite!",
  )
  global.set_interval(4000, update_fejson)
  global.set_timeout(0, update_fejson)
  // fejson.register_fejson_function(fn() {
  //   console.log(
  //     "FEJson instance info: "
  //     <> premixed.text_lightblue(string.inspect(fejson.get().instance))
  //     <> ", last sync: "
  //     <> premixed.text_lightblue(string.inspect(fejson.get().pulled))
  //     <> ".",
  //   )
  // })
  fejson.register_fejson_function(fn() {
    let src = "/user/avatar/" <> int.to_string(fejson.get().user.id)
    document.query_selector_all(".ownuseravatarsrc")
    |> array.to_list
    |> list.each(fn(a) {
      use <-
        bool.guard(
          when: { fejson.get().user.id == -1 },
          return: Nil,
          otherwise: _,
        )

      use <-
        bool.guard(
          when: { a |> element.get_attribute("src") == Ok(src) },
          return: Nil,
          otherwise: _,
        )
      a
      |> element.set_attribute("src", src)
    })
  })
  fejson.register_fejson_function(fn() {
    let href = "/user/" <> fejson.get().user.username <> "/me"
    document.query_selector_all(".ownuserprofilelink")
    |> array.to_list
    |> list.each(fn(a) {
      use <-
        bool.guard(
          when: { fejson.get().user.id == -1 },
          return: Nil,
          otherwise: _,
        )

      use <-
        bool.guard(
          when: { a |> element.get_attribute("href") == Ok(href) },
          return: Nil,
          otherwise: _,
        )
      a
      |> element.set_attribute("href", href)
    })
  })

  fejson.register_fejson_function(fn() {
    let username = fejson.get().user.username
    document.query_selector_all(".ownusernametext")
    |> array.to_list
    |> list.each(fn(a) {
      use <-
        bool.guard(
          when: { fejson.get().user.id == -1 },
          return: Nil,
          otherwise: _,
        )

      use <-
        bool.guard(
          when: { a |> element.inner_text() == username },
          return: Nil,
          otherwise: _,
        )
      a |> element.set_inner_text(username)
    })
  })

  fejson.register_fejson_function(fn() {
    let display_name = fejson.get().user.username
    document.query_selector_all(".settodisplayname")
    |> array.to_list
    |> list.each(fn(a) {
      use <-
        bool.guard(
          when: { fejson.get().user.id == -1 },
          return: Nil,
          otherwise: _,
        )
      use <-
        bool.guard(
          when: { a |> element.inner_text() == display_name },
          return: Nil,
          otherwise: _,
        )

      console.warn("Display names not implemented yet, using username instead.")
      a |> element.set_inner_text(display_name)
    })
  })
  global.set_timeout(80, fn() {
    global.set_interval(80, fn() { run_fejson_functions() })
  })
  document.add_event_listener("DOMContentLoaded", fn(_) {
    mobile_menu_toggle()
    let assert Ok(button) = document.get_element_by_id("btn-mobile-menu")
    button
    |> element.add_event_listener("click", fn(_) { mobile_menu_toggle() })
    Nil
  })
}

fn mobile_menu_toggle() {
  console.info("Toggling mobile menu")
  let assert Ok(mobile_menu) = document.get_element_by_id("mobile-menu")
  let assert Ok(mobile_menu_button_open) =
    document.get_element_by_id("btn-mobile-menu-open")
  let assert Ok(mobile_menu_button_close) =
    document.get_element_by_id("btn-mobile-menu-close")
  case mobile_menu |> element_actions.element_hidden {
    True -> {
      element_actions.show_element(mobile_menu)
      element_actions.hide_element(mobile_menu_button_open)
      element_actions.show_element(mobile_menu_button_close)
    }
    False -> {
      element_actions.hide_element(mobile_menu)
      element_actions.show_element(mobile_menu_button_open)
      element_actions.hide_element(mobile_menu_button_close)
    }
  }
}

fn update_fejson() {
  let origi = fejson.get()
  let first_pull = origi.pulled == 0
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
              console.warn(
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
          console.error(
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
  // run_fejson_functions()
  // instead:
  case first_pull {
    True -> run_fejson_functions()
    False -> Nil
  }
}

/// FE json usually updates every 30 seconds, that means some stuff might change. These functions are ran periodically as well, to keep the frontend in sync with the backend.
/// They'll be fetched from the window object using FFI. Then ran here.
fn run_fejson_functions() {
  use <-
    bool.guard(when: { fejson.get().pulled == 0 }, return: Nil, otherwise: _)
  fetch_fejson_functions()
  |> array.to_list
  |> list.each(fn(f) { f() })

  Nil
}

@external(javascript, "./fejson_ffi.ts", "getQueuedFejsonFunctions")
fn fetch_fejson_functions() -> Array(fn() -> Nil)
