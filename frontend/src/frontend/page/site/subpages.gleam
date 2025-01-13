import gleam/dynamic
import gleam/fetch
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/javascript/promise
import gleam/json
import lumina/shared/shared_fepage_com.{
  type FEPageServeResponse, FEPageServeResponse,
}
import plinth/browser/window

pub fn fetch(page: String, then: fn(Result(FEPageServeResponse, Nil)) -> Nil) {
  {
    let req =
      {
        let assert Ok(a) = request.to(window.origin() <> "/api/fe/fetch-page")
        a
      }
      |> request.set_body("{\"location\": \"" <> page <> "\"}")
      |> request.set_header("Content-Type", "application/json")
      |> request.set_method(http.Post)
    use resp <- promise.try_await(fetch.send(req))
    use resp <- promise.try_await(fetch.read_text_body(resp))
    promise.resolve(Ok(resp))
  }
  |> promise.await(fn(a: Result(response.Response(String), fetch.FetchError)) {
    case a {
      Ok(b) -> {
        case
          json.decode(
            from: b.body,
            using: dynamic.decode3(
              FEPageServeResponse,
              dynamic.field("main", dynamic.string),
              dynamic.field("side", dynamic.string),
              dynamic.field("message", dynamic.list(dynamic.int)),
            ),
          )
        {
          Ok(c) -> then(Ok(c))
          Error(_) -> then(Error(Nil))
        }
      }
      Error(_) -> then(Error(Nil))
    }
    promise.resolve(Nil)
  })
}
