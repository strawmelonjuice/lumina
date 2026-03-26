-module(ewe@internal@http1).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/ewe/internal/http1.gleam").
-export([transform_connection/2, upgrade_websocket/3, append_default_headers/3, set_content_length/1, handle_continue/1, parse_request/2, read_body/2, stream_body/1]).
-export_type([connection/0, parse_error/0, http_version/0, parsed_request/0, http2_upgrade/0, stream/0, body_chunk/0, chunked_stream_state/0, upgrade_websocket_error/0, response_body/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-type connection() :: {connection,
        glisten@transport:transport(),
        glisten@socket:socket(),
        ewe@internal@http1@buffer:buffer(),
        gleam@erlang@process:name(gleam@otp@factory_supervisor:message(fun(() -> {ok,
                gleam@otp@actor:started(nil)} |
            {error, gleam@otp@actor:start_error()}), nil))}.

-type parse_error() :: invalid_method |
    invalid_path |
    invalid_version |
    invalid_headers |
    missing_host |
    duplicate_host |
    invalid_content_length |
    invalid_body |
    body_too_large |
    malformed_request |
    packet_discard.

-type http_version() :: http10 | http11.

-type parsed_request() :: {http1_request,
        gleam@http@request:request(connection()),
        http_version()} |
    {http2_upgrade, http2_upgrade()}.

-type http2_upgrade() :: {upgrade,
        gleam@http@request:request(connection()),
        binary()} |
    {direct, bitstring()}.

-type stream() :: {consumed,
        bitstring(),
        fun((integer()) -> {ok, stream()} | {error, parse_error()})} |
    done.

-type body_chunk() :: incomplete |
    {chunk, bitstring(), integer(), ewe@internal@http1@buffer:buffer()} |
    {final_chunk, ewe@internal@http1@buffer:buffer()}.

-type chunked_stream_state() :: {chunked_stream_state,
        ewe@internal@http1@buffer:buffer(),
        ewe@internal@http1@buffer:buffer(),
        boolean()}.

-type upgrade_websocket_error() :: method_not_get |
    missing_connection_header |
    invalid_connection_header |
    missing_upgrade_header |
    invalid_upgrade_header |
    missing_websocket_version |
    missing_websocket_key.

-type response_body() :: {text_data, binary()} |
    {bytes_data, gleam@bytes_tree:bytes_tree()} |
    {bits_data, bitstring()} |
    {string_tree_data, gleam@string_tree:string_tree()} |
    {file, ewe@internal@file:io_device(), integer(), integer()} |
    chunked |
    websocket |
    s_s_e |
    empty.

-file("src/ewe/internal/http1.gleam", 49).
?DOC(false).
-spec transform_connection(
    glisten:connection(any()),
    gleam@erlang@process:name(gleam@otp@factory_supervisor:message(fun(() -> {ok,
            gleam@otp@actor:started(nil)} |
        {error, gleam@otp@actor:start_error()}), nil))
) -> connection().
transform_connection(Conn, Factory_name) ->
    {connection,
        erlang:element(3, Conn),
        erlang:element(2, Conn),
        {buffer, <<>>, 0},
        Factory_name}.

-file("src/ewe/internal/http1.gleam", 329).
?DOC(false).
-spec available_cookie_key(gleam@dict:dict(binary(), binary()), integer()) -> binary().
available_cookie_key(Headers, Idx) ->
    Key = case Idx of
        0 ->
            <<"set-cookie"/utf8>>;

        N ->
            <<"set-cookie-"/utf8, (erlang:integer_to_binary(N))/binary>>
    end,
    case gleam@dict:has_key(Headers, Key) of
        true ->
            available_cookie_key(Headers, Idx + 1);

        false ->
            Key
    end.

-file("src/ewe/internal/http1.gleam", 310).
?DOC(false).
-spec insert_header(gleam@dict:dict(binary(), binary()), binary(), binary()) -> gleam@dict:dict(binary(), binary()).
insert_header(Headers, Field, Value) ->
    case Field /= <<"set-cookie"/utf8>> of
        true ->
            gleam@dict:upsert(Headers, Field, fun(Target) -> case Target of
                        {some, Existing} ->
                            <<<<Existing/binary, ", "/utf8>>/binary,
                                Value/binary>>;

                        none ->
                            Value
                    end end);

        false ->
            gleam@dict:insert(Headers, available_cookie_key(Headers, 0), Value)
    end.

-file("src/ewe/internal/http1.gleam", 459).
?DOC(false).
-spec parse_body_chunk(ewe@internal@http1@buffer:buffer()) -> {ok, body_chunk()} |
    {error, parse_error()}.
parse_body_chunk(Buffer) ->
    case binary:split(erlang:element(2, Buffer), <<"\r\n"/utf8>>, []) of
        [<<"0"/utf8>>, Rest] ->
            {ok, {final_chunk, {buffer, Rest, 0}}};

        [Chunk_size, Rest@1] ->
            gleam@result:'try'(
                begin
                    _pipe = gleam@bit_array:to_string(Chunk_size),
                    _pipe@1 = gleam@result:'try'(
                        _pipe,
                        fun(_capture) -> gleam@int:base_parse(_capture, 16) end
                    ),
                    gleam@result:replace_error(_pipe@1, invalid_body)
                end,
                fun(Size) -> case binary:split(Rest@1, <<"\r\n"/utf8>>, []) of
                        [Chunk, Rest@2] ->
                            case erlang:byte_size(Chunk) =:= Size of
                                true ->
                                    {ok,
                                        {chunk,
                                            Chunk,
                                            Size,
                                            {buffer, Rest@2, 0}}};

                                false ->
                                    {error, invalid_body}
                            end;

                        _ ->
                            {ok, incomplete}
                    end end
            );

        _ ->
            {ok, incomplete}
    end.

-file("src/ewe/internal/http1.gleam", 527).
?DOC(false).
-spec is_allowed_trailer(binary()) -> boolean().
is_allowed_trailer(Field) ->
    case Field of
        <<"server-timing"/utf8>> ->
            true;

        <<"content-digest"/utf8>> ->
            true;

        <<"repr-digest"/utf8>> ->
            true;

        _ ->
            false
    end.

-file("src/ewe/internal/http1.gleam", 491).
?DOC(false).
-spec handle_trailers(
    gleam@http@request:request(bitstring()),
    gleam@set:set(binary()),
    ewe@internal@http1@buffer:buffer()
) -> gleam@http@request:request(bitstring()).
handle_trailers(Req, Set, Rest) ->
    case ewe@internal@decoder:decode_packet(httph_bin, Rest) of
        {ok, {packet, http_eoh, _}} ->
            Req;

        {ok, {packet, {http_header, Idx, Field, Value}, Headers}} ->
            Field_name@1 = case ewe@internal@decoder:formatted_field_by_idx(Idx) of
                {ok, Field_name} ->
                    {ok, Field_name};

                {error, nil} ->
                    ewe_ffi:validate_lowercase_field(Field)
            end,
            case Field_name@1 of
                {ok, Field_name@2} ->
                    case gleam@set:contains(Set, Field_name@2) andalso is_allowed_trailer(
                        Field_name@2
                    ) of
                        true ->
                            case ewe_ffi:validate_field_value(Value) of
                                {ok, Value@1} ->
                                    _pipe = gleam@http@request:set_header(
                                        Req,
                                        Field_name@2,
                                        Value@1
                                    ),
                                    handle_trailers(
                                        _pipe,
                                        Set,
                                        {buffer, Headers, 0}
                                    );

                                {error, _} ->
                                    handle_trailers(
                                        Req,
                                        Set,
                                        {buffer, Headers, 0}
                                    )
                            end;

                        false ->
                            handle_trailers(Req, Set, {buffer, Headers, 0})
                    end;

                {error, _} ->
                    handle_trailers(Req, Set, {buffer, Headers, 0})
            end;

        _ ->
            Req
    end.

-file("src/ewe/internal/http1.gleam", 746).
?DOC(false).
-spec upgrade_websocket(
    gleam@http@request:request(connection()),
    glisten@transport:transport(),
    glisten@socket:socket()
) -> {ok, {list(binary()), boolean()}} | {error, upgrade_websocket_error()}.
upgrade_websocket(Req, Transport, Socket) ->
    gleam@bool:guard(
        erlang:element(2, Req) /= get,
        {error, method_not_get},
        fun() ->
            Is_upgrade = begin
                _pipe = gleam@http@request:get_header(
                    Req,
                    <<"connection"/utf8>>
                ),
                gleam@result:map(
                    _pipe,
                    fun(_capture) ->
                        gleam_stdlib:contains_string(
                            _capture,
                            <<"upgrade"/utf8>>
                        )
                    end
                )
            end,
            gleam@result:'try'(case Is_upgrade of
                    {ok, true} ->
                        {ok, nil};

                    {ok, false} ->
                        {error, invalid_connection_header};

                    {error, _} ->
                        {error, missing_connection_header}
                end, fun(_) ->
                    gleam@result:'try'(
                        case gleam@http@request:get_header(
                            Req,
                            <<"upgrade"/utf8>>
                        ) of
                            {ok, <<"websocket"/utf8>>} ->
                                {ok, nil};

                            {ok, _} ->
                                {error, invalid_upgrade_header};

                            {error, _} ->
                                {error, missing_upgrade_header}
                        end,
                        fun(_) ->
                            gleam@bool:guard(
                                gleam@http@request:get_header(
                                    Req,
                                    <<"sec-websocket-version"/utf8>>
                                )
                                =:= {error, nil},
                                {error, missing_websocket_version},
                                fun() ->
                                    gleam@result:'try'(
                                        begin
                                            _pipe@1 = gleam@http@request:get_header(
                                                Req,
                                                <<"sec-websocket-key"/utf8>>
                                            ),
                                            gleam@result:replace_error(
                                                _pipe@1,
                                                missing_websocket_key
                                            )
                                        end,
                                        fun(Key) ->
                                            Accept_key = websocks:compute_accept(
                                                Key
                                            ),
                                            Extensions = begin
                                                _pipe@2 = gleam@http@request:get_header(
                                                    Req,
                                                    <<"sec-websocket-extensions"/utf8>>
                                                ),
                                                _pipe@3 = gleam@result:map(
                                                    _pipe@2,
                                                    fun(_capture@1) ->
                                                        gleam@string:split(
                                                            _capture@1,
                                                            <<";"/utf8>>
                                                        )
                                                    end
                                                ),
                                                gleam@result:unwrap(_pipe@3, [])
                                            end,
                                            Permessage_deflate = websocks:has_deflate(
                                                Extensions
                                            ),
                                            Resp = begin
                                                _pipe@4 = gleam@http@response:new(
                                                    101
                                                ),
                                                _pipe@5 = gleam@http@response:set_body(
                                                    _pipe@4,
                                                    <<>>
                                                ),
                                                _pipe@6 = gleam@http@response:set_header(
                                                    _pipe@5,
                                                    <<"connection"/utf8>>,
                                                    <<"upgrade"/utf8>>
                                                ),
                                                _pipe@7 = gleam@http@response:set_header(
                                                    _pipe@6,
                                                    <<"upgrade"/utf8>>,
                                                    <<"websocket"/utf8>>
                                                ),
                                                _pipe@8 = gleam@http@response:set_header(
                                                    _pipe@7,
                                                    <<"sec-websocket-accept"/utf8>>,
                                                    Accept_key
                                                ),
                                                gleam@http@response:set_header(
                                                    _pipe@8,
                                                    <<"sec-websocket-version"/utf8>>,
                                                    <<"13"/utf8>>
                                                )
                                            end,
                                            Resp@1 = case Permessage_deflate of
                                                true ->
                                                    gleam@http@response:set_header(
                                                        Resp,
                                                        <<"sec-websocket-extensions"/utf8>>,
                                                        <<"permessage-deflate"/utf8>>
                                                    );

                                                false ->
                                                    Resp
                                            end,
                                            _ = begin
                                                _pipe@9 = ewe@internal@encoder:encode_response(
                                                    Resp@1
                                                ),
                                                glisten@transport:send(
                                                    Transport,
                                                    Socket,
                                                    _pipe@9
                                                )
                                            end,
                                            {ok,
                                                {Extensions, Permessage_deflate}}
                                        end
                                    )
                                end
                            )
                        end
                    )
                end)
        end
    ).

-file("src/ewe/internal/http1.gleam", 832).
?DOC(false).
-spec append_default_headers(
    gleam@http@response:response(NLI),
    gleam@http@request:request(connection()),
    http_version()
) -> gleam@http@response:response(NLI).
append_default_headers(Resp, Req, Version) ->
    Set_close = gleam@http@request:get_header(Req, <<"connection"/utf8>>) =:= {ok,
        <<"close"/utf8>>},
    Resp@1 = case gleam@http@response:get_header(Resp, <<"date"/utf8>>) of
        {ok, _} ->
            Resp;

        {error, nil} ->
            gleam@http@response:set_header(
                Resp,
                <<"date"/utf8>>,
                ewe@internal@clock:get_http_date()
            )
    end,
    case {Version, Set_close} of
        {http10, _} ->
            gleam@http@response:set_header(
                Resp@1,
                <<"connection"/utf8>>,
                <<"close"/utf8>>
            );

        {_, true} ->
            gleam@http@response:set_header(
                Resp@1,
                <<"connection"/utf8>>,
                <<"close"/utf8>>
            );

        {http11, false} ->
            case gleam@http@response:get_header(Resp@1, <<"connection"/utf8>>) of
                {ok, _} ->
                    Resp@1;

                {error, nil} ->
                    gleam@http@response:set_header(
                        Resp@1,
                        <<"connection"/utf8>>,
                        <<"keep-alive"/utf8>>
                    )
            end
    end.

-file("src/ewe/internal/http1.gleam", 857).
?DOC(false).
-spec set_content_length(gleam@http@response:response(bitstring())) -> gleam@http@response:response(bitstring()).
set_content_length(Resp) ->
    case gleam@http@response:get_header(Resp, <<"content-length"/utf8>>) of
        {ok, _} ->
            Resp;

        {error, nil} ->
            Body_size = begin
                _pipe = erlang:byte_size(erlang:element(4, Resp)),
                erlang:integer_to_binary(_pipe)
            end,
            gleam@http@response:set_header(
                Resp,
                <<"content-length"/utf8>>,
                Body_size
            )
    end.

-file("src/ewe/internal/http1.gleam", 869).
?DOC(false).
-spec handle_continue(gleam@http@request:request(connection())) -> {ok, nil} |
    {error, parse_error()}.
handle_continue(Req) ->
    Expect = begin
        _pipe = erlang:element(3, Req),
        gleam@list:find(
            _pipe,
            fun(Tupple) ->
                (erlang:element(1, Tupple) =:= <<"expect"/utf8>>) andalso (erlang:element(
                    2,
                    Tupple
                )
                =:= <<"100-continue"/utf8>>)
            end
        )
    end,
    case Expect of
        {ok, _} ->
            _pipe@1 = gleam@http@response:new(100),
            _pipe@2 = gleam@http@response:set_body(_pipe@1, <<>>),
            _pipe@3 = ewe@internal@encoder:encode_response(_pipe@2),
            _pipe@4 = glisten@transport:send(
                erlang:element(2, erlang:element(4, Req)),
                erlang:element(3, erlang:element(4, Req)),
                _pipe@3
            ),
            gleam@result:replace_error(_pipe@4, malformed_request);

        {error, nil} ->
            {ok, nil}
    end.

-file("src/ewe/internal/http1.gleam", 63).
?DOC(false).
-spec read_from_socket(
    glisten@transport:transport(),
    glisten@socket:socket(),
    ewe@internal@http1@buffer:buffer(),
    parse_error()
) -> {ok, ewe@internal@http1@buffer:buffer()} | {error, parse_error()}.
read_from_socket(Transport, Socket, Buffer, On_error) ->
    Read_size = gleam@int:min(erlang:element(3, Buffer), 2000000),
    gleam@result:'try'(
        begin
            _pipe = glisten@transport:receive_timeout(
                Transport,
                Socket,
                Read_size,
                5000
            ),
            gleam@result:replace_error(_pipe, On_error)
        end,
        fun(Data) ->
            New_buffer = ewe@internal@http1@buffer:append(Buffer, Data),
            case erlang:element(3, New_buffer) of
                0 ->
                    {ok, New_buffer};

                _ ->
                    read_from_socket(Transport, Socket, New_buffer, On_error)
            end
        end
    ).

-file("src/ewe/internal/http1.gleam", 236).
?DOC(false).
-spec parse_headers(
    glisten@transport:transport(),
    glisten@socket:socket(),
    ewe@internal@http1@buffer:buffer(),
    gleam@dict:dict(binary(), binary())
) -> {ok, {gleam@dict:dict(binary(), binary()), bitstring()}} |
    {error, parse_error()}.
parse_headers(Transport, Socket, Buffer, Headers) ->
    case ewe@internal@decoder:decode_packet(httph_bin, Buffer) of
        {ok, {packet, http_eoh, Rest}} ->
            {ok, {Headers, Rest}};

        {ok, {packet, {http_header, Idx, Field, Value}, Rest@1}} ->
            gleam@result:'try'(
                case ewe@internal@decoder:formatted_field_by_idx(Idx) of
                    {ok, Field@1} ->
                        {ok, Field@1};

                    {error, nil} ->
                        ewe_ffi:validate_lowercase_field(Field)
                end,
                fun(Field@2) -> gleam@result:'try'(case Field@2 of
                            <<"transfer-encoding"/utf8>> ->
                                ewe_ffi:validate_lowercase_field_value(Value);

                            <<"connection"/utf8>> ->
                                ewe_ffi:validate_lowercase_field_value(Value);

                            <<"upgrade"/utf8>> ->
                                ewe_ffi:validate_lowercase_field_value(Value);

                            <<"expect"/utf8>> ->
                                ewe_ffi:validate_lowercase_field_value(Value);

                            <<"trailer"/utf8>> ->
                                ewe_ffi:validate_lowercase_field_value(Value);

                            _ ->
                                ewe_ffi:validate_field_value(Value)
                        end, fun(Value@1) ->
                            New_buffer = {buffer, Rest@1, 0},
                            gleam@result:'try'(case Field@2 of
                                    <<"host"/utf8>> ->
                                        case gleam@dict:has_key(
                                            Headers,
                                            Field@2
                                        ) of
                                            true ->
                                                {error, duplicate_host};

                                            false ->
                                                {ok, nil}
                                        end;

                                    <<"content-length"/utf8>> ->
                                        _pipe = gleam_stdlib:parse_int(Value@1),
                                        _pipe@1 = gleam@result:'try'(
                                            _pipe,
                                            fun(Value@2) -> case Value@2 < 0 of
                                                    true ->
                                                        {error, nil};

                                                    false ->
                                                        {ok, nil}
                                                end end
                                        ),
                                        gleam@result:replace_error(
                                            _pipe@1,
                                            invalid_content_length
                                        );

                                    _ ->
                                        {ok, nil}
                                end, fun(_) ->
                                    _pipe@2 = insert_header(
                                        Headers,
                                        Field@2,
                                        Value@1
                                    ),
                                    parse_headers(
                                        Transport,
                                        Socket,
                                        New_buffer,
                                        _pipe@2
                                    )
                                end)
                        end) end
            );

        {ok, {more, Size}} ->
            Read_size = gleam@option:unwrap(Size, 0),
            Sized_buffer = {buffer, erlang:element(2, Buffer), Read_size},
            gleam@result:'try'(
                read_from_socket(
                    Transport,
                    Socket,
                    Sized_buffer,
                    invalid_headers
                ),
                fun(New_buffer@1) ->
                    parse_headers(Transport, Socket, New_buffer@1, Headers)
                end
            );

        _ ->
            {error, invalid_headers}
    end.

-file("src/ewe/internal/http1.gleam", 129).
?DOC(false).
-spec parse_request(connection(), ewe@internal@http1@buffer:buffer()) -> {ok,
        parsed_request()} |
    {error, parse_error()}.
parse_request(Conn, Buffer) ->
    Transport = erlang:element(2, Conn),
    Socket = erlang:element(3, Conn),
    case ewe@internal@decoder:decode_packet(http_bin, Buffer) of
        {ok,
            {packet,
                {http_request, Atom_method, {abs_path, Target}, Version},
                Rest}} ->
            gleam@result:'try'(
                begin
                    _pipe = ewe@internal@decoder:decode_method(Atom_method),
                    gleam@result:replace_error(_pipe, invalid_method)
                end,
                fun(Method) ->
                    gleam@result:'try'(
                        begin
                            _pipe@1 = gleam@bit_array:to_string(Target),
                            _pipe@2 = gleam@result:'try'(
                                _pipe@1,
                                fun ewe_ffi:parse_path/1
                            ),
                            gleam@result:replace_error(_pipe@2, invalid_path)
                        end,
                        fun(_use0) ->
                            {Path, Query} = _use0,
                            gleam@result:'try'(
                                parse_headers(
                                    Transport,
                                    Socket,
                                    {buffer, Rest, 0},
                                    maps:new()
                                ),
                                fun(_use0@1) ->
                                    {Headers, Rest@1} = _use0@1,
                                    Scheme = case Transport of
                                        tcp ->
                                            http;

                                        ssl ->
                                            https
                                    end,
                                    gleam@result:'try'(
                                        begin
                                            _pipe@3 = gleam_stdlib:map_get(
                                                Headers,
                                                <<"host"/utf8>>
                                            ),
                                            gleam@result:replace_error(
                                                _pipe@3,
                                                missing_host
                                            )
                                        end,
                                        fun(Host) ->
                                            {Host@2, Port@1} = case gleam@string:split_once(
                                                Host,
                                                <<":"/utf8>>
                                            ) of
                                                {ok, {Host@1, Port}} ->
                                                    {Host@1, {some, Port}};

                                                {error, _} ->
                                                    {Host, none}
                                            end,
                                            Port@3 = gleam@option:map(
                                                Port@1,
                                                fun(Port@2) ->
                                                    _pipe@4 = gleam_stdlib:parse_int(
                                                        Port@2
                                                    ),
                                                    gleam@result:unwrap(
                                                        _pipe@4,
                                                        case Scheme of
                                                            http ->
                                                                80;

                                                            https ->
                                                                443
                                                        end
                                                    )
                                                end
                                            ),
                                            Req = {request,
                                                Method,
                                                maps:to_list(Headers),
                                                {connection,
                                                    erlang:element(2, Conn),
                                                    erlang:element(3, Conn),
                                                    {buffer, Rest@1, 0},
                                                    erlang:element(5, Conn)},
                                                Scheme,
                                                Host@2,
                                                Port@3,
                                                Path,
                                                Query},
                                            case Version of
                                                {1, 0} ->
                                                    {ok,
                                                        {http1_request,
                                                            Req,
                                                            http10}};

                                                {1, 1} ->
                                                    Connection = gleam_stdlib:map_get(
                                                        Headers,
                                                        <<"connection"/utf8>>
                                                    ),
                                                    Upgrade = gleam_stdlib:map_get(
                                                        Headers,
                                                        <<"upgrade"/utf8>>
                                                    ),
                                                    Settings = gleam_stdlib:map_get(
                                                        Headers,
                                                        <<"http2-settings"/utf8>>
                                                    ),
                                                    case {Connection,
                                                        Upgrade,
                                                        Settings} of
                                                        {{ok, Connection@1},
                                                            {ok, <<"h2c"/utf8>>},
                                                            {ok, Settings@1}} ->
                                                            case gleam_stdlib:contains_string(
                                                                Connection@1,
                                                                <<"upgrade"/utf8>>
                                                            ) of
                                                                true ->
                                                                    {ok,
                                                                        {http2_upgrade,
                                                                            {upgrade,
                                                                                Req,
                                                                                Settings@1}}};

                                                                false ->
                                                                    {ok,
                                                                        {http1_request,
                                                                            Req,
                                                                            http11}}
                                                            end;

                                                        {_, _, _} ->
                                                            {ok,
                                                                {http1_request,
                                                                    Req,
                                                                    http11}}
                                                    end;

                                                _ ->
                                                    {error, invalid_version}
                                            end
                                        end
                                    )
                                end
                            )
                        end
                    )
                end
            );

        {ok, {packet, http2_upgrade, <<"\r\nSM\r\n\r\n"/utf8, Data/bitstring>>}} ->
            {ok, {http2_upgrade, {direct, Data}}};

        {ok, {more, Size}} ->
            gleam@result:'try'(
                read_from_socket(
                    Transport,
                    Socket,
                    {buffer,
                        erlang:element(2, Buffer),
                        gleam@option:unwrap(Size, 0)},
                    malformed_request
                ),
                fun(New_buffer) -> parse_request(Conn, New_buffer) end
            );

        _ ->
            {error, packet_discard}
    end.

-file("src/ewe/internal/http1.gleam", 415).
?DOC(false).
-spec read_chunked_body(
    glisten@transport:transport(),
    glisten@socket:socket(),
    ewe@internal@http1@buffer:buffer(),
    bitstring(),
    integer(),
    integer()
) -> {ok, {bitstring(), ewe@internal@http1@buffer:buffer()}} |
    {error, parse_error()}.
read_chunked_body(
    Transport,
    Socket,
    Buffer,
    Accumulated_body,
    Body_size_limit,
    Body_current_size
) ->
    gleam@bool:guard(
        Body_current_size > Body_size_limit,
        {error, body_too_large},
        fun() -> case parse_body_chunk(Buffer) of
                {ok, {final_chunk, Rest}} ->
                    {ok, {Accumulated_body, Rest}};

                {ok, incomplete} ->
                    gleam@result:'try'(
                        read_from_socket(
                            Transport,
                            Socket,
                            Buffer,
                            invalid_body
                        ),
                        fun(New_buffer) ->
                            read_chunked_body(
                                Transport,
                                Socket,
                                New_buffer,
                                Accumulated_body,
                                Body_size_limit,
                                Body_current_size
                            )
                        end
                    );

                {ok, {chunk, Chunk, Size, Rest@1}} ->
                    read_chunked_body(
                        Transport,
                        Socket,
                        Rest@1,
                        <<Accumulated_body/bitstring, Chunk/bitstring>>,
                        Body_size_limit,
                        Body_current_size + Size
                    );

                {error, Error} ->
                    {error, Error}
            end end
    ).

-file("src/ewe/internal/http1.gleam", 350).
?DOC(false).
-spec read_body(gleam@http@request:request(connection()), integer()) -> {ok,
        gleam@http@request:request(bitstring())} |
    {error, parse_error()}.
read_body(Req, Size_limit) ->
    gleam@result:'try'(
        handle_continue(Req),
        fun(_) ->
            Transport = erlang:element(2, erlang:element(4, Req)),
            Socket = erlang:element(3, erlang:element(4, Req)),
            case gleam@http@request:get_header(
                Req,
                <<"transfer-encoding"/utf8>>
            ) of
                {ok, <<"chunked"/utf8>>} ->
                    gleam@result:'try'(
                        read_chunked_body(
                            Transport,
                            Socket,
                            erlang:element(4, erlang:element(4, Req)),
                            <<>>,
                            Size_limit,
                            0
                        ),
                        fun(_use0) ->
                            {Body, Rest_buffer} = _use0,
                            Req@1 = gleam@http@request:set_body(Req, Body),
                            case gleam@list:key_find(
                                erlang:element(3, Req@1),
                                <<"trailer"/utf8>>
                            ) of
                                {ok, Trailer} ->
                                    Set@1 = begin
                                        _pipe = Trailer,
                                        _pipe@1 = gleam@string:split(
                                            _pipe,
                                            <<","/utf8>>
                                        ),
                                        gleam@list:fold(
                                            _pipe@1,
                                            gleam@set:new(),
                                            fun(Set, Field) ->
                                                gleam@set:insert(
                                                    Set,
                                                    gleam@string:trim(Field)
                                                )
                                            end
                                        )
                                    end,
                                    {ok,
                                        handle_trailers(
                                            Req@1,
                                            Set@1,
                                            Rest_buffer
                                        )};

                                {error, nil} ->
                                    {ok, Req@1}
                            end
                        end
                    );

                _ ->
                    Content_length = begin
                        _pipe@2 = gleam@http@request:get_header(
                            Req,
                            <<"content-length"/utf8>>
                        ),
                        _pipe@3 = gleam@result:'try'(
                            _pipe@2,
                            fun gleam_stdlib:parse_int/1
                        ),
                        gleam@result:unwrap(_pipe@3, 0)
                    end,
                    gleam@bool:guard(
                        Content_length > Size_limit,
                        {error, body_too_large},
                        fun() ->
                            Left = Content_length - erlang:byte_size(
                                erlang:element(
                                    2,
                                    erlang:element(4, erlang:element(4, Req))
                                )
                            ),
                            _pipe@5 = case {Content_length, Left} of
                                {0, 0} ->
                                    {ok, <<>>};

                                {0, _} ->
                                    {ok,
                                        erlang:element(
                                            2,
                                            erlang:element(
                                                4,
                                                erlang:element(4, Req)
                                            )
                                        )};

                                {_, 0} ->
                                    {ok,
                                        erlang:element(
                                            2,
                                            erlang:element(
                                                4,
                                                erlang:element(4, Req)
                                            )
                                        )};

                                {_, _} ->
                                    _pipe@4 = read_from_socket(
                                        Transport,
                                        Socket,
                                        {buffer,
                                            erlang:element(
                                                2,
                                                erlang:element(
                                                    4,
                                                    erlang:element(4, Req)
                                                )
                                            ),
                                            Left},
                                        invalid_body
                                    ),
                                    gleam@result:map(
                                        _pipe@4,
                                        fun(Buffer) ->
                                            erlang:element(2, Buffer)
                                        end
                                    )
                            end,
                            gleam@result:map(
                                _pipe@5,
                                fun(_capture) ->
                                    gleam@http@request:set_body(Req, _capture)
                                end
                            )
                        end
                    )
            end
        end
    ).

-file("src/ewe/internal/http1.gleam", 612).
?DOC(false).
-spec read_from_socket_until(
    glisten@transport:transport(),
    glisten@socket:socket(),
    chunked_stream_state(),
    integer()
) -> {ok, {bitstring(), chunked_stream_state()}} | {error, parse_error()}.
read_from_socket_until(Transport, Socket, State, Until) ->
    Size = erlang:byte_size(erlang:element(2, erlang:element(2, State))),
    case {erlang:element(4, State), Size} of
        {_, Size@1} when Size@1 >= Until ->
            {Data, Rest} = ewe@internal@http1@buffer:split(
                erlang:element(2, State),
                Until
            ),
            {ok,
                {Data,
                    {chunked_stream_state,
                        {buffer, Rest, 0},
                        erlang:element(3, State),
                        erlang:element(4, State)}}};

        {true, _} ->
            {ok, {erlang:element(2, erlang:element(2, State)), State}};

        {false, _} ->
            case parse_body_chunk(erlang:element(3, State)) of
                {ok, {final_chunk, _}} ->
                    read_from_socket_until(
                        Transport,
                        Socket,
                        {chunked_stream_state,
                            erlang:element(2, State),
                            {buffer, <<>>, 0},
                            true},
                        Until
                    );

                {ok, incomplete} ->
                    gleam@result:'try'(
                        read_from_socket(
                            Transport,
                            Socket,
                            erlang:element(3, State),
                            invalid_body
                        ),
                        fun(New_buffer) ->
                            read_from_socket_until(
                                Transport,
                                Socket,
                                {chunked_stream_state,
                                    erlang:element(2, State),
                                    New_buffer,
                                    erlang:element(4, State)},
                                Until
                            )
                        end
                    );

                {ok, {chunk, Chunk, _, Rest@1}} ->
                    read_from_socket_until(
                        Transport,
                        Socket,
                        {chunked_stream_state,
                            ewe@internal@http1@buffer:append(
                                erlang:element(2, State),
                                Chunk
                            ),
                            Rest@1,
                            erlang:element(4, State)},
                        Until
                    );

                {error, Error} ->
                    {error, Error}
            end
    end.

-file("src/ewe/internal/http1.gleam", 588).
?DOC(false).
-spec do_stream_body_chunked(
    gleam@http@request:request(connection()),
    chunked_stream_state()
) -> fun((integer()) -> {ok, stream()} | {error, parse_error()}).
do_stream_body_chunked(Req, Chunked_stream_state) ->
    fun(Size) ->
        Read_result = read_from_socket_until(
            erlang:element(2, erlang:element(4, Req)),
            erlang:element(3, erlang:element(4, Req)),
            Chunked_stream_state,
            Size
        ),
        case Read_result of
            {ok, {Data, {chunked_stream_state, _, _, true}}} ->
                {ok, {consumed, Data, fun(_) -> {ok, done} end}};

            {ok, {Data@1, State}} ->
                {ok, {consumed, Data@1, do_stream_body_chunked(Req, State)}};

            {error, _} ->
                {error, invalid_body}
        end
    end.

-file("src/ewe/internal/http1.gleam", 680).
?DOC(false).
-spec do_stream_body(
    gleam@http@request:request(connection()),
    ewe@internal@http1@buffer:buffer()
) -> fun((integer()) -> {ok, stream()} | {error, parse_error()}).
do_stream_body(Req, Buffer) ->
    fun(Size) ->
        Buffer_size = erlang:byte_size(erlang:element(2, Buffer)),
        case {erlang:element(3, Buffer), Buffer_size} of
            {0, 0} ->
                {ok, done};

            {0, _} ->
                {Data, Rest} = ewe@internal@http1@buffer:split(Buffer, Size),
                {ok, {consumed, Data, do_stream_body(Req, {buffer, Rest, 0})}};

            {_, Buffer_size@1} when Buffer_size@1 >= Size ->
                {Data@1, Rest@1} = ewe@internal@http1@buffer:split(Buffer, Size),
                New_buffer = {buffer, Rest@1, erlang:element(3, Buffer)},
                {ok, {consumed, Data@1, do_stream_body(Req, New_buffer)}};

            {_, _} ->
                gleam@result:'try'(
                    read_from_socket(
                        erlang:element(2, erlang:element(4, Req)),
                        erlang:element(3, erlang:element(4, Req)),
                        {buffer, <<>>, 0},
                        invalid_body
                    ),
                    fun(Read_buffer) ->
                        New_buffer@1 = {buffer,
                            <<(erlang:element(2, Buffer))/bitstring,
                                (erlang:element(2, Read_buffer))/bitstring>>,
                            gleam@int:max(
                                0,
                                erlang:element(3, Buffer) - erlang:byte_size(
                                    erlang:element(2, Read_buffer)
                                )
                            )},
                        {Data@2, Rest@2} = ewe@internal@http1@buffer:split(
                            New_buffer@1,
                            Size
                        ),
                        {ok,
                            {consumed,
                                Data@2,
                                do_stream_body(Req, {buffer, Rest@2, 0})}}
                    end
                )
        end
    end.

-file("src/ewe/internal/http1.gleam", 560).
?DOC(false).
-spec stream_body(gleam@http@request:request(connection())) -> {ok,
        fun((integer()) -> {ok, stream()} | {error, parse_error()})} |
    {error, parse_error()}.
stream_body(Req) ->
    gleam@result:'try'(
        begin
            _pipe = handle_continue(Req),
            gleam@result:replace_error(_pipe, invalid_body)
        end,
        fun(_) ->
            case gleam@http@request:get_header(
                Req,
                <<"transfer-encoding"/utf8>>
            ) of
                {ok, <<"chunked"/utf8>>} ->
                    State = {chunked_stream_state,
                        {buffer, <<>>, 0},
                        erlang:element(4, erlang:element(4, Req)),
                        false},
                    {ok, do_stream_body_chunked(Req, State)};

                _ ->
                    Content_length = begin
                        _pipe@1 = gleam@http@request:get_header(
                            Req,
                            <<"content-length"/utf8>>
                        ),
                        _pipe@2 = gleam@result:'try'(
                            _pipe@1,
                            fun gleam_stdlib:parse_int/1
                        ),
                        gleam@result:unwrap(_pipe@2, 0)
                    end,
                    Pending = Content_length - erlang:byte_size(
                        erlang:element(
                            2,
                            erlang:element(4, erlang:element(4, Req))
                        )
                    ),
                    Stream_buffer = {buffer,
                        erlang:element(
                            2,
                            erlang:element(4, erlang:element(4, Req))
                        ),
                        gleam@int:max(0, Pending)},
                    _pipe@3 = do_stream_body(Req, Stream_buffer),
                    {ok, _pipe@3}
            end
        end
    ).
