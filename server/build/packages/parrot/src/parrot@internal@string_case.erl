-module(parrot@internal@string_case).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/parrot/internal/string_case.gleam").
-export([snake_case/1, pascal_case/1]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-file("src/parrot/internal/string_case.gleam", 79).
?DOC(false).
-spec add(list(binary()), binary()) -> list(binary()).
add(Words, Word) ->
    case Word of
        <<""/utf8>> ->
            Words;

        _ ->
            [Word | Words]
    end.

-file("src/parrot/internal/string_case.gleam", 86).
?DOC(false).
-spec is_upper(binary()) -> boolean().
is_upper(G) ->
    string:lowercase(G) /= G.

-file("src/parrot/internal/string_case.gleam", 44).
?DOC(false).
-spec split(list(binary()), boolean(), binary(), list(binary())) -> list(binary()).
split(In, Up, Word, Words) ->
    case In of
        [] when Word =:= <<""/utf8>> ->
            lists:reverse(Words);

        [] ->
            lists:reverse(add(Words, Word));

        [<<"\n"/utf8>> | In@1] ->
            split(In@1, false, <<""/utf8>>, add(Words, Word));

        [<<"\t"/utf8>> | In@1] ->
            split(In@1, false, <<""/utf8>>, add(Words, Word));

        [<<"!"/utf8>> | In@1] ->
            split(In@1, false, <<""/utf8>>, add(Words, Word));

        [<<"?"/utf8>> | In@1] ->
            split(In@1, false, <<""/utf8>>, add(Words, Word));

        [<<"#"/utf8>> | In@1] ->
            split(In@1, false, <<""/utf8>>, add(Words, Word));

        [<<"."/utf8>> | In@1] ->
            split(In@1, false, <<""/utf8>>, add(Words, Word));

        [<<"-"/utf8>> | In@1] ->
            split(In@1, false, <<""/utf8>>, add(Words, Word));

        [<<"_"/utf8>> | In@1] ->
            split(In@1, false, <<""/utf8>>, add(Words, Word));

        [<<" "/utf8>> | In@1] ->
            split(In@1, false, <<""/utf8>>, add(Words, Word));

        [G | In@2] ->
            case is_upper(G) of
                false ->
                    split(In@2, false, <<Word/binary, G/binary>>, Words);

                true when Up ->
                    split(In@2, Up, <<Word/binary, G/binary>>, Words);

                true ->
                    split(In@2, true, G, add(Words, Word))
            end
    end.

-file("src/parrot/internal/string_case.gleam", 38).
?DOC(false).
-spec split_words(binary()) -> list(binary()).
split_words(Text) ->
    _pipe = Text,
    _pipe@1 = gleam@string:to_graphemes(_pipe),
    split(_pipe@1, false, <<""/utf8>>, []).

-file("src/parrot/internal/string_case.gleam", 15).
?DOC(false).
-spec snake_case(binary()) -> binary().
snake_case(Text) ->
    _pipe = Text,
    _pipe@1 = split_words(_pipe),
    _pipe@2 = gleam@string:join(_pipe@1, <<"_"/utf8>>),
    string:lowercase(_pipe@2).

-file("src/parrot/internal/string_case.gleam", 31).
?DOC(false).
-spec pascal_case(binary()) -> binary().
pascal_case(Text) ->
    _pipe = Text,
    _pipe@1 = split_words(_pipe),
    _pipe@2 = gleam@list:map(_pipe@1, fun gleam@string:capitalise/1),
    erlang:list_to_binary(_pipe@2).
