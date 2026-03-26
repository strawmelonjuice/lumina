-record(catalog, {
    comment :: binary(),
    default_schema :: binary(),
    name :: binary(),
    schemas :: list(parrot@internal@sqlc:schema())
}).
