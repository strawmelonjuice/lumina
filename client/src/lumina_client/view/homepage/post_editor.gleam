//// Lumina > Client > View > Application/Homepage > Post Editor
//// This module contains the post editor.

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

import lumina_client/view/common_view_parts/svgs
import gleam/dict
import lumina_client/message_type.{type Msg}
import lumina_client/model_type
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

/// Post editor's exposed view function.
/// Parameters:
///  params - dict of String to String, these are params specific to the post editor modal, and also exist in the wider model, beit behind a wrapped option.
///  model - the full application model, in case the post editor needs to read from it
pub fn main(
  params: dict.Dict(String, String),
model: model_type.Model,
) -> Element(Msg) {
	// Placeholder implementation
	html.div([attribute.class("tabs tabs-lift")], [
	html.label([attribute.class("tab")], [
	html.input([attribute.name("editortypeswitch"), attribute.type_("radio")]),
	svgs.pen("class size-4 me-2"),
	html.text(" Jot "),
	]),
	html.div([attribute.class("tab-content bg-base-100 border-base-300 p-6")], [
	text_post_editor(params, model)
	]),
	html.label([attribute.class("tab")], [
	html.input([
	attribute.checked(True),
	attribute.name("editortypeswitch"),
	attribute.type_("radio"),
	]),
	svgs.camera("class size-4 me-2"),

	html.text(" Snap ")
	]),
	html.div([attribute.class("tab-content bg-base-100 border-base-300 p-6")], [
	media_post_editor(params, model)
	]),
	html.label([attribute.class("tab")], [
	html.input([attribute.name("editortypeswitch"), attribute.type_("radio")]),
	svgs.pen_paper("class size-4 me-2"),

	html.text(" Compose "),
	]),
	html.div([attribute.class("tab-content bg-base-100 border-base-300 p-6")], [
	article_post_editor(params, model)
	]),
	])
}

fn text_post_editor(
params: dict.Dict(String, String),
  _model: model_type.Model,
) -> Element(Msg) {
	html.div([], [
	html.text("This is the text post editor!"),
	])
}

fn media_post_editor(
params: dict.Dict(String, String),
_model: model_type.Model,
) -> Element(Msg) {
	html.div([], [
	html.text("This is the media post editor!"),
	])
}

fn article_post_editor(
params: dict.Dict(String, String),
_model: model_type.Model,
) -> Element(Msg) {
	html.div([], [
	html.text("This is the article post editor!"),
	])
}
