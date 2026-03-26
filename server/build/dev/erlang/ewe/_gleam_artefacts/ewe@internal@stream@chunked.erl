-module(ewe@internal@stream@chunked).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/ewe/internal/stream/chunked.gleam").
-export([send_response/3, start/5, send_chunk/3]).
-export_type([chunked_body/0, chunked_next/1]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-type chunked_body() :: {chunked_body,
        glisten@transport:transport(),
        glisten@socket:socket()}.

-type chunked_next(OOK) :: {continue, OOK} |
    normal_stop |
    {abnormal_stop, binary()}.

-file("src/ewe/internal/stream/chunked.gleam", 15).
?DOC(false).
-spec send_response(
    gleam@http@response:response(any()),
    glisten@transport:transport(),
    glisten@socket:socket()
) -> {ok, nil} | {error, nil}.
send_response(Resp, Transport, Socket) ->
    _pipe = case gleam@http@response:get_header(
        Resp,
        <<"transfer-encoding"/utf8>>
    ) of
        {ok, <<"chunked"/utf8>>} ->
            Resp;

        _ ->
            gleam@http@response:set_header(
                Resp,
                <<"transfer-encoding"/utf8>>,
                <<"chunked"/utf8>>
            )
    end,
    _pipe@1 = ewe@internal@encoder:encode_response_partially(_pipe),
    _pipe@2 = glisten@transport:send(Transport, Socket, _pipe@1),
    gleam@result:replace_error(_pipe@2, nil).

-file("src/ewe/internal/stream/chunked.gleam", 99).
?DOC(false).
-spec send_end(glisten@transport:transport(), glisten@socket:socket()) -> {ok,
        nil} |
    {error, glisten@socket:socket_reason()}.
send_end(Transport, Socket) ->
    glisten@transport:send(
        Transport,
        Socket,
        gleam@bytes_tree:from_bit_array(<<"0\r\n\r\n"/utf8>>)
    ).

-file("src/ewe/internal/stream/chunked.gleam", 45).
?DOC(false).
-spec start(
    glisten@transport:transport(),
    glisten@socket:socket(),
    fun((gleam@erlang@process:subject(OOP)) -> OOR),
    fun((chunked_body(), OOR, OOP) -> chunked_next(OOR)),
    fun((chunked_body(), OOR) -> nil)
) -> {ok, gleam@otp@actor:started(nil)} | {error, gleam@otp@actor:start_error()}.
start(Transport, Socket, On_init, Handler, On_close) ->
    _pipe@4 = gleam@otp@actor:new_with_initialiser(
        1000,
        fun(_) ->
            Subject = gleam@erlang@process:new_subject(),
            State = On_init(Subject),
            Selector = begin
                _pipe = gleam_erlang_ffi:new_selector(),
                gleam@erlang@process:select(_pipe, Subject)
            end,
            _pipe@1 = gleam@otp@actor:initialised(State),
            _pipe@2 = gleam@otp@actor:returning(_pipe@1, nil),
            _pipe@3 = gleam@otp@actor:selecting(_pipe@2, Selector),
            {ok, _pipe@3}
        end
    ),
    _pipe@5 = gleam@otp@actor:on_message(
        _pipe@4,
        fun(State@1, Message) ->
            Conn = {chunked_body, Transport, Socket},
            case Handler(Conn, State@1, Message) of
                {continue, New_state} ->
                    gleam@otp@actor:continue(New_state);

                normal_stop ->
                    case send_end(Transport, Socket) of
                        {ok, nil} ->
                            On_close(Conn, State@1),
                            gleam@otp@actor:stop();

                        {error, Socket_reason} ->
                            Message@1 = <<"Failed to send chunked response terminator: "/utf8,
                                (glisten@socket:reason_to_string(Socket_reason))/binary>>,
                            logging:log(warning, Message@1),
                            On_close(Conn, State@1),
                            gleam@otp@actor:stop_abnormal(Message@1)
                    end;

                {abnormal_stop, Reason} ->
                    logging:log(
                        warning,
                        <<"Chunked response stopped: "/utf8, Reason/binary>>
                    ),
                    On_close(Conn, State@1),
                    gleam@otp@actor:stop_abnormal(Reason)
            end
        end
    ),
    gleam@otp@actor:start(_pipe@5).

-file("src/ewe/internal/stream/chunked.gleam", 123).
?DOC(false).
-spec to_hex_string(integer()) -> binary().
to_hex_string(Integer) ->
    erlang:integer_to_list(Integer, 16).

-file("src/ewe/internal/stream/chunked.gleam", 108).
?DOC(false).
-spec send_chunk(
    glisten@transport:transport(),
    glisten@socket:socket(),
    bitstring()
) -> {ok, nil} | {error, glisten@socket:socket_reason()}.
send_chunk(Transport, Socket, Chunk) ->
    _pipe = gleam@bytes_tree:new(),
    _pipe@1 = gleam@bytes_tree:append_string(
        _pipe,
        to_hex_string(erlang:byte_size(Chunk))
    ),
    _pipe@2 = gleam@bytes_tree:append(_pipe@1, <<"\r\n"/utf8>>),
    _pipe@3 = gleam@bytes_tree:append(_pipe@2, Chunk),
    _pipe@4 = gleam@bytes_tree:append(_pipe@3, <<"\r\n"/utf8>>),
    glisten@transport:send(Transport, Socket, _pipe@4).
