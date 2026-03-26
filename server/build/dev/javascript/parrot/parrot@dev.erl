-module(parrot@dev).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/parrot/dev.gleam").
-export([bool_decoder/0, calendar_date_decoder/0, datetime_decoder/0]).
-export_type([param/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

-type param() :: {param_int, integer()} |
    {param_string, binary()} |
    {param_float, float()} |
    {param_bool, boolean()} |
    {param_bit_array, bitstring()} |
    {param_timestamp, gleam@time@timestamp:timestamp()} |
    {param_date, gleam@time@calendar:date()} |
    {param_list, list(param())} |
    {param_dynamic, gleam@dynamic:dynamic_()} |
    {param_nullable, gleam@option:option(param())}.

-file("src/parrot/dev.gleam", 20).
-spec bool_decoder() -> gleam@dynamic@decode:decoder(boolean()).
bool_decoder() ->
    Int_to_bool = begin
        _pipe = {decoder, fun gleam@dynamic@decode:decode_int/1},
        gleam@dynamic@decode:then(_pipe, fun(V) -> case V of
                    0 ->
                        gleam@dynamic@decode:success(false);

                    1 ->
                        gleam@dynamic@decode:success(true);

                    _ ->
                        gleam@dynamic@decode:failure(
                            false,
                            <<"could not decode int to boolean"/utf8>>
                        )
                end end)
    end,
    gleam@dynamic@decode:one_of(
        {decoder, fun gleam@dynamic@decode:decode_bool/1},
        [Int_to_bool]
    ).

-file("src/parrot/dev.gleam", 42).
?DOC(" https://github.com/lpil/pog/blob/v4.1.0/src/pog.gleam#L394\n").
-spec timestamp_decoder() -> gleam@dynamic@decode:decoder(gleam@time@timestamp:timestamp()).
timestamp_decoder() ->
    gleam@dynamic@decode:map(
        {decoder, fun gleam@dynamic@decode:decode_int/1},
        fun(Microseconds) ->
            Seconds = Microseconds div 1000000,
            Nanoseconds = (Microseconds rem 1000000) * 1000,
            gleam@time@timestamp:from_unix_seconds_and_nanoseconds(
                Seconds,
                Nanoseconds
            )
        end
    ).

-file("src/parrot/dev.gleam", 50).
?DOC(" https://github.com/lpil/pog/blob/v4.1.0/src/pog.gleam#L873\n").
-spec calendar_date_decoder() -> gleam@dynamic@decode:decoder(gleam@time@calendar:date()).
calendar_date_decoder() ->
    gleam@dynamic@decode:field(
        0,
        {decoder, fun gleam@dynamic@decode:decode_int/1},
        fun(Year) ->
            gleam@dynamic@decode:field(
                1,
                {decoder, fun gleam@dynamic@decode:decode_int/1},
                fun(Month) ->
                    gleam@dynamic@decode:field(
                        2,
                        {decoder, fun gleam@dynamic@decode:decode_int/1},
                        fun(Day) ->
                            case gleam@time@calendar:month_from_int(Month) of
                                {ok, Month@1} ->
                                    gleam@dynamic@decode:success(
                                        {date, Year, Month@1, Day}
                                    );

                                {error, _} ->
                                    gleam@dynamic@decode:failure(
                                        {date, 0, january, 1},
                                        <<"Calendar date"/utf8>>
                                    )
                            end
                        end
                    )
                end
            )
        end
    ).

-file("src/parrot/dev.gleam", 61).
-spec datetime_string_decoder() -> gleam@dynamic@decode:decoder(gleam@time@timestamp:timestamp()).
datetime_string_decoder() ->
    _pipe = {decoder, fun gleam@dynamic@decode:decode_string/1},
    gleam@dynamic@decode:then(
        _pipe,
        fun(Datetime_str) ->
            case gleam@time@timestamp:parse_rfc3339(Datetime_str) of
                {ok, Ts} ->
                    gleam@dynamic@decode:success(Ts);

                {error, _} ->
                    gleam@dynamic@decode:failure(
                        gleam@time@timestamp:from_unix_seconds(0),
                        <<"Invalid datetime format"/utf8>>
                    )
            end
        end
    ).

-file("src/parrot/dev.gleam", 83).
-spec date_decoder() -> gleam@dynamic@decode:decoder(gleam@time@calendar:date()).
date_decoder() ->
    gleam@dynamic@decode:field(
        0,
        {decoder, fun gleam@dynamic@decode:decode_int/1},
        fun(Year) ->
            gleam@dynamic@decode:field(
                1,
                begin
                    _pipe = {decoder, fun gleam@dynamic@decode:decode_int/1},
                    gleam@dynamic@decode:then(
                        _pipe,
                        fun(Month) ->
                            case gleam@time@calendar:month_from_int(Month) of
                                {error, _} ->
                                    gleam@dynamic@decode:failure(
                                        january,
                                        <<"Month"/utf8>>
                                    );

                                {ok, Month@1} ->
                                    gleam@dynamic@decode:success(Month@1)
                            end
                        end
                    )
                end,
                fun(Month@2) ->
                    gleam@dynamic@decode:field(
                        2,
                        {decoder, fun gleam@dynamic@decode:decode_int/1},
                        fun(Day) ->
                            gleam@dynamic@decode:success(
                                {date, Year, Month@2, Day}
                            )
                        end
                    )
                end
            )
        end
    ).

-file("src/parrot/dev.gleam", 109).
-spec seconds_decoder() -> gleam@dynamic@decode:decoder({integer(), integer()}).
seconds_decoder() ->
    Int = begin
        _pipe = {decoder, fun gleam@dynamic@decode:decode_int/1},
        gleam@dynamic@decode:map(_pipe, fun(I) -> {I, 0} end)
    end,
    Float = begin
        _pipe@1 = {decoder, fun gleam@dynamic@decode:decode_float/1},
        gleam@dynamic@decode:map(
            _pipe@1,
            fun(F) ->
                Floored = math:floor(F),
                Seconds = erlang:round(Floored),
                Nanoseconds = erlang:round((F - Floored) * 1000000000.0),
                {Seconds, Nanoseconds}
            end
        )
    end,
    gleam@dynamic@decode:one_of(Int, [Float]).

-file("src/parrot/dev.gleam", 100).
-spec time_decoder() -> gleam@dynamic@decode:decoder(gleam@time@calendar:time_of_day()).
time_decoder() ->
    gleam@dynamic@decode:field(
        0,
        {decoder, fun gleam@dynamic@decode:decode_int/1},
        fun(Hours) ->
            gleam@dynamic@decode:field(
                1,
                {decoder, fun gleam@dynamic@decode:decode_int/1},
                fun(Minutes) ->
                    gleam@dynamic@decode:field(
                        2,
                        seconds_decoder(),
                        fun(_use0) ->
                            {Seconds, Nanoseconds} = _use0,
                            _pipe = {time_of_day,
                                Hours,
                                Minutes,
                                Seconds,
                                Nanoseconds},
                            gleam@dynamic@decode:success(_pipe)
                        end
                    )
                end
            )
        end
    ).

-file("src/parrot/dev.gleam", 75).
-spec datetime_tuple_decoder() -> gleam@dynamic@decode:decoder(gleam@time@timestamp:timestamp()).
datetime_tuple_decoder() ->
    gleam@dynamic@decode:field(
        0,
        date_decoder(),
        fun(Date) ->
            gleam@dynamic@decode:field(
                1,
                time_decoder(),
                fun(Time) ->
                    _pipe = gleam@time@timestamp:from_calendar(
                        Date,
                        Time,
                        {duration, 0, 0}
                    ),
                    gleam@dynamic@decode:success(_pipe)
                end
            )
        end
    ).

-file("src/parrot/dev.gleam", 34).
-spec datetime_decoder() -> gleam@dynamic@decode:decoder(gleam@time@timestamp:timestamp()).
datetime_decoder() ->
    gleam@dynamic@decode:one_of(
        datetime_string_decoder(),
        [datetime_tuple_decoder(), timestamp_decoder()]
    ).
