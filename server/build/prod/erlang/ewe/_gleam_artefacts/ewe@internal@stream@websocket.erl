-module(ewe@internal@stream@websocket).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/ewe/internal/stream/websocket.gleam").
-export([send_frame/5, send_close_frame/3, start/7]).
-export_type([websocket_connection/0, websocket_message/1, websocket_next/2, websocket_state/1, internal_message/1, resolve_state/2]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-type websocket_connection() :: {websocket_connection,
        glisten@transport:transport(),
        glisten@socket:socket(),
        websocks:context()}.

-type websocket_message(OUM) :: {frame, websocks:frame()} | {user_message, OUM}.

-type websocket_next(OUN, OUO) :: {continue,
        OUN,
        gleam@option:option(gleam@erlang@process:selector(OUO))} |
    normal_stop |
    {abnormal_stop, binary()}.

-type websocket_state(OUP) :: {websocket_state, OUP, websocks:context()}.

-type internal_message(OUQ) :: {packet, bitstring()} |
    close |
    tcp_passive |
    {user, OUQ} |
    invalid.

-type resolve_state(OUR, OUS) :: {resolve_state,
        glisten@socket:socket(),
        glisten@transport:transport(),
        fun((websocket_connection(), OUR, websocket_message(OUS)) -> websocket_next(OUR, OUS)),
        websocket_next(OUR, internal_message(OUS))}.

-file("src/ewe/internal/stream/websocket.gleam", 172).
?DOC(false).
-spec create_socket_selector() -> gleam@erlang@process:selector(internal_message(any())).
create_socket_selector() ->
    _pipe = gleam_erlang_ffi:new_selector(),
    _pipe@1 = gleam@erlang@process:select_record(
        _pipe,
        erlang:binary_to_atom(<<"tcp"/utf8>>),
        2,
        fun(Record) -> {packet, ewe_ffi:coerce_tcp_message(Record)} end
    ),
    _pipe@2 = gleam@erlang@process:select_record(
        _pipe@1,
        erlang:binary_to_atom(<<"ssl"/utf8>>),
        2,
        fun(Record@1) -> {packet, ewe_ffi:coerce_tcp_message(Record@1)} end
    ),
    _pipe@3 = gleam@erlang@process:select_record(
        _pipe@2,
        erlang:binary_to_atom(<<"tcp_closed"/utf8>>),
        1,
        fun(_) -> close end
    ),
    _pipe@4 = gleam@erlang@process:select_record(
        _pipe@3,
        erlang:binary_to_atom(<<"ssl_closed"/utf8>>),
        1,
        fun(_) -> close end
    ),
    gleam@erlang@process:select_record(
        _pipe@4,
        erlang:binary_to_atom(<<"tcp_passive"/utf8>>),
        1,
        fun(_) -> tcp_passive end
    ).

-file("src/ewe/internal/stream/websocket.gleam", 362).
?DOC(false).
-spec handle_close(
    fun((websocket_connection(), OWU) -> nil),
    websocket_state(OWU),
    websocket_connection(),
    gleam@option:option(binary())
) -> gleam@otp@actor:next(websocket_state(OWU), internal_message(any())).
handle_close(On_close, State, Conn, Abnormal_reason) ->
    websocks:close_context(erlang:element(3, State)),
    On_close(Conn, erlang:element(2, State)),
    case Abnormal_reason of
        {some, Reason} ->
            Level = case Reason =:= <<"Crash in websocket handler"/utf8>> of
                true ->
                    error;

                false ->
                    warning
            end,
            logging:log(Level, <<"WebSocket closed: "/utf8, Reason/binary>>),
            gleam@otp@actor:stop_abnormal(Reason);

        none ->
            gleam@otp@actor:stop()
    end.

-file("src/ewe/internal/stream/websocket.gleam", 325).
?DOC(false).
-spec handle_user_message(
    glisten@transport:transport(),
    glisten@socket:socket(),
    websocket_state(OWM),
    OWO,
    fun((websocket_connection(), OWM, websocket_message(OWO)) -> websocket_next(OWM, OWO)),
    fun((websocket_connection(), OWM) -> nil)
) -> gleam@otp@actor:next(websocket_state(OWM), internal_message(OWO)).
handle_user_message(Transport, Socket, State, User_message, Handler, On_close) ->
    Conn = {websocket_connection, Transport, Socket, erlang:element(3, State)},
    Call = exception_ffi:rescue(
        fun() ->
            Handler(
                Conn,
                erlang:element(2, State),
                {user_message, User_message}
            )
        end
    ),
    case Call of
        {ok, {continue, New_user_state, New_selector}} ->
            Next_selector = begin
                _pipe = gleam@option:map(
                    New_selector,
                    fun(_capture) ->
                        gleam_erlang_ffi:map_selector(
                            _capture,
                            fun(Field@0) -> {user, Field@0} end
                        )
                    end
                ),
                gleam@option:map(
                    _pipe,
                    fun(_capture@1) ->
                        gleam_erlang_ffi:merge_selector(
                            create_socket_selector(),
                            _capture@1
                        )
                    end
                )
            end,
            Next = gleam@otp@actor:continue(
                {websocket_state, New_user_state, erlang:element(3, State)}
            ),
            case Next_selector of
                {some, Selector} ->
                    gleam@otp@actor:with_selector(Next, Selector);

                none ->
                    Next
            end;

        {ok, normal_stop} ->
            handle_close(On_close, State, Conn, none);

        {ok, {abnormal_stop, Reason}} ->
            handle_close(On_close, State, Conn, {some, Reason});

        {error, _} ->
            handle_close(
                On_close,
                State,
                Conn,
                {some, <<"Crash in websocket handler"/utf8>>}
            )
    end.

-file("src/ewe/internal/stream/websocket.gleam", 245).
?DOC(false).
-spec handle_frame(
    resolve_state(OWF, OWG),
    websocks:context(),
    websocks:frame()
) -> websocks:resolve_next(resolve_state(OWF, OWG)).
handle_frame(State, Context, Frame) ->
    case Frame of
        {control, {ping, Payload}} ->
            case erlang:byte_size(Payload) of
                Size when Size > 125 ->
                    {stop,
                        {resolve_state,
                            erlang:element(2, State),
                            erlang:element(3, State),
                            erlang:element(4, State),
                            {abnormal_stop,
                                <<"control frames are only allowed to have payload up to and including 125 octets"/utf8>>}}};

                _ ->
                    Sent = glisten@transport:send(
                        erlang:element(3, State),
                        erlang:element(2, State),
                        begin
                            _pipe = websocks:encode_pong_frame(Payload, none),
                            gleam@bytes_tree:from_bit_array(_pipe)
                        end
                    ),
                    case Sent of
                        {ok, nil} ->
                            {continue, State};

                        {error, _} ->
                            {stop,
                                {resolve_state,
                                    erlang:element(2, State),
                                    erlang:element(3, State),
                                    erlang:element(4, State),
                                    {abnormal_stop,
                                        <<"Failed to send PONG frame"/utf8>>}}}
                    end
            end;

        {control, {close, Reason}} ->
            _ = glisten@transport:send(
                erlang:element(3, State),
                erlang:element(2, State),
                begin
                    _pipe@1 = websocks:encode_close_frame(Reason, none),
                    gleam@bytes_tree:from_bit_array(_pipe@1)
                end
            ),
            {stop,
                {resolve_state,
                    erlang:element(2, State),
                    erlang:element(3, State),
                    erlang:element(4, State),
                    normal_stop}};

        Frame@1 ->
            {User_state@1, Selector@1} = case erlang:element(5, State) of
                {continue, User_state, Selector} -> {User_state, Selector};
                _assert_fail ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"ewe/internal/stream/websocket"/utf8>>,
                                function => <<"handle_frame"/utf8>>,
                                line => 295,
                                value => _assert_fail,
                                start => 8260,
                                'end' => 8314,
                                pattern_start => 8271,
                                pattern_end => 8301})
            end,
            Conn = {websocket_connection,
                erlang:element(3, State),
                erlang:element(2, State),
                Context},
            Call = exception_ffi:rescue(
                fun() ->
                    (erlang:element(4, State))(
                        Conn,
                        User_state@1,
                        {frame, Frame@1}
                    )
                end
            ),
            case Call of
                {ok, {continue, User_state@2, New_selector}} ->
                    Next_selector = begin
                        _pipe@2 = gleam@option:map(
                            New_selector,
                            fun(_capture) ->
                                gleam_erlang_ffi:map_selector(
                                    _capture,
                                    fun(Field@0) -> {user, Field@0} end
                                )
                            end
                        ),
                        _pipe@3 = gleam@option:'or'(_pipe@2, Selector@1),
                        gleam@option:map(
                            _pipe@3,
                            fun(_capture@1) ->
                                gleam_erlang_ffi:merge_selector(
                                    create_socket_selector(),
                                    _capture@1
                                )
                            end
                        )
                    end,
                    {continue,
                        {resolve_state,
                            erlang:element(2, State),
                            erlang:element(3, State),
                            erlang:element(4, State),
                            {continue, User_state@2, Next_selector}}};

                {ok, normal_stop} ->
                    {stop,
                        {resolve_state,
                            erlang:element(2, State),
                            erlang:element(3, State),
                            erlang:element(4, State),
                            normal_stop}};

                {ok, {abnormal_stop, Reason@1}} ->
                    {stop,
                        {resolve_state,
                            erlang:element(2, State),
                            erlang:element(3, State),
                            erlang:element(4, State),
                            {abnormal_stop, Reason@1}}};

                {error, _} ->
                    {stop,
                        {resolve_state,
                            erlang:element(2, State),
                            erlang:element(3, State),
                            erlang:element(4, State),
                            {abnormal_stop,
                                <<"Crash in websocket handler"/utf8>>}}}
            end
    end.

