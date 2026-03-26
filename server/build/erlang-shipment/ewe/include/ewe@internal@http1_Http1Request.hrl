-record(http1_request, {
    req :: gleam@http@request:request(ewe@internal@http1:connection()),
    version :: ewe@internal@http1:http_version()
}).
