-module(humanise@time).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch]).

-export([to_string/1, as_nanoseconds/1, as_microseconds/1, as_milliseconds/1, as_seconds/1, as_minutes/1, as_hours/1, as_days/1, as_weeks/1, humanise/1, from_duration/1]).
-export_type([time/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " This module contains functions for formatting durations of time to `String`s (e.g. `\"100.0ms\"`, `\"1.5s\"`).\n"
    "\n"
    " Usage generally looks like this:\n"
    " ```\n"
    " time.Millisecond(2000.0) |> time.humanise |> time.to_string // \"2.0s\"\n"
    "\n"
    " // or, if you don't want to change the unit\n"
    " time.Millisecond(2000.0) |> time.to_string // \"2000.0ms\"\n"
    " ```\n"
).

-type time() :: {nanoseconds, float()} |
    {microseconds, float()} |
    {milliseconds, float()} |
    {seconds, float()} |
    {minutes, float()} |
    {hours, float()} |
    {days, float()} |
    {weeks, float()}.

-file("src/humanise/time.gleam", 177).
?DOC(
    " Format a value as a `String`, rounded to at most 2 decimal places, followed by a unit suffix.\n"
    "\n"
    " Example:\n"
    " ```\n"
    " time.Seconds(30.125) |> time.to_string // \"30.13s\"\n"
    " ```\n"
).
-spec to_string(time()) -> binary().
to_string(Time) ->
    {N, Suffix} = case Time of
        {nanoseconds, Ns} ->
            {Ns, <<"ns"/utf8>>};

        {microseconds, Us} ->
            {Us, <<"us"/utf8>>};

        {milliseconds, Ms} ->
            {Ms, <<"ms"/utf8>>};

        {seconds, S} ->
            {S, <<"s"/utf8>>};

        {minutes, M} ->
            {M, <<"m"/utf8>>};

        {hours, H} ->
            {H, <<"h"/utf8>>};

        {days, D} ->
            {D, <<"d"/utf8>>};

        {weeks, W} ->
            {W, <<"w"/utf8>>}
    end,
    humanise@util:format(N, Suffix).

-file("src/humanise/time.gleam", 61).
?DOC(
    " Convert a value to nanoseconds.\n"
    "\n"
    " Example:\n"
    " ```\n"
    " time.Microseconds(1.0) |> time.as_nanoseconds // 1000.0\n"
    " ```\n"
).
-spec as_nanoseconds(time()) -> float().
as_nanoseconds(Time) ->
    case Time of
        {nanoseconds, N} ->
            N;

        {microseconds, N@1} ->
            N@1 * 1000.0;

        {milliseconds, N@2} ->
            N@2 * 1000000.0;

        {seconds, N@3} ->
            N@3 * 1000000000.0;

        {minutes, N@4} ->
            N@4 * 60000000000.0;

        {hours, N@5} ->
            N@5 * 3600000000000.0;

        {days, N@6} ->
            N@6 * 86400000000000.0;

        {weeks, N@7} ->
            N@7 * 604800000000000.0
    end.

-file("src/humanise/time.gleam", 80).
?DOC(
    " Convert a value to microseconds.\n"
    "\n"
    " Example:\n"
    " ```\n"
    " time.Nanoseconds(1000.0) |> time.as_microseconds // 1.0\n"
    " ```\n"
).
-spec as_microseconds(time()) -> float().
as_microseconds(Time) ->
    case 1000.0 of
        +0.0 -> +0.0;
        -0.0 -> -0.0;
        Gleam@denominator -> as_nanoseconds(Time) / Gleam@denominator
    end.

-file("src/humanise/time.gleam", 90).
?DOC(
    " Convert a value to milliseconds.\n"
    "\n"
    " Example:\n"
    " ```\n"
    " time.Microseconds(1000.0) |> time.as_milliseconds // 1.0\n"
    " ```\n"
).
-spec as_milliseconds(time()) -> float().
as_milliseconds(Time) ->
    case 1000000.0 of
        +0.0 -> +0.0;
        -0.0 -> -0.0;
        Gleam@denominator -> as_nanoseconds(Time) / Gleam@denominator
    end.

-file("src/humanise/time.gleam", 100).
?DOC(
    " Convert a value to seconds.\n"
    "\n"
    " Example:\n"
    " ```\n"
    " time.Milliseconds(1000.0) |> time.as_seconds // 1.0\n"
    " ```\n"
).
-spec as_seconds(time()) -> float().
as_seconds(Time) ->
    case 1000000000.0 of
        +0.0 -> +0.0;
        -0.0 -> -0.0;
        Gleam@denominator -> as_nanoseconds(Time) / Gleam@denominator
    end.

-file("src/humanise/time.gleam", 110).
?DOC(
    " Convert a value to minutes.\n"
    "\n"
    " Example:\n"
    " ```\n"
    " time.Seconds(60.0) |> time.as_minutes // 1.0\n"
    " ```\n"
).
-spec as_minutes(time()) -> float().
as_minutes(Time) ->
    case 60000000000.0 of
        +0.0 -> +0.0;
        -0.0 -> -0.0;
        Gleam@denominator -> as_nanoseconds(Time) / Gleam@denominator
    end.

-file("src/humanise/time.gleam", 120).
?DOC(
    " Convert a value to hours.\n"
    "\n"
    " Example:\n"
    " ```\n"
    " time.Minutes(60.0) |> time.as_hours // 1.0\n"
    " ```\n"
).
-spec as_hours(time()) -> float().
as_hours(Time) ->
    case 3600000000000.0 of
        +0.0 -> +0.0;
        -0.0 -> -0.0;
        Gleam@denominator -> as_nanoseconds(Time) / Gleam@denominator
    end.

-file("src/humanise/time.gleam", 130).
?DOC(
    " Convert a value to days.\n"
    "\n"
    " Example:\n"
    " ```\n"
    " time.Hours(24.0) |> time.as_days // 1.0\n"
    " ```\n"
).
-spec as_days(time()) -> float().
as_days(Time) ->
    case 86400000000000.0 of
        +0.0 -> +0.0;
        -0.0 -> -0.0;
        Gleam@denominator -> as_nanoseconds(Time) / Gleam@denominator
    end.

-file("src/humanise/time.gleam", 140).
?DOC(
    " Convert a value to weeks.\n"
    "\n"
    " Example:\n"
    " ```\n"
    " time.Days(7.0) |> time.as_weeks // 1.0\n"
    " ```\n"
).
-spec as_weeks(time()) -> float().
as_weeks(Time) ->
    case 604800000000000.0 of
        +0.0 -> +0.0;
        -0.0 -> -0.0;
        Gleam@denominator -> as_nanoseconds(Time) / Gleam@denominator
    end.

-file("src/humanise/time.gleam", 150).
?DOC(
    " Convert a value to a more optimal unit, if possible.\n"
    "\n"
    " Example:\n"
    " ```\n"
    " time.Seconds(120.0) |> time.humanise // time.Minutes(2.0)\n"
    " ```\n"
).
-spec humanise(time()) -> time().
humanise(Time) ->
    Abs = fun gleam@float:absolute_value/1,
    Ns = as_nanoseconds(Time),
    gleam@bool:guard(
        Abs(Ns) < 1000.0,
        {nanoseconds, Ns},
        fun() ->
            gleam@bool:guard(Abs(Ns) < 1000000.0, {microseconds, case 1000.0 of
                        +0.0 -> +0.0;
                        -0.0 -> -0.0;
                        Gleam@denominator -> Ns / Gleam@denominator
                    end}, fun() ->
                    gleam@bool:guard(
                        Abs(Ns) < 1000000000.0,
                        {milliseconds, case 1000000.0 of
                                +0.0 -> +0.0;
                                -0.0 -> -0.0;
                                Gleam@denominator@1 -> Ns / Gleam@denominator@1
                            end},
                        fun() ->
                            gleam@bool:guard(
                                Abs(Ns) < 60000000000.0,
                                {seconds, case 1000000000.0 of
                                        +0.0 -> +0.0;
                                        -0.0 -> -0.0;
                                        Gleam@denominator@2 -> Ns / Gleam@denominator@2
                                    end},
                                fun() ->
                                    gleam@bool:guard(
                                        Abs(Ns) < 3600000000000.0,
                                        {minutes, case 60000000000.0 of
                                                +0.0 -> +0.0;
                                                -0.0 -> -0.0;
                                                Gleam@denominator@3 -> Ns / Gleam@denominator@3
                                            end},
                                        fun() ->
                                            gleam@bool:guard(
                                                Abs(Ns) < 86400000000000.0,
                                                {hours, case 3600000000000.0 of
                                                        +0.0 -> +0.0;
                                                        -0.0 -> -0.0;
                                                        Gleam@denominator@4 -> Ns
                                                        / Gleam@denominator@4
                                                    end},
                                                fun() ->
                                                    gleam@bool:guard(
                                                        Abs(Ns) < 604800000000000.0,
                                                        {days,
                                                            case 86400000000000.0 of
                                                                +0.0 -> +0.0;
                                                                -0.0 -> -0.0;
                                                                Gleam@denominator@5 -> Ns
                                                                / Gleam@denominator@5
                                                            end},
                                                        fun() ->
                                                            {weeks,
                                                                case 604800000000000.0 of
                                                                    +0.0 -> +0.0;
                                                                    -0.0 -> -0.0;
                                                                    Gleam@denominator@6 -> Ns
                                                                    / Gleam@denominator@6
                                                                end}
                                                        end
                                                    )
                                                end
                                            )
                                        end
                                    )
                                end
                            )
                        end
                    )
                end)
        end
    ).

-file("src/humanise/time.gleam", 51).
?DOC(
    " Convert a Duration from `gleam/time`.\n"
    "\n"
    " Example:\n"
    " ```\n"
    " duration.seconds(120) |> time.from_duration // time.Minutes(2.0)\n"
    " ```\n"
).
-spec from_duration(gleam@time@duration:duration()) -> time().
from_duration(Duration) ->
    _pipe@1 = {seconds,
        begin
            _pipe = Duration,
            gleam@time@duration:to_seconds(_pipe)
        end},
    humanise(_pipe@1).
