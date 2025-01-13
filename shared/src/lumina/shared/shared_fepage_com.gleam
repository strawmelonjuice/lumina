// Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
// Licensed under the BSD 3-Clause License. See the LICENSE file for more info.

/// A request from the client to the server to serve a page.
pub type FEPageServeRequest {
  FEPageServeRequest(location: String)
}

/// A response from the server to a request to serve a page.
pub type FEPageServeResponse {
  FEPageServeResponse(main: String, side: String, message: List(Int))
}
