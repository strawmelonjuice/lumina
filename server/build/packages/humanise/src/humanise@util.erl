-module(humanise@util).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch]).

-export([round_to/2, format/2]).

-file("src/humanise/util.gleam", 4).
-spec round_to(float(), integer()) -> float().
round_to(N, Places) ->
    _assert_subject = begin
        _pipe = erlang:float(gleam@int:max(1, Places)),
        gleam@float:power(10.0, _pipe)
    end,
    {ok, Places@1} = case _assert_subject of
        {ok, _} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        value => _assert_fail,
                        module => <<"humanise/util"/utf8>>,
                        function => <<"round_to"/utf8>>,
                        line => 5})
    end,
    case Places@1 of
        +0.0 -> +0.0;
        -0.0 -> -0.0;
        Gleam@denominator -> begin
            _pipe@1 = erlang:round(N * Places@1),
            erlang:float(_pipe@1)
        end
        / Gleam@denominator
    end.

-file("src/humanise/util.gleam", 11).
-spec format(float(), binary()) -> binary().
format(N, Suffix) ->
    <<(begin
            _pipe = N,
            _pipe@1 = round_to(_pipe, 2),
            gleam_stdlib:float_to_string(_pipe@1)
        end)/binary,
        Suffix/binary>>.
