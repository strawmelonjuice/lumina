//// For now, as you may see, I am compiling examples from Lustre packages into a single file.
//// Once I get time to work on the actual project, I'll adapt them further to original code fitting the project's needs.

import gleam/option.{type Option, None, Some}
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

// Lustre_http is a community package that provides a simple API for making
// HTTP requests from your update function. You can find the docs for the package
// here: https://hexdocs.pm/lustre_http/index.html
import lustre/ui
import lustre/ui/aside
import lustre_websocket as ws

// MAIN ------------------------------------------------------------------------

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
}

// MODEL -----------------------------------------------------------------------

type Model {
  Model(quote: Option(Quote))
}

type Quote {
  Quote(author: String, content: String)
}

fn init(_flags: a) -> #(Model, Effect(Msg)) {
  #(Model(None), ws.init("/path", WsWrapper))
}

// UPDATE ----------------------------------------------------------------------

pub opaque type Msg {
  WsWrapper(ws.WebSocketEvent)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    WsWrapper(InvalidUrl) -> panic
    WsWrapper(OnOpen(socket)) -> #(
      Model(..model, ws: Some(socket)),
      ws.send(socket, "client-init"),
    )
    WsWrapper(OnTextMessage(msg)) -> todo
    WsWrapper(OnBinaryMessage(msg)) -> todo as "either-or"
    WsWrapper(OnClose(reason)) -> #(Model(..model, ws: None), effect.none())
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  let styles = [#("width", "100vw"), #("height", "100vh"), #("padding", "1rem")]

  ui.centre(
    [attribute.style(styles)],
    ui.aside(
      [aside.min_width(70), attribute.style([#("width", "60ch")])],
      view_quote(model.quote),
      ui.button([], [element.text("New quote")]),
    ),
  )
}

fn view_quote(quote: Option(Quote)) -> Element(msg) {
  case quote {
    Some(quote) ->
      ui.stack([], [
        element.text(quote.author <> " once said..."),
        html.p([attribute.style([#("font-style", "italic")])], [
          element.text(quote.content),
        ]),
      ])
    None -> html.p([], [element.text("Click the button to get a quote!")])
  }
}
