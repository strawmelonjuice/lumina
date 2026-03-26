-module(parrot).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/parrot.gleam").
-export([main/0]).

-file("src/parrot.gleam", 58).
-spec cmd_gen(parrot@internal@sqlc:engine(), binary()) -> {ok, nil} |
    {error, parrot@internal@errors:parrot_error()}.
cmd_gen(Engine, Db) ->
    Db@4 = case Db of
        <<"sqlite://"/utf8, Db@1/binary>> ->
            Db@1;

        <<"sqlite:"/utf8, Db@2/binary>> ->
            Db@2;

        Db@3 ->
            Db@3
    end,
    Files = parrot@internal@lib:walk(parrot@internal@project:src()),
    Queries = begin
        _pipe = Files,
        _pipe@1 = maps:to_list(_pipe),
        _pipe@2 = gleam@list:map(
            _pipe@1,
            fun(File) ->
                {_, Files@1} = File,
                gleam@list:map(
                    Files@1,
                    fun(File@1) ->
                        File@2 = case File@1 of
                            <<"./"/utf8, Rest/binary>> ->
                                Rest;

                            X ->
                                X
                        end,
                        filepath:join(<<"../.."/utf8>>, File@2)
                    end
                )
            end
        ),
        lists:append(_pipe@2)
    end,
    Sqlc_binary = parrot@internal@sqlc:sqlc_binary_path(),
    Sqlc_dir = filepath:directory_name(Sqlc_binary),
    Schema_file = filepath:join(Sqlc_dir, <<"schema.sql"/utf8>>),
    Sqlc_file = filepath:join(Sqlc_dir, <<"sqlc.json"/utf8>>),
    Queries_file = filepath:join(Sqlc_dir, <<"queries.json"/utf8>>),
    _ = simplifile:create_directory_all(Sqlc_dir),
    Spinner = begin
        _pipe@3 = parrot@internal@spinner:new(
            <<"downloading sqlc binary"/utf8>>
        ),
        parrot@internal@spinner:start(_pipe@3)
    end,
    _ = case parrot@internal@sqlc:download_binary() of
        {error, _} ->
            parrot@internal@spinner:complete_current(
                Spinner,
                parrot@internal@spinner:orange_warning()
            );

        {ok, _} ->
            parrot@internal@spinner:complete_current(
                Spinner,
                parrot@internal@spinner:green_checkmark()
            )
    end,
    Spinner@1 = begin
        _pipe@4 = parrot@internal@spinner:new(<<"verifying sqlc binary"/utf8>>),
        parrot@internal@spinner:start(_pipe@4)
    end,
    _ = case parrot@internal@sqlc:verify_binary() of
        {error, _} ->
            parrot@internal@spinner:complete_current(
                Spinner@1,
                parrot@internal@spinner:orange_warning()
            );

        {ok, _} ->
            parrot@internal@spinner:complete_current(
                Spinner@1,
                parrot@internal@spinner:green_checkmark()
            )
    end,
    Sqlc_json = parrot@internal@sqlc:gen_sqlc_json(Engine, Queries),
    _ = simplifile:write(Sqlc_file, Sqlc_json),
    Spinner@2 = begin
        _pipe@5 = parrot@internal@spinner:new(<<"fetching schema"/utf8>>),
        parrot@internal@spinner:start(_pipe@5)
    end,
    gleam@result:'try'(case Engine of
            my_s_q_l ->
                gleam@result:'try'(
                    parrot@internal@db:fetch_schema_mysql(Db@4),
                    fun(Schema) -> {ok, Schema} end
                );

            postgre_s_q_l ->
                gleam@result:'try'(
                    parrot@internal@db:fetch_schema_postgresql(Db@4),
                    fun(Schema@1) ->
                        Schema@2 = begin
                            _pipe@6 = Schema@1,
                            _pipe@7 = gleam@string:split(_pipe@6, <<"\n"/utf8>>),
                            _pipe@8 = gleam@list:filter(
                                _pipe@7,
                                fun(Line) ->
                                    not gleam_stdlib:string_starts_with(
                                        Line,
                                        <<"\\restrict"/utf8>>
                                    )
                                    andalso not gleam_stdlib:string_starts_with(
                                        Line,
                                        <<"\\unrestrict"/utf8>>
                                    )
                                end
                            ),
                            gleam@string:join(_pipe@8, <<"\n"/utf8>>)
                        end,
                        {ok, Schema@2}
                    end
                );

            s_q_lite ->
                gleam@result:'try'(
                    parrot@internal@db:fetch_schema_sqlite(Db@4),
                    fun(Schema@3) ->
                        Sql = gleam@string:trim(Schema@3),
                        {ok, Sql}
                    end
                )
        end, fun(Schema_sql) ->
            _ = simplifile:write(Schema_file, Schema_sql),
            parrot@internal@spinner:complete_current(
                Spinner@2,
                parrot@internal@spinner:green_checkmark()
            ),
            Spinner@3 = begin
                _pipe@9 = parrot@internal@spinner:new(
                    <<"generating gleam code"/utf8>>
                ),
                parrot@internal@spinner:start(_pipe@9)
            end,
            Gen_result = parrot@internal@shellout:command(
                <<"./sqlc"/utf8>>,
                [<<"generate"/utf8>>, <<"--file"/utf8>>, <<"sqlc.json"/utf8>>],
                Sqlc_dir,
                []
            ),
            gleam@result:'try'(case Gen_result of
                    {ok, _} ->
                        {ok, nil};

                    {error, Error} ->
                        {_, Error@1} = Error,
                        {error, {sqlc_generate_error, Error@1}}
                end, fun(_) ->
                    Project_name = parrot@internal@project:project_name(),
                    Config = {config,
                        Queries_file,
                        <<Project_name/binary, "/sql.gleam"/utf8>>},
                    gleam@result:'try'(
                        parrot@internal@codegen:codegen_from_config(Config),
                        fun(Gen_result@1) ->
                            parrot@internal@spinner:complete_current(
                                Spinner@3,
                                parrot@internal@spinner:green_checkmark()
                            ),
                            Spinner@4 = begin
                                _pipe@10 = parrot@internal@spinner:new(
                                    <<"formatting generated code"/utf8>>
                                ),
                                parrot@internal@spinner:start(_pipe@10)
                            end,
                            Output_path = filepath:join(
                                parrot@internal@project:src(),
                                <<Project_name/binary, "/sql.gleam"/utf8>>
                            ),
                            Stdout_format = parrot@internal@shellout:command(
                                <<"gleam"/utf8>>,
                                [<<"format"/utf8>>, Output_path],
                                parrot@internal@project:root(),
                                []
                            ),
                            gleam@result:'try'(case Stdout_format of
                                    {ok, _} ->
                                        {ok, nil};

                                    {error, Error@2} ->
                                        {_, Error@3} = Error@2,
                                        {error, {gleam_format_error, Error@3}}
                                end, fun(_) ->
                                    parrot@internal@spinner:complete_current(
                                        Spinner@4,
                                        parrot@internal@spinner:green_checkmark(
                                            
                                        )
                                    ),
                                    _pipe@11 = erlang:element(2, Gen_result@1),
                                    _pipe@12 = gleam@list:unique(_pipe@11),
                                    gleam@list:each(
                                        _pipe@12,
                                        fun(Unknown) ->
                                            gleam_stdlib:println(
                                                parrot@internal@lib:yellow(
                                                    <<"unknown column type: "/utf8,
                                                        Unknown/binary>>
                                                )
                                            )
                                        end
                                    ),
                                    gleam_stdlib:println(<<""/utf8>>),
                                    {ok, nil}
                                end)
                        end
                    )
                end)
        end).

