-module(ewe@internal@encoder).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/ewe/internal/encoder.gleam").
-export([encode_response/1, encode_response_partially/1]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-file("src/ewe/internal/encoder.gleam", 38).
?DOC(false).
-spec encode_headers(list({binary(), binary()})) -> bitstring().
encode_headers(Headers) ->
    Headers@2 = gleam@list:fold(
        Headers,
        <<>>,
        fun(Acc, Headers@1) ->
            {Key, Value} = Headers@1,
            <<Acc/bitstring,
                (ewe_ffi:sanitize_header_value(Key))/binary,
                ": "/utf8,
                (ewe_ffi:sanitize_header_value(Value))/binary,
                "\r\n"/utf8>>
        end
    ),
    <<Headers@2/bitstring, "\r\n"/utf8>>.

-file("src/ewe/internal/encoder.gleam", 60).
?DOC(false).
-spec status_to_bit_array(integer()) -> bitstring().
status_to_bit_array(Status) ->
    case Status of
        100 ->
            <<"Continue"/utf8>>;

        101 ->
            <<"Switching Protocols"/utf8>>;

        102 ->
            <<"Processing"/utf8>>;

        103 ->
            <<"Early Hints"/utf8>>;

        200 ->
            <<"OK"/utf8>>;

        201 ->
            <<"Created"/utf8>>;

        202 ->
            <<"Accepted"/utf8>>;

        203 ->
            <<"Non-Authoritative Information"/utf8>>;

        204 ->
            <<"No Content"/utf8>>;

        205 ->
            <<"Reset Content"/utf8>>;

        206 ->
            <<"Partial Content"/utf8>>;

        207 ->
            <<"Multi-Status"/utf8>>;

        208 ->
            <<"Already Reported"/utf8>>;

        226 ->
            <<"IM Used"/utf8>>;

        300 ->
            <<"Multiple Choices"/utf8>>;

        301 ->
            <<"Moved Permanently"/utf8>>;

        302 ->
            <<"Found"/utf8>>;

        303 ->
            <<"See Other"/utf8>>;

        304 ->
            <<"Not Modified"/utf8>>;

        307 ->
            <<"Temporary Redirect"/utf8>>;

        308 ->
            <<"Permanent Redirect"/utf8>>;

        400 ->
            <<"Bad Request"/utf8>>;

        401 ->
            <<"Unauthorized"/utf8>>;

        403 ->
            <<"Forbidden"/utf8>>;

        404 ->
            <<"Not Found"/utf8>>;

        405 ->
            <<"Method Not Allowed"/utf8>>;

        406 ->
            <<"Not Acceptable"/utf8>>;

        407 ->
            <<"Proxy Authentication Required"/utf8>>;

        408 ->
            <<"Request Timeout"/utf8>>;

        409 ->
            <<"Conflict"/utf8>>;

        410 ->
            <<"Gone"/utf8>>;

        411 ->
            <<"Length Required"/utf8>>;

        412 ->
            <<"Precondition Failed"/utf8>>;

        413 ->
            <<"Payload Too Large"/utf8>>;

        414 ->
            <<"URI Too Long"/utf8>>;

        415 ->
            <<"Unsupported Media Type"/utf8>>;

        416 ->
            <<"Range Not Satisfiable"/utf8>>;

        417 ->
            <<"Expectation Failed"/utf8>>;

        418 ->
            <<"I'm a teapot"/utf8>>;

        421 ->
            <<"Misdirected Request"/utf8>>;

        422 ->
            <<"Unprocessable Entity"/utf8>>;

        423 ->
            <<"Locked"/utf8>>;

        424 ->
            <<"Failed Dependency"/utf8>>;

        425 ->
            <<"Too Early"/utf8>>;

        426 ->
            <<"Upgrade Required"/utf8>>;

        428 ->
            <<"Precondition Required"/utf8>>;

        429 ->
            <<"Too Many Requests"/utf8>>;

        431 ->
            <<"Request Header Fields Too Large"/utf8>>;

        451 ->
            <<"Unavailable For Legal Reasons"/utf8>>;

        500 ->
            <<"Internal Server Error"/utf8>>;

        501 ->
            <<"Not Implemented"/utf8>>;

        502 ->
            <<"Bad Gateway"/utf8>>;

        503 ->
            <<"Service Unavailable"/utf8>>;

        504 ->
            <<"Gateway Timeout"/utf8>>;

        505 ->
            <<"HTTP Version Not Supported"/utf8>>;

        506 ->
            <<"Variant Also Negotiates"/utf8>>;

        507 ->
            <<"Insufficient Storage"/utf8>>;

        508 ->
            <<"Loop Detected"/utf8>>;

        510 ->
            <<"Not Extended"/utf8>>;

        511 ->
            <<"Network Authentication Required"/utf8>>;

        _ ->
            <<"Unknown HTTP Status"/utf8>>
    end.

-file("src/ewe/internal/encoder.gleam", 29).
?DOC(false).
-spec encode_status_line(integer()) -> bitstring().
encode_status_line(Status) ->
    Status_name = status_to_bit_array(Status),
    Status@1 = erlang:integer_to_binary(Status),
    <<"HTTP/1.1 "/utf8,
        Status@1/binary,
        " "/utf8,
        Status_name/bitstring,
        "\r\n"/utf8>>.

-file("src/ewe/internal/encoder.gleam", 8).
?DOC(false).
-spec encode_response(gleam@http@response:response(bitstring())) -> gleam@bytes_tree:bytes_tree().
encode_response(Response) ->
    _pipe = gleam@bytes_tree:new(),
    _pipe@1 = gleam@bytes_tree:append(
        _pipe,
        encode_status_line(erlang:element(2, Response))
    ),
    _pipe@2 = gleam@bytes_tree:append(
        _pipe@1,
        encode_headers(erlang:element(3, Response))
    ),
    gleam@bytes_tree:append(_pipe@2, erlang:element(4, Response)).

-file("src/ewe/internal/encoder.gleam", 19).
?DOC(false).
-spec encode_response_partially(gleam@http@response:response(any())) -> gleam@bytes_tree:bytes_tree().
encode_response_partially(Response) ->
    _pipe = gleam@bytes_tree:new(),
    _pipe@1 = gleam@bytes_tree:append(
        _pipe,
        encode_status_line(erlang:element(2, Response))
    ),
    gleam@bytes_tree:append(
        _pipe@1,
        encode_headers(erlang:element(3, Response))
    ).
