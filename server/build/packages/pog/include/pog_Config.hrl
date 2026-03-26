-record(config, {
    pool_name :: gleam@erlang@process:name(pog:message()),
    host :: binary(),
    port :: integer(),
    database :: binary(),
    user :: binary(),
    password :: gleam@option:option(binary()),
    ssl :: pog:ssl(),
    connection_parameters :: list({binary(), binary()}),
    pool_size :: integer(),
    queue_target :: integer(),
    queue_interval :: integer(),
    idle_interval :: integer(),
    trace :: boolean(),
    ip_version :: pog:ip_version(),
    rows_as_map :: boolean()
}).
