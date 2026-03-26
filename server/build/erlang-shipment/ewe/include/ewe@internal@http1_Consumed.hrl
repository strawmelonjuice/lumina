-record(consumed, {
    data :: bitstring(),
    next :: fun((integer()) -> {ok, ewe@internal@http1:stream()} |
        {error, ewe@internal@http1:parse_error()})
}).
