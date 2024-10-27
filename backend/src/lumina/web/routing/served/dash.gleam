//// Dashboard routes and handlers

// Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
// Licensed under the BSD 3-Clause License. See the LICENSE file for more info.

import lumina/data/context.{type Context}
import lumina/web/pages
import lumina/web/routing/fence
import lustre/element
import wisp

pub fn homeroute(req: wisp.Request, ctx: Context) -> wisp.Response {
  use _, user <- fence.fence(_, req, ctx)
  pages.dash(ctx, user)
  |> element.to_document_string_builder
  |> wisp.html_response(200)
}