-file("src/ewe/internal/stream/websocket.gleam", 190).
?DOC(false).
-spec handle_valid_packet(
    glisten@transport:transport(),
    glisten@socket:socket(),
    websocket_state(OVX),
    bitstring(),
    fun((websocket_connection(), OVX, websocket_message(OVZ)) -> websocket_next(OVX, OVZ)),
    fun((websocket_connection(), OVX) -> nil)
) -> gleam@otp@actor:next(websocket_state(OVX), internal_message(OVZ)).
handle_valid_packet(Transport, Socket, State, Data, Handler, On_close) ->
    Conn = {websocket_connection, Transport, Socket, erlang:element(3, State)},
    Processed = websocks:process_incoming_frames(
        Data,
        erlang:element(3, State),
        {resolve_state,
            Socket,
            Transport,
            Handler,
            {continue, erlang:element(2, State), none}},
        fun handle_frame/3
    ),
    case Processed of
        {ok, {Resolved_state, Context}} ->
            case erlang:element(5, Resolved_state) of
                {continue, User_state, Selector} ->
                    Next = gleam@otp@actor:continue(
                        {websocket_state, User_state, Context}
                    ),
                    case Selector of
                        {some, Selector@1} ->
                            gleam@otp@actor:with_selector(Next, Selector@1);

                        none ->
                            Next
                    end;

                normal_stop ->
                    handle_close(On_close, State, Conn, none);

                {abnormal_stop, Reason} ->
                    handle_close(On_close, State, Conn, {some, Reason})
            end;

        {error, _} ->
            handle_close(
                On_close,
                State,
                Conn,
                {some, <<"Received malformed message"/utf8>>}
            )
    end.

