-module(humanise).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/humanise.gleam").
-export([date_relative/2, date/2, duration/1, nanoseconds_float/1, nanoseconds_int/1, microseconds_float/1, microseconds_int/1, milliseconds_float/1, milliseconds_int/1, seconds_float/1, seconds_int/1, hours_float/1, hours_int/1, days_float/1, days_int/1, weeks_float/1, weeks_int/1, bytes_float/1, bytes_int/1, kilobytes_float/1, kilobytes_int/1, megabytes_float/1, megabytes_int/1, gigabytes_float/1, gigabytes_int/1, terabytes_float/1, terabytes_int/1, kibibytes_float/1, kibibytes_int/1, mebibytes_float/1, mebibytes_int/1, gibibytes_float/1, gibibytes_int/1, tebibytes_float/1, tebibytes_int/1]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " This module contains a bunch of shortcuts to the `time`, `bytes` and 'bytes1024' modules for directly \"humanising\" and formatting a number (`Float` or `Int`) to a `String`.\n"
    "\n"
    " For more control (e.g. work with `time.Time` or `bytes.Bytes` directly, use the given unit instead of the most optimal one), look at the `time`, `bytes` or `bytes1024` modules.\n"
).

-file("src/humanise.gleam", 18).
?DOC(
    " Format a `Timestamp` relative to the provided current `Timestamp`.\n"
    "\n"
    " This function finds the difference between the current time and the given time, and returns a string describing the difference. (e.g. \"in 2.0s\", \"3.5d ago\")\n"
).
-spec date_relative(
    gleam@time@timestamp:timestamp(),
    gleam@time@timestamp:timestamp()
) -> binary().
date_relative(Date, Current) ->
    Relative = begin
        _pipe = Current,
        _pipe@1 = gleam@time@timestamp:difference(_pipe, Date),
        humanise@time:from_duration(_pipe@1)
    end,
    Decompose = fun(A) -> case A of
            {nanoseconds, N} ->
                {fun(Field@0) -> {nanoseconds, Field@0} end, N};

            {days, N@1} ->
                {fun(Field@0) -> {days, Field@0} end, N@1};

            {hours, N@2} ->
                {fun(Field@0) -> {hours, Field@0} end, N@2};

            {microseconds, N@3} ->
                {fun(Field@0) -> {microseconds, Field@0} end, N@3};

            {milliseconds, N@4} ->
                {fun(Field@0) -> {milliseconds, Field@0} end, N@4};

            {minutes, N@5} ->
                {fun(Field@0) -> {minutes, Field@0} end, N@5};

            {seconds, N@6} ->
                {fun(Field@0) -> {seconds, Field@0} end, N@6};

            {weeks, N@7} ->
                {fun(Field@0) -> {weeks, Field@0} end, N@7}
        end end,
    {Constructor, N@8} = Decompose(Relative),
    case N@8 >= +0.0 of
        true ->
            <<"in "/utf8, (humanise@time:to_string(Relative))/binary>>;

        false ->
            <<(humanise@time:to_string(
                    Constructor(gleam@float:absolute_value(N@8))
                ))/binary,
                " ago"/utf8>>
    end.

