-module(devmode).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "dev/devmode.gleam").
-export([main/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

-file("dev/devmode.gleam", 7).
?DOC(
    " This will generate the testing username-password combinations defined in the README, as well\n"
    " as a `/data/debug` file, which sets log levels to... Yup! To debug instead of Info\n"
).
-spec main() -> nil.
main() ->
    case simplifile:create_file(<<"../data/debug"/utf8>>) of
        {ok, _} ->
            nil;

        {error, eexist} ->
            nil;

        {error, Fuck} ->
            Fucking_error = gleam@string:inspect(Fuck),
            erlang:error(#{gleam_error => panic,
                    message => Fucking_error,
                    file => <<?FILEPATH/utf8>>,
                    module => <<"devmode"/utf8>>,
                    function => <<"main"/utf8>>,
                    line => 12})
    end,
    sqlight:with_connection(<<"../data/instance.db"/utf8>>, fun(Db) -> nil end).
