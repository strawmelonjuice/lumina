//// Request routing module

// Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
// Licensed under the BSD 3-Clause License. See the LICENSE file for more info.

import gleam/bool
import gleam/http.{Get, Post}
import gleam/string
import gleam/string_builder
import lumina/data/context.{type Context}
import lumina/web/pages
import lumina/web/routing/api_fe
import lumina/web/routing/served/dash
import lustre/element
import simplifile as fs
import wisp.{type Request, type Response}
import wisp_kv_sessions

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- static(req, ctx)
  use req <- wisp_kv_sessions.middleware(ctx.session_config, req)

  case req.method {
    Get -> {
      // If the request path ends with .svg, serve the SVG file
      use <- bool.lazy_guard(
        when: req.path
        |> string.ends_with(".svg")
          && {
          let assert Ok(a) =
            fs.is_file(ctx.priv_directory <> "/static/svg/" <> req.path)
          a
        },
        return: fn() {
          // let assert Ok(svg) =
          // fs.read(from: ctx.priv_directory <> "/static/svg/" <> req.path)
          // wisp.html_response(string_builder.from_string(svg), 200)
          wisp.response(200)
          |> wisp.set_body(wisp.File(
            ctx.priv_directory <> "/static/svg/" <> req.path,
          ))
          |> wisp.set_header("Content-Type", "image/svg+xml")
        },
      )
      // Normal routing
      case wisp.path_segments(req) {
        [] -> {
          pages.index(ctx)
          |> element.to_document_string_builder
          |> wisp.html_response(200)
        }
        ["logo.svg"] -> {
          // let assert Ok(svg) =
          // fs.read(from: ctx.priv_directory <> "/static/svg/luminalogo-1.svg")
          // wisp.html_response(string_builder.from_string(svg), 200)
          wisp.response(200)
          |> wisp.set_body(wisp.File(
            ctx.priv_directory <> "/static/svg/luminalogo-1.svg",
          ))
          |> wisp.set_header("Content-Type", "image/svg+xml")
        }
        ["logo.png"] | ["favicon.ico"] -> {
          wisp.response(200)
          |> wisp.set_body(wisp.File(
            ctx.priv_directory <> "/static/png/luminalogo-1.png",
          ))
          |> wisp.set_header("Content-Type", "image/png")
        }
        ["api", "fe", "update"] -> api_fe.get_update(req, ctx)
        ["login"] -> {
          pages.login(ctx)
          |> element.to_document_string_builder
          |> wisp.html_response(200)
        }
        ["signup"] -> {
          pages.signup(ctx)
          |> element.to_document_string_builder
          |> wisp.html_response(200)
        }

        ["session", "logout"] -> {
          let assert Ok(_) =
            wisp_kv_sessions.delete_session(ctx.session_config, req)
          wisp.redirect("/login")
        }
        ["home"] -> {
          dash.homeroute(req, ctx)
        }

        ["app.js"] -> {
          let fpath = ctx.priv_directory <> "/generated/js/app.js"
          // io.println(fpath)
          let assert Ok(js) = fs.read(from: fpath)
          wisp.html_response(string_builder.from_string(js), 200)
          |> wisp.set_header("Content-Type", "text/javascript")
        }
        ["api", "test"] -> {
          wisp.response(200)
          |> wisp.set_body(wisp.Text("FETCHED!" |> string_builder.from_string))
          |> wisp.set_header("Content-Type", "text/plain")
        }
        ["user", "avatar", id] -> api_fe.get_avatar(req, ctx, id)
        ["app.js.map"] -> {
          wisp.log_info("\t\tOoh, someone is debugging?")
          let fpath = ctx.priv_directory <> "/generated/js/app.js.map"
          // io.println(fpath)
          let assert Ok(js) = fs.read(from: fpath)
          wisp.html_response(string_builder.from_string(js), 200)
          |> wisp.set_header("Content-Type", "application/json")
        }
        _ -> {
          wisp.not_found()
        }
      }
    }
    Post -> {
      // Normal routing for POST.
      case wisp.path_segments(req) {
        ["api", "fe", "auth"] -> api_fe.auth(req, ctx)
        ["api", "fe", "auth-create"] -> api_fe.create_user(req, ctx)
        ["api", "fe", "fetch-page"] -> api_fe.pagesrverresponder(req, ctx)
        ["api", "fe", "editor_fetch_markdownpreview"] ->
          api_fe.editor_preview_markdown(req, ctx)
        _ ->
          wisp.not_found()
          |> wisp.set_body(wisp.Text(
            "Invalid POST request" |> string_builder.from_string,
          ))
      }
    }
    _ -> {
      wisp.method_not_allowed([Get, Post])
    }
  }
}

pub fn static(
  req: wisp.Request,
  ctx: Context,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  // use <- wisp.serve_static(req, under: "/static", from: ctx.static_directory)
  use <- wisp.serve_static(
    req,
    under: "/fonts",
    from: ctx.priv_directory <> "/static/fonts",
  )
  use <- wisp.serve_static(
    req,
    under: "/favicon.ico",
    from: ctx.priv_directory <> "/static/png/luminalogo-1.png",
  )
  handle_request(req)
}