-file("src/humanise.gleam", 51).
?DOC(
    " Format a `Date`, `TimeOfDay` pair, automatically omitting redundant information (omit year if it matches the current year, omit month and day if it also matches the current day)\n"
    "\n"
    " The given date will be compared against the provided \"current\" date to determine what information to omit.\n"
    "\n"
    " This function does not currently support internationalization, and simply returns a string in the following largest-to-smallest format:\n"
    " ```\n"
    " <maybe year> <maybe <month> <day>> <hours>:<minutes>:<seconds>\n"
    " ```\n"
    " Note that hours are in 24 hour format, not 12 hours with AM/PM.\n"
).
-spec date(
    {gleam@time@calendar:date(), gleam@time@calendar:time_of_day()},
    gleam@time@calendar:date()
) -> binary().
date(Date, Current) ->
    Year_matches = case {Current, erlang:element(1, Date)} of
        {{date, Current@1, _, _}, {date, Given, _, _}} when Current@1 =:= Given ->
            true;

        {_, _} ->
            false
    end,
    Day_matches = case {Current, erlang:element(1, Date)} of
        {{date, _, _, Current@2}, {date, _, _, Given@1}} when Current@2 =:= Given@1 ->
            true;

        {_, _} ->
            false
    end,
    {date, Year, Month, Day} = erlang:element(1, Date),
    {time_of_day, Hours, Minutes, Seconds, _} = erlang:element(2, Date),
    Maybe_year = case Year_matches of
        true ->
            <<""/utf8>>;

        false ->
            <<(erlang:integer_to_binary(Year))/binary, " "/utf8>>
    end,
    Maybe_month = case {Year_matches andalso Day_matches, Month} of
        {true, _} ->
            <<""/utf8>>;

        {_, april} ->
            <<"April "/utf8>>;

        {_, august} ->
            <<"August "/utf8>>;

        {_, december} ->
            <<"December "/utf8>>;

        {_, february} ->
            <<"February "/utf8>>;

        {_, january} ->
            <<"January "/utf8>>;

        {_, july} ->
            <<"July "/utf8>>;

        {_, june} ->
            <<"June "/utf8>>;

        {_, march} ->
            <<"March "/utf8>>;

        {_, may} ->
            <<"May "/utf8>>;

        {_, november} ->
            <<"November "/utf8>>;

        {_, october} ->
            <<"October "/utf8>>;

        {_, september} ->
            <<"September "/utf8>>
    end,
    Maybe_day = case Year_matches andalso Day_matches of
        true ->
            <<""/utf8>>;

        false ->
            <<(erlang:integer_to_binary(Day))/binary, " "/utf8>>
    end,
    Hours@1 = case Hours < 10 of
        true ->
            <<"0"/utf8, (erlang:integer_to_binary(Hours))/binary>>;

        false ->
            erlang:integer_to_binary(Hours)
    end,
    Minutes@1 = case Minutes < 10 of
        true ->
            <<"0"/utf8, (erlang:integer_to_binary(Minutes))/binary>>;

        false ->
            erlang:integer_to_binary(Minutes)
    end,
    Seconds@1 = case Seconds < 10 of
        true ->
            <<"0"/utf8, (erlang:integer_to_binary(Seconds))/binary>>;

        false ->
            erlang:integer_to_binary(Seconds)
    end,
    <<<<<<<<<<<<<<Maybe_year/binary, Maybe_month/binary>>/binary,
                            Maybe_day/binary>>/binary,
                        Hours@1/binary>>/binary,
                    ":"/utf8>>/binary,
                Minutes@1/binary>>/binary,
            ":"/utf8>>/binary,
        Seconds@1/binary>>.

-file("src/humanise.gleam", 113).
?DOC(" Format a `Duration`, using the most optimal unit.\n").
-spec duration(gleam@time@duration:duration()) -> binary().
duration(Duration) ->
    _pipe = humanise@time:from_duration(Duration),
    humanise@time:to_string(_pipe).

-file("src/humanise.gleam", 118).
?DOC(" Format *n* nanoseconds as a `Float`, converting to a more optimal unit if possible.\n").
-spec nanoseconds_float(float()) -> binary().
nanoseconds_float(N) ->
    _pipe = {nanoseconds, N},
    _pipe@1 = humanise@time:humanise(_pipe),
    humanise@time:to_string(_pipe@1).

-file("src/humanise.gleam", 123).
?DOC(" Format *n* nanoseconds as a `Float`, converting to a more optimal unit if possible.\n").
-spec nanoseconds_int(integer()) -> binary().
nanoseconds_int(N) ->
    _pipe = {nanoseconds, erlang:float(N)},
    _pipe@1 = humanise@time:humanise(_pipe),
    humanise@time:to_string(_pipe@1).

