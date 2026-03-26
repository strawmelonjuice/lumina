-record(consumed, {
    data :: bitstring(),
    next :: fun((integer()) -> {ok, ewe:stream()} | {error, ewe:body_error()})
}).
