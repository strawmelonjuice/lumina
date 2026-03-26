-module(compresso).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/compresso.gleam").
-export([gzip/1, gzip_yielder/1, gunzip/1]).
-export_type([yielder_acc/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

-type yielder_acc() :: {yielder_acc,
        compresso@compression:stream(),
        gleam@yielder:yielder(bitstring()),
        boolean()}.

-file("src/compresso.gleam", 7).
?DOC(" Compresses the given data using gzip.\n").
-spec gzip(bitstring()) -> bitstring().
gzip(Data) ->
    zlib:gzip(Data).

-file("src/compresso.gleam", 47).
-spec deflate_until_not_empty(yielder_acc()) -> {bitstring(), yielder_acc()}.
deflate_until_not_empty(Acc) ->
    case gleam@yielder:step(erlang:element(3, Acc)) of
        done ->
            Last_chunk = begin
                _pipe = zlib:deflate(erlang:element(2, Acc), <<>>, finish),
                gleam_stdlib:bit_array_concat(_pipe)
            end,
            case compresso@compression:end_deflate(erlang:element(2, Acc)) of
                {ok, nil} -> nil;
                _assert_fail ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"compresso"/utf8>>,
                                function => <<"deflate_until_not_empty"/utf8>>,
                                line => 54,
                                value => _assert_fail,
                                start => 1311,
                                'end' => 1367,
                                pattern_start => 1322,
                                pattern_end => 1329})
            end,
            compresso@compression:close_stream(erlang:element(2, Acc)),
            {Last_chunk,
                {yielder_acc,
                    erlang:element(2, Acc),
                    erlang:element(3, Acc),
                    true}};

        {next, Data, Rest} ->
            Compressed = zlib:deflate(erlang:element(2, Acc), Data, none),
            case Compressed of
                [] ->
                    deflate_until_not_empty(
                        {yielder_acc,
                            erlang:element(2, Acc),
                            Rest,
                            erlang:element(4, Acc)}
                    );

                Compressed@1 ->
                    {gleam_stdlib:bit_array_concat(Compressed@1),
                        {yielder_acc,
                            erlang:element(2, Acc),
                            Rest,
                            erlang:element(4, Acc)}}
            end
    end.

-file("src/compresso.gleam", 20).
?DOC(" Lazily compresses data using gzip.\n").
-spec gzip_yielder(gleam@yielder:yielder(bitstring())) -> gleam@yielder:yielder(bitstring()).
gzip_yielder(Uncompressed) ->
    Stream = compresso@compression:init_stream(),
    case compresso@compression:init_deflate(
        Stream,
        {some, 6},
        {some, 15 + 16},
        none,
        none
    ) of
        {ok, nil} -> nil;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"compresso"/utf8>>,
                        function => <<"gzip_yielder"/utf8>>,
                        line => 25,
                        value => _assert_fail,
                        start => 531,
                        'end' => 747,
                        pattern_start => 542,
                        pattern_end => 549})
    end,
    Acc = {yielder_acc, Stream, Uncompressed, false},
    gleam@yielder:unfold(Acc, fun(Acc@1) -> case erlang:element(4, Acc@1) of
                true ->
                    done;

                false ->
                    {Compressed, Acc@2} = deflate_until_not_empty(Acc@1),
                    {next, Compressed, Acc@2}
            end end).

-file("src/compresso.gleam", 73).
?DOC(" Decompresses the given data using gzip.\n").
-spec gunzip(bitstring()) -> bitstring().
gunzip(Data) ->
    zlib:gunzip(Data).