-file("src/humanise.gleam", 128).
?DOC(" Format *n* microseconds as a `Float`, converting to a more optimal unit if possible.\n").
-spec microseconds_float(float()) -> binary().
microseconds_float(N) ->
    _pipe = {microseconds, N},
    _pipe@1 = humanise@time:humanise(_pipe),
    humanise@time:to_string(_pipe@1).

-file("src/humanise.gleam", 133).
?DOC(" Format *n* microseconds as an `Int`, converting to a more optimal unit if possible.\n").
-spec microseconds_int(integer()) -> binary().
microseconds_int(N) ->
    _pipe = {microseconds, erlang:float(N)},
    _pipe@1 = humanise@time:humanise(_pipe),
    humanise@time:to_string(_pipe@1).

-file("src/humanise.gleam", 138).
?DOC(" Format *n* milliseconds as a `Float`, converting to a more optimal unit if possible.\n").
-spec milliseconds_float(float()) -> binary().
milliseconds_float(N) ->
    _pipe = {milliseconds, N},
    _pipe@1 = humanise@time:humanise(_pipe),
    humanise@time:to_string(_pipe@1).

-file("src/humanise.gleam", 143).
?DOC(" Format *n* milliseconds as an `Int`, converting to a more optimal unit if possible.\n").
-spec milliseconds_int(integer()) -> binary().
milliseconds_int(N) ->
    _pipe = {milliseconds, erlang:float(N)},
    _pipe@1 = humanise@time:humanise(_pipe),
    humanise@time:to_string(_pipe@1).

-file("src/humanise.gleam", 148).
?DOC(" Format *n* seconds as a `Float`, converting to a more optimal unit if possible.\n").
-spec seconds_float(float()) -> binary().
seconds_float(N) ->
    _pipe = {seconds, N},
    _pipe@1 = humanise@time:humanise(_pipe),
    humanise@time:to_string(_pipe@1).

-file("src/humanise.gleam", 153).
?DOC(" Format *n* seconds as an `Int`, converting to a more optimal unit if possible.\n").
-spec seconds_int(integer()) -> binary().
seconds_int(N) ->
    _pipe = {seconds, erlang:float(N)},
    _pipe@1 = humanise@time:humanise(_pipe),
    humanise@time:to_string(_pipe@1).

-file("src/humanise.gleam", 158).
?DOC(" Format *n* hours as a `Float`, converting to a more optimal unit if possible.\n").
-spec hours_float(float()) -> binary().
hours_float(N) ->
    _pipe = {hours, N},
    _pipe@1 = humanise@time:humanise(_pipe),
    humanise@time:to_string(_pipe@1).

-file("src/humanise.gleam", 163).
?DOC(" Format *n* hours as an `Int`, converting to a more optimal unit if possible.\n").
-spec hours_int(integer()) -> binary().
hours_int(N) ->
    _pipe = {hours, erlang:float(N)},
    _pipe@1 = humanise@time:humanise(_pipe),
    humanise@time:to_string(_pipe@1).

-file("src/humanise.gleam", 168).
?DOC(" Format *n* days as a `Float`, converting to a more optimal unit if possible.\n").
-spec days_float(float()) -> binary().
days_float(N) ->
    _pipe = {days, N},
    _pipe@1 = humanise@time:humanise(_pipe),
    humanise@time:to_string(_pipe@1).

-file("src/humanise.gleam", 173).
?DOC(" Format *n* days as an `Int`, converting to a more optimal unit if possible.\n").
-spec days_int(integer()) -> binary().
days_int(N) ->
    _pipe = {days, erlang:float(N)},
    _pipe@1 = humanise@time:humanise(_pipe),
    humanise@time:to_string(_pipe@1).