-file("src/ewe/internal/stream/websocket.gleam", 386).
?DOC(false).
-spec send_frame(
    fun((bitstring(), websocks:context(), gleam@option:option(bitstring())) -> bitstring()),
    glisten@transport:transport(),
    glisten@socket:socket(),
    websocks:context(),
    bitstring()
) -> {ok, nil} | {error, glisten@socket:socket_reason()}.
send_frame(Encoder, Transport, Socket, Context, Payload) ->
    Frame = exception_ffi:rescue(
        fun() -> _pipe = Encoder(Payload, Context, none),
            _pipe@1 = gleam@bytes_tree:from_bit_array(_pipe),
            glisten@transport:send(Transport, Socket, _pipe@1) end
    ),
    case Frame of
        {ok, Frame@1} ->
            Frame@1;

        {error, _} ->
            logging:log(
                error,
                <<"Frame should be sent from the WebSocket connection, but was sent from different process."/utf8>>
            ),
            erlang:error(#{gleam_error => panic,
                    message => <<"Sending WebSocket message from non-owning process"/utf8>>,
                    file => <<?FILEPATH/utf8>>,
                    module => <<"ewe/internal/stream/websocket"/utf8>>,
                    function => <<"send_frame"/utf8>>,
                    line => 407})
    end.

