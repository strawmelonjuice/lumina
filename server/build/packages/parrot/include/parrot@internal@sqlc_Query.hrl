-record('query', {
    text :: binary(),
    name :: binary(),
    cmd :: parrot@internal@sqlc:query_cmd(),
    filename :: binary(),
    columns :: list(parrot@internal@sqlc:table_column()),
    insert_into_table :: gleam@option:option(parrot@internal@sqlc:table_ref()),
    comments :: list(binary()),
    params :: list(parrot@internal@sqlc:query_param())
}).
