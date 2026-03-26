-module(lumina_server).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/lumina_server.gleam").
-export([main/0]).
-export_type([handler_context/0]).

-type handler_context() :: {handler_context,
        sqlight:connection(),
        binary(),
        binary()}.

-file("src/lumina_server.gleam", 84).
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
            begin
                _pipe@1 = Vars,
                lists:append(
                    _pipe@1,
                    [{<<"path"/utf8>>, erlang:element(8, Req)}]
                )
            end
        )
    end,
    case begin
        _pipe@2 = erlang:element(8, Req),
        gleam@uri:path_segments(_pipe@2)
    end of
        [<<"/"/utf8>>] ->
            _pipe@3 = gleam@http@response:new(200),
            _pipe@4 = gleam@http@response:set_header(
                _pipe@3,
                <<"content-type"/utf8>>,
                <<"text/html; charset=utf-8"/utf8>>
            ),
            gleam@http@response:set_body(
                _pipe@4,
                {text_data,
                    <<<<"<!doctype html><html lang=\"en\"><head><meta charset=\"UTF-8\" /><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, viewport-fit=cover\" /><title>Lumina</title><link rel=\"preconnect\" href=\"https://fontlay.com\" corossorigin /><link href=\"https://fontlay.com/css2?family=DM+Mono:ital,wght@0,300;0,400;0,500;1,300;1,400;1,500&family=Elms+Sans:ital,wght@0,100..900;1,100..900&family=Gantari:ital,wght@0,100..900;1,100..900&family=Josefin+Sans:ital,wght@0,100..700;1,100..700&family=Vend+Sans&display=swap\" rel=\"stylesheet\"><link	rel=\"stylesheet\" href=\"/static/lumina.css\"/><meta name=\"robots\" content=\"noai, noimageai, nofollow\"><script>window.clientHash = \""/utf8,
                            ((erlang:element(3, Handler_ctx)))/binary>>/binary,
                        "\";</script><script type=\"module\" src=\"/static/lumina.min.mjs\"></script></head><body id=\"app\"></body></html>"/utf8>>}
            );

        [<<""/utf8>>] ->
            _pipe@3 = gleam@http@response:new(200),
            _pipe@4 = gleam@http@response:set_header(
                _pipe@3,
                <<"content-type"/utf8>>,
                <<"text/html; charset=utf-8"/utf8>>
            ),
            gleam@http@response:set_body(
                _pipe@4,
                {text_data,
                    <<<<"<!doctype html><html lang=\"en\"><head><meta charset=\"UTF-8\" /><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, viewport-fit=cover\" /><title>Lumina</title><link rel=\"preconnect\" href=\"https://fontlay.com\" corossorigin /><link href=\"https://fontlay.com/css2?family=DM+Mono:ital,wght@0,300;0,400;0,500;1,300;1,400;1,500&family=Elms+Sans:ital,wght@0,100..900;1,100..900&family=Gantari:ital,wght@0,100..900;1,100..900&family=Josefin+Sans:ital,wght@0,100..700;1,100..700&family=Vend+Sans&display=swap\" rel=\"stylesheet\"><link	rel=\"stylesheet\" href=\"/static/lumina.css\"/><meta name=\"robots\" content=\"noai, noimageai, nofollow\"><script>window.clientHash = \""/utf8,
                            ((erlang:element(3, Handler_ctx)))/binary>>/binary,
                        "\";</script><script type=\"module\" src=\"/static/lumina.min.mjs\"></script></head><body id=\"app\"></body></html>"/utf8>>}
            );

        [] ->
            _pipe@3 = gleam@http@response:new(200),
            _pipe@4 = gleam@http@response:set_header(
                _pipe@3,
                <<"content-type"/utf8>>,
                <<"text/html; charset=utf-8"/utf8>>
            ),
            gleam@http@response:set_body(
                _pipe@4,
                {text_data,
                    <<<<"<!doctype html><html lang=\"en\"><head><meta charset=\"UTF-8\" /><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, viewport-fit=cover\" /><title>Lumina</title><link rel=\"preconnect\" href=\"https://fontlay.com\" corossorigin /><link href=\"https://fontlay.com/css2?family=DM+Mono:ital,wght@0,300;0,400;0,500;1,300;1,400;1,500&family=Elms+Sans:ital,wght@0,100..900;1,100..900&family=Gantari:ital,wght@0,100..900;1,100..900&family=Josefin+Sans:ital,wght@0,100..700;1,100..700&family=Vend+Sans&display=swap\" rel=\"stylesheet\"><link	rel=\"stylesheet\" href=\"/static/lumina.css\"/><meta name=\"robots\" content=\"noai, noimageai, nofollow\"><script>window.clientHash = \""/utf8,
                            ((erlang:element(3, Handler_ctx)))/binary>>/binary,
                        "\";</script><script type=\"module\" src=\"/static/lumina.min.mjs\"></script></head><body id=\"app\"></body></html>"/utf8>>}
            );

        [<<"static"/utf8>>, <<"lumina.min.mjs"/utf8>>] ->
            File = <<(erlang:element(4, Handler_ctx))/binary,
                "/static/lumina_client.min.mjs"/utf8>>,
            case ewe:file(File, none, none) of
                {error, _} ->
                    Httplogger(
                        error,
                        <<"Missing application assets."/utf8>>,
                        []
                    ),
                    _pipe@5 = gleam@http@response:new(500),
                    _pipe@6 = gleam@http@response:set_header(
                        _pipe@5,
                        <<"content-type"/utf8>>,
                        <<"text/plain; charset=utf-8"/utf8>>
                    ),
                    gleam@http@response:set_body(
                        _pipe@6,
                        {text_data, <<"500 Internal Server Error"/utf8>>}
                    );

                {ok, Outcome} ->
                    _pipe@7 = gleam@http@response:new(200),
                    _pipe@8 = gleam@http@response:set_header(
                        _pipe@7,
                        <<"content-type"/utf8>>,
                        <<"application/javascript; charset=utf-8"/utf8>>
                    ),
                    gleam@http@response:set_body(_pipe@8, Outcome)
            end;

        [<<"static"/utf8>>, <<"lumina.mjs"/utf8>>] ->
            File@1 = <<(erlang:element(4, Handler_ctx))/binary,
                "/static/lumina_client.mjs"/utf8>>,
            case ewe:file(File@1, none, none) of
                {error, _} ->
                    Httplogger(
                        error,
                        <<"Missing application assets."/utf8>>,
                        []
                    ),
                    _pipe@9 = gleam@http@response:new(500),
                    _pipe@10 = gleam@http@response:set_header(
                        _pipe@9,
                        <<"content-type"/utf8>>,
                        <<"text/plain; charset=utf-8"/utf8>>
                    ),
                    gleam@http@response:set_body(
                        _pipe@10,
                        {text_data, <<"500 Internal Server Error"/utf8>>}
                    );

                {ok, Outcome@1} ->
                    _pipe@11 = gleam@http@response:new(200),
                    _pipe@12 = gleam@http@response:set_header(
                        _pipe@11,
                        <<"content-type"/utf8>>,
                        <<"application/javascript; charset=utf-8"/utf8>>
                    ),
                    gleam@http@response:set_body(_pipe@12, Outcome@1)
            end;

        [<<"static"/utf8>>, <<"lumina.css"/utf8>>] ->
            File@2 = <<(erlang:element(4, Handler_ctx))/binary,
                "/static/lumina_client.css"/utf8>>,
            case ewe:file(File@2, none, none) of
                {error, _} ->
                    Httplogger(
                        error,
                        <<"Missing application assets."/utf8>>,
                        []
                    ),
                    _pipe@13 = gleam@http@response:new(500),
                    _pipe@14 = gleam@http@response:set_header(
                        _pipe@13,
                        <<"content-type"/utf8>>,
                        <<"text/plain; charset=utf-8"/utf8>>
                    ),
                    gleam@http@response:set_body(
                        _pipe@14,
                        {text_data, <<"500 Internal Server Error"/utf8>>}
                    );

                {ok, Outcome@2} ->
                    _pipe@15 = gleam@http@response:new(200),
                    _pipe@16 = gleam@http@response:set_header(
                        _pipe@15,
                        <<"content-type"/utf8>>,
                        <<"text/css; charset=utf-8"/utf8>>
                    ),
                    gleam@http@response:set_body(_pipe@16, Outcome@2)
            end;

        [<<"static"/utf8>>, Staticfile] ->
            File@3 = <<<<(erlang:element(4, Handler_ctx))/binary,
                    "/static/"/utf8>>/binary,
                Staticfile/binary>>,
            case ewe:file(File@3, none, none) of
                {error, _} ->
                    Httplogger(
                        warning,
                        <<"Not found."/utf8>>,
                        [{<<"file"/utf8>>, File@3}]
                    ),
                    _pipe@17 = gleam@http@response:new(404),
                    _pipe@18 = gleam@http@response:set_header(
                        _pipe@17,
                        <<"content-type"/utf8>>,
                        <<"text/plain; charset=utf-8"/utf8>>
                    ),
                    gleam@http@response:set_body(
                        _pipe@18,
                        {text_data, <<"404! Not found!"/utf8>>}
                    );

                {ok, Outcome@3} ->
                    _pipe@19 = gleam@http@response:new(200),
                    gleam@http@response:set_body(_pipe@19, Outcome@3)
            end;

        _ ->
            Httplogger(warning, <<"Not found."/utf8>>, []),
            _pipe@20 = gleam@http@response:new(404),
            _pipe@21 = gleam@http@response:set_header(
                _pipe@20,
                <<"content-type"/utf8>>,
                <<"text/plain; charset=utf-8"/utf8>>
            ),
            gleam@http@response:set_body(
                _pipe@21,
                {text_data, <<"404! Not found!"/utf8>>}
            )
    end.

-file("src/lumina_server.gleam", 19).
-spec main() -> nil.
main() ->
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
            woof:configure({config, debug, text, auto}),
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
                            line => 46})
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
                            line => 61});

                {ok, Outcome@1} ->
                    _pipe@2 = Setuplog,
                    woof:log(
                        _pipe@2,
                        info,
                        <<"Found client revision!"/utf8>>,
                        [{<<"revision"/utf8>>, Outcome@1}]
                    ),
                    Outcome@1
            end,
            case begin
                _pipe@3 = ewe:new(
                    fun(_capture) ->
                        handler(
                            _capture,
                            {handler_context, Db, Client_hash, Assets}
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
                                line => 70,
                                value => _assert_fail,
                                start => 1771,
                                'end' => 2046,
                                pattern_start => 1782,
                                pattern_end => 1787})
            end,
            gleam_erlang_ffi:sleep_forever()
        end
    ).
