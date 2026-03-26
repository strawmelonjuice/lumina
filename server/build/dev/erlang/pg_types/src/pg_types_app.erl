%%%-------------------------------------------------------------------
%% @doc pgo_types application
%% @end
%%%-------------------------------------------------------------------
-module(pg_types_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    pg_types_sup:start_link().

stop(_State) ->
    ok.
