-record(table, {
    rel :: parrot@internal@sqlc:table_ref(),
    comment :: binary(),
    columns :: list(parrot@internal@sqlc:table_column())
}).
