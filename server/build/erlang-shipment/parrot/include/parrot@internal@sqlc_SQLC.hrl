-record(s_q_l_c, {
    sqlc_version :: binary(),
    plugin_options :: binary(),
    global_options :: binary(),
    catalog :: parrot@internal@sqlc:catalog(),
    queries :: list(parrot@internal@sqlc:'query'())
}).
