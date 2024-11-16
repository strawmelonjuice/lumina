// Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
// Licensed under the BSD 3-Clause License. See the LICENSE file for more info.

import gleamy_lights/helper as web_io
import gleamy_lights/premixed
import gleamy_lights/premixed/gleam_colours

pub fn home_render() {
  web_io.println(
	"Detected you are on the " <> premixed.text_pink("home page") <> ".",
	)
}

pub fn index_render() {
	web_io.println(
	"Detected you are on the " <> gleam_colours.text_faff_pink("first page") <> ".",
	)
}
