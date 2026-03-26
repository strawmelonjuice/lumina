-module(ewe@internal@stream@sse).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/ewe/internal/stream/sse.gleam").
-export([send_response/2, start/5, send_event/3]).
-export_type([s_s_e_connection/0, s_s_e_next/1, s_s_e_messages/1, s_s_e_event/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-type s_s_e_connection() :: {s_s_e_connection,
        glisten@transport:transport(),
        glisten@socket:socket()}.

-type s_s_e_next(OQM) :: {continue, OQM} |
    normal_stop |
    {abnormal_stop, binary()}.

-type s_s_e_messages(OQN) :: {user, OQN} | close.

-type s_s_e_event() :: {s_s_e_event,
        gleam@option:option(binary()),
        binary(),
        gleam@option:option(binary()),
        gleam@option:option(integer())}.

-file("src/ewe/internal/stream/sse.gleam", 18).
?DOC(false).
-spec send_response(glisten@transport:transport(), glisten@socket:socket()) -> {ok,
        nil} |
    {error, nil}.
send_response(Transport, Socket) ->
    _pipe = gleam@http@response:new(200),
    _pipe@1 = gleam@http@response:set_header(
        _pipe,
        <<"content-type"/utf8>>,
        <<"text/event-stream"/utf8>>
    ),
    _pipe@2 = gleam@http@response:set_header(
        _pipe@1,
        <<"cache-control"/utf8>>,
        <<"no-cache"/utf8>>
    ),
    _pipe@3 = gleam@http@response:set_header(
        _pipe@2,
        <<"connection"/utf8>>,
        <<"keep-alive"/utf8>>
    ),
    _pipe@4 = ewe@internal@encoder:encode_response_partially(_pipe@3),
    _pipe@5 = glisten@transport:send(Transport, Socket, _pipe@4),
    gleam@result:replace_error(_pipe@5, nil).

-file("src/ewe/internal/stream/sse.gleam", 98).
?DOC(false).
-spec create_socket_selector(gleam@erlang@process:subject(OQX)) -> gleam@erlang@process:selector(s_s_e_messages(OQX)).
create_socket_selector(User_subject) ->
    _pipe = gleam_erlang_ffi:new_selector(),
    _pipe@1 = gleam@erlang@process:select_map(
        _pipe,
        User_subject,
        fun(Msg) -> {user, Msg} end
    ),
    _pipe@2 = gleam@erlang@process:select_record(
        _pipe@1,
        erlang:binary_to_atom(<<"tcp_closed"/utf8>>),
        1,
        fun(_) -> close end
    ),
    gleam@erlang@process:select_record(
        _pipe@2,
        erlang:binary_to_atom(<<"ssl_closed"/utf8>>),
        1,
        fun(_) -> close end
    ).

-file("src/ewe/internal/stream/sse.gleam", 52).
?DOC(false).
-spec start(
    glisten@transport:transport(),
    glisten@socket:socket(),
    fun((gleam@erlang@process:subject(OQQ)) -> OQS),
    fun((s_s_e_connection(), OQS, OQQ) -> s_s_e_next(OQS)),
    fun((s_s_e_connection(), OQS) -> nil)
) -> {ok, gleam@otp@actor:started(nil)} | {error, gleam@otp@actor:start_error()}.
start(Transport, Socket, On_init, Handler, On_close) ->
    _pipe@3 = gleam@otp@actor:new_with_initialiser(
        1000,
        fun(_) ->
            _ = glisten@transport:set_opts(
                Transport,
                Socket,
                [{active_mode, active}]
            ),
            Subject = gleam@erlang@process:new_subject(),
            State = On_init(Subject),
            Selector = create_socket_selector(Subject),
            _pipe = gleam@otp@actor:initialised(State),
            _pipe@1 = gleam@otp@actor:returning(_pipe, nil),
            _pipe@2 = gleam@otp@actor:selecting(_pipe@1, Selector),
            {ok, _pipe@2}
        end
    ),
    _pipe@4 = gleam@otp@actor:on_message(
        _pipe@3,
        fun(State@1, Message) -> case Message of
                {user, Message@1} ->
                    Conn = {s_s_e_connection, Transport, Socket},
                    case Handler(Conn, State@1, Message@1) of
                        {continue, New_state} ->
                            gleam@otp@actor:continue(New_state);

                        normal_stop ->
                            On_close(Conn, State@1),
                            gleam@otp@actor:stop();

                        {abnormal_stop, Reason} ->
                            On_close(Conn, State@1),
                            gleam@otp@actor:stop_abnormal(Reason)
                    end;

                close ->
                    On_close({s_s_e_connection, Transport, Socket}, State@1),
                    gleam@otp@actor:stop()
            end end
    ),
    gleam@otp@actor:start(_pipe@4).

-file("src/ewe/internal/stream/sse.gleam", 156).
?DOC(false).
-spec format(binary(), binary()) -> binary().
format(Field, Value) ->
    <<<<<<Field/binary, ": "/utf8>>/binary, Value/binary>>/binary, "\n"/utf8>>.

-file("src/ewe/internal/stream/sse.gleam", 120).
?DOC(false).
-spec send_event(
    glisten@transport:transport(),
    glisten@socket:socket(),
    s_s_e_event()
) -> {ok, nil} | {error, glisten@socket:socket_reason()}.
send_event(Transport, Socket, Event) ->
    Id = begin
        _pipe = gleam@option:map(
            erlang:element(4, Event),
            fun(_capture) -> format(<<"id"/utf8>>, _capture) end
        ),
        gleam@option:unwrap(_pipe, <<""/utf8>>)
    end,
    Retry = begin
        _pipe@1 = gleam@option:map(
            erlang:element(5, Event),
            fun erlang:integer_to_binary/1
        ),
        _pipe@2 = gleam@option:map(
            _pipe@1,
            fun(_capture@1) -> format(<<"retry"/utf8>>, _capture@1) end
        ),
        gleam@option:unwrap(_pipe@2, <<""/utf8>>)
    end,
    Data = begin
        _pipe@3 = gleam_stdlib:identity(erlang:element(3, Event)),
        _pipe@4 = gleam@string_tree:split(_pipe@3, <<"\n"/utf8>>),
        _pipe@5 = gleam@list:map(
            _pipe@4,
            fun(_capture@2) ->
                gleam@string_tree:prepend(_capture@2, <<"data: "/utf8>>)
            end
        ),
        gleam@string_tree:join(_pipe@5, <<"\n"/utf8>>)
    end,
    Event@1 = begin
        _pipe@6 = gleam@option:map(
            erlang:element(2, Event),
            fun(_capture@3) -> format(<<"event"/utf8>>, _capture@3) end
        ),
        gleam@option:unwrap(_pipe@6, <<""/utf8>>)
    end,
    _pipe@7 = gleam@string_tree:new(),
    _pipe@8 = gleam@string_tree:append(_pipe@7, Event@1),
    _pipe@9 = gleam@string_tree:append(_pipe@8, Id),
    _pipe@10 = gleam@string_tree:append(_pipe@9, Retry),
    _pipe@11 = gleam_stdlib:iodata_append(_pipe@10, Data),
    _pipe@12 = gleam@string_tree:append(_pipe@11, <<"\n\n"/utf8>>),
    _pipe@13 = gleam_stdlib:wrap_list(_pipe@12),
    glisten@transport:send(Transport, Socket, _pipe@13).
