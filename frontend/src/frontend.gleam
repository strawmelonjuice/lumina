// Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
// Licensed under the BSD 3-Clause License. See the LICENSE file for more info.


import gleamy_lights/helper
import gleamy_lights/premixed/gleam_colours

pub fn main() {
  helper.println(
    "Hello from the "
    <> gleam_colours.text_faff_pink("Gleam")
    <> " frontend rewrite.",
  )
}
