-module(compresso@compression).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/compresso/compression.gleam").
-export([init_stream/0, close_stream/1, deflate/3, end_deflate/1, gzip/1, gunzip/1, init_deflate/5]).
-export_type([stream/0, compression_strategy/0, compression_method/0, flush/0]).

-type stream() :: any().

-type compression_strategy() :: default | filtered | huffman_only | r_l_e.

-type compression_method() :: deflated.

-type flush() :: none | sync | full | finish.

-file("src/compresso/compression.gleam", 10).
-spec init_stream() -> stream().
init_stream() ->
    zlib:open().

-file("src/compresso/compression.gleam", 14).
-spec close_stream(stream()) -> nil.
close_stream(Stream) ->
    zlib:close(Stream).

-file("src/compresso/compression.gleam", 112).
-spec deflate(stream(), bitstring(), flush()) -> list(bitstring()).
deflate(Stream, Data, Flush) ->
    zlib:deflate(Stream, Data, Flush).

-file("src/compresso/compression.gleam", 114).
-spec end_deflate(stream()) -> {ok, nil} | {error, nil}.
end_deflate(Stream) ->
    _pipe = exception_ffi:rescue(fun() -> zlib:'deflateEnd'(Stream) end),
    _pipe@1 = gleam@result:replace(_pipe, nil),
    gleam@result:map_error(
        _pipe@1,
        fun(E) ->
            logging:log(
                error,
                <<"Failed to end deflate: "/utf8,
                    (gleam@string:inspect(E))/binary>>
            ),
            nil
        end
    ).

-file("src/compresso/compression.gleam", 127).
-spec gzip(bitstring()) -> bitstring().
gzip(Data) ->
    zlib:gzip(Data).

-file("src/compresso/compression.gleam", 130).
-spec gunzip(bitstring()) -> bitstring().
gunzip(Data) ->
    zlib:gunzip(Data).

-file("src/compresso/compression.gleam", 33).
-spec init_deflate(
    stream(),
    gleam@option:option(integer()),
    gleam@option:option(integer()),
    gleam@option:option(integer()),
    gleam@option:option(compression_strategy())
) -> {ok, nil} | {error, nil}.
init_deflate(Stream, Compression_level, Window_bits, Memory_level, Strategy) ->
    Compression_level@1 = case Compression_level of
        {some, Level} when (Level >= 0) andalso (Level =< 9) ->
            Level;

        _ ->
            6
    end,
    Window_bits@1 = gleam@option:unwrap(Window_bits, 15),
    Memory_level@1 = case Memory_level of
        {some, Level@1} when (Level@1 >= 1) andalso (Level@1 =< 9) ->
            Level@1;

        _ ->
            8
    end,
    Strategy@2 = case Strategy of
        {some, Strategy@1} ->
            erlang:binary_to_atom(case Strategy@1 of
                    default ->
                        <<"default"/utf8>>;

                    filtered ->
                        <<"filtered"/utf8>>;

                    huffman_only ->
                        <<"huffman_only"/utf8>>;

                    r_l_e ->
                        <<"rle"/utf8>>
                end);

        _ ->
            erlang:binary_to_atom(<<"default"/utf8>>)
    end,
    _pipe = exception_ffi:rescue(
        fun() ->
            zlib:'deflateInit'(
                Stream,
                Compression_level@1,
                deflated,
                Window_bits@1,
                Memory_level@1,
                Strategy@2
            )
        end
    ),
    _pipe@1 = gleam@result:replace(_pipe, nil),
    gleam@result:map_error(
        _pipe@1,
        fun(E) ->
            logging:log(
                error,
                <<"Failed to initialize deflate: "/utf8,
                    (gleam@string:inspect(E))/binary>>
            ),
            nil
        end
    ).
