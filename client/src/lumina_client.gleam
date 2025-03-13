//// For now, as you may see, I am compiling examples from Lustre packages into a single file.
//// Once I get time to work on the actual project, I'll adapt them further to original code fitting the project's needs.

import gleam/option.{type Option, None, Some}
import gleamy_lights/console
import gleamy_lights/premixed
import lumina_client/model.{type Model, Model}
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
import lustre_websocket

// MAIN ------------------------------------------------------------------------

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
}

// INIT ------------------------------------------------------------------------

fn init(_flags: a) -> #(Model, Effect(Msg)) {
  #(
    Model(model.Login("", ""), None, None),
    lustre_websocket.init("/connection", WsWrapper),
  )
}

// UPDATE ----------------------------------------------------------------------

pub opaque type Msg {
  WsWrapper(lustre_websocket.WebSocketEvent)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    WsWrapper(lustre_websocket.InvalidUrl) -> panic
    WsWrapper(lustre_websocket.OnTextMessage(notice)) ->
      case notice {
        "client-init" -> {
          console.log(
            "The server echoed my initialisation message! (client-init)",
          )
          #(model, effect.none())
        }
        _ -> todo as "unknown message"
      }
    WsWrapper(lustre_websocket.OnBinaryMessage(msg)) ->
      todo as "bitarray incoming, what to do?"
    WsWrapper(lustre_websocket.OnClose(_reason)) -> #(
      Model(..model, ws: None),
      effect.none(),
    )
    WsWrapper(lustre_websocket.OnOpen(socket)) -> #(
      Model(..model, ws: Some(socket)),
      lustre_websocket.send(socket, "client-init"),
    )
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  let styles = [#("width", "100vw"), #("height", "100vh"), #("padding", "1rem")]

  ui.centre(
    [attribute.style(styles)],
    ui.aside(
      [aside.min_width(70), attribute.style([#("width", "60ch")])],
      view_quote(None),
      ui.button([], [element.text("New quote")]),
    ),
  )
}

fn view_quote(quote: Option(#(String, String))) -> Element(msg) {
  case quote {
    Some(quote) ->
      ui.stack([], [
        element.text(quote.0 <> " once said..."),
        html.p([attribute.style([#("font-style", "italic")])], [
          element.text(quote.1),
        ]),
      ])
    None -> html.p([], [element.text("Click the button to get a quote!")])
  }
}
