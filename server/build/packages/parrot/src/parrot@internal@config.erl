-module(parrot@internal@config).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/parrot/internal/config.gleam").
-export([get_json_file/1, get_module_directory/1, get_module_path/1]).
-export_type([config/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-type config() :: {config, binary(), binary()}.

-file("src/parrot/internal/config.gleam", 14).
?DOC(false).
-spec get_json_file(config()) -> {ok, binary()} |
    {error, simplifile:file_error()}.
get_json_file(Config) ->
    Path = filepath:join(
        parrot@internal@project:root(),
        erlang:element(2, Config)
    ),
    simplifile:read(Path).

-file("src/parrot/internal/config.gleam", 19).
?DOC(false).
-spec get_module_directory(config()) -> binary().
get_module_directory(Config) ->
    _pipe = filepath:join(
        parrot@internal@project:src(),
        erlang:element(3, Config)
    ),
    filepath:directory_name(_pipe).

-file("src/parrot/internal/config.gleam", 24).
?DOC(false).
-spec get_module_path(config()) -> binary().
get_module_path(Config) ->
    filepath:join(parrot@internal@project:src(), erlang:element(3, Config)).
