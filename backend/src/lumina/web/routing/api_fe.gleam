//// Module handling API's to the front end

// Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
// Licensed under the BSD 3-Clause License. See the LICENSE file for more info.

import gleam/bool
import gleam/dynamic
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleam/string_builder
import lumina/data/context.{type Context}
import lumina/shared/shared_fejsonobject
import lumina/shared/shared_users
import lumina/users
import lumina/web/pages
import lumina/web/routing/fence
import lumina_rsffi
import lustre/element
import wisp.{type Request, type Response}
import wisp_kv_sessions

pub fn get_update(req: Request, ctx: Context) -> Response {
  let uid = case
    wisp_kv_sessions.get(ctx.session_config, req, "uid", dynamic.int)
  {
    Ok(option.Some(user)) -> {
      // wisp.log_info("Logged in.")
      Some(user)
    }
    // If the session is not found, the user is not logged in
    _ -> {
      // wisp.log_info("Not logged in.")
      None
    }
  }
  let username = case uid {
    Some(id) -> {
      case users.fetch(ctx, id) {
        Some(user) -> user.username
        None -> "unset"
      }
    }
    None -> {
      "unset"
    }
  }
  let clientdata =
    shared_fejsonobject.FEJSonObj(
      pulled: 0,
      instance: shared_fejsonobject.FEJsonObjInstanceInfo(
        iid: "localhost",
        last_sync: 0,
      ),
      user: shared_users.SafeUser(id: -1, username: username, email: "unset"),
    )
  json.object([
    #(
      "instance",
      json.object([
        #("iid", json.string(clientdata.instance.iid)),
        #("last_sync", json.int(clientdata.instance.last_sync)),
      ]),
    ),
    #(
      "user",
      json.object([
        #("id", json.int(clientdata.user.id)),
        #("username", json.string(clientdata.user.username)),
        #("email", json.string(clientdata.user.email)),
      ]),
    ),
  ])
  |> json.to_string_builder
  |> wisp.html_response(200)
}

pub fn auth(req: wisp.Request, ctx: context.Context) {
  wisp.log_info("Authentication request received.")
  use form <- wisp.require_form(req)
  case form.values {
    [#("password", password), #("username", username)] -> {
      // The form data is in. Now we can use it to authenticate this user.
      case users.auth(username, password, ctx) {
        Ok(Some(id)) -> {
          // If the user is authenticated, we can store their user ID in the session.
          let d = fn(continue: fn() -> Response) {
            case
              wisp_kv_sessions.set(
                ctx.session_config,
                req,
                "uid",
                id,
                fn(in: Int) { json.int(in) |> json.to_string },
              )
            {
              Ok(_) -> continue()
              Error(e) -> {
                wisp.log_critical(
                  "Error in setting session: " <> string.inspect(e),
                )
                wisp.internal_server_error()
              }
            }
          }

          use <- d()
          // Then send them on
          string_builder.from_string("{\"Ok\": true, \"Errorvalue\": \"\"}")
          |> wisp.json_response(200)
        }
        Error(e) ->
          case e {
            users.PasswordIncorrect -> {
              string_builder.from_string(
                "{\"Ok\": false, \"Errorvalue\": \"No user known with that username-password combination.\"}",
              )
              |> wisp.json_response(401)
            }
            users.InvalidIdentifier -> {
              wisp.log_warning("Invalid identifier in auth")
              wisp.response(422)
            }
            users.NonexistentUser -> {
              wisp.log_warning("Nonexistent user in auth")
              string_builder.from_string(
                "{\"Ok\": false, \"Errorvalue\": \"No user known with that username-password combination.\"}",
              )
              |> wisp.json_response(401)
            }
            users.Unspecified -> {
              wisp.log_critical("Unspecified error in auth")
              wisp.internal_server_error()
            }

            users.DataBaseError(d) -> {
              wisp.log_critical(string.inspect(d))
              wisp.internal_server_error()
            }
            users.DecryptionError(e) -> {
              wisp.log_critical(
                "Decryption error in auth: " <> string.inspect(e),
              )
              wisp.internal_server_error()
            }
          }
        _ -> {
          wisp.unprocessable_entity()
        }
      }
    }
    _ -> {
      io.println("Invalid form data in auth")
      wisp.log_warning("Invalid form data in auth")
      wisp.bad_request()
      |> wisp.set_body(wisp.Text(
        "Invalid form data" |> string_builder.from_string,
      ))
    }
  }
}

pub fn create_user(req: wisp.Request, ctx: context.Context) {
  use form <- wisp.require_form(req)
  case form.values {
    [#("email", email), #("password", password), #("username", username)] -> {
      case users.add_user(ctx, username, email, password) {
        Ok(new_uid) -> {
          let assert Ok(_) =
            wisp_kv_sessions.set(
              ctx.session_config,
              req,
              "uid",
              new_uid,
              fn(in: Int) { json.int(in) |> json.to_string },
            )

          string_builder.from_string("{\"Ok\": true, \"Errorvalue\": \"\"}")
          |> wisp.json_response(200)
        }
        Error(e) -> {
          wisp.log_error("Error in creating user: " <> string.inspect(e))
          case e {
            users.UsernameCharacters
            | users.UsernameTooShort
            | users.InvalidEmail
            | users.PasswordTooShort -> {
              string_builder.from_string(
                "{\"Ok\": false, \"Errorvalue\": \""
                <> e |> string.inspect()
                <> "\"}",
              )
              |> wisp.json_response(417)
            }
            users.EncryptError -> {
              wisp.log_critical("Hash Error.")
              wisp.response(412)
            }
            users.RegexError(f) -> {
              wisp.log_critical("Regex Error: " <> string.inspect(f))
              wisp.bad_request()
            }
            users.DatabaseError(f) -> {
              wisp.log_critical("Database Error: " <> f)
              wisp.unprocessable_entity()
            }
            users.ReturnError -> {
              wisp.log_critical("Return Error.")
              wisp.internal_server_error()
            }
          }
        }
      }
    }
    _ -> {
      wisp.unprocessable_entity()
    }
  }
}

