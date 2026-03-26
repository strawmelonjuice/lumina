-module(ewe@internal@clock).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/ewe/internal/clock.gleam").
-export([stop/1, start/2, get_http_date/0]).
-export_type([message/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-type message() :: tick.

-file("src/ewe/internal/clock.gleam", 44).
?DOC(false).
-spec stop(any()) -> gleam@erlang@atom:atom_().
stop(_) ->
    erlang:binary_to_atom(<<"ok"/utf8>>).

-file("src/ewe/internal/clock.gleam", 88).
?DOC(false).
-spec weekday_to_string(integer()) -> binary().
weekday_to_string(Weekday) ->
    case Weekday of
        1 ->
            <<"Mon"/utf8>>;

        2 ->
            <<"Tue"/utf8>>;

        3 ->
            <<"Wed"/utf8>>;

        4 ->
            <<"Thu"/utf8>>;

        5 ->
            <<"Fri"/utf8>>;

        6 ->
            <<"Sat"/utf8>>;

        7 ->
            <<"Sun"/utf8>>;

        _ ->
            erlang:error(#{gleam_error => panic,
                    message => <<"erlang is breaking the fourth wall: erlang weekday outside of 1-7 range"/utf8>>,
                    file => <<?FILEPATH/utf8>>,
                    module => <<"ewe/internal/clock"/utf8>>,
                    function => <<"weekday_to_string"/utf8>>,
                    line => 98})
    end.

-file("src/ewe/internal/clock.gleam", 104).
?DOC(false).
-spec month_to_string(integer()) -> binary().
month_to_string(Month) ->
    case Month of
        1 ->
            <<"Jan"/utf8>>;

        2 ->
            <<"Feb"/utf8>>;

        3 ->
            <<"Mar"/utf8>>;

        4 ->
            <<"Apr"/utf8>>;

        5 ->
            <<"May"/utf8>>;

        6 ->
            <<"Jun"/utf8>>;

        7 ->
            <<"Jul"/utf8>>;

        8 ->
            <<"Aug"/utf8>>;

        9 ->
            <<"Sep"/utf8>>;

        10 ->
            <<"Oct"/utf8>>;

        11 ->
            <<"Nov"/utf8>>;

        12 ->
            <<"Dec"/utf8>>;

        _ ->
            erlang:error(#{gleam_error => panic,
                    message => <<"erlang is breaking the fourth wall: erlang month outside of 1-12 range"/utf8>>,
                    file => <<?FILEPATH/utf8>>,
                    module => <<"ewe/internal/clock"/utf8>>,
                    function => <<"month_to_string"/utf8>>,
                    line => 119})
    end.

-file("src/ewe/internal/clock.gleam", 66).
?DOC(false).
-spec calculate_http_date() -> binary().
calculate_http_date() ->
    {Weekday, {Year, Month, Day}, {Hour, Minute, Second}} = ewe_ffi:now(),
    _pipe = gleam@string_tree:new(),
    _pipe@1 = gleam@string_tree:append(_pipe, weekday_to_string(Weekday)),
    _pipe@2 = gleam@string_tree:append(_pipe@1, <<", "/utf8>>),
    _pipe@4 = gleam@string_tree:append(
        _pipe@2,
        begin
            _pipe@3 = erlang:integer_to_binary(Day),
            gleam@string:pad_start(_pipe@3, 2, <<"0"/utf8>>)
        end
    ),
    _pipe@5 = gleam@string_tree:append(_pipe@4, <<" "/utf8>>),
    _pipe@6 = gleam@string_tree:append(_pipe@5, month_to_string(Month)),
    _pipe@7 = gleam@string_tree:append(_pipe@6, <<" "/utf8>>),
    _pipe@9 = gleam@string_tree:append(
        _pipe@7,
        begin
            _pipe@8 = erlang:integer_to_binary(Year),
            gleam@string:pad_start(_pipe@8, 4, <<"0"/utf8>>)
        end
    ),
    _pipe@10 = gleam@string_tree:append(_pipe@9, <<" "/utf8>>),
    _pipe@12 = gleam@string_tree:append(
        _pipe@10,
        begin
            _pipe@11 = erlang:integer_to_binary(Hour),
            gleam@string:pad_start(_pipe@11, 2, <<"0"/utf8>>)
        end
    ),
    _pipe@13 = gleam@string_tree:append(_pipe@12, <<":"/utf8>>),
    _pipe@15 = gleam@string_tree:append(
        _pipe@13,
        begin
            _pipe@14 = erlang:integer_to_binary(Minute),
            gleam@string:pad_start(_pipe@14, 2, <<"0"/utf8>>)
        end
    ),
    _pipe@16 = gleam@string_tree:append(_pipe@15, <<":"/utf8>>),
    _pipe@18 = gleam@string_tree:append(
        _pipe@16,
        begin
            _pipe@17 = erlang:integer_to_binary(Second),
            gleam@string:pad_start(_pipe@17, 2, <<"0"/utf8>>)
        end
    ),
    _pipe@19 = gleam@string_tree:append(_pipe@18, <<" GMT"/utf8>>),
    unicode:characters_to_binary(_pipe@19).

-file("src/ewe/internal/clock.gleam", 18).
?DOC(false).
-spec start(any(), any()) -> {ok, gleam@erlang@process:pid_()} |
    {error, gleam@otp@actor:start_error()}.
start(_, _) ->
    _pipe@2 = gleam@otp@actor:new_with_initialiser(
        1000,
        fun(Subject) ->
            ewe_ffi:init_clock_storage(),
            ewe_ffi:set_http_date(calculate_http_date()),
            gleam@erlang@process:send_after(Subject, 1000, tick),
            _pipe = gleam@otp@actor:initialised(Subject),
            _pipe@1 = gleam@otp@actor:returning(_pipe, Subject),
            {ok, _pipe@1}
        end
    ),
    _pipe@3 = gleam@otp@actor:on_message(
        _pipe@2,
        fun(Subject@1, _) ->
            gleam@erlang@process:send_after(Subject@1, 1000, tick),
            ewe_ffi:set_http_date(calculate_http_date()),
            gleam@otp@actor:continue(Subject@1)
        end
    ),
    _pipe@4 = gleam@otp@actor:start(_pipe@3),
    gleam@result:map(
        _pipe@4,
        fun(Started) ->
            Pid@1 = case gleam@erlang@process:subject_owner(
                erlang:element(3, Started)
            ) of
                {ok, Pid} -> Pid;
                _assert_fail ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"ewe/internal/clock"/utf8>>,
                                function => <<"start"/utf8>>,
                                line => 37,
                                value => _assert_fail,
                                start => 815,
                                'end' => 871,
                                pattern_start => 826,
                                pattern_end => 833})
            end,
            Pid@1
        end
    ).

-file("src/ewe/internal/clock.gleam", 51).
?DOC(false).
-spec get_http_date() -> binary().
get_http_date() ->
    case ewe_ffi:lookup_http_date() of
        {ok, Date} ->
            Date;

        {error, nil} ->
            logging:log(
                warning,
                <<"Failed to lookup HTTP date, calculating new one"/utf8>>
            ),
            calculate_http_date()
    end.