-file("src/parrot.gleam", 20).
-spec main() -> nil.
main() ->
    Cmd = case erlang:element(4, argv:load()) of
        [] ->
            _pipe = parrot@internal@cli:parse_env(<<"DATABASE_URL"/utf8>>),
            gleam@result:map(
                _pipe,
                fun(A) ->
                    {generate, erlang:element(1, A), erlang:element(2, A)}
                end
            );

        [<<"--env-var"/utf8>>, Env] ->
            _pipe@1 = parrot@internal@cli:parse_env(Env),
            gleam@result:map(
                _pipe@1,
                fun(A@1) ->
                    {generate, erlang:element(1, A@1), erlang:element(2, A@1)}
                end
            );

        [<<"-e"/utf8>>, Env@1] ->
            _pipe@2 = parrot@internal@cli:parse_env(Env@1),
            gleam@result:map(
                _pipe@2,
                fun(A@2) ->
                    {generate, erlang:element(1, A@2), erlang:element(2, A@2)}
                end
            );

        [<<"--sqlite"/utf8>>, File_path] ->
            {ok, {generate, s_q_lite, File_path}};

        [<<"help"/utf8>>] ->
            {ok, usage};

        _ ->
            {ok, usage}
    end,
    case Cmd of
        {error, E} ->
            gleam_stdlib:println(
                parrot@internal@lib:red(<<"Error: "/utf8, E/binary>>)
            );

        {ok, Cmd@1} ->
            case Cmd@1 of
                usage ->
                    gleam_stdlib:println(
                        <<"
  🦜 Parrot - type-safe SQL in gleam for sqlite, postgresql & mysql

  USAGE:
    gleam run -m parrot -- [OPTIONS]
    gleam run -m parrot help

  DESCRIPTION:
    This tool generates type-safe Gleam code from your raw SQL queries.
    It connects to your database to introspect schemas and validate queries,
    then generates Gleam functions that you can use in your application.

    By default, it automatically detects your database driver (PostgreSQL,
    MySQL, or SQLite) by reading the DATABASE_URL environment variable.

  OPTIONS:
    --sqlite <FILE_PATH>
      Directly specify the path to a SQLite database file. When this
      option is used, it bypasses the DATABASE_URL environment
      variable entirely.

    -e, --env-var <VAR_NAME>
      Specify the name of an alternative environment variable to use
      for the database connection URL.
      Defaults to 'DATABASE_URL'.

  DATABASE_URL:
    Parrot automatically detects the driver from the URL scheme.

    Formats:
    - PostgreSQL: postgres://user:password@host:port/dbname
    - MySQL:      mysql://user:password@host:port/dbname
    - SQLite:     file:/path/to/your/database.db

  EXAMPLES:
    # 1. The default: run with a DATABASE_URL environment variable set.
    $ export DATABASE_URL=\"postgres://user:pass@localhost/mydb\"
    $ gleam run -m parrot

    # 2. Using Sqlite: directly point to a database file.
    $ gleam run -m parrot -- --sqlite ./priv/app.db

    # 3. Different environment variable
    $ export STAGING_DB_URL=\"mysql://staging:pass@remote/db\"
    $ gleam run -m parrot -- --env-var STAGING_DB_URL

    # 4. Get help
    $ gleam run -m parrot help
"/utf8>>
                    );

                {generate, Engine, Db} ->
                    Result = cmd_gen(Engine, Db),
                    case Result of
                        {error, E@1} ->
                            gleam_stdlib:println(
                                parrot@internal@lib:red(
                                    <<"\nError: "/utf8,
                                        (parrot@internal@errors:err_to_string(
                                            E@1
                                        ))/binary>>
                                )
                            );

                        {ok, _} ->
                            gleam_stdlib:println(
                                parrot@internal@lib:green(
                                    <<"SQL successfully generated!"/utf8>>
                                )
                            )
                    end
            end
    end.
