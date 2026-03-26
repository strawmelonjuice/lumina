-record(builder, {
    request :: gleam@http@request:request(any()),
    named :: gleam@option:option(gleam@erlang@process:name(collie:websocket_message(any()))),
    connection_timeout :: integer(),
    initialise :: fun((gleam@erlang@process:subject(collie:websocket_message(any()))) -> {ok,
            collie:initialised(any(), any())} |
        {error, binary()}),
    handler :: fun((collie:connection(), any(), collie:message(any())) -> collie:next(any(), any())),
    on_close :: fun((any(), collie:close_reason()) -> nil)
}).
