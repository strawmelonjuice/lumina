import gleamy_lights/helper
import gleamy_lights/premixed/gleam_colours

pub fn main() {
  helper.println(
    "Hello from the "
    <> gleam_colours.text_faff_pink("Gleam")
    <> " frontend rewrite.",
  )
}
