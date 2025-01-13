import frontend/other/element_actions
import frontend/page/site/subpages
import gleam/bool
import gleam/javascript/map
import gleam/list
import gleam/string
import gleamy_lights/console
import gleamy_lights/premixed
import lumina/shared/shared_fepage_com.{
  type FEPageServeResponse, FEPageServeResponse,
}
import plinth/browser/document
import plinth/browser/element
import plinth/javascript/global

pub fn fetch() {
  use presp <- subpages.fetch("editor", _)
  case presp {
    Ok(resp) -> {
      console.log("Page: " <> premixed.text_lightblue(string.inspect(resp)))
      let resp: FEPageServeResponse = resp
      let message_list = resp.message
      case
        bool.and(
          message_list |> list.contains(1) |> bool.negate,
          message_list |> list.contains(2) |> bool.negate,
        )
      {
        True -> {
          // document.querySelector("div#posteditor").innerHTML =
          // response.data.main;
          // window.history.back();
          {
            let assert Ok(a) = document.query_selector("div#posteditor")
            a
          }
          |> element.set_inner_html(resp.main)
          element_actions.go_back()
          Nil
        }
        False -> {
          // document.querySelector("div#posteditor").innerHTML =
          // errormsg;
          {
            let assert Ok(a) = document.query_selector("div#posteditor")
            a
          }
          |> element.set_inner_html(
            "<p class=\"w-full h-full text-black bg-white dark:text-white dark:bg-black\">Failed to load post editor.</p>",
          )
          Nil
        }
      }
    }
    Error(_) -> {
      Nil
    }
  }
}

pub fn fold() {
  let assert Ok(posteditor) = document.query_selector("div#posteditor")
  posteditor |> element_actions.hide_element()
  case document.body() |> element.dataset_get("editorOpen") {
    Ok(_) ->
      document.body() |> element.set_attribute("data-editor-open", "false")
    Error(_) ->
      document.body() |> element.set_attribute("data-editor-open", "initial")
  }
}

pub fn unfold() {
  let assert Ok(mobiletimelineswitcher) =
    document.query_selector("#mobiletimelineswitcher")
  let assert Ok(posteditor) = document.query_selector("div#posteditor")
  mobiletimelineswitcher |> element_actions.hide_element()
  posteditor |> element_actions.show_element()
  case document.body() |> element.dataset_get("editorOpen") {
    Ok("initial") -> {
      fetch()
      Nil
    }
    _ -> Nil
  }
  global.set_timeout(100, fn() { post_fold_out() })
  Nil
}

@external(javascript, "../../../editor_ffi.mjs", "postfoldout")
fn post_fold_out() -> nil



pub fn trigger() {
  let hash = element_actions.get_window_location_hash()

  case document.body() |> element.dataset_get("editorOpen") {
    Ok("true") -> {
      console.info(
        "triggerEditor: got called, but editor is already open. Refolding editor instead.",
      )
      fold()
    }
    _ -> {
      case hash == "editor" {
        True -> {
          // Editor glitched out, going back to retry...
          console.log("triggerEditor: retrying...")
          element_actions.go_back()
          global.set_timeout(600, fn() {
            element_actions.set_window_location_hash("editor")
            Nil
          })
          Nil
        }
        False -> {
          element_actions.set_window_location_hash("editor")
        }
      }
    }
  }
}

