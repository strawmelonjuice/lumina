// Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
// Licensed under the BSD 3-Clause License. See the LICENSE file for more info.

import gleam/http/request.{type Request}
import gleam/int
import gleam/list

/// Encode a list of key-value pairs into a multipart form data string.
/// 
/// This function replaces the body and content-type header of a request with the encoded form data.
pub fn encode(
  req: Request(String),
  data: List(#(String, String)),
) -> Request(String) {
  let boundary =
    "---------------------------"
    <> int.to_string(int.random(1_000_000_000_000_000))
  req
  |> request.set_body(
    encoder(
      data,
      // |> dict.to_list
      boundary,
      "--" <> boundary,
    )
    <> "--\r\n",
  )
  |> request.prepend_header(
    "content-type",
    "multipart/form-data; boundary=" <> boundary,
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
