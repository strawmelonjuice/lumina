-record(s_s_e_event, {
    event :: gleam@option:option(binary()),
    data :: binary(),
    id :: gleam@option:option(binary()),
    retry :: gleam@option:option(integer())
}).
