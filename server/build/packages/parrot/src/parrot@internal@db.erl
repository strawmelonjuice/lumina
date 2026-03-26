-module(parrot@internal@db).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/parrot/internal/db.gleam").
-export([fetch_schema_mysql/1, fetch_schema_postgresql/1, fetch_schema_sqlite/1]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-file("src/parrot/internal/db.gleam", 10).
?DOC(false).
-spec fetch_schema_mysql(binary()) -> {ok, binary()} |
    {error, parrot@internal@errors:parrot_error()}.
fetch_schema_mysql(Db) ->
    Conn@1 = case gleam_stdlib:uri_parse(Db) of
        {ok, Conn} -> Conn;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"parrot/internal/db"/utf8>>,
                        function => <<"fetch_schema_mysql"/utf8>>,
                        line => 11,
                        value => _assert_fail,
                        start => 255,
                        'end' => 290,
                        pattern_start => 266,
                        pattern_end => 274})
    end,
    Creds = case erlang:element(3, Conn@1) of
        none ->
            none;

        {some, Userinfo} ->
            case gleam@string:split(Userinfo, <<":"/utf8>>) of
                [User] ->
                    {some, {User, <<""/utf8>>}};

                [User@1, Pass] ->
                    {some, {User@1, Pass}};

                _ ->
                    none
            end
    end,
    gleam@result:'try'(
        gleam@option:to_result(Creds, {my_sql_d_b_not_found, <<""/utf8>>}),
        fun(_use0) ->
            {User@2, Pass@1} = _use0,
            Port@1 = case erlang:element(5, Conn@1) of
                none ->
                    <<"3306"/utf8>>;

                {some, Port} ->
                    erlang:integer_to_binary(Port)
            end,
            Host@1 = case erlang:element(4, Conn@1) of
                none ->
                    <<"localhost"/utf8>>;

                {some, Host} ->
                    Host
            end,
            Db@1 = gleam@string:replace(
                erlang:element(6, Conn@1),
                <<"/"/utf8>>,
                <<""/utf8>>
            ),
            gleam@result:'try'(
                begin
                    _pipe = parrot@internal@shellout:command(
                        <<"mysqldump"/utf8>>,
                        [<<"--no-data"/utf8>>,
                            <<"-u"/utf8>>,
                            User@2,
                            <<"-p"/utf8, Pass@1/binary>>,
                            <<"-h"/utf8>>,
                            Host@1,
                            <<"-P"/utf8>>,
                            Port@1,
                            Db@1],
                        <<"."/utf8>>,
                        []
                    ),
                    gleam@result:replace_error(_pipe, mysqldump_error)
                end,
                fun(Out) -> _pipe@1 = Out,
                    _pipe@2 = gleam@string:split(_pipe@1, <<"\n"/utf8>>),
                    _pipe@3 = gleam@list:filter(
                        _pipe@2,
                        fun(Line) ->
                            gleam_stdlib:contains_string(
                                Line,
                                <<"mysqldump:"/utf8>>
                            )
                            =:= false
                        end
                    ),
                    _pipe@4 = gleam@string:join(_pipe@3, <<"\n"/utf8>>),
                    {ok, _pipe@4} end
            )
        end
    ).

-file("src/parrot/internal/db.gleam", 56).
?DOC(false).
-spec fetch_schema_postgresql(binary()) -> {ok, binary()} |
    {error, parrot@internal@errors:parrot_error()}.
fetch_schema_postgresql(Db) ->
    _pipe = parrot@internal@shellout:command(
        <<"pg_dump"/utf8>>,
        [<<"--no-privileges"/utf8>>,
            <<"--no-acl"/utf8>>,
            <<"--no-owner"/utf8>>,
            <<"--schema-only"/utf8>>,
            <<"--no-comments"/utf8>>,
            <<"--encoding=utf8"/utf8>>,
            Db],
        <<"."/utf8>>,
        []
    ),
    gleam@result:map_error(
        _pipe,
        fun(E) ->
            {_, Err} = E,
            {pgdump_error, Err}
        end
    ).

-file("src/parrot/internal/db.gleam", 77).
?DOC(false).
-spec fetch_schema_sqlite(binary()) -> {ok, binary()} |
    {error, parrot@internal@errors:parrot_error()}.
fetch_schema_sqlite(Db) ->
    _pipe = parrot@internal@shellout:command(
        <<"sqlite3"/utf8>>,
        [Db, <<".schema"/utf8>>],
        <<"."/utf8>>,
        []
    ),
    gleam@result:replace_error(_pipe, {sqlite_d_b_not_found, <<""/utf8>>}).
