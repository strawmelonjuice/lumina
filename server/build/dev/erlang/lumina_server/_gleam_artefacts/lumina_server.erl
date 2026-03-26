-module(lumina_server).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/lumina_server.gleam").
-export([main/0]).
-export_type([handler_context/0, static_route/0, client_connection_data/0, client_type/0, user/0, websocket_state/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " Lumina > Server\n"
    " Main entry point for Lumina.\n"
).

-type handler_context() :: {handler_context,
        sqlight:connection(),
        binary(),
        binary(),
        fun((static_route()) -> gleam@http@response:response(ewe:response_body()))}.

-type static_route() :: route_for_index |
    route_for_client_as_minified_javascript |
    route_for_client_as_javascript |
    route_for_client_styles |
    route_for_icon_as_p_n_g |
    route_for_icon_as_s_v_g.

-type client_connection_data() :: {client_connection_data,
        gleam@option:option(client_type()),
        gleam@option:option(user())}.

-type client_type() :: web_client | native_app.

-type user() :: {user, nil}.

-type websocket_state() :: {websocket_state,
        handler_context(),
        client_connection_data()}.

-file("src/lumina_server.gleam", 153).
-spec static(binary(), binary(), woof:logger()) -> fun((static_route()) -> gleam@http@response:response(ewe:response_body())).
static(Client_hash, Assets, Setuplog) ->
    Client_servible = begin
        _pipe@2 = [<<"<!doctype html><html lang=\"en\"><head><meta charset=\"UTF-8\" /><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, viewport-fit=cover\" /><title>Lumina</title><link rel=\"preconnect\" href=\"https://fontlay.com\" corossorigin /><link href=\"https://fontlay.com/css2?family=DM+Mono:ital,wght@0,300;0,400;0,500;1,300;1,400;1,500&family=Elms+Sans:ital,wght@0,100..900;1,100..900&family=Gantari:ital,wght@0,100..900;1,100..900&family=Josefin+Sans:ital,wght@0,100..700;1,100..700&family=Vend+Sans&display=swap\" rel=\"stylesheet\"><link	rel=\"stylesheet\" href=\"/static/lumina.css\"/><meta name=\"robots\" content=\"noai, noimageai, nofollow\"><script>window.clientHash = \""/utf8>>,
            begin
                _pipe = Client_hash,
                gleam_stdlib:identity(_pipe)
            end,
            <<"\";</script><script type=\"module\">"/utf8>>,
            case simplifile_erl:read_bits(
                <<Assets/binary, "/static/lumina_client.min.mjs"/utf8>>
            ) of
                {error, _} ->
                    _pipe@1 = Setuplog,
                    woof:log(
                        _pipe@1,
                        error,
                        <<"Missing application assets."/utf8>>,
                        [woof:field(
                                <<"File"/utf8>>,
                                <<Assets/binary,
                                    "/static/lumina_client.min.mjs"/utf8>>
                            )]
                    ),
                    erlang:error(#{gleam_error => panic,
                            message => <<"Missing application assets."/utf8>>,
                            file => <<?FILEPATH/utf8>>,
                            module => <<"lumina_server"/utf8>>,
                            function => <<"static"/utf8>>,
                            line => 171});

                {ok, Outcome} ->
                    Outcome
            end,
            <<"</script></head><body id=\"app\"></body></html>"/utf8>>],
        gleam_stdlib:bit_array_concat(_pipe@2)
    end,
    _pipe@3 = Setuplog,
    woof:log(
        _pipe@3,
        debug,
        <<"Total client size is: "/utf8,
            (begin
                _pipe@4 = erlang:byte_size(Client_servible),
                humanise:bytes_int(_pipe@4)
            end)/binary>>,
        [{<<"revision"/utf8>>, Client_hash}]
    ),
    Builtin_file = fun(File, Mime) -> case simplifile_erl:read_bits(File) of
            {error, _} ->
                _pipe@5 = Setuplog,
                woof:log(
                    _pipe@5,
                    error,
                    <<"Missing application assets."/utf8>>,
                    [woof:field(<<"File"/utf8>>, File)]
                ),
                erlang:error(#{gleam_error => panic,
                        message => <<"Missing application assets."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"lumina_server"/utf8>>,
                        function => <<"static"/utf8>>,
                        line => 196});

            {ok, Outcome@1} ->
                _pipe@6 = gleam@http@response:new(200),
                _pipe@7 = gleam@http@response:set_header(
                    _pipe@6,
                    <<"content-type"/utf8>>,
                    Mime
                ),
                gleam@http@response:set_body(_pipe@7, {bits_data, Outcome@1})
        end end,
    Index = gleam@http@response:set_body(
        gleam@http@response:set_header(
            gleam@http@response:new(200),
            <<"content-type"/utf8>>,
            <<"text/html; charset=utf-8"/utf8>>
        ),
        {bits_data, Client_servible}
    ),
    Client_js_min = Builtin_file(
        <<Assets/binary, "/static/lumina_client.min.mjs"/utf8>>,
        <<"application/javascript; charset=utf-8"/utf8>>
    ),
    Client_js = Builtin_file(
        <<Assets/binary, "/static/lumina_client.mjs"/utf8>>,
        <<"application/javascript; charset=utf-8"/utf8>>
    ),
    Client_styles = Builtin_file(
        <<Assets/binary, "/static/lumina_client.css"/utf8>>,
        <<"text/css; charset=utf-8"/utf8>>
    ),
    Icon_png = Builtin_file(
        <<Assets/binary, "/static/logo.png"/utf8>>,
        <<"image/png"/utf8>>
    ),
    Icon_svg = Builtin_file(
        <<Assets/binary, "/static/logo.svg"/utf8>>,
        <<"image/svg+xml"/utf8>>
    ),
    fun(Route) -> case Route of
            route_for_index ->
                Index;

            route_for_icon_as_s_v_g ->
                Icon_svg;

            route_for_icon_as_p_n_g ->
                Icon_png;

            route_for_client_styles ->
                Client_styles;

            route_for_client_as_javascript ->
                Client_js;

            route_for_client_as_minified_javascript ->
                Client_js_min
        end end.

