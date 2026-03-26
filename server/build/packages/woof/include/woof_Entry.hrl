-record(entry, {
    level :: woof:level(),
    message :: binary(),
    fields :: list({binary(), binary()}),
    namespace :: gleam@option:option(binary()),
    timestamp :: binary()
}).
