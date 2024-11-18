-module(rsffi).
-export([add/2, md_render_to_html/1]).
-nifs([add/2, md_render_to_html/1]).
-on_load(init/0).

init() ->
    ok = erlang:load_nif("priv/generated/libs/rsffi", 0).

add(left, right) ->
    exit(nif_library_not_loaded).

md_render_to_html(markdown) ->
    exit(nif_library_not_loaded).
