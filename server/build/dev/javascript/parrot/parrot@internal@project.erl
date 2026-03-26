-module(parrot@internal@project).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/parrot/internal/project.gleam").
-export([root/0, src/0, project_name/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-file("src/parrot/internal/project.gleam", 28).
?DOC(false).
-spec find_root(binary()) -> binary().
find_root(Path) ->
    Toml = filepath:join(Path, <<"gleam.toml"/utf8>>),
    case simplifile_erl:is_file(Toml) of
        {ok, false} ->
            find_root(filepath:join(<<".."/utf8>>, Path));

        {error, _} ->
            find_root(filepath:join(<<".."/utf8>>, Path));

        {ok, true} ->
            Path
    end.

-file("src/parrot/internal/project.gleam", 9).
?DOC(false).
-spec root() -> binary().
root() ->
    find_root(<<"."/utf8>>).

-file("src/parrot/internal/project.gleam", 13).
?DOC(false).
-spec src() -> binary().
src() ->
    filepath:join(root(), <<"src"/utf8>>).

-file("src/parrot/internal/project.gleam", 17).
?DOC(false).
-spec project_name() -> binary().
project_name() ->
    Root = find_root(<<"."/utf8>>),
    Toml_path = filepath:join(Root, <<"gleam.toml"/utf8>>),
    Toml@1 = case simplifile:read(Toml_path) of
        {ok, Toml} -> Toml;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"parrot/internal/project"/utf8>>,
                        function => <<"project_name"/utf8>>,
                        line => 20,
                        value => _assert_fail,
                        start => 441,
                        'end' => 489,
                        pattern_start => 452,
                        pattern_end => 460})
    end,
    Parsed@1 = case tom:parse(Toml@1) of
        {ok, Parsed} -> Parsed;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"parrot/internal/project"/utf8>>,
                        function => <<"project_name"/utf8>>,
                        line => 22,
                        value => _assert_fail@1,
                        start => 493,
                        'end' => 532,
                        pattern_start => 504,
                        pattern_end => 514})
    end,
    Name@1 = case tom:get_string(Parsed@1, [<<"name"/utf8>>]) of
        {ok, Name} -> Name;
        _assert_fail@2 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"parrot/internal/project"/utf8>>,
                        function => <<"project_name"/utf8>>,
                        line => 23,
                        value => _assert_fail@2,
                        start => 535,
                        'end' => 589,
                        pattern_start => 546,
                        pattern_end => 554})
    end,
    Name@1.
