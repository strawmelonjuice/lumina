-module(collie@internal@http).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/collie/internal/http.gleam").
-export([construct_upgrade/1, decode_response/3]).
-export_type([decode_error/0, decoder_error/0, packet_type/0, packet/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-type decode_error() :: {socket_failed, collie@internal@socket:socket_reason()} |
    malformed_request.

-type decoder_error() :: {more, integer()} | {http_error, binary()}.

-type packet_type() :: httph_bin | http_bin.

-type packet() :: {http_response, {integer(), integer()}, integer(), binary()} |
    {http_header, integer(), bitstring(), bitstring()} |
    http_eoh.

-file("src/collie/internal/http.gleam", 13).
?DOC(false).
-spec construct_upgrade(gleam@http@request:request(any())) -> gleam@bytes_tree:bytes_tree().
construct_upgrade(Request) ->
    Headers = <<(gleam@list:fold(
            erlang:element(3, Request),
            <<""/utf8>>,
            fun(Acc, Pair) ->
                {Key, Value} = Pair,
                case Key of
                    <<"host"/utf8>> ->
                        Acc;

                    <<"upgrade"/utf8>> ->
                        Acc;

                    <<"connection"/utf8>> ->
                        Acc;

                    <<"sec-websocket-key"/utf8>> ->
                        Acc;

                    <<"sec-websocket-version"/utf8>> ->
                        Acc;

                    <<"sec-websocket-extensions"/utf8>> ->
                        Acc;

                    Key@1 ->
                        <<<<<<<<Acc/binary, Key@1/binary>>/binary, ": "/utf8>>/binary,
                                Value/binary>>/binary,
                            "\r\n"/utf8>>
                end
            end
        ))/binary,
        "\r\n"/utf8>>,
    Port@1 = begin
        _pipe = gleam@option:map(
            erlang:element(7, Request),
            fun(Port) ->
                <<":"/utf8, (erlang:integer_to_binary(Port))/binary>>
            end
        ),
        gleam@option:unwrap(_pipe, <<""/utf8>>)
    end,
    Path@1 = case erlang:element(8, Request) of
        <<""/utf8>> ->
            <<"/"/utf8>>;

        Path ->
            Path
    end,
    Query@1 = case gleam@option:then(
        erlang:element(9, Request),
        fun collie_ffi:validate_query/1
    ) of
        none ->
            <<""/utf8>>;

        {some, <<""/utf8>>} ->
            <<""/utf8>>;

        {some, Query} ->
            <<"?"/utf8, Query/binary>>
    end,
    Extensions_header = <<"sec-websocket-extensions: permessage-deflate; client_max_window_bits\r\n"/utf8>>,
    _pipe@1 = gleam@bytes_tree:new(),
    _pipe@2 = gleam@bytes_tree:append_string(
        _pipe@1,
        <<<<<<"GET "/utf8, Path@1/binary>>/binary, Query@1/binary>>/binary,
            " HTTP/1.1\r\n"/utf8>>
    ),
    _pipe@3 = gleam@bytes_tree:append_string(
        _pipe@2,
        <<<<<<"host: "/utf8, (erlang:element(6, Request))/binary>>/binary,
                Port@1/binary>>/binary,
            "\r\n"/utf8>>
    ),
    _pipe@4 = gleam@bytes_tree:append_string(
        _pipe@3,
        <<"connection: upgrade\r\n"/utf8>>
    ),
    _pipe@5 = gleam@bytes_tree:append_string(
        _pipe@4,
        <<"upgrade: websocket\r\n"/utf8>>
    ),
    _pipe@6 = gleam@bytes_tree:append_string(
        _pipe@5,
        <<<<"sec-websocket-key: "/utf8, (websocks:websocket_key())/binary>>/binary,
            "\r\n"/utf8>>
    ),
    _pipe@7 = gleam@bytes_tree:append_string(
        _pipe@6,
        <<"sec-websocket-version: 13\r\n"/utf8>>
    ),
    _pipe@8 = gleam@bytes_tree:append_string(_pipe@7, Extensions_header),
    gleam@bytes_tree:append_string(_pipe@8, Headers).

-file("src/collie/internal/http.gleam", 184).
?DOC(false).
-spec decode_body(
    collie@internal@socket:transport(),
    collie@internal@socket:socket(),
    integer(),
    integer(),
    bitstring()
) -> {ok, {bitstring(), bitstring()}} | {error, decode_error()}.
decode_body(Transport, Socket, Timeout, Content_length, Buffer) ->
    case Buffer of
        <<Data:Content_length/binary, Remaining/bitstring>> ->
            {ok, {Data, Remaining}};

        _ ->
            case collie@internal@socket:receive_timeout(
                Transport,
                Socket,
                0,
                Timeout
            ) of
                {ok, Data@1} ->
                    decode_body(
                        Transport,
                        Socket,
                        Timeout,
                        Content_length,
                        <<Buffer/bitstring, Data@1/bitstring>>
                    );

                {error, Reason} ->
                    {error, {socket_failed, Reason}}
            end
    end.

-file("src/collie/internal/http.gleam", 209).
?DOC(false).
-spec formatted_field_by_idx(integer()) -> {ok, binary()} | {error, nil}.
formatted_field_by_idx(Idx) ->
    case Idx of
        0 ->
            {error, nil};

        1 ->
            {ok, <<"cache-control"/utf8>>};

        2 ->
            {ok, <<"connection"/utf8>>};

        3 ->
            {ok, <<"date"/utf8>>};

        4 ->
            {ok, <<"pragma"/utf8>>};

        5 ->
            {ok, <<"transfer-encoding"/utf8>>};

        6 ->
            {ok, <<"upgrade"/utf8>>};

        7 ->
            {ok, <<"via"/utf8>>};

        8 ->
            {ok, <<"accept"/utf8>>};

        9 ->
            {ok, <<"accept-charset"/utf8>>};

        10 ->
            {ok, <<"accept-encoding"/utf8>>};

        11 ->
            {ok, <<"accept-language"/utf8>>};

        12 ->
            {ok, <<"authorization"/utf8>>};

        13 ->
            {ok, <<"from"/utf8>>};

        14 ->
            {ok, <<"host"/utf8>>};

        15 ->
            {ok, <<"if-modified-since"/utf8>>};

        16 ->
            {ok, <<"if-match"/utf8>>};

        17 ->
            {ok, <<"if-none-match"/utf8>>};

        18 ->
            {ok, <<"if-range"/utf8>>};

        19 ->
            {ok, <<"if-unmodified-since"/utf8>>};

        20 ->
            {ok, <<"max-forwards"/utf8>>};

        21 ->
            {ok, <<"proxy-authorization"/utf8>>};

        22 ->
            {ok, <<"range"/utf8>>};

        23 ->
            {ok, <<"referer"/utf8>>};

        24 ->
            {ok, <<"user-agent"/utf8>>};

        25 ->
            {ok, <<"age"/utf8>>};

        26 ->
            {ok, <<"location"/utf8>>};

        27 ->
            {ok, <<"proxy-authenticate"/utf8>>};

        28 ->
            {ok, <<"public"/utf8>>};

        29 ->
            {ok, <<"retry-after"/utf8>>};

        30 ->
            {ok, <<"server"/utf8>>};

        31 ->
            {ok, <<"vary"/utf8>>};

        32 ->
            {ok, <<"warning"/utf8>>};

        33 ->
            {ok, <<"www-authenticate"/utf8>>};

        34 ->
            {ok, <<"allow"/utf8>>};

        35 ->
            {ok, <<"content-base"/utf8>>};

        36 ->
            {ok, <<"content-encoding"/utf8>>};

        37 ->
            {ok, <<"content-language"/utf8>>};

        38 ->
            {ok, <<"content-length"/utf8>>};

        39 ->
            {ok, <<"content-location"/utf8>>};

        40 ->
            {ok, <<"content-md5"/utf8>>};

        41 ->
            {ok, <<"content-range"/utf8>>};

        42 ->
            {ok, <<"content-type"/utf8>>};

        43 ->
            {ok, <<"etag"/utf8>>};

        44 ->
            {ok, <<"expires"/utf8>>};

        45 ->
            {ok, <<"last-modified"/utf8>>};

        46 ->
            {ok, <<"accept-ranges"/utf8>>};

        47 ->
            {ok, <<"set-cookie"/utf8>>};

        48 ->
            {ok, <<"set-cookie2"/utf8>>};

        49 ->
            {ok, <<"x-forwarded-for"/utf8>>};

        50 ->
            {ok, <<"cookie"/utf8>>};

        51 ->
            {ok, <<"keep-alive"/utf8>>};

        52 ->
            {ok, <<"proxy-connection"/utf8>>};

        _ ->
            {error, nil}
    end.

-file("src/collie/internal/http.gleam", 139).
?DOC(false).
-spec decode_headers(
    collie@internal@socket:transport(),
    collie@internal@socket:socket(),
    integer(),
    bitstring(),
    list({binary(), binary()})
) -> {ok, {list({binary(), binary()}), bitstring()}} | {error, decode_error()}.
decode_headers(Transport, Socket, Timeout, Buffer, Headers) ->
    case collie_ffi:decode_packet(httph_bin, Buffer) of
        {ok, {http_eoh, Remaining}} ->
            {ok, {lists:reverse(Headers), Remaining}};

        {ok, {{http_header, Idx, Field, Value}, Remaining@1}} ->
            gleam@result:'try'(case formatted_field_by_idx(Idx) of
                    {ok, Field@1} ->
                        {ok, Field@1};

                    {error, nil} ->
                        _pipe = gleam@bit_array:to_string(Field),
                        _pipe@1 = gleam@result:map(
                            _pipe,
                            fun string:lowercase/1
                        ),
                        gleam@result:replace_error(_pipe@1, malformed_request)
                end, fun(Field@2) ->
                    gleam@result:'try'(
                        begin
                            _pipe@2 = collie_ffi:validate_field_value(Value),
                            gleam@result:replace_error(
                                _pipe@2,
                                malformed_request
                            )
                        end,
                        fun(Value@1) ->
                            decode_headers(
                                Transport,
                                Socket,
                                Timeout,
                                Remaining@1,
                                [{Field@2, Value@1} | Headers]
                            )
                        end
                    )
                end);

        {error, {more, Length}} ->
            case collie@internal@socket:receive_timeout(
                Transport,
                Socket,
                Length,
                Timeout
            ) of
                {ok, Data} ->
                    decode_headers(
                        Transport,
                        Socket,
                        Timeout,
                        <<Buffer/bitstring, Data/bitstring>>,
                        Headers
                    );

                {error, Reason} ->
                    {error, {socket_failed, Reason}}
            end;

        {ok, _} ->
            {error, malformed_request};

        {error, _} ->
            {error, malformed_request}
    end.

-file("src/collie/internal/http.gleam", 98).
?DOC(false).
-spec do_decode_response(
    collie@internal@socket:transport(),
    collie@internal@socket:socket(),
    integer(),
    integer(),
    bitstring()
) -> {ok, {gleam@http@response:response(bitstring()), bitstring()}} |
    {error, decode_error()}.
do_decode_response(Transport, Socket, Timeout, Length, Buffer) ->
    case collie@internal@socket:receive_timeout(
        Transport,
        Socket,
        Length,
        Timeout
    ) of
        {ok, Data} ->
            case collie_ffi:decode_packet(http_bin, Data) of
                {ok, {{http_response, _, Status, _}, Remaining}} ->
                    gleam@result:'try'(
                        decode_headers(
                            Transport,
                            Socket,
                            Timeout,
                            Remaining,
                            []
                        ),
                        fun(_use0) ->
                            {Headers, Remaining@1} = _use0,
                            Content_length = begin
                                _pipe = gleam@list:key_find(
                                    Headers,
                                    <<"content-length"/utf8>>
                                ),
                                _pipe@1 = gleam@result:'try'(
                                    _pipe,
                                    fun gleam_stdlib:parse_int/1
                                ),
                                gleam@result:unwrap(_pipe@1, 0)
                            end,
                            gleam@result:'try'(
                                decode_body(
                                    Transport,
                                    Socket,
                                    Timeout,
                                    Content_length,
                                    Remaining@1
                                ),
                                fun(_use0@1) ->
                                    {Body, Remaining@2} = _use0@1,
                                    {ok,
                                        {{response, Status, Headers, Body},
                                            Remaining@2}}
                                end
                            )
                        end
                    );

                {error, {more, Length@1}} ->
                    do_decode_response(
                        Transport,
                        Socket,
                        Timeout,
                        Length@1,
                        <<Buffer/bitstring, Data/bitstring>>
                    );

                {ok, _} ->
                    {error, malformed_request};

                {error, _} ->
                    {error, malformed_request}
            end;

        {error, Reason} ->
            {error, {socket_failed, Reason}}
    end.

-file("src/collie/internal/http.gleam", 90).
?DOC(false).
-spec decode_response(
    collie@internal@socket:transport(),
    collie@internal@socket:socket(),
    integer()
) -> {ok, {gleam@http@response:response(bitstring()), bitstring()}} |
    {error, decode_error()}.
decode_response(Transport, Socket, Timeout) ->
    do_decode_response(Transport, Socket, Timeout, 0, <<>>).