-file("src/humanise.gleam", 178).
?DOC(" Format *n* weeks as a `Float`, converting to a more optimal unit if possible.\n").
-spec weeks_float(float()) -> binary().
weeks_float(N) ->
    _pipe = {weeks, N},
    _pipe@1 = humanise@time:humanise(_pipe),
    humanise@time:to_string(_pipe@1).

-file("src/humanise.gleam", 183).
?DOC(" Format *n* weeks as an `Int`, converting to a more optimal unit if possible.\n").
-spec weeks_int(integer()) -> binary().
weeks_int(N) ->
    _pipe = {weeks, erlang:float(N)},
    _pipe@1 = humanise@time:humanise(_pipe),
    humanise@time:to_string(_pipe@1).

-file("src/humanise.gleam", 188).
?DOC(" Format *n* bytes as a `Float`, converting to a more optimal unit if possible.\n").
-spec bytes_float(float()) -> binary().
bytes_float(N) ->
    _pipe = {bytes, N},
    _pipe@1 = humanise@bytes:humanise(_pipe),
    humanise@bytes:to_string(_pipe@1).

-file("src/humanise.gleam", 193).
?DOC(" Format *n* bytes as an `Int`, converting to a more optimal unit if possible.\n").
-spec bytes_int(integer()) -> binary().
bytes_int(N) ->
    _pipe = {bytes, erlang:float(N)},
    _pipe@1 = humanise@bytes:humanise(_pipe),
    humanise@bytes:to_string(_pipe@1).

-file("src/humanise.gleam", 198).
?DOC(" Format *n* kilobytes as a `Float`, converting to a more optimal unit if possible.\n").
-spec kilobytes_float(float()) -> binary().
kilobytes_float(N) ->
    _pipe = {kilobytes, N},
    _pipe@1 = humanise@bytes:humanise(_pipe),
    humanise@bytes:to_string(_pipe@1).

-file("src/humanise.gleam", 203).
?DOC(" Format *n* kilobytes as an `Int`, converting to a more optimal unit if possible.\n").
-spec kilobytes_int(integer()) -> binary().
kilobytes_int(N) ->
    _pipe = {kilobytes, erlang:float(N)},
    _pipe@1 = humanise@bytes:humanise(_pipe),
    humanise@bytes:to_string(_pipe@1).

-file("src/humanise.gleam", 208).
?DOC(" Format *n* megabytes as a `Float`, converting to a more optimal unit if possible.\n").
-spec megabytes_float(float()) -> binary().
megabytes_float(N) ->
    _pipe = {megabytes, N},
    _pipe@1 = humanise@bytes:humanise(_pipe),
    humanise@bytes:to_string(_pipe@1).

-file("src/humanise.gleam", 213).
?DOC(" Format *n* megabytes as an `Int`, converting to a more optimal unit if possible.\n").
-spec megabytes_int(integer()) -> binary().
megabytes_int(N) ->
    _pipe = {megabytes, erlang:float(N)},
    _pipe@1 = humanise@bytes:humanise(_pipe),
    humanise@bytes:to_string(_pipe@1).

-file("src/humanise.gleam", 218).
?DOC(" Format *n* gigabytes as a `Float`, converting to a more optimal unit if possible.\n").
-spec gigabytes_float(float()) -> binary().
gigabytes_float(N) ->
    _pipe = {gigabytes, N},
    _pipe@1 = humanise@bytes:humanise(_pipe),
    humanise@bytes:to_string(_pipe@1).

-file("src/humanise.gleam", 223).
?DOC(" Format *n* gigabytes as an `Int`, converting to a more optimal unit if possible.\n").
-spec gigabytes_int(integer()) -> binary().
gigabytes_int(N) ->
    _pipe = {gigabytes, erlang:float(N)},
    _pipe@1 = humanise@bytes:humanise(_pipe),
    humanise@bytes:to_string(_pipe@1).