-file("src/ewe/internal/stream/websocket.gleam", 414).
?DOC(false).
-spec send_close_frame(
    glisten@transport:transport(),
    glisten@socket:socket(),
    websocks:close_reason()
) -> websocket_next(any(), any()).
send_close_frame(Transport, Socket, Code) ->
    Frame = exception_ffi:rescue(
        fun() -> _pipe = websocks:encode_close_frame(Code, none),
            _pipe@1 = gleam@bytes_tree:from_bit_array(_pipe),
            glisten@transport:send(Transport, Socket, _pipe@1) end
    ),
    case Frame of
        {ok, {ok, nil}} ->
            normal_stop;

        {ok, {error, Reason}} ->
            {abnormal_stop,
                <<"Socket error occured while trying to send close frame: "/utf8,
                    (glisten@socket:reason_to_string(Reason))/binary>>};

        {error, _} ->
            logging:log(
                error,
                <<"Frame should be sent from the WebSocket connection, but was sent from different process."/utf8>>
            ),
            erlang:error(#{gleam_error => panic,
                    message => <<"Sending WebSocket message from non-owning process"/utf8>>,
                    file => <<?FILEPATH/utf8>>,
                    module => <<"ewe/internal/stream/websocket"/utf8>>,
                    function => <<"send_close_frame"/utf8>>,
                    line => 439})
    end.

-file("src/ewe/internal/stream/websocket.gleam", 100).
?DOC(false).
-spec start(
    glisten@transport:transport(),
    glisten@socket:socket(),
    fun((websocket_connection(), gleam@erlang@process:selector(OVK)) -> {OVJ,
        gleam@erlang@process:selector(OVK)}),
    fun((websocket_connection(), OVJ, websocket_message(OVK)) -> websocket_next(OVJ, OVK)),
    fun((websocket_connection(), OVJ) -> nil),
    list(binary()),
    boolean()
) -> {ok, gleam@otp@actor:started(nil)} | {error, gleam@otp@actor:start_error()}.
start(
    Transport,
    Socket,
    On_init,
    Handler,
    On_close,
    Extensions,
    Permessage_deflate
) ->
    _pipe@6 = gleam@otp@actor:new_with_initialiser(
        1000,
        fun(_) ->
            _ = glisten@transport:set_opts(
                Transport,
                Socket,
                [{active_mode, {count, 100}}]
            ),
            Compression = case Permessage_deflate of
                true ->
                    {some, websocks:get_compression_extensions(Extensions)};

                false ->
                    none
            end,
            Context = websocks:create_context(Compression, server),
            {User_state, User_selector} = begin
                _pipe = {websocket_connection, Transport, Socket, Context},
                On_init(_pipe, gleam_erlang_ffi:new_selector())
            end,
            Selector = begin
                _pipe@1 = gleam_erlang_ffi:map_selector(
                    User_selector,
                    fun(Field@0) -> {user, Field@0} end
                ),
                gleam_erlang_ffi:merge_selector(
                    _pipe@1,
                    create_socket_selector()
                )
            end,
            _pipe@2 = {websocket_state, User_state, Context},
            _pipe@3 = gleam@otp@actor:initialised(_pipe@2),
            _pipe@4 = gleam@otp@actor:selecting(_pipe@3, Selector),
            _pipe@5 = gleam@otp@actor:returning(_pipe@4, nil),
            {ok, _pipe@5}
        end
    ),
    _pipe@7 = gleam@otp@actor:on_message(_pipe@6, fun(State, Msg) -> case Msg of
                {packet, Data} ->
                    handle_valid_packet(
                        Transport,
                        Socket,
                        State,
                        Data,
                        Handler,
                        On_close
                    );

                {user, User_message} ->
                    handle_user_message(
                        Transport,
                        Socket,
                        State,
                        User_message,
                        Handler,
                        On_close
                    );

                close ->
                    Conn = {websocket_connection,
                        Transport,
                        Socket,
                        erlang:element(3, State)},
                    handle_close(On_close, State, Conn, none);

                invalid ->
                    Conn@1 = {websocket_connection,
                        Transport,
                        Socket,
                        erlang:element(3, State)},
                    handle_close(
                        On_close,
                        State,
                        Conn@1,
                        {some, <<"Received malformed message"/utf8>>}
                    );

                tcp_passive ->
                    _ = glisten@transport:set_opts(
                        Transport,
                        Socket,
                        [{active_mode, {count, 100}}]
                    ),
                    gleam@otp@actor:continue(State)
            end end),
    gleam@otp@actor:start(_pipe@7).
