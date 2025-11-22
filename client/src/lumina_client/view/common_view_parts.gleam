//// Lumina > Client > View > Application/Homepage > Common View Parts
//// This module contains common view parts used across Lumina client views.

//	Lumina/Peonies
//	Copyright (C) 2018-2026 MLC 'Strawmelonjuice'  Bloeiman and contributors.
//
//	This program is free software: you can redistribute it and/or modify
//	it under the terms of the GNU Affero General Public License as published
//	by the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	This program is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU Affero General Public License for more details.
//
//	You should have received a copy of the GNU Affero General Public License
//	along with this program.  If not, see <https://www.gnu.org/licenses/>.

import lumina_client/message_type.{type Msg}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn common_view_parts(
  main_body: List(Element(Msg)),
  with_menu menuitems: List(Element(Msg)),
) {
  html.div([attribute.class("font-sans")], [
    html.div(
      [attribute.class("navbar bg-base-100 dark:bg-neutral-800 shadow-sm")],
      [
        html.div([attribute.class("flex-none")], [
          html.button([attribute.class("")], [
            html.img([
              attribute.src("/static/logo.svg"),
              attribute.alt("Lumina logo"),
              attribute.class("h-8"),
            ]),
          ]),
        ]),
        html.div([attribute.class("flex-1")], [
          html.a([attribute.class("btn btn-ghost text-xl font-logo")], [
            element.text("Lumina"),
          ]),
        ]),
        html.div([attribute.class("flex-none")], [
          html.ul(
            [attribute.class("menu menu-horizontal px-1 font-menuitems")],
            menuitems,
          ),
        ]),
      ],
    ),
    html.div(
      [attribute.class("bg-base-200 h-screen max-h-[calc(100vh-4rem)]")],
      main_body,
    ),
  ])
}
