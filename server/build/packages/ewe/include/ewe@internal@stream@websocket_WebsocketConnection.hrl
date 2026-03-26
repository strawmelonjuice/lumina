-record(websocket_connection, {
    transport :: glisten@transport:transport(),
    socket :: glisten@socket:socket(),
    context :: websocks:context()
}).
