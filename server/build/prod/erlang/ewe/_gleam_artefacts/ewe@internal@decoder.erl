-module(ewe@internal@decoder).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/ewe/internal/decoder.gleam").
-export([decode_packet/2, decode_method/1, formatted_field_by_idx/1]).
-export_type([packet_type/0, abs_path/0, http_packet/0, packet/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-type packet_type() :: http_bin | httph_bin.

-type abs_path() :: {abs_path, bitstring()}.

-type http_packet() :: {http_request,
        bitstring(),
        abs_path(),
        {integer(), integer()}} |
    {http_header, integer(), bitstring(), bitstring()} |
    http_eoh |
    http2_upgrade.

-type packet() :: {packet, http_packet(), bitstring()} |
    {more, gleam@option:option(integer())}.

-file("src/ewe/internal/decoder.gleam", 42).
?DOC(false).
-spec decode_packet(packet_type(), ewe@internal@http1@buffer:buffer()) -> {ok,
        packet()} |
    {error, gleam@dynamic:dynamic_()}.
decode_packet(Type_, Buffer) ->
    ewe_ffi:decode_packet(Type_, erlang:element(2, Buffer), []).

-file("src/ewe/internal/decoder.gleam", 58).
?DOC(false).
-spec decode_method(bitstring()) -> {ok, gleam@http:method()} | {error, nil}.
decode_method(Method) ->
    case Method of
        <<"GET"/utf8>> ->
            {ok, get};

        <<"POST"/utf8>> ->
            {ok, post};

        <<"HEAD"/utf8>> ->
            {ok, head};

        <<"PUT"/utf8>> ->
            {ok, put};

        <<"DELETE"/utf8>> ->
            {ok, delete};

        <<"TRACE"/utf8>> ->
            {ok, trace};

        <<"CONNECT"/utf8>> ->
            {ok, connect};

        <<"OPTIONS"/utf8>> ->
            {ok, options};

        <<"PATCH"/utf8>> ->
            {ok, patch};

        _ ->
            {error, nil}
    end.

-file("src/ewe/internal/decoder.gleam", 75).
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
