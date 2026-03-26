-module(parrot@internal@cli).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/parrot/internal/cli.gleam").
-export([engine_from_env/1, parse_env/1]).
-export_type([command/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-type command() :: usage | {generate, parrot@internal@sqlc:engine(), binary()}.

-file("src/parrot/internal/cli.gleam", 61).
?DOC(false).
-spec engine_from_env(binary()) -> {ok, parrot@internal@sqlc:engine()} |
    {error, parrot@internal@errors:parrot_error()}.
engine_from_env(Str) ->
    case Str of
        <<"postgres"/utf8, _/binary>> ->
            {ok, postgre_s_q_l};

        <<"mysql"/utf8, _/binary>> ->
            {ok, my_s_q_l};

        <<"file"/utf8>> ->
            {ok, s_q_lite};

        <<"sqlite"/utf8, _/binary>> ->
            {ok, s_q_lite};

        _ ->
            {error, {unknown_engine, Str}}
    end.

-file("src/parrot/internal/cli.gleam", 70).
?DOC(false).
-spec parse_env(binary()) -> {ok, {parrot@internal@sqlc:engine(), binary()}} |
    {error, binary()}.
parse_env(Env) ->
    Env_result = envoy_ffi:get(Env),
    gleam@result:'try'(
        gleam@result:replace_error(
            Env_result,
            <<<<"Environment Variable \""/utf8, Env/binary>>/binary,
                "\" is empty!"/utf8>>
        ),
        fun(Env_var) ->
            Engine_result = engine_from_env(Env_var),
            gleam@result:'try'(
                gleam@result:replace_error(
                    Engine_result,
                    <<<<"\""/utf8, Env/binary>>/binary,
                        "\" does not match any of the supported formats (MySQL, PostgreSQL, SQLite)"/utf8>>
                ),
                fun(Engine) -> {ok, {Engine, Env_var}} end
            )
        end
    ).
