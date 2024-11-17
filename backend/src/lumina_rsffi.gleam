//// This is a Gleam module that binds to the Rust FFI module rsffi

/// An example of a Rust FFI function, more useful functions can be added
@external(erlang, "rsffi", "add")
pub fn add(left: Int, right: Int) -> Int
