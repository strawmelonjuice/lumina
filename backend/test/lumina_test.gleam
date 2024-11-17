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

pub fn failing_test() {
  1
  |> should.equal(2)
}

pub fn rsffi_add_test() {
  lumina_rsffi.add(1, 2)
  |> should.equal(3)
}