-file("src/lumina_server.gleam", 310).
-spec client_communication_handler(
    ewe@internal@stream@websocket:websocket_connection(),
    websocket_state(),
    ewe:websocket_message(nil)
) -> ewe:websocket_next(websocket_state(), nil).
client_communication_handler(_, State, Message) ->
    case Message of
        {text, Json_str} ->
            ewe:websocket_continue(State);

        {binary, _} ->
            ewe:websocket_continue(State);

        {user, nil} ->
            ewe:websocket_continue(State)
    end.

-file("src/lumina_server.gleam", 243).
-spec handler(
    gleam@http@request:request(ewe@internal@http1:connection()),
    handler_context()
) -> gleam@http@response:response(ewe:response_body()).
handler(Req, Handler_ctx) ->
    Httplogger = fun(Level, Msg, Vars) ->
        _pipe = woof:new(<<"WEBSERVER"/utf8>>),
        woof:log(
            _pipe,
            Level,
            Msg,
            [woof:field(<<"uri path"/utf8>>, erlang:element(8, Req)) | Vars]
        )
    end,
    case begin
        _pipe@1 = erlang:element(8, Req),
        gleam@uri:path_segments(_pipe@1)
    end of
        [<<"/"/utf8>>] ->
            Httplogger(info, <<"OK"/utf8>>, []),
            (erlang:element(5, Handler_ctx))(route_for_index);

        [<<""/utf8>>] ->
            Httplogger(info, <<"OK"/utf8>>, []),
            (erlang:element(5, Handler_ctx))(route_for_index);

        [] ->
            Httplogger(info, <<"OK"/utf8>>, []),
            (erlang:element(5, Handler_ctx))(route_for_index);

        [<<"static"/utf8>>, <<"lumina.min.mjs"/utf8>>] ->
            Httplogger(info, <<"OK"/utf8>>, []),
            (erlang:element(5, Handler_ctx))(
                route_for_client_as_minified_javascript
            );

        [<<"static"/utf8>>, <<"lumina.mjs"/utf8>>] ->
            Httplogger(info, <<"OK"/utf8>>, []),
            (erlang:element(5, Handler_ctx))(route_for_client_as_javascript);

        [<<"static"/utf8>>, <<"lumina.css"/utf8>>] ->
            Httplogger(info, <<"OK"/utf8>>, []),
            (erlang:element(5, Handler_ctx))(route_for_client_styles);

        [<<"favicon.ico"/utf8>>] ->
            Httplogger(info, <<"OK"/utf8>>, []),
            (erlang:element(5, Handler_ctx))(route_for_icon_as_p_n_g);

        [<<"static"/utf8>>, <<"logo.png"/utf8>>] ->
            Httplogger(info, <<"OK"/utf8>>, []),
            (erlang:element(5, Handler_ctx))(route_for_icon_as_p_n_g);

        [<<"static"/utf8>>, <<"logo.svg"/utf8>>] ->
            Httplogger(info, <<"OK"/utf8>>, []),
            (erlang:element(5, Handler_ctx))(route_for_icon_as_s_v_g);

        [<<"connection"/utf8>>] ->
            ewe:upgrade_websocket(
                Req,
                fun(_, Selector) ->
                    State = {websocket_state,
                        Handler_ctx,
                        {client_connection_data, none, none}},
                    {State, Selector}
                end,
                fun client_communication_handler/3,
                fun(_, _) -> nil end
            );

        _ ->
            Httplogger(warning, <<"Not found."/utf8>>, []),
            _pipe@2 = gleam@http@response:new(404),
            _pipe@3 = gleam@http@response:set_header(
                _pipe@2,
                <<"content-type"/utf8>>,
                <<"text/plain; charset=utf-8"/utf8>>
            ),
            gleam@http@response:set_body(
                _pipe@3,
                {text_data, <<"404! Not found!"/utf8>>}
            )
    end.

