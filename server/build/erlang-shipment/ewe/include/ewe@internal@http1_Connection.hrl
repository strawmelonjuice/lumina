-record(connection, {
    transport :: glisten@transport:transport(),
    socket :: glisten@socket:socket(),
    buffer :: ewe@internal@http1@buffer:buffer(),
    factory_name :: gleam@erlang@process:name(gleam@otp@factory_supervisor:message(fun(() -> {ok,
            gleam@otp@actor:started(nil)} |
        {error, gleam@otp@actor:start_error()}), nil))
}).
