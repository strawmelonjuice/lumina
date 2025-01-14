// Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
// Licensed under the BSD 3-Clause License. See the LICENSE file for more info.

import frontend/other/element_actions
import frontend/other/fejson
import frontend/other/rendering
import frontend/other/rust_kind_of_unwrap.{unwrap}
import frontend/page/site/editor
import frontend/page/site/subpages
import gleam/bool
import gleam/dict.{type Dict}
import gleam/javascript/array
import gleam/javascript/promise
import gleam/list
import gleam/string
import gleamy_lights/console
import gleamy_lights/premixed
import gleamy_lights/premixed/gleam_colours
import plinth/browser/document
import plinth/browser/element
import plinth/browser/event
import plinth/browser/window
import plinth/javascript/global
import plinth/javascript/storage

pub fn home_render() {
  console.log(
    "Detected you are on the " <> premixed.text_pink("home page") <> ".",
  )
  let sub_page_list: SubPageList =
    dict.new()
    |> dict.insert(
      "home",
      SubPageMeta(
        {
          let assert Ok(a) = document.query_selector("#home-nav")
          a
        },
        {
          let assert Ok(a) = document.query_selector("#mobile-home-nav")
          a
        },
        fn() {
          let assert Ok(a) = document.query_selector("#mobiletimelineswitcher")
          a |> element_actions.show_element()
          Nil
        },
        "home",
        True,
      ),
    )
    |> dict.insert(
      "test",
      SubPageMeta(
        {
          let assert Ok(a) = document.query_selector("#test-nav")
          a
        },
        {
          let assert Ok(a) = document.query_selector("#mobile-test-nav")
          a
        },
        fn() {
          let assert Ok(a) = document.query_selector("#mobiletimelineswitcher")
          a |> element_actions.hide_element()
          Nil
        },
        "test",
        True,
      ),
    )
    |> dict.insert(
      "editor",
      SubPageMeta(
        {
          let assert Ok(a) = document.query_selector("#home-nav")
          a
        },
        {
          let assert Ok(a) = document.query_selector("#mobile-home-nav")
          a
        },
        fn() { editor.unfold() },
        "editor",
        False,
      ),
    )
    |> dict.insert(
      "notifications",
      SubPageMeta(
        {
          let assert Ok(a) = document.query_selector("#notifications-nav")
          a
        },
        {
          let assert Ok(a) =
            document.query_selector("#mobile-notifications-nav")
          a
        },
        fn() {
          let assert Ok(a) = document.query_selector("#mobiletimelineswitcher")
          a |> element_actions.hide_element()
          Nil
        },
        "notifications",
        True,
      ),
    )
  console.log(
    "Subpage list: " <> premixed.text_lightblue(string.inspect(sub_page_list)),
  )
  global.set_interval(60, fn() {
    check_if_page_needs_to_be_switched(sub_page_list)
  })
  user_menu_toggle()

  document.query_selector("main")
  |> rust_kind_of_unwrap.unwrap
  |> element.add_event_listener("click", fn(_) {
    case document.get_element_by_id("user-menu") {
      Ok(user_menu) -> {
        let classes =
          user_menu
          |> element.get_attribute("class")
          |> unwrap
        user_menu |> element.set_attribute("class", classes <> " hidden")
      }
      Error(_) -> {
        console.error("Failed to find user menu.")
      }
    }
  })

  case document.get_element_by_id("user-menu-button") {
    Ok(user_menu_button) -> {
      element.add_event_listener(user_menu_button, "click", fn(_) {
        console.log("User menu button clicked.")
        user_menu_toggle()
      })
      Nil
    }
    _ -> {
      console.error("Failed to find user menu button.")
      Nil
    }
  }
  fejson.register_fejson_function(fn() {
    let d = fejson.get()
    case document.get_element_by_id("userimg") {
      Ok(f) -> {
        f |> element.set_attribute("alt", d.user.username)
      }
      _ -> Nil
    }

    document.query_selector_all(".settodisplayname")
    |> array.to_list
    |> list.each(fn(a) { a |> element.set_inner_text(d.user.username) })
  })
  editor.fold()
  {
    let assert Ok(a) =
      document.get_element_by_id("switchpageNotificationsTrigger")
    a
    |> element.add_event_listener("click", fn(_) {
      switch_subpage("notifications", "special click event", sub_page_list)
      Nil
    })
  }
  {
    let assert Ok(a) = document.get_element_by_id("editorTrigger")
    a
    |> element.add_event_listener("click", fn(_) {
      editor.trigger()
      Nil
    })
  }
  {
    let a = document.query_selector_all(".logoutbutton")
    a
    |> array.to_list
    |> list.each(fn(b) {
      b
      |> element.add_event_listener("click", fn(_) {
        let assert Ok(stor) = storage.local()
        storage.clear(stor)
        window.set_location(window.self(), "/session/logout")
        Nil
      })
    })
  }
  {
    document.add_event_listener("keydown", fn(event) {
      case event |> event.key() |> string.lowercase() {
        "e" -> {
          event |> event.prevent_default()
          editor.trigger()
        }
        "h" -> {
          event |> event.prevent_default()
          window.set_location(window.self(), "#home")
        }
        "n" -> {
          event |> event.prevent_default()
          window.set_location(window.self(), "#notifications")
        }
        _ -> Nil
      }
    })
  }
  Nil
}

pub fn index_render() {
  console.log(
    "Detected you are on the "
    <> gleam_colours.text_faff_pink("first page")
    <> ".",
  )
}

type SubPageList =
  Dict(String, SubPageMeta)

