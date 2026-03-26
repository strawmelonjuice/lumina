-record(schema, {
    comment :: binary(),
    name :: binary(),
    tables :: list(parrot@internal@sqlc:table()),
    enums :: list(parrot@internal@sqlc:enum())
}).
