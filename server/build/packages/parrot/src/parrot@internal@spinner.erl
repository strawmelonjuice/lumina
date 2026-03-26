-module(parrot@internal@spinner).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/parrot/internal/spinner.gleam").
-export([with_frames/2, with_colour/2, set_text/2, set_colour/2, green_checkmark/0, orange_warning/0, complete_and_continue/2, complete_and_continue_current/1, complete/3, complete_current/2, fail/2, stop/1, start/1, with_spinner/2, new/1]).
-export_type([spinner/0, state/0, builder/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-opaque spinner() :: {spinner,
        repeatedly:repeater(state()),
        glearray:array(binary()),
        binary()}.

-type state() :: {state, binary(), fun((binary()) -> binary())}.

-opaque builder() :: {builder,
        list(binary()),
        binary(),
        fun((binary()) -> binary())}.

-file("src/parrot/internal/spinner.gleam", 8).
?DOC(false).
-spec magenta(binary()) -> binary().
magenta(Text) ->
    <<<<"\x{001b}[35m"/utf8, Text/binary>>/binary,
        (<<"\x{001b}[0m"/utf8>>)/binary>>.

-file("src/parrot/internal/spinner.gleam", 12).
?DOC(false).
-spec green(binary()) -> binary().
green(Text) ->
    <<<<"\x{001b}[32m"/utf8, Text/binary>>/binary,
        (<<"\x{001b}[0m"/utf8>>)/binary>>.

-file("src/parrot/internal/spinner.gleam", 60).
?DOC(false).
-spec with_frames(builder(), list(binary())) -> builder().
with_frames(Builder, Frames) ->
    {builder, Frames, erlang:element(3, Builder), erlang:element(4, Builder)}.

-file("src/parrot/internal/spinner.gleam", 64).
?DOC(false).
-spec with_colour(builder(), fun((binary()) -> binary())) -> builder().
with_colour(Builder, Colour) ->
    {builder, erlang:element(2, Builder), erlang:element(3, Builder), Colour}.

-file("src/parrot/internal/spinner.gleam", 87).
?DOC(false).
-spec set_text(spinner(), binary()) -> nil.
set_text(Spinner, Text) ->
    repeatedly_ffi:update_state(
        erlang:element(2, Spinner),
        fun(State) -> {state, Text, erlang:element(3, State)} end
    ).

-file("src/parrot/internal/spinner.gleam", 93).
?DOC(false).
-spec set_colour(spinner(), fun((binary()) -> binary())) -> nil.
set_colour(Spinner, Colour) ->
    repeatedly_ffi:update_state(
        erlang:element(2, Spinner),
        fun(State) -> {state, erlang:element(2, State), Colour} end
    ).

-file("src/parrot/internal/spinner.gleam", 124).
?DOC(false).
-spec green_checkmark() -> binary().
green_checkmark() ->
    Checkmark = <<"✓"/utf8>>,
    green(Checkmark).

-file("src/parrot/internal/spinner.gleam", 129).
?DOC(false).
-spec orange_warning() -> binary().
orange_warning() ->
    Warning = <<"⚠️"/utf8>>,
    magenta(Warning).

-file("src/parrot/internal/spinner.gleam", 204).
?DOC(false).
-spec frame(glearray:array(binary()), integer()) -> binary().
frame(Frames, Index) ->
    Frame@1 = case glearray_ffi:get(Frames, case erlang:tuple_size(Frames) of
            0 -> 0;
            Gleam@denominator -> Index rem Gleam@denominator
        end) of
        {ok, Frame} -> Frame;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"parrot/internal/spinner"/utf8>>,
                        function => <<"frame"/utf8>>,
                        line => 205,
                        value => _assert_fail,
                        start => 5323,
                        'end' => 5399,
                        pattern_start => 5334,
                        pattern_end => 5343})
    end,
    Frame@1.

-file("src/parrot/internal/spinner.gleam", 102).
?DOC(false).
-spec complete_and_continue(spinner(), binary()) -> nil.
complete_and_continue(Spinner, Completed_text) ->
    repeatedly_ffi:stop(erlang:element(2, Spinner)),
    Checkmark = <<"✓"/utf8>>,
    gleam_stdlib:print(
        <<<<<<<<"\x{001b}[2K"/utf8, "\r"/utf8>>/binary,
                    (green(Checkmark))/binary>>/binary,
                " "/utf8>>/binary,
            Completed_text/binary>>
    ),
    gleam_stdlib:print(<<"\n"/utf8>>).

