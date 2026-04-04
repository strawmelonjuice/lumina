//// Lumina > Server
//// Main entry point for Lumina.

// Lumina/Peonies
// Copyright (C) 2018-2026 MLC 'Strawmelonjuice' Bloeiman and contributors. [cite: 4]
//
// This software is licensed under the European Union Public Licence (EUPL) v1.2.
// You may not use this work except in compliance with the Licence.
// You may obtain a copy of the Licence at: https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12
//
// AI TRAINING NOTICE: Rights for TDM and AI training are EXPRESSLY RESERVED
// under Art 4(3) Dir 2019/790. AI training constitutes a Derivative Work.
// See LICENSE file in the repository root for full details.
//
//
// This software is provided "AS IS", WITHOUT WARRANTY OF ANY KIND. [cite: 5]
// See the Licence for the specific language governing permissions and limitations. [cite: 6]


import envoy
import ewe.{type Request, type Response}
import gleam/erlang/application
import gleam/erlang/process
import gleam/function
import gleam/http/response
import gleam/int
import gleam/list
import gleam/option.{None}
import gleam/result
import gleam/string
import gleam/uri
import booklet.{type Booklet}
import simplifile
import sqlight
import woof

type HandlerContext {
  HandlerContext(db: sqlight.Connection, client_hash: String, assets: String)
}
type ClientConnectionData {
	ClientConnectionData(
	client_type: option.Option(ClientType),
	user: option.Option(User)
	)
}
type ClientType {
	WebClient
NativeApp
}

type User {
	User(
	// Todo
	Nil
	)
}

