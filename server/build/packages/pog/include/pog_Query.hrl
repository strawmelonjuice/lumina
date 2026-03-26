-record('query', {
    sql :: binary(),
    parameters :: list(pog:value()),
    row_decoder :: gleam@dynamic@decode:decoder(any()),
    timeout :: integer()
}).