type FEPageServeRequest {
  FEPageServeRequest(location: String)
}

type FEPageServeResponse {
  FEPageServeResponse(main: String, side: String, message: List(Int))
}

pub fn pagesrverresponder(req: wisp.Request, ctx: context.Context) {
  let pagesrverresponseencoder = fn(response: FEPageServeResponse) {
    json.object([
      #("main", json.string(response.main)),
      #("side", json.string(response.side)),
      #("message", json.array(response.message, json.int)),
    ])
    |> json.to_string_builder
    |> wisp.json_response(200)
  }
  use req, _user <-
    fence.shield(
      _,
      fn(_) {
        FEPageServeResponse(
          main: "It seems your session has expired.",
          side: "",
          message: [1],
        )
        |> pagesrverresponseencoder
      },
      req,
      ctx,
    )
  use json <- wisp.require_json(req)
  let decode_fe_page_serve_req = fn(json: dynamic.Dynamic) -> Result(
    FEPageServeRequest,
    dynamic.DecodeErrors,
  ) {
    let decoder =
      dynamic.decode1(
        FEPageServeRequest,
        dynamic.field("location", dynamic.string),
      )
    decoder(json)
  }
  use <- wisp.rescue_crashes
  let data_ = decode_fe_page_serve_req(json)
  use <- bool.lazy_guard(data_ |> result.is_error, fn() { wisp.bad_request() })
  let assert Ok(data) = data_
  case data.location {
    "test" ->
      FEPageServeResponse(main: "test (todo)", side: "test", message: [])

    "home" ->
      FEPageServeResponse(
        main: "
<h1>welcome to instance <code class=\"placeholder-iid\"></code></h1>
			<p>
				as you can see, there is no such thing as a homepage. lumina is
				not ready for anything yet.
			</p>
			",
        side: "todo",
        message: [],
      )

    "notifications-centre" ->
      FEPageServeResponse(
        main: "Notifications should show up here!",
        side: "",
        message: [33],
      )

    "editor" ->
      FEPageServeResponse(
        main: {
          pages.editor(ctx)
          |> element.to_string
        },
        side: "",
        message: [34],
      )
    _ -> {
      FEPageServeResponse(main: "404", side: "404", message: [2])
    }
  }
  |> pagesrverresponseencoder
}

type MarkdownPreviewRequest {
  MarkdownPreviewRequest(markdown: String)
}

type MarkdownPreviewResponse {
  MarkdownPreviewResponse(ok: Bool, html: String)
}

pub fn editor_preview_markdown(req: wisp.Request, _ctx: context.Context) {
  let pagesrverresponseencoder = fn(response: MarkdownPreviewResponse) {
    json.object([
      #("Ok", json.bool(response.ok)),
      #("htmlContent", json.string(response.html)),
    ])
    |> json.to_string_builder
    |> wisp.json_response(200)
  }
  // Disabled the fence for now.
  // use req, _user <-
  //   fence.shield(
  //     _,
  //     fn(_) {
  //       MarkdownPreviewResponse(
  //         ok: False,
  //         html: "It seems your session has expired.",
  //       )
  //       |> pagesrverresponseencoder
  //     },
  //     req,
  //     ctx,
  //   )
  use json <- wisp.require_json(req)
  let decode_req = fn(json: dynamic.Dynamic) -> Result(
    MarkdownPreviewRequest,
    dynamic.DecodeErrors,
  ) {
    let decoder =
      dynamic.decode1(
        MarkdownPreviewRequest,
        dynamic.field("a", dynamic.string),
      )
    decoder(json)
  }
  use <- wisp.rescue_crashes
  let data_ = decode_req(json)
  use <- bool.lazy_guard(data_ |> result.is_error, fn() { wisp.bad_request() })
  let assert Ok(data) = data_
  MarkdownPreviewResponse(ok: True, html: {
    let assert Ok(html) =
      data.markdown
      |> lumina_rsffi.md_render_to_html
    html
  })
  |> pagesrverresponseencoder
}

import lumina/users/avatars

pub fn get_avatar(_req: wisp.Request, ctx: context.Context, id: String) {
  let uid_maybe = id |> int.parse

  case
    uid_maybe
    |> result.map(fn(i) { users.fetch(ctx, i) })
  {
    Ok(Some(user)) -> {
      // Currently, avatar is not implemented.
      case user |> avatars.get(ctx, _) {
        Some(avatar) -> {
          wisp.html_response(avatar, 200)
          |> wisp.set_header("Content-Type", "image/svg+xml")
        }
        None -> {
          let _ = user
          avatars.anonymous(ctx)
          |> result.map(fn(l) {
            l
            |> list.shuffle
            |> list.first
            |> result.map_error(fn(_) { Nil })
            |> result.map(fn(a) {
              a
              |> string_builder.from_string
              |> wisp.html_response(200)
              |> wisp.set_header("Content-Type", "image/svg+xml")
            })
          })
          |> result.flatten
          |> result.map_error(fn(_) { wisp.internal_server_error() })
          |> result.unwrap_both
        }
      }
    }
    _ -> {
      wisp.bad_request()
    }
  }
}