type SubPageMeta {
  SubPageMeta(
    desktop: element.Element,
    mobile: element.Element,
    f: fn() -> Nil,
    location: String,
    navigator: Bool,
  )
}

fn check_if_page_needs_to_be_switched(sub_page_list: SubPageList) {
  let hash = element_actions.get_window_location_hash()
  let p = document.body() |> element.get_attribute("data-current-page")
  case p {
    Ok(a) -> {
      case a == hash {
        True -> {
          // Do nothing.
          Nil
        }
        False -> {
          switch_subpage(hash, "URL change", sub_page_list)
          Nil
        }
      }
    }
    Error(_) -> {
      // If we get this, that means the initial page load has not been done yet.
      switch_subpage(hash, "Initial load", sub_page_list)
      Nil
    }
  }
}

fn switch_subpage(to_page: String, reason: String, sub_page_list: SubPageList) {
  let to = case to_page {
    "" -> {
      // The next line might cause some errors.
      // In the TypeScript version, the hash is only changed at the end of the function.
      // It also keeps the other URL parameters intact.
      element_actions.set_window_location_hash("home")
      "home"
    }
    _ -> {
      element_actions.set_window_location_hash(to_page)
      to_page
    }
  }
  let error_out = fn() {
    let assert Ok(a) = document.query_selector("main div#mainright")
    a |> element.set_inner_html("There was an error loading this page.")
    let assert Ok(a) = document.query_selector("main div#mainleft")
    a |> element.set_inner_html("")
    document.body() |> element.set_attribute("data-current-page", to)
    Nil
  }
  console.info("Switching page to " <> to <> ". Reason: " <> reason)
  dict.each(sub_page_list, fn(k, v) {
    case v {
      SubPageMeta(desktop, mobile, _, location, True) -> {
        case k == to {
          False -> {
            desktop
            |> element.set_attribute(
              "class",
              "px-3 py-2 text-sm font-medium bg-orange-200 border-2 rounded-md text-brown-800 dark:text-orange-200 border-emerald-600 dark:bg-yellow-700 dark:border-zinc-400 hover:bg-gray-700 hover:text-white",
            )
            mobile
            |> element.set_attribute(
              "class",
              "block rounded-md px-3 py-2 text-base font-medium bg-orange-200 text-brown-800 dark:text-orange-200 border-emerald-600 dark:bg-yellow-700 dark:border-zinc-400 hover:bg-gray-700 hover:text-white",
            )
          }
          True -> Nil
        }

        [desktop, mobile]
        |> list.each(fn(h) {
          case h |> element.dataset_get("listening") {
            Ok("true") -> Nil
            _ -> {
              h
              |> element.add_event_listener("click", fn(_) {
                switch_subpage(location, "Click event", sub_page_list)
                Nil
              })
              h |> element.set_attribute("data-listening", "true")
            }
          }
        })
      }
      SubPageMeta(_, _, _, _, False) -> {
        Nil
      }
    }
  })
  case dict.get(sub_page_list, to) {
    Ok(SubPageMeta(desktop, mobile, f, location, _)) -> {
      mobile
      |> element.set_attribute(
        "class",
        "bg-red-400 dark:bg-red-900 text-white block rounded-md px-3 py-2 text-base font-medium",
      )
      desktop
      |> element.set_attribute(
        "class",
        "border-2 px-3 py-2 text-sm font-medium text-white bg-gray-900 rounded-md",
      )
      use resp <- subpages.fetch(location)
      case resp {
        Error(_) -> {
          console.error("Failed to fetch page." |> premixed.text_error_red())
          error_out()
        }
        Ok(responza) -> {
          let respons =
            responza
            |> rendering.renders()
          let msg_list = respons.message
          case msg_list |> list.contains(1) {
            False -> {
              case msg_list |> list.contains(34) |> bool.negate {
                True -> {
                  let assert Ok(a) =
                    document.query_selector("main div#mainright")
                  a |> element.set_inner_html(respons.main)
                  case msg_list |> list.contains(33) |> bool.negate {
                    True -> {
                      let assert Ok(a) =
                        document.query_selector("main div#mainleft")
                      a |> element.set_inner_html(respons.side)
                    }
                    False -> Nil
                  }
                }
                False -> {
                  Nil
                }
              }
            }
            True -> {
              window.set_location(
                window.self(),
                "/login#"
                  <> {
                  let a = element_actions.get_window_location_hash()
                  let assert Ok(b) = a |> string.split("?") |> list.first()
                  b
                },
              )
            }
          }
        }
      }
      document.body() |> element.set_attribute("data-current-page", to)
      f()
    }
    Error(_) -> promise.resolve(error_out())
  }
}

fn user_menu_toggle() {
  let assert Ok(user_menu_button) =
    document.get_element_by_id("user-menu-button")
  user_menu_button |> element.set_attribute("aria-haspopup", "true")

  case document.get_element_by_id("user-menu") {
    Ok(user_menu) -> {
      let classes =
        user_menu
        |> element.get_attribute("class")
        |> rust_kind_of_unwrap.unwrap
      case classes |> string.contains("hidden") {
        True -> {
          user_menu
          |> element.set_attribute(
            "class",
            string.replace(classes, "hidden", ""),
          )
        }
        False -> {
          user_menu |> element.set_attribute("class", classes <> " hidden")
        }
      }
      classes
      |> string.contains("hidden")
      // |> bool.negate
      |> bool.to_string
      |> string.lowercase()
      |> element.set_attribute(user_menu_button, "aria-expanded", _)
    }
    Error(_) -> {
      console.error("Failed to find user menu.")
    }
  }
}