-file("src/lumina_server.gleam", 75).
-spec main() -> nil.
main() ->
    Debug = simplifile_erl:is_file(<<"/data/debug"/utf8>>) =:= {ok, true},
    sqlight:with_connection(
        <<"/data/instance.db"/utf8>>,
        fun(Db) ->
            woof:set_sink(
                fun(Entry, Formatted) ->
                    woof:beam_logger_sink(Entry, Formatted),
                    woof:default_sink(Entry, Formatted)
                end
            ),
            Setuplog = woof:new(<<"WARMUP"/utf8>>),
            _ = sqlight:exec(<<"PRAGMA journal_mode = WAL;"/utf8>>, Db),
            _ = sqlight:exec(<<"PRAGMA synchronous = NORMAL;"/utf8>>, Db),
            _ = sqlight:exec(<<"PRAGMA cache_size = -64000;"/utf8>>, Db),
            _ = sqlight:exec(<<"PRAGMA foreign_keys = ON;"/utf8>>, Db),
            woof:configure({config, (case Debug of
                        true ->
                            debug;

                        false ->
                            info
                    end), text, auto}),
            Assets = case gleam_erlang_ffi:priv_directory(
                <<"lumina_server"/utf8>>
            ) of
                {ok, Outcome} ->
                    Outcome;

                {error, _} ->
                    _pipe = Setuplog,
                    woof:log(
                        _pipe,
                        error,
                        <<"could not get priv folder."/utf8>>,
                        []
                    ),
                    erlang:error(#{gleam_error => panic,
                            message => <<"`panic` expression evaluated."/utf8>>,
                            file => <<?FILEPATH/utf8>>,
                            module => <<"lumina_server"/utf8>>,
                            function => <<"main"/utf8>>,
                            line => 108})
            end,
            Client_hash = case simplifile:read(
                <<Assets/binary, "/static/lumina_client_rev.hash"/utf8>>
            ) of
                {error, _} ->
                    _pipe@1 = Setuplog,
                    woof:log(
                        _pipe@1,
                        error,
                        <<"could not load client revision's hash from filesystem."/utf8>>,
                        []
                    ),
                    erlang:error(#{gleam_error => panic,
                            message => <<"`panic` expression evaluated."/utf8>>,
                            file => <<?FILEPATH/utf8>>,
                            module => <<"lumina_server"/utf8>>,
                            function => <<"main"/utf8>>,
                            line => 123});

                {ok, Outcome@1} ->
                    _pipe@2 = Setuplog,
                    woof:log(
                        _pipe@2,
                        info,
                        <<"Found client revision!"/utf8>>,
                        [woof:field(<<"revision"/utf8>>, Outcome@1)]
                    ),
                    Outcome@1
            end,
            Static_responses = static(Client_hash, Assets, Setuplog),
            case begin
                _pipe@3 = ewe:new(
                    fun(_capture) ->
                        handler(
                            _capture,
                            {handler_context,
                                Db,
                                Client_hash,
                                Assets,
                                Static_responses}
                        )
                    end
                ),
                _pipe@4 = ewe:bind(_pipe@3, <<"0.0.0.0"/utf8>>),
                _pipe@8 = ewe:listening(
                    _pipe@4,
                    begin
                        _pipe@5 = envoy_ffi:get(<<"PORT"/utf8>>),
                        _pipe@6 = gleam@result:map(
                            _pipe@5,
                            fun gleam_stdlib:parse_int/1
                        ),
                        _pipe@7 = gleam@result:flatten(_pipe@6),
                        gleam@result:unwrap(_pipe@7, 3000)
                    end
                ),
                ewe:start(_pipe@8)
            end of
                {ok, _} -> nil;
                _assert_fail ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"lumina_server"/utf8>>,
                                function => <<"main"/utf8>>,
                                line => 136,
                                value => _assert_fail,
                                start => 3395,
                                'end' => 3708,
                                pattern_start => 3406,
                                pattern_end => 3411})
            end,
            gleam_erlang_ffi:sleep_forever()
        end
    ).
