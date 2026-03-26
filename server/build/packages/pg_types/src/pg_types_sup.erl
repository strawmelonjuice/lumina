-module(pg_types_sup).

-behaviour(supervisor).

-export([start_link/0]).

-export([init/1]).

-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%% Child :: {Id,StartFunc,Restart,Shutdown,Type,Modules}
init([]) ->
    SupFlags = #{strategy => one_for_one,
                 intensity => 5,
                 period => 10},
    ChildSpec = #{id => pg_types_server,
                  start => {pg_types_server, start_link, []},
                  shutdown => 1000},
    {ok, {SupFlags, [ChildSpec]}}.
