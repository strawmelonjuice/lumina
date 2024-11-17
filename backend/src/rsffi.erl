-module(rsffi).
-export([add/2]).
-nifs([add/2]).
-on_load(init/0).

init() ->
    ok = erlang:load_nif("priv/generated/libs/rsffi", 0).

add(left, right) ->
    exit(nif_library_not_loaded).
