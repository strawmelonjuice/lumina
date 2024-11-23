// Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
// Licensed under the BSD 3-Clause License. See the LICENSE file for more info.

import gleam/int
import gleam/list

/// Encode a list of key-value pairs into a multipart form data string.
/// 
/// Returns:
/// `#(String a, String b)` where a is the encoded form data string and b is the boundary used.
pub fn encode(data: List(#(String, String))) -> #(String, String) {
  let boundary =
    "---------------------------"
    <> int.to_string(int.random(1_000_000_000_000_000))
  #(
    encoder(
      data,
      // |> dict.to_list
      boundary,
      "--" <> boundary,
    )
      <> "--\r\n",
    boundary,
  )
}

fn encoder(
  rest: List(#(String, String)),
  boundary: String,
  complete: String,
) -> String {
  case list.first(rest) {
    Error(_) -> complete
    Ok(#(key, value)) -> {
      case list.rest(rest) {
        Ok(new_rest) ->
          encoder(
            new_rest,
            boundary,
            complete
              <> "\r\n"
              <> "Content-Disposition: form-data; name=\""
              <> key
              <> "\""
              <> "\r\n"
              <> "\r\n"
              <> value
              <> "\r\n"
              <> "--"
              <> boundary,
          )
        Error(_) -> complete
      }
    }
  }
}
