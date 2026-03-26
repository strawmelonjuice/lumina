-module(collie@internal@socket).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/collie/internal/socket.gleam").
-export([reason_to_string/1, to_erl_options/1, get_system_cacerts/0, get_custom_hostname_check/0, connect/5, send/3, 'receive'/3, receive_timeout/4, close/2, shutdown/3, set_opts/3, controlling_process/3]).
-export_type([socket/0, socket_reason/0, shutdown/0, active_mode/0, packet_mode/0, verify_mode/0, option/0, erlang_option/0, transport/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-type socket() :: any().

-type socket_reason() :: closed |
    timeout |
    badarg |
    terminated |
    eaddrinuse |
    eaddrnotavail |
    eafnosupport |
    ealready |
    econnaborted |
    econnrefused |
    econnreset |
    edestaddrreq |
    ehostdown |
    ehostunreach |
    einprogress |
    eisconn |
    emsgsize |
    enetdown |
    enetunreach |
    enopkg |
    enoprotoopt |
    enotconn |
    enotty |
    enotsock |
    eproto |
    eprotonosupport |
    eprototype |
    esocktnosupport |
    etimedout |
    ewouldblock |
    exbadport |
    exbadseq.

-type shutdown() :: read | write | read_write.

-type active_mode() :: once | passive | {count, integer()} | active.

-type packet_mode() :: binary.

-type verify_mode() :: verify_peer | verify_none.

-type option() :: {active_mode, active_mode()} |
    {mode, packet_mode()} |
    {send_timeout, integer()} |
    {send_timeout_close, boolean()} |
    {reuseaddr, boolean()} |
    {nodelay, boolean()} |
    {verify, verify_mode()} |
    {cacerts, gleam@dynamic:dynamic_()} |
    {customize_hostname_check, gleam@dynamic:dynamic_()} |
    {server_name_indication, gleam@dynamic:dynamic_()}.

-type erlang_option() :: any().

-type transport() :: tcp | ssl.

-file("src/collie/internal/socket.gleam", 46).
?DOC(false).
-spec reason_to_string(socket_reason()) -> binary().
reason_to_string(Reason) ->
    case Reason of
        closed ->
            <<"connection closed"/utf8>>;

        timeout ->
            <<"operation timed out"/utf8>>;

        badarg ->
            <<"bad argument"/utf8>>;

        terminated ->
            <<"process terminated"/utf8>>;

        eaddrinuse ->
            <<"address already in use"/utf8>>;

        eaddrnotavail ->
            <<"address not available"/utf8>>;

        eafnosupport ->
            <<"address family not supported"/utf8>>;

        ealready ->
            <<"operation already in progress"/utf8>>;

        econnaborted ->
            <<"connection aborted"/utf8>>;

        econnrefused ->
            <<"connection refused"/utf8>>;

        econnreset ->
            <<"connection reset by peer"/utf8>>;

        edestaddrreq ->
            <<"destination address required"/utf8>>;

        ehostdown ->
            <<"host is down"/utf8>>;

        ehostunreach ->
            <<"host is unreachable"/utf8>>;

        einprogress ->
            <<"operation in progress"/utf8>>;

        eisconn ->
            <<"already connected"/utf8>>;

        emsgsize ->
            <<"message too long"/utf8>>;

        enetdown ->
            <<"network is down"/utf8>>;

        enetunreach ->
            <<"network is unreachable"/utf8>>;

        enopkg ->
            <<"package not installed"/utf8>>;

        enoprotoopt ->
            <<"protocol not available"/utf8>>;

        enotconn ->
            <<"not connected"/utf8>>;

        enotty ->
            <<"inappropriate ioctl for device"/utf8>>;

        enotsock ->
            <<"not a socket"/utf8>>;

        eproto ->
            <<"protocol error"/utf8>>;

        eprotonosupport ->
            <<"protocol not supported"/utf8>>;

        eprototype ->
            <<"wrong protocol type for socket"/utf8>>;

        esocktnosupport ->
            <<"socket type not supported"/utf8>>;

        etimedout ->
            <<"connection timed out"/utf8>>;

        ewouldblock ->
            <<"operation would block"/utf8>>;

        exbadport ->
            <<"bad port"/utf8>>;

        exbadseq ->
            <<"bad sequence"/utf8>>
    end.

-file("src/collie/internal/socket.gleam", 140).
?DOC(false).
-spec to_erl_options(list(option())) -> list(erlang_option()).
to_erl_options(Options) ->
    collie_ffi:to_erl_options(Options).

-file("src/collie/internal/socket.gleam", 144).
?DOC(false).
-spec get_system_cacerts() -> gleam@dynamic:dynamic_().
get_system_cacerts() ->
    public_key:cacerts_get().

-file("src/collie/internal/socket.gleam", 148).
?DOC(false).
-spec get_custom_hostname_check() -> gleam@dynamic:dynamic_().
get_custom_hostname_check() ->
    collie_ffi:custom_sni_matcher().

-file("src/collie/internal/socket.gleam", 157).
?DOC(false).
-spec connect(
    transport(),
    gleam@erlang@charlist:charlist(),
    integer(),
    list(option()),
    integer()
) -> {ok, socket()} | {error, socket_reason()}.
connect(Transport, Host, Port, Options, Timeout) ->
    Options@1 = collie_ffi:to_erl_options(Options),
    case Transport of
        tcp ->
            gen_tcp:connect(Host, Port, Options@1, Timeout);

        ssl ->
            ssl:connect(Host, Port, Options@1, Timeout)
    end.

-file("src/collie/internal/socket.gleam", 172).
?DOC(false).
-spec send(transport(), socket(), gleam@bytes_tree:bytes_tree()) -> {ok, nil} |
    {error, socket_reason()}.
send(Transport, Socket, Data) ->
    case Transport of
        tcp ->
            collie_ffi:tcp_send(Socket, Data);

        ssl ->
            collie_ffi:ssl_send(Socket, Data)
    end.

-file("src/collie/internal/socket.gleam", 184).
?DOC(false).
-spec 'receive'(transport(), socket(), integer()) -> {ok, bitstring()} |
    {error, socket_reason()}.
'receive'(Transport, Socket, Length) ->
    case Transport of
        tcp ->
            gen_tcp:recv(Socket, Length);

        ssl ->
            ssl:recv(Socket, Length)
    end.

-file("src/collie/internal/socket.gleam", 196).
?DOC(false).
-spec receive_timeout(transport(), socket(), integer(), integer()) -> {ok,
        bitstring()} |
    {error, socket_reason()}.
receive_timeout(Transport, Socket, Length, Timeout) ->
    case Transport of
        tcp ->
            gen_tcp:recv(Socket, Length, Timeout);

        ssl ->
            ssl:recv(Socket, Length, Timeout)
    end.

-file("src/collie/internal/socket.gleam", 209).
?DOC(false).
-spec close(transport(), socket()) -> {ok, nil} | {error, socket_reason()}.
close(Transport, Socket) ->
    case Transport of
        tcp ->
            collie_ffi:tcp_close(Socket);

        ssl ->
            collie_ffi:ssl_close(Socket)
    end.

-file("src/collie/internal/socket.gleam", 217).
?DOC(false).
-spec shutdown(transport(), socket(), shutdown()) -> {ok, nil} |
    {error, socket_reason()}.
shutdown(Transport, Socket, How) ->
    case Transport of
        tcp ->
            collie_ffi:tcp_shutdown(Socket, How);

        ssl ->
            collie_ffi:ssl_shutdown(Socket, How)
    end.

-file("src/collie/internal/socket.gleam", 229).
?DOC(false).
-spec set_opts(transport(), socket(), list(option())) -> {ok, nil} |
    {error, socket_reason()}.
set_opts(Transport, Socket, Options) ->
    Options@1 = collie_ffi:to_erl_options(Options),
    case Transport of
        tcp ->
            collie_ffi:tcp_set_opts(Socket, Options@1);

        ssl ->
            collie_ffi:ssl_set_opts(Socket, Options@1)
    end.

-file("src/collie/internal/socket.gleam", 242).
?DOC(false).
-spec controlling_process(transport(), socket(), gleam@erlang@process:pid_()) -> {ok,
        nil} |
    {error, socket_reason()}.
controlling_process(Transport, Socket, New_owner) ->
    case Transport of
        tcp ->
            collie_ffi:tcp_controlling_process(Socket, New_owner);

        ssl ->
            collie_ffi:ssl_controlling_process(Socket, New_owner)
    end.
