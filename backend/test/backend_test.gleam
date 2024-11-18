import gleeunit
import gleeunit/should
import lumina_rsffi

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  1
  |> should.equal(1)
}

pub fn rsffi_add_test() {
  lumina_rsffi.add(1, 2)
  |> should.equal(3)
}

pub fn rsffi_md_render_to_html_test() {
  lumina_rsffi.md_render_to_html("# Hello, world!")
  |> should.equal(Ok("<h1>Hello, world!</h1>"))
}
