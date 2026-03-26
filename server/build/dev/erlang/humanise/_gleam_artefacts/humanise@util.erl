-module(humanise@util).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/humanise/util.gleam").
-export([round_to/2, format/2]).

-file("src/humanise/util.gleam", 4).
-spec round_to(float(), integer()) -> float().
round_to(N, Places) ->
    Places@2 = case begin
        _pipe = erlang:float(gleam@int:max(1, Places)),
        gleam@float:power(10.0, _pipe)
    end of
        {ok, Places@1} -> Places@1;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"humanise/util"/utf8>>,
                        function => <<"round_to"/utf8>>,
                        line => 5,
                        value => _assert_fail,
                        start => 97,
                        'end' => 181,
                        pattern_start => 108,
                        pattern_end => 118})
    end,
    case Places@2 of
        +0.0 -> +0.0;
        -0.0 -> -0.0;
        Gleam@denominator -> begin
            _pipe@1 = erlang:round(N * Places@2),
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