-file("src/humanise.gleam", 228).
?DOC(" Format *n* terabytes as a `Float`, converting to a more optimal unit if possible.\n").
-spec terabytes_float(float()) -> binary().
terabytes_float(N) ->
    _pipe = {terabytes, N},
    _pipe@1 = humanise@bytes:humanise(_pipe),
    humanise@bytes:to_string(_pipe@1).

-file("src/humanise.gleam", 233).
?DOC(" Format *n* terabytes as an `Int`, converting to a more optimal unit if possible.\n").
-spec terabytes_int(integer()) -> binary().
terabytes_int(N) ->
    _pipe = {terabytes, erlang:float(N)},
    _pipe@1 = humanise@bytes:humanise(_pipe),
    humanise@bytes:to_string(_pipe@1).

-file("src/humanise.gleam", 238).
?DOC(" Format *n* kibibytes as a `Float`, converting to a more optimal unit if possible.\n").
-spec kibibytes_float(float()) -> binary().
kibibytes_float(N) ->
    _pipe = {kibibytes, N},
    _pipe@1 = humanise@bytes1024:humanise(_pipe),
    humanise@bytes1024:to_string(_pipe@1).

-file("src/humanise.gleam", 245).
?DOC(" Format *n* kibibytes as an `Int`, converting to a more optimal unit if possible.\n").
-spec kibibytes_int(integer()) -> binary().
kibibytes_int(N) ->
    _pipe = {kibibytes, erlang:float(N)},
    _pipe@1 = humanise@bytes1024:humanise(_pipe),
    humanise@bytes1024:to_string(_pipe@1).

-file("src/humanise.gleam", 252).
?DOC(" Format *n* mebibytes as a `Float`, converting to a more optimal unit if possible.\n").
-spec mebibytes_float(float()) -> binary().
mebibytes_float(N) ->
    _pipe = {mebibytes, N},
    _pipe@1 = humanise@bytes1024:humanise(_pipe),
    humanise@bytes1024:to_string(_pipe@1).

-file("src/humanise.gleam", 259).
?DOC(" Format *n* mebibytes as an `Int`, converting to a more optimal unit if possible.\n").
-spec mebibytes_int(integer()) -> binary().
mebibytes_int(N) ->
    _pipe = {mebibytes, erlang:float(N)},
    _pipe@1 = humanise@bytes1024:humanise(_pipe),
    humanise@bytes1024:to_string(_pipe@1).

-file("src/humanise.gleam", 266).
?DOC(" Format *n* gibibytes as a `Float`, converting to a more optimal unit if possible.\n").
-spec gibibytes_float(float()) -> binary().
gibibytes_float(N) ->
    _pipe = {gibibytes, N},
    _pipe@1 = humanise@bytes1024:humanise(_pipe),
    humanise@bytes1024:to_string(_pipe@1).

-file("src/humanise.gleam", 273).
?DOC(" Format *n* gibibytes as an `Int`, converting to a more optimal unit if possible.\n").
-spec gibibytes_int(integer()) -> binary().
gibibytes_int(N) ->
    _pipe = {gibibytes, erlang:float(N)},
    _pipe@1 = humanise@bytes1024:humanise(_pipe),
    humanise@bytes1024:to_string(_pipe@1).

-file("src/humanise.gleam", 280).
?DOC(" Format *n* tebibytes as a `Float`, converting to a more optimal unit if possible.\n").
-spec tebibytes_float(float()) -> binary().
tebibytes_float(N) ->
    _pipe = {tebibytes, N},
    _pipe@1 = humanise@bytes1024:humanise(_pipe),
    humanise@bytes1024:to_string(_pipe@1).

-file("src/humanise.gleam", 287).
?DOC(" Format *n* tebibytes as an `Int`, converting to a more optimal unit if possible.\n").
-spec tebibytes_int(integer()) -> binary().
tebibytes_int(N) ->
    _pipe = {tebibytes, erlang:float(N)},
    _pipe@1 = humanise@bytes1024:humanise(_pipe),
    humanise@bytes1024:to_string(_pipe@1).
