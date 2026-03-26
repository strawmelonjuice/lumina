import ewe/internal/http1.{type Connection, type ResponseBody} as ewe_http
import ewe/internal/http1/handler as http1_handler
import gleam/bytes_tree
import gleam/erlang/process
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/option.{type Option, Some}
import gleam/otp/actor
import gleam/otp/factory_supervisor as factory
import glisten
import glisten/transport
import logging

/// State of the request handler.
///
pub type Handler {
  Http1(state: http1_handler.Http1Handler, self: process.Subject(Nil))
}

/// Initializes the request handler state.
///
pub fn init(_) -> #(Handler, Option(process.Selector(Nil))) {
  let subject = process.new_subject()
  let selector =
    process.new_selector()
    |> process.select(subject)

  #(Http1(http1_handler.init(), self: subject), Some(selector))
}

/// Main loop that processes incoming messages.
///
pub fn loop(
  handler: fn(Request(Connection)) -> Response(ResponseBody),
  on_crash: Response(ResponseBody),
  factory_name: process.Name(
    factory.Message(fn() -> Result(actor.Started(Nil), actor.StartError), Nil),
  ),
  idle_timeout: Int,
) -> glisten.Loop(Handler, Nil) {
  fn(
    state: Handler,
    message: glisten.Message(Nil),
    conn: glisten.Connection(Nil),
  ) -> glisten.Next(Handler, glisten.Message(Nil)) {
    let sender = conn.subject
    let conn = ewe_http.transform_connection(conn, factory_name)

    case state, message {
      Http1(state, self), glisten.Packet(message) -> {
        let result =
          http1_handler.handle_packet(
            state,
            conn,
            message,
            sender,
            handler,
            on_crash,
            idle_timeout,
          )

        case result {
          http1_handler.Continue(state) -> glisten.continue(Http1(state, self))
          http1_handler.Http2Upgrade(http1_handler.Direct(_data)) -> {
            logging.log(logging.Notice, "HTTP/2 upgrade; sending goaway")
            let goaway = <<
              0:size(24), 4, 0, 0:size(32), 8:size(24), 7, 0, 0:size(32),
              0:size(32), 13:size(32),
            >>

            let _ =
              transport.send(
                conn.transport,
                conn.socket,
                bytes_tree.from_bit_array(goaway),
              )

            glisten.stop()
          }
          http1_handler.Stop
          | http1_handler.Http2Upgrade(http1_handler.Upgrade(..)) ->
            glisten.stop()
        }
      }
      _, _ -> glisten.stop()
    }
  }
}