-file("src/parrot/internal/spinner.gleam", 120).
?DOC(false).
-spec complete_and_continue_current(spinner()) -> nil.
complete_and_continue_current(Spinner) ->
    complete_and_continue(Spinner, erlang:element(4, Spinner)).

-file("src/parrot/internal/spinner.gleam", 137).
?DOC(false).
-spec complete(spinner(), binary(), binary()) -> nil.
complete(Spinner, Completed_text, Prefix) ->
    repeatedly_ffi:stop(erlang:element(2, Spinner)),
    Show_cursor = <<"\x{001b}[?25h"/utf8>>,
    gleam_stdlib:print(
        <<<<<<<<<<"\x{001b}[2K"/utf8, "\r"/utf8>>/binary, Prefix/binary>>/binary,
                    " "/utf8>>/binary,
                Completed_text/binary>>/binary,
            Show_cursor/binary>>
    ),
    gleam_stdlib:print(<<"\n"/utf8>>).

-file("src/parrot/internal/spinner.gleam", 154).
?DOC(false).
-spec complete_current(spinner(), binary()) -> nil.
complete_current(Spinner, Prefix) ->
    complete(Spinner, erlang:element(4, Spinner), Prefix),
    gleam_stdlib:print(<<""/utf8>>).

-file("src/parrot/internal/spinner.gleam", 162).
?DOC(false).
-spec fail(spinner(), binary()) -> nil.
fail(Spinner, Failed_text) ->
    repeatedly_ffi:stop(erlang:element(2, Spinner)),
    Error_mark = <<"✗"/utf8>>,
    Red = fun(Text) ->
        <<<<"\x{001b}[31m"/utf8, Text/binary>>/binary,
            (<<"\x{001b}[0m"/utf8>>)/binary>>
    end,
    Show_cursor = <<"\x{001b}[?25h"/utf8>>,
    gleam_stdlib:print(
        <<<<<<<<<<"\x{001b}[2K"/utf8, "\r"/utf8>>/binary,
                        (Red(Error_mark))/binary>>/binary,
                    " "/utf8>>/binary,
                Failed_text/binary>>/binary,
            Show_cursor/binary>>
    ),
    gleam_stdlib:print(<<"\n"/utf8>>).

-file("src/parrot/internal/spinner.gleam", 186).
?DOC(false).
-spec stop(spinner()) -> nil.
stop(Spinner) ->
    repeatedly_ffi:stop(erlang:element(2, Spinner)),
    Show_cursor = <<"\x{001b}[?25h"/utf8>>,
    gleam_stdlib:print(
        <<<<"\x{001b}[2K"/utf8, "\r"/utf8>>/binary, Show_cursor/binary>>
    ).

-file("src/parrot/internal/spinner.gleam", 192).
?DOC(false).
-spec print(glearray:array(binary()), state(), integer()) -> nil.
print(Frames, State, Index) ->
    Hide_cursor = <<"\x{001b}[?25l"/utf8>>,
    gleam_stdlib:print(
        <<<<<<<<<<Hide_cursor/binary, "\x{001b}[2K"/utf8>>/binary, "\r"/utf8>>/binary,
                    ((erlang:element(3, State))(frame(Frames, Index)))/binary>>/binary,
                " "/utf8>>/binary,
            (erlang:element(2, State))/binary>>
    ).

-file("src/parrot/internal/spinner.gleam", 77).
?DOC(false).
-spec start(builder()) -> spinner().
start(Builder) ->
    Frames = erlang:list_to_tuple(erlang:element(2, Builder)),
    Repeater = repeatedly_ffi:call(
        80,
        {state, erlang:element(3, Builder), erlang:element(4, Builder)},
        fun(State, I) ->
            print(Frames, State, I),
            State
        end
    ),
    {spinner, Repeater, Frames, erlang:element(3, Builder)}.

-file("src/parrot/internal/spinner.gleam", 68).
?DOC(false).
-spec with_spinner(builder(), fun((spinner()) -> any())) -> nil.
with_spinner(Builder, Context) ->
    Spinner = start(Builder),
    Context(Spinner),
    stop(Spinner).

-file("src/parrot/internal/spinner.gleam", 56).
?DOC(false).
-spec new(binary()) -> builder().
new(Text) ->
    {builder,
        [<<"⠋"/utf8>>,
            <<"⠙"/utf8>>,
            <<"⠹"/utf8>>,
            <<"⠸"/utf8>>,
            <<"⠼"/utf8>>,
            <<"⠴"/utf8>>,
            <<"⠦"/utf8>>,
            <<"⠧"/utf8>>,
            <<"⠇"/utf8>>,
            <<"⠏"/utf8>>],
        Text,
        fun magenta/1}.
