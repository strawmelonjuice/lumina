import frontend/other/element_actions
import frontend/other/rust_kind_of_unwrap.{unwrap}
import frontend/page/site/subpages
import gleam/bool
import gleam/dynamic/decode
import gleam/fetch
import gleam/http.{Post}
import gleam/http/request
import gleam/javascript/array
import gleam/javascript/promise
import gleam/json
import gleam/list
import gleam/regexp
import gleamy_lights/console
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
      // console.log("Page: " <> premixed.text_lightblue(string.inspect(resp)))
      let resp: FEPageServeResponse = resp
      let message_list = resp.message
      case
        bool.and(
          message_list |> list.contains(1) |> bool.negate,
          message_list |> list.contains(2) |> bool.negate,
        )
      {
        True -> {
          {
            let assert Ok(a) = document.query_selector("div#posteditor")
            a
          }
          |> element.set_inner_html(resp.main)
          element_actions.go_back()
          Nil
        }
        False -> {
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
      document.query_selector("button#bttn_closeeditor")
      |> unwrap
      |> element.add_event_listener("click", fn(_) { fold() })
      document.query_selector("main")
      |> unwrap
      |> element.add_event_listener("click", fn(_) { fold() })
      document.query_selector("nav#editormodepicker [data-mode-opener='short']")
      |> unwrap
      |> switch_editor_mode(render_markdown_short, render_markdown_long)
      document.query_selector_all(".editor-switcher")
      |> array.to_list
      |> list.each(fn(elm) {
        element.add_event_listener(elm, "click", fn(_) {
          switch_editor_mode(elm, render_markdown_short, render_markdown_long)
        })
      })
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

/// Switches the editor mode between short and full.
/// 
/// Is not implemented in Gleam yet.
/// Requires some functions that have been implemented in Gleam already as params.
@external(javascript, "../../../editor_ffi.mjs", "switcheditormode")
fn switch_editor_mode(
  elm: element.Element,
  render_markdown_short: fn() -> Nil,
  render_markdown_long: fn() -> Nil,
) -> Nil

fn render_markdown_short() {
  let editor_short_preview =
    document.get_element_by_id("editor-short-preview") |> unwrap
  document.get_element_by_id("editor-short-input")
  |> unwrap
  |> element_actions.get_value
  |> regexp.replace(
    each: regexp.from_string("/\\*\\*(.*?)\\*\\*/g") |> unwrap,
    in: _,
    with: "<b>$1</b>",
  )
  |> regexp.replace(
    regexp.from_string("/\\*(.*?)\\*/g") |> unwrap,
    _,
    "<i>$1</i>",
  )
  |> regexp.replace(regexp.from_string("/_(.*?)_/g") |> unwrap, _, "<i>$1</i>")
  |> regexp.replace(
    regexp.from_string("/~(.*?)~/g") |> unwrap,
    _,
    "<del>$1</del>",
  )
  |> regexp.replace(
    regexp.from_string("/\\^(.*?)\\^/g") |> unwrap,
    _,
    "<sup>$1</sup>",
  )
  |> regexp.replace(
    regexp.from_string("/`(.*?)`/g") |> unwrap,
    _,
    "<code class=\"text-blue-500 bg-slate-200 dark:text-blue-200 dark:bg-slate-600 m-1\">$1</code>",
  )
  |> element.set_inner_html(editor_short_preview, _)
}

fn render_markdown_long() {
  let editor_long_input =
    document.get_element_by_id("editor-long-input") |> unwrap

  case editor_long_input |> element_actions.get_value {
    "" -> {
      Nil
    }
    _ -> {
      element_actions.phone_home()
      |> request.set_method(Post)
      |> request.set_path("/api/fe/editor_fetch_markdownpreview")
      |> request.set_body(
        json.object([
          #("a", json.string(editor_long_input |> element_actions.get_value)),
        ])
        |> json.to_string,
      )
      |> request.set_header("Content-Type", "application/json")
      |> fetch.send()
      |> promise.try_await(fetch.read_json_body)
      |> promise.await(fn(resp) {
        let assert Ok(resp) = resp
        let w =
          decode.run(resp.body, json_long_markdown_preview_response_decoder())
        case w {
          Ok(JsonLongMarkdownPreviewResponse(True, answer)) -> {
            {
              let assert Ok(a) =
                document.query_selector("div#editor-long-preview")
              a
            }
            |> element.set_inner_html(answer)
            Nil
          }
          _ -> {
            {
              let assert Ok(a) =
                document.query_selector("div#editor-long-preview")
              a
            }
            |> element.set_inner_html(
              "<p class=\"w-full h-full text-black bg-white dark:text-white dark:bg-black\">Failed to render markdown.</p>",
            )
            Nil
          }
        }
        promise.resolve(Nil)
      })
      Nil
    }
  }
}

type JsonLongMarkdownPreviewResponse {
  JsonLongMarkdownPreviewResponse(ok: Bool, html_content: String)
}

fn json_long_markdown_preview_response_decoder() -> decode.Decoder(
  JsonLongMarkdownPreviewResponse,
) {
  use ok <- decode.field("Ok", decode.bool)
  use html_content <- decode.field("htmlContent", decode.string)
  decode.success(JsonLongMarkdownPreviewResponse(ok:, html_content:))
}
