-module(ewe@internal@handler).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/ewe/internal/handler.gleam").
-export([init/1, loop/4]).
-export_type([handler/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-type handler() :: {http1,
        ewe@internal@http1@handler:http1_handler(),
        gleam@erlang@process:subject(nil)}.

-file("src/ewe/internal/handler.gleam", 22).
?DOC(false).
-spec init(any()) -> {handler(),
    gleam@option:option(gleam@erlang@process:selector(nil))}.
init(_) ->
    Subject = gleam@erlang@process:new_subject(),
    Selector = begin
        _pipe = gleam_erlang_ffi:new_selector(),
        gleam@erlang@process:select(_pipe, Subject)
    end,
    {{http1, ewe@internal@http1@handler:init(), Subject}, {some, Selector}}.

-file("src/ewe/internal/handler.gleam", 33).
?DOC(false).
-spec loop(
    fun((gleam@http@request:request(ewe@internal@http1:connection())) -> gleam@http@response:response(ewe@internal@http1:response_body())),
    gleam@http@response:response(ewe@internal@http1:response_body()),
    gleam@erlang@process:name(gleam@otp@factory_supervisor:message(fun(() -> {ok,
            gleam@otp@actor:started(nil)} |
        {error, gleam@otp@actor:start_error()}), nil)),
    integer()
) -> fun((handler(), glisten:message(nil), glisten:connection(nil)) -> glisten:next(handler(), glisten:message(nil))).
loop(Handler, On_crash, Factory_name, Idle_timeout) ->
    fun(State, Message, Conn) ->
        Sender = erlang:element(4, Conn),
        Conn@1 = ewe@internal@http1:transform_connection(Conn, Factory_name),
        case {State, Message} of
            {{http1, State@1, Self}, {packet, Message@1}} ->
                Result = ewe@internal@http1@handler:handle_packet(
                    State@1,
                    Conn@1,
                    Message@1,
                    Sender,
                    Handler,
                    On_crash,
                    Idle_timeout
                ),
                case Result of
                    {continue, State@2} ->
                        glisten:continue({http1, State@2, Self});

                    {http2_upgrade, {direct, _}} ->
                        logging:log(
                            notice,
                            <<"HTTP/2 upgrade; sending goaway"/utf8>>
                        ),
                        Goaway = <<0:24,
                            4,
                            0,
                            0:32,
                            8:24,
                            7,
                            0,
                            0:32,
                            0:32,
                            13:32>>,
                        _ = glisten@transport:send(
                            erlang:element(2, Conn@1),
                            erlang:element(3, Conn@1),
                            gleam@bytes_tree:from_bit_array(Goaway)
                        ),
                        glisten:stop();

                    stop ->
                        glisten:stop();

                    {http2_upgrade, {upgrade, _, _}} ->
                        glisten:stop()
                end;

            {_, _} ->
                glisten:stop()
        end
    end.
