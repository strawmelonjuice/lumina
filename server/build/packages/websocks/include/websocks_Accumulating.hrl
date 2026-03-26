-record(accumulating, {
    compression :: websocks:compression(),
    buffer :: bitstring(),
    frame_builder :: fun((bitstring()) -> websocks:frame()),
    accumulated_payload :: bitstring(),
    compressed :: boolean()
}).