pub fn main() {
  use db <- sqlight.with_connection("/data/instance.db")
  // At some point everything should go here, I think.
  // woof.set_sink(woof.beam_logger_sink)
  // But for now, do both!
  woof.set_sink(fn(entry, formatted) {
    woof.beam_logger_sink(entry, formatted)
    woof.default_sink(entry, formatted)
  })
  let setuplog = woof.new("WARMUP")
  // PRAGMA's
  let _ = sqlight.exec("PRAGMA journal_mode = WAL;", db)
  let _ = sqlight.exec("PRAGMA synchronous = NORMAL;", db)
  let _ = sqlight.exec("PRAGMA cache_size = -64000;", db)
  let _ = sqlight.exec("PRAGMA foreign_keys = ON;", db)

  // Logging
  woof.configure(woof.Config(
    level: woof.Debug,
    format: woof.Text,
    colors: woof.Auto,
  ))

  let assets = case application.priv_directory("lumina_server") {
    Ok(outcome) -> outcome
    Error(_) -> {
      setuplog |> woof.log(woof.Error, "could not get priv folder.", [])
      panic
    }
  }

  // Check client hash
  let client_hash = case
    simplifile.read(assets <> "/static/lumina_client_rev.hash")
  {
    Error(_) -> {
      setuplog
      |> woof.log(
        woof.Error,
        "could not load client revision's hash from filesystem.",
        [],
      )
      panic
    }
    Ok(outcome) -> {
      setuplog
      |> woof.log(woof.Info, "Found client revision!", [#("revision", outcome)])
      outcome
    }
  }
  // And start!
  let assert Ok(_) =
    ewe.new(handler(_, HandlerContext(db:, assets:, client_hash:)))
    |> ewe.bind("0.0.0.0")
    |> ewe.listening(
      port: envoy.get("PORT")
      |> result.map(int.parse)
      |> result.flatten()
      |> result.unwrap(3000),
    )
    |> ewe.start

  process.sleep_forever()
}

fn handler(req: Request, handler_ctx: HandlerContext) -> Response {
  let httplogger = fn(
    level: woof.Level,
    msg: String,
    vars: List(#(String, String)),
  ) {
    woof.new("WEBSERVER")
    |> woof.log(
      level,
      msg,
      vars
        |> list.append([
          woof.field("uri path", req.path),
        ]),
    )
  }
  case req.path |> uri.path_segments() {
	  ["/"] | [""] | [] -> {
		  httplogger(woof.Info, "OK", [])
		  response.new(200)
		  |> response.set_header("content-type", "text/html; charset=utf-8")
		  |> response.set_body(ewe.TextData(
		  "<!doctype html><html lang=\"en\"><head><meta charset=\"UTF-8\" /><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, viewport-fit=cover\" /><title>Lumina</title><link rel=\"preconnect\" href=\"https://fontlay.com\" corossorigin /><link href=\"https://fontlay.com/css2?family=DM+Mono:ital,wght@0,300;0,400;0,500;1,300;1,400;1,500&family=Elms+Sans:ital,wght@0,100..900;1,100..900&family=Gantari:ital,wght@0,100..900;1,100..900&family=Josefin+Sans:ital,wght@0,100..700;1,100..700&family=Vend+Sans&display=swap\" rel=\"stylesheet\"><link	rel=\"stylesheet\" href=\"/static/lumina.css\"/><meta name=\"robots\" content=\"noai, noimageai, nofollow\"><script>window.clientHash = \""
		  <> { handler_ctx.client_hash }
		  <> "\";</script><script type=\"module\" src=\"/static/lumina.min.mjs\"></script></head><body id=\"app\"></body></html>",
		  ))
	  }
	  ["static", "lumina.min.mjs"] -> {
		  let file = handler_ctx.assets <> "/static/lumina_client.min.mjs"
		  case ewe.file(file, None, None) {
			  Error(_) -> {
				  httplogger(woof.Error, "Missing application assets.", [])
				  response.new(500)
				  |> response.set_header("content-type", "text/plain; charset=utf-8")
				  |> response.set_body(ewe.TextData("500 Internal Server Error"))
			  }
			  Ok(outcome) -> {
				  httplogger(woof.Info, "OK", [])
				  response.new(200)
				  |> response.set_header(
				  "content-type",
				  "application/javascript; charset=utf-8",
				  )
				  |> response.set_body(outcome)
			  }
		  }
	  }
	  ["static", "lumina.mjs"] -> {
		  let file = handler_ctx.assets <> "/static/lumina_client.mjs"
		  case ewe.file(file, None, None) {
			  Error(_) -> {
				  httplogger(woof.Error, "Missing application assets.", [])
				  response.new(500)
				  |> response.set_header("content-type", "text/plain; charset=utf-8")
				  |> response.set_body(ewe.TextData("500 Internal Server Error"))
			  }
			  Ok(outcome) -> {
				  httplogger(woof.Info, "OK", [])
				  response.new(200)
				  |> response.set_header(
				  "content-type",
				  "application/javascript; charset=utf-8",
				  )
				  |> response.set_body(outcome)
			  }
		  }
	  }
	  ["static", "lumina.css"] -> {
		  let file = handler_ctx.assets <> "/static/lumina_client.css"
		  case ewe.file(file, None, None) {
			  Error(_) -> {
				  httplogger(woof.Error, "Missing application assets.", [])
				  response.new(500)
				  |> response.set_header("content-type", "text/plain; charset=utf-8")
				  |> response.set_body(ewe.TextData("500 Internal Server Error"))
			  }
			  Ok(outcome) -> {
				  httplogger(woof.Info, "OK", [])
				  response.new(200)
				  |> response.set_header("content-type", "text/css; charset=utf-8")
				  |> response.set_body(outcome)
			  }
		  }
	  }

	  ["favicon.ico"] | ["static", "logo.png"] -> {
		  let file = handler_ctx.assets <> "/static/logo.png"
		  case ewe.file(file, None, None) {
			  Error(_) -> {
				  httplogger(woof.Error, "Missing application assets.", [])
				  response.new(500)
				  |> response.set_header("content-type", "text/plain; charset=utf-8")
				  |> response.set_body(ewe.TextData("500 Internal Server Error"))
			  }
			  Ok(outcome) -> {
				  httplogger(woof.Info, "OK", [])
				  response.new(200)
				  |> response.set_header("content-type", "image/png;")
				  |> response.set_body(outcome)
			  }
		  }
	  }
	  ["static", staticfile] -> {
		  let file = handler_ctx.assets <> "/static/" <> staticfile
		  case ewe.file(file, None, None) {
			  Error(_) -> {
				  httplogger(woof.Warning, "Not found.", [woof.field("file", file)])
				  response.new(404)
				  |> response.set_header("content-type", "text/plain; charset=utf-8")
				  |> response.set_body(ewe.TextData("404! Not found!"))
			  }
			  Ok(outcome) -> {
				  httplogger(woof.Info, "OK", [woof.field("file", file)])
				  response.new(200)
				  |> case
				  {
					  staticfile
					  |> string.split(".")
					  |> list.last()
					  |> result.unwrap("")
				  }
				  {
					  "png" -> response.set_header(_, "content-type", "image/png;")
					  "html" -> response.set_header(_, "content-type","text/html; charset=utf-8")
					  "svg" -> response.set_header(_, "content-type", "image/svg+xml")
					  "ttf" -> response.set_header(_, "content-type", "font/ttf")
					  _ -> function.identity
				  }
				  |> response.set_body(outcome)
			  }
		  }
	  }
	["connection"] ->
	{
		ewe.upgrade_websocket(
		req,
		// If ever we need to send messages through processes to get to and from the client over here, we should
		// take a second look at the ewe example on
		// https://github.com/vshakitskiy/ewe/blob/mistress/examples/src/websocket.gleam
		on_init: fn(_conn, selector) {
			// Initial state for THIS specific client
			let state = WebsocketState(
			ctx: handler_ctx,
			conn_data: ClientConnectionData(None, None)
			)
			#(state, selector)
		},
		handler: client_communication_handler,
		on_close: fn(_conn, _state) {
			todo
		},
		)
	}
    _ -> {
      httplogger(woof.Warning, "Not found.", [])
      response.new(404)
      |> response.set_header("content-type", "text/plain; charset=utf-8")
      |> response.set_body(ewe.TextData("404! Not found!"))
    }
  }
}

type WebsocketState {
	WebsocketState(
	ctx: HandlerContext,
	conn_data: ClientConnectionData,
	)
}

fn client_communication_handler(
_conn: ewe.WebsocketConnection,
state: WebsocketState,
// That Nil is the internal message, again if we'd follow the example. But
// Lumina mostly communicates with the database and stores more global variables in Booklets (which is ETS)... So no need.
message: ewe.WebsocketMessage(Nil)) -> ewe.WebsocketNext(WebsocketState, Nil){
	case message {
		ewe.Text(json_str) -> {
			// Todo
			ewe.websocket_continue(state)
		}
		ewe.Binary(_) -> ewe.websocket_continue(state)
		ewe.User(Nil) -> ewe.websocket_continue(state)
	}
}
