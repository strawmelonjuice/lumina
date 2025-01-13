import plinth/javascript/console

/// Be bad!
/// This is a bad way to unwrap a Result. It will panic if the Result is an Error.
/// However, we know what's in the HTML, so we can safely unwrap it.
pub fn unwrap(p: Result(a, e)) -> a {
  case p {
    Ok(a) -> a
    Error(e) -> {
      console.error(e)
      panic as "Failed to unwrap Result"
    }
  }
}
