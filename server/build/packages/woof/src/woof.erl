-module(woof).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/woof.gleam").
-export([default_sink/2, silent_sink/2, new/1, field/2, int_field/2, float_field/2, bool_field/2, level_name/1, is_enabled/1, get_global_context/0, configure/1, set_colors/1, set_level/1, set_format/1, set_sink/1, set_global_context/1, append_global_context/1, with_context/2, beam_logger_sink/2, format/2, debug/2, info/2, warning/2, error/2, log/4, tap_info/3, tap_debug/3, tap_warning/3, tap_error/3, log_error/3, time/2, debug_lazy/2, info_lazy/2, warning_lazy/2, error_lazy/2]).
-export_type([level/0, format/0, color_mode/0, config/0, entry/0, logger/0, state/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

-type level() :: debug | info | warning | error.

-type format() :: text | json | compact | {custom, fun((entry()) -> binary())}.

-type color_mode() :: auto | always | never.

-type config() :: {config, level(), format(), color_mode()}.

-type entry() :: {entry,
        level(),
        binary(),
        list({binary(), binary()}),
        gleam@option:option(binary()),
        binary()}.

-opaque logger() :: {logger, binary()}.

-type state() :: {state,
        level(),
        format(),
        color_mode(),
        list({binary(), binary()}),
        fun((entry(), binary()) -> nil)}.

-file("src/woof.gleam", 148).
?DOC(
    " The default sink — prints the formatted log line to standard output.\n"
    "\n"
    " This is the out-of-the-box behaviour: zero configuration, beautiful\n"
    " output on any terminal.  Useful when building a custom sink that still\n"
    " wants to write to stdout.\n"
    "\n"
    " See `beam_logger_sink` for the OTP-integrated alternative.\n"
).
-spec default_sink(entry(), binary()) -> nil.
default_sink(_, Formatted) ->
    gleam_stdlib:println(Formatted).

-file("src/woof.gleam", 200).
?DOC(
    " A sink that does nothing and discards all log events.\n"
    "\n"
    " Useful for muting logs entirely, for example during test runs:\n"
    " `woof.set_sink(woof.silent_sink)`\n"
).
-spec silent_sink(entry(), binary()) -> nil.
silent_sink(_, _) ->
    nil.

-file("src/woof.gleam", 265).
?DOC(
    " Create a namespaced logger.\n"
    "\n"
    " The namespace is prepended to every message formatted with `Text` and\n"
    " included as a `\"ns\"` field in `Json` output.\n"
).
-spec new(binary()) -> logger().
new(Namespace) ->
    {logger, Namespace}.

-file("src/woof.gleam", 285).
?DOC(
    " Create a string field. Same as writing `#(key, value)` directly, but\n"
    " reads nicely alongside the typed helpers.\n"
).
-spec field(binary(), binary()) -> {binary(), binary()}.
field(Key, Value) ->
    {Key, Value}.

-file("src/woof.gleam", 290).
?DOC(" Create a field from an `Int`.\n").
-spec int_field(binary(), integer()) -> {binary(), binary()}.
int_field(Key, Value) ->
    {Key, erlang:integer_to_binary(Value)}.

-file("src/woof.gleam", 295).
?DOC(" Create a field from a `Float`.\n").
-spec float_field(binary(), float()) -> {binary(), binary()}.
float_field(Key, Value) ->
    {Key, gleam_stdlib:float_to_string(Value)}.

-file("src/woof.gleam", 300).
?DOC(" Create a field from a `Bool`.\n").
-spec bool_field(binary(), boolean()) -> {binary(), binary()}.
bool_field(Key, Value) ->
    {Key, gleam@bool:to_string(Value)}.

-file("src/woof.gleam", 444).
?DOC(
    " Return the lowercase name of a level.\n"
    "\n"
    " Useful inside `Custom` formatters.\n"
).
-spec level_name(level()) -> binary().
level_name(Level) ->
    case Level of
        debug ->
            <<"debug"/utf8>>;

        info ->
            <<"info"/utf8>>;

        warning ->
            <<"warning"/utf8>>;

        error ->
            <<"error"/utf8>>
    end.

-file("src/woof.gleam", 467).
-spec default_state() -> state().
default_state() ->
    {state, debug, text, auto, [], fun default_sink/2}.

-file("src/woof.gleam", 540).
-spec level_to_int(level()) -> integer().
level_to_int(Level) ->
    case Level of
        debug ->
            0;

        info ->
            1;

        warning ->
            2;

        error ->
            3
    end.

-file("src/woof.gleam", 536).
-spec should_log(level(), level()) -> boolean().
should_log(Msg_level, Min_level) ->
    level_to_int(Msg_level) >= level_to_int(Min_level).

-file("src/woof.gleam", 719).
-spec json_escape(binary()) -> binary().
json_escape(S) ->
    _pipe = S,
    _pipe@1 = gleam@string:replace(_pipe, <<"\\"/utf8>>, <<"\\\\"/utf8>>),
    _pipe@2 = gleam@string:replace(_pipe@1, <<"\""/utf8>>, <<"\\\""/utf8>>),
    _pipe@3 = gleam@string:replace(_pipe@2, <<"\n"/utf8>>, <<"\\n"/utf8>>),
    _pipe@4 = gleam@string:replace(
        _pipe@3,
        <<"\x{001B}"/utf8>>,
        <<"\\u001b"/utf8>>
    ),
    _pipe@5 = gleam@string:replace(_pipe@4, <<"\r"/utf8>>, <<"\\r"/utf8>>),
    _pipe@6 = gleam@string:replace(_pipe@5, <<"\t"/utf8>>, <<"\\t"/utf8>>),
    _pipe@7 = gleam@string:replace(_pipe@6, <<"\x{0008}"/utf8>>, <<"\\b"/utf8>>),
    gleam@string:replace(_pipe@7, <<"\x{000C}"/utf8>>, <<"\\f"/utf8>>).

-file("src/woof.gleam", 715).
-spec json_pair(binary(), binary()) -> binary().
json_pair(Key, Value) ->
    <<<<<<<<"\""/utf8, (json_escape(Key))/binary>>/binary, "\":\""/utf8>>/binary,
            (json_escape(Value))/binary>>/binary,
        "\""/utf8>>.

-file("src/woof.gleam", 687).
?DOC(
    " JSON format — one object per line (NDJSON / JSON Lines).\n"
    "\n"
    " Example:\n"
    "   {\"level\":\"info\",\"time\":\"2026-…\",\"msg\":\"Server started\",\"port\":\"3000\"}\n"
).
-spec format_json(entry()) -> binary().
format_json(Entry) ->
    Core = case erlang:element(5, Entry) of
        {some, Ns} ->
            [json_pair(<<"level"/utf8>>, level_name(erlang:element(2, Entry))),
                json_pair(<<"time"/utf8>>, erlang:element(6, Entry)),
                json_pair(<<"ns"/utf8>>, Ns),
                json_pair(<<"msg"/utf8>>, erlang:element(3, Entry))];

        none ->
            [json_pair(<<"level"/utf8>>, level_name(erlang:element(2, Entry))),
                json_pair(<<"time"/utf8>>, erlang:element(6, Entry)),
                json_pair(<<"msg"/utf8>>, erlang:element(3, Entry))]
    end,
    User_fields = gleam@list:map(
        erlang:element(4, Entry),
        fun(F) ->
            {K, V} = F,
            Safe_k = case K of
                <<"level"/utf8>> ->
                    <<"_"/utf8, K/binary>>;

                <<"time"/utf8>> ->
                    <<"_"/utf8, K/binary>>;

                <<"ns"/utf8>> ->
                    <<"_"/utf8, K/binary>>;

                <<"msg"/utf8>> ->
                    <<"_"/utf8, K/binary>>;

                _ ->
                    K
            end,
            json_pair(Safe_k, V)
        end
    ),
    <<<<"{"/utf8,
            (gleam@string:join(lists:append(Core, User_fields), <<","/utf8>>))/binary>>/binary,
        "}"/utf8>>.

-file("src/woof.gleam", 731).
-spec level_tag(level()) -> binary().
level_tag(Level) ->
    case Level of
        debug ->
            <<"DEBUG"/utf8>>;

        info ->
            <<"INFO"/utf8>>;

        warning ->
            <<"WARN"/utf8>>;

        error ->
            <<"ERROR"/utf8>>
    end.

-file("src/woof.gleam", 637).
?DOC(
    " Compact format: single-line, key=value style.\n"
    "\n"
    "   INFO 2026-02-11T10:30:45Z Server started port=3000 workers=4\n"
).
-spec format_compact(entry()) -> binary().
format_compact(Entry) ->
    Tag = level_tag(erlang:element(2, Entry)),
    Ns = case erlang:element(5, Entry) of
        none ->
            <<""/utf8>>;

        {some, N} ->
            <<" ns="/utf8, N/binary>>
    end,
    Msg = begin
        _pipe = erlang:element(3, Entry),
        _pipe@1 = gleam@string:replace(_pipe, <<"\\"/utf8>>, <<"\\\\"/utf8>>),
        _pipe@2 = gleam@string:replace(_pipe@1, <<"\n"/utf8>>, <<"\\n"/utf8>>),
        gleam@string:replace(_pipe@2, <<"\r"/utf8>>, <<"\\r"/utf8>>)
    end,
    Base = <<<<<<<<<<Tag/binary, " "/utf8>>/binary,
                    (erlang:element(6, Entry))/binary>>/binary,
                Ns/binary>>/binary,
            " "/utf8>>/binary,
        Msg/binary>>,
    case erlang:element(4, Entry) of
        [] ->
            Base;

        Fields ->
            Pairs = begin
                _pipe@7 = gleam@list:map(
                    Fields,
                    fun(F) ->
                        {K, V} = F,
                        Needs_quotes = (((gleam_stdlib:contains_string(
                            V,
                            <<" "/utf8>>
                        )
                        orelse gleam_stdlib:contains_string(V, <<"="/utf8>>))
                        orelse gleam_stdlib:contains_string(V, <<"\n"/utf8>>))
                        orelse gleam_stdlib:contains_string(V, <<"\r"/utf8>>))
                        orelse gleam@string:is_empty(V),
                        Val = case Needs_quotes of
                            true ->
                                <<<<"\""/utf8,
                                        (begin
                                            _pipe@3 = V,
                                            _pipe@4 = gleam@string:replace(
                                                _pipe@3,
                                                <<"\\"/utf8>>,
                                                <<"\\\\"/utf8>>
                                            ),
                                            _pipe@5 = gleam@string:replace(
                                                _pipe@4,
                                                <<"\""/utf8>>,
                                                <<"\\\""/utf8>>
                                            ),
                                            _pipe@6 = gleam@string:replace(
                                                _pipe@5,
                                                <<"\n"/utf8>>,
                                                <<"\\n"/utf8>>
                                            ),
                                            gleam@string:replace(
                                                _pipe@6,
                                                <<"\r"/utf8>>,
                                                <<"\\r"/utf8>>
                                            )
                                        end)/binary>>/binary,
                                    "\""/utf8>>;

                            false ->
                                V
                        end,
                        <<<<K/binary, "="/utf8>>/binary, Val/binary>>
                    end
                ),
                gleam@string:join(_pipe@7, <<" "/utf8>>)
            end,
            <<<<Base/binary, " "/utf8>>/binary, Pairs/binary>>
    end.

-file("src/woof.gleam", 742).
?DOC(
    " Extract HH:MM:SS from an ISO 8601 timestamp.\n"
    " \"2026-02-11T10:30:45.123Z\" → \"10:30:45\"\n"
).
-spec short_time(binary()) -> binary().
short_time(Iso) ->
    gleam@string:slice(Iso, 11, 8).

-file("src/woof.gleam", 477).
-spec read_state() -> state().
read_state() ->
    woof_ffi:get_state(default_state()).

-file("src/woof.gleam", 122).
?DOC(
    " Check if a specific log level is currently enabled.\n"
    "\n"
    " Useful if you need to perform expensive work before emitting several\n"
    " log messages, and want to skip that work if the level is silenced.\n"
).
-spec is_enabled(level()) -> boolean().
is_enabled(Level) ->
    State = read_state(),
    should_log(Level, erlang:element(2, State)).

-file("src/woof.gleam", 340).
?DOC(" Get the current global context fields.\n").
-spec get_global_context() -> list({binary(), binary()}).
get_global_context() ->
    State = read_state(),
    erlang:element(5, State).

-file("src/woof.gleam", 481).
-spec write_state(state()) -> nil.
write_state(State) ->
    woof_ffi:set_state(State).

-file("src/woof.gleam", 91).
?DOC(
    " Replace the current configuration.\n"
    "\n"
    " This sets level, format, and color mode at once.  Global context is\n"
    " left untouched — use `set_global_context` if you need to change it.\n"
).
-spec configure(config()) -> nil.
configure(Config) ->
    State = read_state(),
    write_state(
        {state,
            erlang:element(2, Config),
            erlang:element(3, Config),
            erlang:element(4, Config),
            erlang:element(5, State),
            erlang:element(6, State)}
    ).

-file("src/woof.gleam", 105).
?DOC(
    " Change whether text logs use ANSI colors.\n"
    " (Json/Compact formats ignore this setting.)\n"
).
-spec set_colors(color_mode()) -> nil.
set_colors(Mode) ->
    State = read_state(),
    write_state(
        {state,
            erlang:element(2, State),
            erlang:element(3, State),
            Mode,
            erlang:element(5, State),
            erlang:element(6, State)}
    ).

-file("src/woof.gleam", 113).
?DOC(
    " Set the minimum log level.\n"
    "\n"
    " Messages below this level are silently dropped with near-zero overhead.\n"
).
-spec set_level(level()) -> nil.
set_level(Level) ->
    State = read_state(),
    write_state(
        {state,
            Level,
            erlang:element(3, State),
            erlang:element(4, State),
            erlang:element(5, State),
            erlang:element(6, State)}
    ).

-file("src/woof.gleam", 128).
?DOC(" Set the output format.\n").
-spec set_format(format()) -> nil.
set_format(Format) ->
    State = read_state(),
    write_state(
        {state,
            erlang:element(2, State),
            Format,
            erlang:element(4, State),
            erlang:element(5, State),
            erlang:element(6, State)}
    ).

-file("src/woof.gleam", 136).
?DOC(
    " Set the sink function used to emit formatted logs.\n"
    "\n"
    " The default sink uses `io.println` to write to standard output.\n"
).
-spec set_sink(fun((entry(), binary()) -> nil)) -> nil.
set_sink(Sink) ->
    State = read_state(),
    write_state(
        {state,
            erlang:element(2, State),
            erlang:element(3, State),
            erlang:element(4, State),
            erlang:element(5, State),
            Sink}
    ).

-file("src/woof.gleam", 334).
?DOC(
    " Set fields that appear on **every** log message globally.\n"
    "\n"
    " Typically called once at application start.\n"
).
-spec set_global_context(list({binary(), binary()})) -> nil.
set_global_context(Fields) ->
    State = read_state(),
    write_state(
        {state,
            erlang:element(2, State),
            erlang:element(3, State),
            erlang:element(4, State),
            Fields,
            erlang:element(6, State)}
    ).

-file("src/woof.gleam", 346).
?DOC(" Append fields to the global context without replacing the existing ones.\n").
-spec append_global_context(list({binary(), binary()})) -> nil.
append_global_context(Fields) ->
    Current = get_global_context(),
    set_global_context(lists:append(Current, Fields)).

-file("src/woof.gleam", 323).
?DOC(
    " Run `body` with extra fields attached to every log call inside it.\n"
    "\n"
    " Fields from the context are merged with inline fields.  If a key appears\n"
    " in both, the inline value wins (it comes last in the list).\n"
    "\n"
    " Contexts can be nested — inner fields accumulate on top of outer ones.\n"
    "\n"
    " On the BEAM each process gets its own context (process dictionary), so\n"
    " concurrent request handlers never interfere with each other.\n"
    "\n"
    " **Notice for JavaScript async users**: On the JavaScript target, because\n"
    " JS uses cooperative concurrency and is single-threaded, `with_context` \n"
    " modifies a global state. If your callback enters an async sleep/promise,\n"
    " the context might be overwritten by other concurrent tasks. Use with \n"
    " caution in highly concurrent async Node/Deno servers.\n"
).
-spec with_context(list({binary(), binary()}), fun(() -> DQW)) -> DQW.
with_context(Fields, Body) ->
    Previous = woof_ffi:get_context([]),
    woof_ffi:set_context(lists:append(Previous, Fields)),
    Result = Body(),
    woof_ffi:set_context(Previous),
    Result.

-file("src/woof.gleam", 583).
-spec no_color_set() -> boolean().
no_color_set() ->
    gleam@result:is_ok(woof_ffi:get_env(<<"NO_COLOR"/utf8>>)).

-file("src/woof.gleam", 567).
?DOC(" Decide whether to actually use colors given the mode.\n").
-spec resolve_colors(color_mode()) -> boolean().
resolve_colors(Mode) ->
    case Mode of
        always ->
            true;

        never ->
            false;

        auto ->
            case woof_ffi:is_tty() of
                false ->
                    false;

                true ->
                    case no_color_set() of
                        true ->
                            false;

                        false ->
                            true
                    end
            end
    end.

-file("src/woof.gleam", 186).
?DOC(
    " A sink that routes log events through the official logging pipeline.\n"
    "\n"
    " On the **BEAM target** each event is delivered to OTP's `logger` module\n"
    " (available since OTP 21), so the entire BEAM ecosystem can observe,\n"
    " filter, and re-route woof messages:\n"
    "\n"
    " - Applications that use woof no longer need a second logging system.\n"
    " - Libraries that depend on woof can be silenced by the host application.\n"
    " - BEAM logger handlers (Loki, Datadog, etc.) receive woof events.\n"
    " - OTP performance features apply: async dispatch, load-shedding, etc.\n"
    "\n"
    " Each event is tagged with `domain => [woof]` so handlers and filters\n"
    " can target woof output specifically:\n"
    "\n"
    " ```erlang\n"
    " %% Silence all woof output in a specific environment:\n"
    " logger:add_primary_filter(no_woof,\n"
    "     {fun logger_filters:domain/2, {stop, sub, [woof]}}).\n"
    " ```\n"
    "\n"
    " On the **JavaScript target** the event is passed to the level-appropriate\n"
    " `console` method (`console.debug`, `console.info`, `console.warn`, or\n"
    " `console.error`) — the JS equivalent of routing by severity.\n"
    "\n"
    " ## Usage\n"
    "\n"
    " Call once at application startup, before any logging:\n"
    "\n"
    " ```gleam\n"
    " pub fn main() {\n"
    "   woof.set_sink(woof.beam_logger_sink)\n"
    "   // ... rest of startup\n"
    " }\n"
    " ```\n"
).
-spec beam_logger_sink(entry(), binary()) -> nil.
beam_logger_sink(Entry, Formatted) ->
    woof_ffi:beam_log(
        erlang:element(2, Entry),
        erlang:element(3, Entry),
        erlang:element(4, Entry),
        erlang:element(5, Entry),
        Formatted
    ).

-file("src/woof.gleam", 760).
-spec level_color(level()) -> binary().
level_color(Level) ->
    case Level of
        debug ->
            <<"\x{001b}[90m"/utf8>>;

        info ->
            <<"\x{001b}[34m"/utf8>>;

        warning ->
            <<"\x{001b}[33m"/utf8>>;

        error ->
            <<"\x{001b}[1;31m"/utf8>>
    end.

-file("src/woof.gleam", 593).
?DOC(
    " Text format example:\n"
    "   [INFO] 10:30:45 Server started\n"
    "     port: 3000\n"
    "\n"
    " With namespace:\n"
    "   [INFO] 10:30:45 database: Connecting\n"
).
-spec format_text(entry(), boolean()) -> binary().
format_text(Entry, Use_colors) ->
    Tag = level_tag(erlang:element(2, Entry)),
    Time = short_time(erlang:element(6, Entry)),
    Ns = case erlang:element(5, Entry) of
        none ->
            <<""/utf8>>;

        {some, N} ->
            <<N/binary, ": "/utf8>>
    end,
    Header = case Use_colors of
        false ->
            <<<<<<<<<<<<"["/utf8, Tag/binary>>/binary, "] "/utf8>>/binary,
                            Time/binary>>/binary,
                        " "/utf8>>/binary,
                    Ns/binary>>/binary,
                (erlang:element(3, Entry))/binary>>;

        true ->
            Color = level_color(erlang:element(2, Entry)),
            <<<<<<<<<<<<<<<<<<<<<<Color/binary, "["/utf8>>/binary, Tag/binary>>/binary,
                                                "]"/utf8>>/binary,
                                            "\x{001b}[0m"/utf8>>/binary,
                                        " "/utf8>>/binary,
                                    "\x{001b}[90m"/utf8>>/binary,
                                Time/binary>>/binary,
                            "\x{001b}[0m"/utf8>>/binary,
                        " "/utf8>>/binary,
                    Ns/binary>>/binary,
                (erlang:element(3, Entry))/binary>>
    end,
    case erlang:element(4, Entry) of
        [] ->
            Header;

        Fields ->
            Field_lines = begin
                _pipe = gleam@list:map(
                    Fields,
                    fun(Pair) ->
                        {K, V} = Pair,
                        <<<<<<"  "/utf8, K/binary>>/binary, ": "/utf8>>/binary,
                            V/binary>>
                    end
                ),
                gleam@string:join(_pipe, <<"\n"/utf8>>)
            end,
            <<<<Header/binary, "\n"/utf8>>/binary, Field_lines/binary>>
    end.

-file("src/woof.gleam", 553).
-spec format_entry(entry(), format(), color_mode()) -> binary().
format_entry(Entry, Output_format, Colors) ->
    case Output_format of
        text ->
            format_text(Entry, resolve_colors(Colors));

        json ->
            format_json(Entry);

        compact ->
            format_compact(Entry);

        {custom, F} ->
            F(Entry)
    end.

-file("src/woof.gleam", 437).
?DOC(
    " Format an entry without emitting it.\n"
    "\n"
    " Handy for testing, previews, or sending formatted output to a custom\n"
    " sink (file, HTTP, etc.).\n"
).
-spec format(entry(), format()) -> binary().
format(Entry, Output_format) ->
    format_entry(Entry, Output_format, never).

-file("src/woof.gleam", 515).
-spec do_emit(
    state(),
    level(),
    binary(),
    list({binary(), binary()}),
    gleam@option:option(binary())
) -> nil.
do_emit(State, Level, Message, Fields, Namespace) ->
    Ctx = woof_ffi:get_context([]),
    All_fields = lists:append([erlang:element(5, State), Ctx, Fields]),
    Entry = {entry, Level, Message, All_fields, Namespace, woof_ffi:now()},
    Formatted = format_entry(
        Entry,
        erlang:element(3, State),
        erlang:element(4, State)
    ),
    (erlang:element(6, State))(Entry, Formatted).

-file("src/woof.gleam", 489).
-spec emit(
    level(),
    binary(),
    list({binary(), binary()}),
    gleam@option:option(binary())
) -> nil.
emit(Level, Message, Fields, Namespace) ->
    State = read_state(),
    case should_log(Level, erlang:element(2, State)) of
        false ->
            nil;

        true ->
            do_emit(State, Level, Message, Fields, Namespace)
    end.

-file("src/woof.gleam", 209).
?DOC(" Log at Debug level.\n").
-spec debug(binary(), list({binary(), binary()})) -> nil.
debug(Message, Fields) ->
    emit(debug, Message, Fields, none).

-file("src/woof.gleam", 214).
?DOC(" Log at Info level.\n").
-spec info(binary(), list({binary(), binary()})) -> nil.
info(Message, Fields) ->
    emit(info, Message, Fields, none).

-file("src/woof.gleam", 219).
?DOC(" Log at Warning level.\n").
-spec warning(binary(), list({binary(), binary()})) -> nil.
warning(Message, Fields) ->
    emit(warning, Message, Fields, none).

-file("src/woof.gleam", 224).
?DOC(" Log at Error level.\n").
-spec error(binary(), list({binary(), binary()})) -> nil.
error(Message, Fields) ->
    emit(error, Message, Fields, none).

-file("src/woof.gleam", 270).
?DOC(" Log a message through a namespaced logger.\n").
-spec log(logger(), level(), binary(), list({binary(), binary()})) -> nil.
log(Logger, Level, Message, Fields) ->
    emit(Level, Message, Fields, {some, erlang:element(2, Logger)}).

-file("src/woof.gleam", 357).
?DOC(
    " Log the value at Info level and pass it through.  Fits naturally in\n"
    " pipelines.\n"
).
-spec tap_info(DRA, binary(), list({binary(), binary()})) -> DRA.
tap_info(Value, Message, Fields) ->
    info(Message, Fields),
    Value.

-file("src/woof.gleam", 363).
?DOC(" Log the value at Debug level and pass it through.\n").
-spec tap_debug(DRC, binary(), list({binary(), binary()})) -> DRC.
tap_debug(Value, Message, Fields) ->
    debug(Message, Fields),
    Value.

-file("src/woof.gleam", 373).
?DOC(" Log the value at Warning level and pass it through.\n").
-spec tap_warning(DRE, binary(), list({binary(), binary()})) -> DRE.
tap_warning(Value, Message, Fields) ->
    warning(Message, Fields),
    Value.

-file("src/woof.gleam", 383).
?DOC(" Log the value at Error level and pass it through.\n").
-spec tap_error(DRG, binary(), list({binary(), binary()})) -> DRG.
tap_error(Value, Message, Fields) ->
    error(Message, Fields),
    Value.

-file("src/woof.gleam", 398).
?DOC(
    " If the `Result` is `Error`, log the message at Error level and pass\n"
    " the original value through — useful in result pipelines.\n"
).
-spec log_error({ok, DRI} | {error, DRJ}, binary(), list({binary(), binary()})) -> {ok,
        DRI} |
    {error, DRJ}.
log_error(Res, Message, Fields) ->
    case gleam@result:is_ok(Res) of
        true ->
            Res;

        false ->
            error(Message, Fields),
            Res
    end.

-file("src/woof.gleam", 419).
?DOC(
    " Measure how long `body` takes and log it at Info level.\n"
    "\n"
    " Returns whatever `body` returns — the timing log is a side effect.\n"
).
-spec time(binary(), fun(() -> DRP)) -> DRP.
time(Label, Body) ->
    Start = woof_ffi:monotonic_now(),
    Result = Body(),
    Elapsed = woof_ffi:monotonic_now() - Start,
    info(
        <<Label/binary, " completed"/utf8>>,
        [{<<"duration_ms"/utf8>>, erlang:integer_to_binary(Elapsed)}]
    ),
    Result.

-file("src/woof.gleam", 502).
-spec emit_lazy(
    level(),
    fun(() -> binary()),
    list({binary(), binary()}),
    gleam@option:option(binary())
) -> nil.
emit_lazy(Level, Build, Fields, Namespace) ->
    State = read_state(),
    case should_log(Level, erlang:element(2, State)) of
        false ->
            nil;

        true ->
            do_emit(State, Level, Build(), Fields, Namespace)
    end.

-file("src/woof.gleam", 235).
?DOC(
    " Log at Debug level, evaluating the message only if Debug is enabled.\n"
    "\n"
    " Use this when building the message string is expensive.\n"
).
-spec debug_lazy(fun(() -> binary()), list({binary(), binary()})) -> nil.
debug_lazy(Build, Fields) ->
    emit_lazy(debug, Build, Fields, none).

-file("src/woof.gleam", 240).
?DOC(" Log at Info level, evaluating the message only if Info is enabled.\n").
-spec info_lazy(fun(() -> binary()), list({binary(), binary()})) -> nil.
info_lazy(Build, Fields) ->
    emit_lazy(info, Build, Fields, none).

-file("src/woof.gleam", 245).
?DOC(" Log at Warning level, evaluating the message only if Warning is enabled.\n").
-spec warning_lazy(fun(() -> binary()), list({binary(), binary()})) -> nil.
warning_lazy(Build, Fields) ->
    emit_lazy(warning, Build, Fields, none).

-file("src/woof.gleam", 253).
?DOC(" Log at Error level, evaluating the message only if Error is enabled.\n").
-spec error_lazy(fun(() -> binary()), list({binary(), binary()})) -> nil.
error_lazy(Build, Fields) ->
    emit_lazy(error, Build, Fields, none).
