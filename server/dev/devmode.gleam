import gleam/string
import simplifile
import sqlight

/// This will generate the testing username-password combinations defined in the README, as well
/// as a `/data/debug` file, which sets log levels to... Yup! To debug instead of Info
pub fn main() {
  case simplifile.create_file("../data/configvars/debug") {
    Ok(..) | Error(simplifile.Eexist) -> Nil
    Error(fuck) -> {
      let fucking_error = string.inspect(fuck)
      panic as fucking_error
    }
  }
  use db <- sqlight.with_connection("../data/instance.db")
  // todo as "The database changes for creating a user are yet unknown."
  Nil
}
