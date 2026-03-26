-record(compression_extensions, {
    client_no_context_takeover :: boolean(),
    client_max_window_bits :: gleam@option:option(integer()),
    server_no_context_takeover :: boolean(),
    server_max_window_bits :: gleam@option:option(integer())
}).
