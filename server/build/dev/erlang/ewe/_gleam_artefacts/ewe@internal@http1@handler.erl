-module(ewe@internal@http1@handler).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/ewe/internal/http1/handler.gleam").
-export([init/0, handle_packet/7]).
-export_type([http1_handler/0, next/0, http2_upgrade/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-type http1_handler() :: {http1_handler,
        gleam@option:option(gleam@erlang@process:timer())}.

-type next() :: {continue, http1_handler()} |
    stop |
    {http2_upgrade, http2_upgrade()}.

-type http2_upgrade() :: {upgrade,
        gleam@http@request:request(ewe@internal@http1:connection()),
        binary()} |
    {direct, bitstring()}.

-file("src/ewe/internal/http1/handler.gleam", 34).
?DOC(false).
-spec init() -> http1_handler().
init() ->
    {http1_handler, none}.

-file("src/ewe/internal/http1/handler.gleam", 211).
?DOC(false).
-spec send_file(
    gleam@http@request:request(ewe@internal@http1:connection()),
    ewe@internal@http1:http_version(),
    gleam@http@response:response(ewe@internal@http1:response_body()),
    ewe@internal@file:io_device(),
    integer(),
    integer()
) -> {ok, nil} | {error, glisten@socket:socket_reason()}.
send_file(Request, Version, Response, Descriptor, Offset, Size) ->
    Response@1 = case gleam@http@response:get_header(
        Response,
        <<"content-length"/utf8>>
    ) of
        {ok, _} ->
            Response;

        {error, nil} ->
            gleam@http@response:set_header(
                Response,
                <<"content-length"/utf8>>,
                erlang:integer_to_binary(Size)
            )
    end,
    Sent = begin
        _pipe = ewe@internal@http1:append_default_headers(
            Response@1,
            Request,
            Version
        ),
        _pipe@1 = ewe@internal@encoder:encode_response_partially(_pipe),
        _pipe@2 = glisten@transport:send(
            erlang:element(2, erlang:element(4, Request)),
            erlang:element(3, erlang:element(4, Request)),
            _pipe@1
        ),
        gleam@result:'try'(
            _pipe@2,
            fun(_) ->
                _pipe@3 = ewe@internal@file:send(
                    erlang:element(2, erlang:element(4, Request)),
                    erlang:element(3, erlang:element(4, Request)),
                    Descriptor,
                    Offset,
                    Size
                ),
                gleam@result:replace_error(_pipe@3, badarg)
            end
        )
    end,
    _ = ewe_ffi:close_file(Descriptor),
    Sent.

-file("src/ewe/internal/http1/handler.gleam", 298).
?DOC(false).
-spec can_encode_gzip(
    gleam@http@request:request(ewe@internal@http1:connection()),
    gleam@http@response:response(any())
) -> boolean().
can_encode_gzip(Request, Response) ->
    Accept_encoding = begin
        _pipe = gleam@http@request:get_header(
            Request,
            <<"accept-encoding"/utf8>>
        ),
        gleam@result:map(
            _pipe,
            fun(_capture) ->
                gleam_stdlib:contains_string(_capture, <<"gzip"/utf8>>)
            end
        )
    end,
    Content_encoding = gleam@http@response:get_header(
        Response,
        <<"content-encoding"/utf8>>
    ),
    case {Accept_encoding, Content_encoding} of
        {{ok, true}, {error, nil}} ->
            true;

        {_, _} ->
            false
    end.

-file("src/ewe/internal/http1/handler.gleam", 313).
?DOC(false).
-spec remove_charset(gleam@http@response:response(OHT)) -> gleam@http@response:response(OHT).
remove_charset(Response) ->
    _pipe = gleam@http@response:get_header(Response, <<"content-type"/utf8>>),
    _pipe@1 = gleam@result:'try'(
        _pipe,
        fun(_capture) -> gleam@string:split_once(_capture, <<";"/utf8>>) end
    ),
    _pipe@2 = gleam@result:map(
        _pipe@1,
        fun(Parts) ->
            gleam@http@response:set_header(
                Response,
                <<"content-type"/utf8>>,
                erlang:element(1, Parts)
            )
        end
    ),
    gleam@result:unwrap(_pipe@2, Response).

-file("src/ewe/internal/http1/handler.gleam", 247).
?DOC(false).
-spec send_body(
    gleam@http@request:request(ewe@internal@http1:connection()),
    ewe@internal@http1:http_version(),
    gleam@http@response:response(ewe@internal@http1:response_body())
) -> {ok, nil} | {error, glisten@socket:socket_reason()}.
send_body(Request, Version, Response) ->
    Bits@1 = case erlang:element(4, Response) of
        {text_data, Text} ->
            gleam_stdlib:identity(Text);

        {string_tree_data, String_tree} ->
            _pipe = unicode:characters_to_binary(String_tree),
            gleam_stdlib:identity(_pipe);

        {bits_data, Bits} ->
            Bits;

        {bytes_data, Bytes} ->
            erlang:list_to_bitstring(Bytes);

        empty ->
            <<>>;

        _ ->
            erlang:error(#{gleam_error => panic,
                    message => <<"`panic` expression evaluated."/utf8>>,
                    file => <<?FILEPATH/utf8>>,
                    module => <<"ewe/internal/http1/handler"/utf8>>,
                    function => <<"send_body"/utf8>>,
                    line => 259})
    end,
    Content_length = erlang:byte_size(Bits@1),
    Response@1 = case Content_length > 1024 of
        true ->
            case can_encode_gzip(Request, Response) of
                true ->
                    Compressed = compresso:gzip(Bits@1),
                    Content_length@1 = erlang:byte_size(Compressed),
                    _pipe@1 = remove_charset(Response),
                    _pipe@2 = gleam@http@response:set_header(
                        _pipe@1,
                        <<"content-encoding"/utf8>>,
                        <<"gzip"/utf8>>
                    ),
                    _pipe@3 = gleam@http@response:set_header(
                        _pipe@2,
                        <<"vary"/utf8>>,
                        <<"Accept-Encoding"/utf8>>
                    ),
                    _pipe@4 = gleam@http@response:set_header(
                        _pipe@3,
                        <<"content-length"/utf8>>,
                        erlang:integer_to_binary(Content_length@1)
                    ),
                    gleam@http@response:set_body(_pipe@4, Compressed);

                _ ->
                    _pipe@5 = gleam@http@response:set_body(Response, Bits@1),
                    gleam@http@response:set_header(
                        _pipe@5,
                        <<"content-length"/utf8>>,
                        erlang:integer_to_binary(Content_length)
                    )
            end;

        false ->
            _pipe@6 = gleam@http@response:set_body(Response, Bits@1),
            gleam@http@response:set_header(
                _pipe@6,
                <<"content-length"/utf8>>,
                erlang:integer_to_binary(Content_length)
            )
    end,
    _pipe@7 = ewe@internal@http1:append_default_headers(
        Response@1,
        Request,
        Version
    ),
    _pipe@8 = ewe@internal@encoder:encode_response(_pipe@7),
    glisten@transport:send(
        erlang:element(2, erlang:element(4, Request)),
        erlang:element(3, erlang:element(4, Request)),
        _pipe@8
    ).

-file("src/ewe/internal/http1/handler.gleam", 324).
?DOC(false).
-spec is_connection_close(gleam@http@response:response(any())) -> boolean().
is_connection_close(Response) ->
    case gleam@http@response:get_header(Response, <<"connection"/utf8>>) of
        {ok, <<"close"/utf8>>} ->
            true;

        _ ->
            false
    end.

-file("src/ewe/internal/http1/handler.gleam", 192).
?DOC(false).
-spec on_sent(
    {ok, nil} | {error, glisten@socket:socket_reason()},
    gleam@http@response:response(ewe@internal@http1:response_body()),
    gleam@erlang@process:subject(glisten@internal@handler:message(any())),
    integer()
) -> {ok, http1_handler()} | {error, nil}.
on_sent(Sent, Response, Glisten_subject, Idle_timeout) ->
    case {Sent, is_connection_close(Response)} of
        {{ok, nil}, false} ->
            Timer = gleam@erlang@process:send_after(
                Glisten_subject,
                Idle_timeout,
                {internal, close}
            ),
            {ok, {http1_handler, {some, Timer}}};

        {_, _} ->
            {error, nil}
    end.

-file("src/ewe/internal/http1/handler.gleam", 162).
?DOC(false).
-spec call(
    gleam@http@request:request(ewe@internal@http1:connection()),
    ewe@internal@http1:http_version(),
    gleam@erlang@process:subject(glisten@internal@handler:message(any())),
    fun((gleam@http@request:request(ewe@internal@http1:connection())) -> gleam@http@response:response(ewe@internal@http1:response_body())),
    gleam@http@response:response(ewe@internal@http1:response_body()),
    integer()
) -> {ok, http1_handler()} | {error, nil}.
call(Request, Version, Glisten_subject, Handler, On_crash, Idle_timeout) ->
    Response@1 = case exception_ffi:rescue(fun() -> Handler(Request) end) of
        {ok, Response} ->
            Response;

        {error, _} ->
            logging:log(error, <<"Caught crash in request handler"/utf8>>),
            gleam@http@response:set_header(
                On_crash,
                <<"connection"/utf8>>,
                <<"close"/utf8>>
            )
    end,
    case erlang:element(4, Response@1) of
        websocket ->
            {error, nil};

        s_s_e ->
            {error, nil};

        chunked ->
            {error, nil};

        {file, Descriptor, Offset, Size} ->
            _pipe = send_file(
                Request,
                Version,
                Response@1,
                Descriptor,
                Offset,
                Size
            ),
            on_sent(_pipe, Response@1, Glisten_subject, Idle_timeout);

        _ ->
            _pipe@1 = send_body(Request, Version, Response@1),
            on_sent(_pipe@1, Response@1, Glisten_subject, Idle_timeout)
    end.

-file("src/ewe/internal/http1/handler.gleam", 55).
?DOC(false).
-spec handle_packet(
    http1_handler(),
    ewe@internal@http1:connection(),
    bitstring(),
    gleam@erlang@process:subject(glisten@internal@handler:message(any())),
    fun((gleam@http@request:request(ewe@internal@http1:connection())) -> gleam@http@response:response(ewe@internal@http1:response_body())),
    gleam@http@response:response(ewe@internal@http1:response_body()),
    integer()
) -> next().
handle_packet(
    State,
    Connection,
    Data,
    Glisten_subject,
    Handler,
    On_crash,
    Idle_timeout
) ->
    case erlang:element(2, State) of
        {some, Timer} ->
            gleam@erlang@process:cancel_timer(Timer);

        none ->
            timer_not_found
    end,
    case ewe@internal@http1:parse_request(Connection, {buffer, Data, 0}) of
        {ok, {http1_request, Request, Version}} ->
            Call_result = call(
                Request,
                Version,
                Glisten_subject,
                Handler,
                On_crash,
                Idle_timeout
            ),
            case Call_result of
                {ok, State@1} ->
                    {continue, State@1};

                {error, nil} ->
                    stop
            end;

        {ok, {http2_upgrade, {direct, Data@1}}} ->
            {http2_upgrade, {direct, Data@1}};

        {ok, {http2_upgrade, {upgrade, Request@1, _}}} ->
            logging:log(notice, <<"HTTP/2 upgrade; using HTTP/1.1"/utf8>>),
            Call_result@1 = call(
                Request@1,
                http11,
                Glisten_subject,
                Handler,
                On_crash,
                Idle_timeout
            ),
            case Call_result@1 of
                {ok, State@2} ->
                    {continue, State@2};

                {error, nil} ->
                    stop
            end;

        {error, Reason} ->
            {Status, Message} = case Reason of
                invalid_method ->
                    {400, <<"Rejected HTTP request with invalid method"/utf8>>};

                invalid_path ->
                    {400, <<"Rejected HTTP request with invalid path"/utf8>>};

                invalid_version ->
                    {505,
                        <<"Rejected HTTP request with unsupported version"/utf8>>};

                invalid_headers ->
                    {400,
                        <<"Rejected HTTP request with malformed headers"/utf8>>};

                missing_host ->
                    {400,
                        <<"Rejected HTTP request with missing Host header"/utf8>>};

                duplicate_host ->
                    {400,
                        <<"Rejected HTTP request with duplicate Host header"/utf8>>};

                invalid_content_length ->
                    {400,
                        <<"Rejected HTTP request with invalid Content-Length"/utf8>>};

                invalid_body ->
                    {400, <<"Rejected HTTP request with malformed body"/utf8>>};

                body_too_large ->
                    {400,
                        <<"Rejected HTTP request with body exceeding size limit"/utf8>>};

                malformed_request ->
                    {400,
                        <<"Rejected HTTP request due to malformed packet"/utf8>>};

                packet_discard ->
                    {400,
                        <<"Rejected HTTP request due to unrecognized packet"/utf8>>}
            end,
            logging:log(warning, Message),
            _ = begin
                _pipe = gleam@http@response:new(Status),
                _pipe@1 = gleam@http@response:set_body(_pipe, <<>>),
                _pipe@2 = gleam@http@response:set_header(
                    _pipe@1,
                    <<"connection"/utf8>>,
                    <<"close"/utf8>>
                ),
                _pipe@3 = ewe@internal@encoder:encode_response(_pipe@2),
                glisten@transport:send(
                    erlang:element(2, Connection),
                    erlang:element(3, Connection),
                    _pipe@3
                )
            end,
            stop
    end.
