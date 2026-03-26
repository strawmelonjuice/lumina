-record(builder, {
    handler :: fun((gleam@http@request:request(ewe@internal@http1:connection())) -> gleam@http@response:response(ewe:response_body())),
    port :: integer(),
    interface :: binary(),
    ipv6 :: boolean(),
    tls :: gleam@option:option({binary(), binary()}),
    on_start :: fun((gleam@http:scheme(), ewe:socket_address()) -> nil),
    on_crash :: gleam@http@response:response(ewe:response_body()),
    listener_name :: gleam@erlang@process:name(glisten@internal@listener:message()),
    idle_timeout :: integer()
}).
