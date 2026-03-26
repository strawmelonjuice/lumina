-module(parrot@internal@lib).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/parrot/internal/lib.gleam").
-export([try_nil/2, walk/1, green/1, red/1, yellow/1]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-file("src/parrot/internal/lib.gleam", 13).
?DOC(false).
-spec try_nil(
    {ok, ABFC} | {error, any()},
    fun((ABFC) -> {ok, ABFG} | {error, nil})
) -> {ok, ABFG} | {error, nil}.
try_nil(Result, Do) ->
    gleam@result:'try'(gleam@result:replace_error(Result, nil), Do).

-file("src/parrot/internal/lib.gleam", 24).
?DOC(false).
-spec walk(binary()) -> gleam@dict:dict(binary(), list(binary())).
walk(From) ->
    case filepath:base_name(From) of
        <<"sql"/utf8>> ->
            Files@1 = case simplifile_erl:read_directory(From) of
                {ok, Files} -> Files;
                _assert_fail ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"parrot/internal/lib"/utf8>>,
                                function => <<"walk"/utf8>>,
                                line => 27,
                                value => _assert_fail,
                                start => 653,
                                'end' => 707,
                                pattern_start => 664,
                                pattern_end => 673})
            end,
            Files@2 = begin
                gleam@list:filter_map(
                    Files@1,
                    fun(File) ->
                        gleam@result:'try'(
                            filepath:extension(File),
                            fun(Extension) ->
                                gleam@bool:guard(
                                    Extension /= <<"sql"/utf8>>,
                                    {error, nil},
                                    fun() ->
                                        File_name = filepath:join(From, File),
                                        case simplifile_erl:is_file(File_name) of
                                            {ok, true} ->
                                                {ok, File_name};

                                            {ok, false} ->
                                                {error, nil};

                                            {error, _} ->
                                                {error, nil}
                                        end
                                    end
                                )
                            end
                        )
                    end
                )
            end,
            maps:from_list([{From, Files@2}]);

        _ ->
            Files@4 = case simplifile_erl:read_directory(From) of
                {ok, Files@3} -> Files@3;
                _assert_fail@1 ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"parrot/internal/lib"/utf8>>,
                                function => <<"walk"/utf8>>,
                                line => 42,
                                value => _assert_fail@1,
                                start => 1162,
                                'end' => 1216,
                                pattern_start => 1173,
                                pattern_end => 1182})
            end,
            Directories = begin
                gleam@list:filter_map(
                    Files@4,
                    fun(File@1) ->
                        File_name@1 = filepath:join(From, File@1),
                        case simplifile_erl:is_directory(File_name@1) of
                            {ok, true} ->
                                {ok, File_name@1};

                            {ok, false} ->
                                {error, nil};

                            {error, _} ->
                                {error, nil}
                        end
                    end
                )
            end,
            _pipe = gleam@list:map(Directories, fun walk/1),
            gleam@list:fold(_pipe, maps:new(), fun maps:merge/2)
    end.

-file("src/parrot/internal/lib.gleam", 58).
?DOC(false).
-spec green(binary()) -> binary().
green(Text) ->
    <<<<"\x{001b}[32m"/utf8, Text/binary>>/binary, "\x{001b}[0m"/utf8>>.

-file("src/parrot/internal/lib.gleam", 62).
?DOC(false).
-spec red(binary()) -> binary().
red(Text) ->
    <<<<"\x{001b}[31m"/utf8, Text/binary>>/binary, "\x{001b}[0m"/utf8>>.

-file("src/parrot/internal/lib.gleam", 66).
?DOC(false).
-spec yellow(binary()) -> binary().
yellow(Text) ->
    <<<<"\x{001b}[33m"/utf8, Text/binary>>/binary, "\x{001b}[0m"/utf8>>.
