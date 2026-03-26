-record(connection, {
    transport :: collie@internal@socket:transport(),
    socket :: collie@internal@socket:socket(),
    context :: websocks:context()
}).
