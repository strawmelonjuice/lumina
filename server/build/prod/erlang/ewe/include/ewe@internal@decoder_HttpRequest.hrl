-record(http_request, {
    method :: bitstring(),
    path :: ewe@internal@decoder:abs_path(),
    version :: {integer(), integer()}
}).
