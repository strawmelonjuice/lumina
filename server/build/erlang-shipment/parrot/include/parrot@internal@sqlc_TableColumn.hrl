-record(table_column, {
    name :: binary(),
    not_null :: boolean(),
    is_array :: boolean(),
    comment :: binary(),
    length :: integer(),
    is_named_param :: boolean(),
    is_func_call :: boolean(),
    scope :: binary(),
    table_alias :: binary(),
    is_sqlc_slice :: boolean(),
    original_name :: binary(),
    unsigned :: boolean(),
    array_dims :: integer(),
    table :: gleam@option:option(parrot@internal@sqlc:table_ref()),
    type_ref :: parrot@internal@sqlc:type_ref()
}).
