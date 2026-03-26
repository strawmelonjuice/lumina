-module(pog).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch]).
-define(FILEPATH, "src/pog.gleam").
-export([named_connection/1, host/2, port/2, database/2, user/2, password/2, ssl/2, connection_parameter/3, pool_size/2, queue_target/2, queue_interval/2, idle_interval/2, trace/2, ip_version/2, rows_as_map/2, start/1, supervised/1, null/0, bool/1, int/1, float/1, text/1, bytea/1, array/2, timestamp/1, timestamp_decoder/0, calendar_date/1, calendar_time_of_day/1, nullable/2, transaction/2, 'query'/1, returning/2, parameter/2, timeout/2, execute/2, error_code_name/1, calendar_date_decoder/0, calendar_time_of_day_decoder/0, numeric_decoder/0, default_config/1, url_config/2]).
-export_type([connection/0, single_connection/0, message/0, config/0, ssl/0, ip_version/0, value/0, transaction_error/1, returned/1, query_error/0, 'query'/1]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " Postgresql client\n"
    "\n"
    " Gleam wrapper around pgo library\n"
).

-opaque connection() :: {pool, gleam@erlang@process:name(message())} |
    {single_connection, single_connection()}.

-type single_connection() :: any().

-type message() :: any().

-type config() :: {config,
        gleam@erlang@process:name(message()),
        binary(),
        integer(),
        binary(),
        binary(),
        gleam@option:option(binary()),
        ssl(),
        list({binary(), binary()}),
        integer(),
        integer(),
        integer(),
        integer(),
        boolean(),
        ip_version(),
        boolean()}.

-type ssl() :: ssl_verified | ssl_unverified | ssl_disabled.

-type ip_version() :: ipv4 | ipv6.

-type value() :: any().

-type transaction_error(FSH) :: {transaction_query_error, query_error()} |
    {transaction_rolled_back, FSH}.

-type returned(FSI) :: {returned, integer(), list(FSI)}.

-type query_error() :: {constraint_violated, binary(), binary(), binary()} |
    {postgresql_error, binary(), binary(), binary()} |
    {unexpected_argument_count, integer(), integer()} |
    {unexpected_argument_type, binary(), binary()} |
    {unexpected_result_type, list(gleam@dynamic@decode:decode_error())} |
    query_timeout |
    connection_unavailable.

-opaque 'query'(FSJ) :: {'query',
        binary(),
        list(value()),
        gleam@dynamic@decode:decoder(FSJ),
        integer()}.

-file("src/pog.gleam", 41).
?DOC(
    " Create a reference to a pool using the pool's name.\n"
    "\n"
    " If no pool has been started using this name then queries using this\n"
    " connection will fail.\n"
).
-spec named_connection(gleam@erlang@process:name(message())) -> connection().
named_connection(Name) ->
    {pool, Name}.

-file("src/pog.gleam", 112).
?DOC(
    " Database server hostname.\n"
    "\n"
    " (default: 127.0.0.1)\n"
).
-spec host(config(), binary()) -> config().
host(Config, Host) ->
    {config,
        erlang:element(2, Config),
        Host,
        erlang:element(4, Config),
        erlang:element(5, Config),
        erlang:element(6, Config),
        erlang:element(7, Config),
        erlang:element(8, Config),
        erlang:element(9, Config),
        erlang:element(10, Config),
        erlang:element(11, Config),
        erlang:element(12, Config),
        erlang:element(13, Config),
        erlang:element(14, Config),
        erlang:element(15, Config),
        erlang:element(16, Config)}.

-file("src/pog.gleam", 119).
?DOC(
    " Port the server is listening on.\n"
    "\n"
    " (default: 5432)\n"
).
-spec port(config(), integer()) -> config().
port(Config, Port) ->
    {config,
        erlang:element(2, Config),
        erlang:element(3, Config),
        Port,
        erlang:element(5, Config),
        erlang:element(6, Config),
        erlang:element(7, Config),
        erlang:element(8, Config),
        erlang:element(9, Config),
        erlang:element(10, Config),
        erlang:element(11, Config),
        erlang:element(12, Config),
        erlang:element(13, Config),
        erlang:element(14, Config),
        erlang:element(15, Config),
        erlang:element(16, Config)}.

-file("src/pog.gleam", 124).
?DOC(" Name of database to use.\n").
-spec database(config(), binary()) -> config().
database(Config, Database) ->
    {config,
        erlang:element(2, Config),
        erlang:element(3, Config),
        erlang:element(4, Config),
        Database,
        erlang:element(6, Config),
        erlang:element(7, Config),
        erlang:element(8, Config),
        erlang:element(9, Config),
        erlang:element(10, Config),
        erlang:element(11, Config),
        erlang:element(12, Config),
        erlang:element(13, Config),
        erlang:element(14, Config),
        erlang:element(15, Config),
        erlang:element(16, Config)}.

-file("src/pog.gleam", 129).
?DOC(" Username to connect to database as.\n").
-spec user(config(), binary()) -> config().
user(Config, User) ->
    {config,
        erlang:element(2, Config),
        erlang:element(3, Config),
        erlang:element(4, Config),
        erlang:element(5, Config),
        User,
        erlang:element(7, Config),
        erlang:element(8, Config),
        erlang:element(9, Config),
        erlang:element(10, Config),
        erlang:element(11, Config),
        erlang:element(12, Config),
        erlang:element(13, Config),
        erlang:element(14, Config),
        erlang:element(15, Config),
        erlang:element(16, Config)}.

-file("src/pog.gleam", 134).
?DOC(" Password for the user.\n").
-spec password(config(), gleam@option:option(binary())) -> config().
password(Config, Password) ->
    {config,
        erlang:element(2, Config),
        erlang:element(3, Config),
        erlang:element(4, Config),
        erlang:element(5, Config),
        erlang:element(6, Config),
        Password,
        erlang:element(8, Config),
        erlang:element(9, Config),
        erlang:element(10, Config),
        erlang:element(11, Config),
        erlang:element(12, Config),
        erlang:element(13, Config),
        erlang:element(14, Config),
        erlang:element(15, Config),
        erlang:element(16, Config)}.

-file("src/pog.gleam", 141).
?DOC(
    " Whether to use SSL or not.\n"
    "\n"
    " (default: False)\n"
).
-spec ssl(config(), ssl()) -> config().
ssl(Config, Ssl) ->
    {config,
        erlang:element(2, Config),
        erlang:element(3, Config),
        erlang:element(4, Config),
        erlang:element(5, Config),
        erlang:element(6, Config),
        erlang:element(7, Config),
        Ssl,
        erlang:element(9, Config),
        erlang:element(10, Config),
        erlang:element(11, Config),
        erlang:element(12, Config),
        erlang:element(13, Config),
        erlang:element(14, Config),
        erlang:element(15, Config),
        erlang:element(16, Config)}.

-file("src/pog.gleam", 147).
?DOC(
    " Any Postgres connection parameter here, such as\n"
    " `\"application_name: myappname\"` and `\"timezone: GMT\"`\n"
).
-spec connection_parameter(config(), binary(), binary()) -> config().
connection_parameter(Config, Name, Value) ->
    {config,
        erlang:element(2, Config),
        erlang:element(3, Config),
        erlang:element(4, Config),
        erlang:element(5, Config),
        erlang:element(6, Config),
        erlang:element(7, Config),
        erlang:element(8, Config),
        [{Name, Value} | erlang:element(9, Config)],
        erlang:element(10, Config),
        erlang:element(11, Config),
        erlang:element(12, Config),
        erlang:element(13, Config),
        erlang:element(14, Config),
        erlang:element(15, Config),
        erlang:element(16, Config)}.

-file("src/pog.gleam", 161).
?DOC(
    " Number of connections to keep open with the database\n"
    "\n"
    " default: 10\n"
).
-spec pool_size(config(), integer()) -> config().
pool_size(Config, Pool_size) ->
    {config,
        erlang:element(2, Config),
        erlang:element(3, Config),
        erlang:element(4, Config),
        erlang:element(5, Config),
        erlang:element(6, Config),
        erlang:element(7, Config),
        erlang:element(8, Config),
        erlang:element(9, Config),
        Pool_size,
        erlang:element(11, Config),
        erlang:element(12, Config),
        erlang:element(13, Config),
        erlang:element(14, Config),
        erlang:element(15, Config),
        erlang:element(16, Config)}.

-file("src/pog.gleam", 171).
?DOC(
    " Checking out connections is handled through a queue. If it\n"
    " takes longer than queue_target to get out of the queue for longer than\n"
    " queue_interval then the queue_target will be doubled and checkouts will\n"
    " start to be dropped if that target is surpassed.\n"
    "\n"
    " default: 50\n"
).
-spec queue_target(config(), integer()) -> config().
queue_target(Config, Queue_target) ->
    {config,
        erlang:element(2, Config),
        erlang:element(3, Config),
        erlang:element(4, Config),
        erlang:element(5, Config),
        erlang:element(6, Config),
        erlang:element(7, Config),
        erlang:element(8, Config),
        erlang:element(9, Config),
        erlang:element(10, Config),
        Queue_target,
        erlang:element(12, Config),
        erlang:element(13, Config),
        erlang:element(14, Config),
        erlang:element(15, Config),
        erlang:element(16, Config)}.

-file("src/pog.gleam", 181).
?DOC(
    " Checking out connections is handled through a queue. If it\n"
    " takes longer than queue_target to get out of the queue for longer than\n"
    " queue_interval then the queue_target will be doubled and checkouts will\n"
    " start to be dropped if that target is surpassed.\n"
    "\n"
    " default: 1000\n"
).
-spec queue_interval(config(), integer()) -> config().
queue_interval(Config, Queue_interval) ->
    {config,
        erlang:element(2, Config),
        erlang:element(3, Config),
        erlang:element(4, Config),
        erlang:element(5, Config),
        erlang:element(6, Config),
        erlang:element(7, Config),
        erlang:element(8, Config),
        erlang:element(9, Config),
        erlang:element(10, Config),
        erlang:element(11, Config),
        Queue_interval,
        erlang:element(13, Config),
        erlang:element(14, Config),
        erlang:element(15, Config),
        erlang:element(16, Config)}.

-file("src/pog.gleam", 188).
?DOC(
    " The database is pinged every idle_interval when the connection is idle.\n"
    "\n"
    " default: 1000\n"
).
-spec idle_interval(config(), integer()) -> config().
idle_interval(Config, Idle_interval) ->
    {config,
        erlang:element(2, Config),
        erlang:element(3, Config),
        erlang:element(4, Config),
        erlang:element(5, Config),
        erlang:element(6, Config),
        erlang:element(7, Config),
        erlang:element(8, Config),
        erlang:element(9, Config),
        erlang:element(10, Config),
        erlang:element(11, Config),
        erlang:element(12, Config),
        Idle_interval,
        erlang:element(14, Config),
        erlang:element(15, Config),
        erlang:element(16, Config)}.

-file("src/pog.gleam", 198).
?DOC(
    " Trace pgo is instrumented with [OpenTelemetry][1] and\n"
    " when this option is true a span will be created (if sampled).\n"
    "\n"
    " default: False\n"
    "\n"
    " [1]: https://opentelemetry.io\n"
).
-spec trace(config(), boolean()) -> config().
trace(Config, Trace) ->
    {config,
        erlang:element(2, Config),
        erlang:element(3, Config),
        erlang:element(4, Config),
        erlang:element(5, Config),
        erlang:element(6, Config),
        erlang:element(7, Config),
        erlang:element(8, Config),
        erlang:element(9, Config),
        erlang:element(10, Config),
        erlang:element(11, Config),
        erlang:element(12, Config),
        erlang:element(13, Config),
        Trace,
        erlang:element(15, Config),
        erlang:element(16, Config)}.

-file("src/pog.gleam", 203).
?DOC(" Which internet protocol to use for this connection\n").
-spec ip_version(config(), ip_version()) -> config().
ip_version(Config, Ip_version) ->
    {config,
        erlang:element(2, Config),
        erlang:element(3, Config),
        erlang:element(4, Config),
        erlang:element(5, Config),
        erlang:element(6, Config),
        erlang:element(7, Config),
        erlang:element(8, Config),
        erlang:element(9, Config),
        erlang:element(10, Config),
        erlang:element(11, Config),
        erlang:element(12, Config),
        erlang:element(13, Config),
        erlang:element(14, Config),
        Ip_version,
        erlang:element(16, Config)}.

-file("src/pog.gleam", 209).
?DOC(
    " By default, pgo will return a n-tuple, in the order of the query.\n"
    " By setting `rows_as_map` to `True`, the result will be `Dict`.\n"
).
-spec rows_as_map(config(), boolean()) -> config().
rows_as_map(Config, Rows_as_map) ->
    {config,
        erlang:element(2, Config),
        erlang:element(3, Config),
        erlang:element(4, Config),
        erlang:element(5, Config),
        erlang:element(6, Config),
        erlang:element(7, Config),
        erlang:element(8, Config),
        erlang:element(9, Config),
        erlang:element(10, Config),
        erlang:element(11, Config),
        erlang:element(12, Config),
        erlang:element(13, Config),
        erlang:element(14, Config),
        erlang:element(15, Config),
        Rows_as_map}.

-file("src/pog.gleam", 291).
?DOC(" Expects `userinfo` as `\"username\"` or `\"username:password\"`. Fails otherwise.\n").
-spec extract_user_password(binary()) -> {ok,
        {binary(), gleam@option:option(binary())}} |
    {error, nil}.
extract_user_password(Userinfo) ->
    case gleam@string:split(Userinfo, <<":"/utf8>>) of
        [User] ->
            {ok, {User, none}};

        [User@1, Password] ->
            {ok, {User@1, {some, Password}}};

        _ ->
            {error, nil}
    end.

-file("src/pog.gleam", 311).
?DOC(
    " Expects `sslmode` to be `require`, `verify-ca`, `verify-full` or `disable`.\n"
    "\n"
    " If `sslmode` is set, but not one of those value, fails.\n"
    "\n"
    " If `sslmode` is `verify-ca` or `verify-full`, returns `SslVerified`.\n"
    "\n"
    " If `sslmode` is `require`, returns `SslUnverified`.\n"
    "\n"
    " If `sslmode` is unset, returns `SslDisabled`.\n"
).
-spec extract_ssl_mode(gleam@option:option(binary())) -> {ok, ssl()} |
    {error, nil}.
extract_ssl_mode(Query) ->
    case Query of
        none ->
            {ok, ssl_disabled};

        {some, Query@1} ->
            gleam@result:'try'(
                gleam_stdlib:parse_query(Query@1),
                fun(Query@2) ->
                    gleam@result:'try'(
                        gleam@list:key_find(Query@2, <<"sslmode"/utf8>>),
                        fun(Sslmode) -> case Sslmode of
                                <<"require"/utf8>> ->
                                    {ok, ssl_unverified};

                                <<"verify-ca"/utf8>> ->
                                    {ok, ssl_verified};

                                <<"verify-full"/utf8>> ->
                                    {ok, ssl_verified};

                                <<"disable"/utf8>> ->
                                    {ok, ssl_disabled};

                                _ ->
                                    {error, nil}
                            end end
                    )
                end
            )
    end.

-file("src/pog.gleam", 336).
?DOC(
    " Start a database connection pool. Most the time you want to use\n"
    " `supervised` and add the pool to your supervision tree instead of using this\n"
    " function directly.\n"
    "\n"
    " The pool is started in a new process and will asynchronously connect to the\n"
    " PostgreSQL instance specified in the config. If the configuration is invalid\n"
    " or it cannot connect for another reason it will continue to attempt to\n"
    " connect, and any queries made using the connection pool will fail.\n"
).
-spec start(config()) -> {ok, gleam@otp@actor:started(connection())} |
    {error, gleam@otp@actor:start_error()}.
start(Config) ->
    case pog_ffi:start(Config) of
        {ok, Pid} ->
            {ok, {started, Pid, {pool, erlang:element(2, Config)}}};

        {error, Reason} ->
            {error, {init_exited, {abnormal, Reason}}}
    end.

-file("src/pog.gleam", 357).
?DOC(
    " Start a database connection pool by adding it to your supervision tree.\n"
    "\n"
    " Use the `named_connection` function to create a connection to query this\n"
    " pool with if your supervisor does not pass back the return value of\n"
    " creating the pool.\n"
    "\n"
    " The pool is started in a new process and will asynchronously connect to the\n"
    " PostgreSQL instance specified in the config. If the configuration is invalid\n"
    " or it cannot connect for another reason it will continue to attempt to\n"
    " connect, and any queries made using the connection pool will fail.\n"
).
-spec supervised(config()) -> gleam@otp@supervision:child_specification(connection()).
supervised(Config) ->
    gleam@otp@supervision:supervisor(fun() -> start(Config) end).

-file("src/pog.gleam", 366).
-spec null() -> value().
null() ->
    pog_ffi:null().

-file("src/pog.gleam", 369).
-spec bool(boolean()) -> value().
bool(A) ->
    pog_ffi:coerce(A).

-file("src/pog.gleam", 372).
-spec int(integer()) -> value().
int(A) ->
    pog_ffi:coerce(A).

-file("src/pog.gleam", 375).
-spec float(float()) -> value().
float(A) ->
    pog_ffi:coerce(A).

-file("src/pog.gleam", 378).
-spec text(binary()) -> value().
text(A) ->
    pog_ffi:coerce(A).

-file("src/pog.gleam", 381).
-spec bytea(bitstring()) -> value().
bytea(A) ->
    pog_ffi:coerce(A).

-file("src/pog.gleam", 383).
-spec array(fun((FTA) -> value()), list(FTA)) -> value().
array(Converter, Values) ->
    _pipe = gleam@list:map(Values, Converter),
    pog_ffi:coerce(_pipe).

-file("src/pog.gleam", 388).
-spec timestamp(gleam@time@timestamp:timestamp()) -> value().
timestamp(Timestamp) ->
    {Seconds, Nanoseconds} = gleam@time@timestamp:to_unix_seconds_and_nanoseconds(
        Timestamp
    ),
    pog_ffi:coerce((Seconds * 1000000) + (Nanoseconds div 1000)).

-file("src/pog.gleam", 394).
-spec timestamp_decoder() -> gleam@dynamic@decode:decoder(gleam@time@timestamp:timestamp()).
timestamp_decoder() ->
    gleam@dynamic@decode:map(
        {decoder, fun gleam@dynamic@decode:decode_int/1},
        fun(Microseconds) ->
            Seconds = Microseconds div 1000000,
            Nanoseconds = (Microseconds rem 1000000) * 1000,
            gleam@time@timestamp:from_unix_seconds_and_nanoseconds(
                Seconds,
                Nanoseconds
            )
        end
    ).

-file("src/pog.gleam", 401).
-spec calendar_date(gleam@time@calendar:date()) -> value().
calendar_date(Date) ->
    Month = gleam@time@calendar:month_to_int(erlang:element(3, Date)),
    pog_ffi:coerce({erlang:element(2, Date), Month, erlang:element(4, Date)}).

-file("src/pog.gleam", 406).
-spec calendar_time_of_day(gleam@time@calendar:time_of_day()) -> value().
calendar_time_of_day(Time) ->
    Seconds = erlang:float(erlang:element(4, Time)),
    Seconds@1 = Seconds + (erlang:float(erlang:element(5, Time)) / 1000000000.0),
    pog_ffi:coerce(
        {erlang:element(2, Time), erlang:element(3, Time), Seconds@1}
    ).

-file("src/pog.gleam", 489).
-spec nullable(fun((FTV) -> value()), gleam@option:option(FTV)) -> value().
nullable(Inner_type, Value) ->
    case Value of
        {some, Term} ->
            Inner_type(Term);

        none ->
            pog_ffi:null()
    end.

-file("src/pog.gleam", 449).
-spec transaction_layer(
    single_connection(),
    fun((connection()) -> {ok, FTL} | {error, FTM})
) -> {ok, FTL} | {error, transaction_error(FTM)}.
transaction_layer(Conn, Callback) ->
    Do = fun(Conn@1, Sql) -> _pipe = pog_ffi:query_extended(Conn@1, Sql),
        gleam@result:map_error(
            _pipe,
            fun(Field@0) -> {transaction_query_error, Field@0} end
        ) end,
    gleam@result:'try'(
        Do(Conn, <<"begin"/utf8>>),
        fun(_) ->
            exception_ffi:on_crash(
                fun() -> _assert_subject = Do(Conn, <<"rollback"/utf8>>),
                    case _assert_subject of
                        {ok, _} -> _assert_subject;
                        _assert_fail ->
                            erlang:error(#{gleam_error => let_assert,
                                        message => <<"rollback exec failed"/utf8>>,
                                        file => <<?FILEPATH/utf8>>,
                                        module => <<"pog"/utf8>>,
                                        function => <<"transaction_layer"/utf8>>,
                                        line => 463,
                                        value => _assert_fail,
                                        start => 14403,
                                        'end' => 14442,
                                        pattern_start => 14414,
                                        pattern_end => 14419})
                    end end,
                fun() -> case Callback({single_connection, Conn}) of
                        {ok, T} ->
                            gleam@result:'try'(
                                Do(Conn, <<"commit"/utf8>>),
                                fun(_) -> {ok, T} end
                            );

                        {error, Error} ->
                            gleam@result:'try'(
                                Do(Conn, <<"rollback"/utf8>>),
                                fun(_) ->
                                    {error, {transaction_rolled_back, Error}}
                                end
                            )
                    end end
            )
        end
    ).

-file("src/pog.gleam", 426).
?DOC(
    " Runs a function within a PostgreSQL transaction.\n"
    "\n"
    " If the function returns an `Ok` then the transaction is committed.\n"
    "\n"
    " If the function returns an `Error` or panics then the transaction is rolled\n"
    " back.\n"
).
-spec transaction(connection(), fun((connection()) -> {ok, FTE} | {error, FTF})) -> {ok,
        FTE} |
    {error, transaction_error(FTF)}.
transaction(Pool, Callback) ->
    case Pool of
        {single_connection, Conn} ->
            transaction_layer(Conn, Callback);

        {pool, Name} ->
            gleam@result:'try'(
                begin
                    _pipe = pog_ffi:checkout(Name),
                    gleam@result:map_error(
                        _pipe,
                        fun(Field@0) -> {transaction_query_error, Field@0} end
                    )
                end,
                fun(_use0) ->
                    {Ref, Conn@1} = _use0,
                    exception_ffi:defer(
                        fun() -> pgo:checkin(Ref, Conn@1) end,
                        fun() -> transaction_layer(Conn@1, Callback) end
                    )
                end
            )
    end.

-file("src/pog.gleam", 549).
?DOC(
    " Create a new query to use with the `execute`, `returning`, and `parameter`\n"
    " functions.\n"
).
-spec 'query'(binary()) -> 'query'(nil).
'query'(Sql) ->
    {'query', Sql, [], gleam@dynamic@decode:success(nil), 5000}.

-file("src/pog.gleam", 560).
?DOC(
    " Set the decoder to use for the type of row returned by executing this\n"
    " query.\n"
    "\n"
    " If the decoder is unable to decode the row value then the query will return\n"
    " an error from the `exec` function, but the query will still have been run\n"
    " against the database.\n"
).
-spec returning('query'(any()), gleam@dynamic@decode:decoder(FUH)) -> 'query'(FUH).
returning(Query, Decoder) ->
    {'query', Sql, Parameters, _, Timeout} = Query,
    {'query', Sql, Parameters, Decoder, Timeout}.

-file("src/pog.gleam", 566).
?DOC(" Push a new query parameter value for the query.\n").
-spec parameter('query'(FUK), value()) -> 'query'(FUK).
parameter(Query, Parameter) ->
    {'query',
        erlang:element(2, Query),
        [Parameter | erlang:element(3, Query)],
        erlang:element(4, Query),
        erlang:element(5, Query)}.

-file("src/pog.gleam", 576).
?DOC(
    " Use a custom timeout for the query, in milliseconds.\n"
    " the default connection timeout.\n"
    "\n"
    " If this function is not used to give a timeout then default of 5000 ms is\n"
    " used.\n"
).
-spec timeout('query'(FUN), integer()) -> 'query'(FUN).
timeout(Query, Timeout) ->
    {'query',
        erlang:element(2, Query),
        erlang:element(3, Query),
        erlang:element(4, Query),
        Timeout}.

-file("src/pog.gleam", 582).
?DOC(" Run a query against a PostgreSQL database.\n").
-spec execute('query'(FUQ), connection()) -> {ok, returned(FUQ)} |
    {error, query_error()}.
execute(Query, Pool) ->
    Parameters = lists:reverse(erlang:element(3, Query)),
    gleam@result:'try'(
        pog_ffi:'query'(
            Pool,
            erlang:element(2, Query),
            Parameters,
            erlang:element(5, Query)
        ),
        fun(_use0) ->
            {Count, Rows} = _use0,
            gleam@result:'try'(
                begin
                    _pipe = gleam@list:try_map(
                        Rows,
                        fun(_capture) ->
                            gleam@dynamic@decode:run(
                                _capture,
                                erlang:element(4, Query)
                            )
                        end
                    ),
                    gleam@result:map_error(
                        _pipe,
                        fun(Field@0) -> {unexpected_result_type, Field@0} end
                    )
                end,
                fun(Rows@1) -> {ok, {returned, Count, Rows@1}} end
            )
        end
    ).

-file("src/pog.gleam", 608).
?DOC(
    " Get the name for a PostgreSQL error code.\n"
    "\n"
    " ```gleam\n"
    " > error_code_name(\"01007\")\n"
    " Ok(\"privilege_not_granted\")\n"
    " ```\n"
    "\n"
    " https://www.postgresql.org/docs/current/errcodes-appendix.html\n"
).
-spec error_code_name(binary()) -> {ok, binary()} | {error, nil}.
error_code_name(Error_code) ->
    case Error_code of
        <<"00000"/utf8>> ->
            {ok, <<"successful_completion"/utf8>>};

        <<"01000"/utf8>> ->
            {ok, <<"warning"/utf8>>};

        <<"0100C"/utf8>> ->
            {ok, <<"dynamic_result_sets_returned"/utf8>>};

        <<"01008"/utf8>> ->
            {ok, <<"implicit_zero_bit_padding"/utf8>>};

        <<"01003"/utf8>> ->
            {ok, <<"null_value_eliminated_in_set_function"/utf8>>};

        <<"01007"/utf8>> ->
            {ok, <<"privilege_not_granted"/utf8>>};

        <<"01006"/utf8>> ->
            {ok, <<"privilege_not_revoked"/utf8>>};

        <<"01004"/utf8>> ->
            {ok, <<"string_data_right_truncation"/utf8>>};

        <<"01P01"/utf8>> ->
            {ok, <<"deprecated_feature"/utf8>>};

        <<"02000"/utf8>> ->
            {ok, <<"no_data"/utf8>>};

        <<"02001"/utf8>> ->
            {ok, <<"no_additional_dynamic_result_sets_returned"/utf8>>};

        <<"03000"/utf8>> ->
            {ok, <<"sql_statement_not_yet_complete"/utf8>>};

        <<"08000"/utf8>> ->
            {ok, <<"connection_exception"/utf8>>};

        <<"08003"/utf8>> ->
            {ok, <<"connection_does_not_exist"/utf8>>};

        <<"08006"/utf8>> ->
            {ok, <<"connection_failure"/utf8>>};

        <<"08001"/utf8>> ->
            {ok, <<"sqlclient_unable_to_establish_sqlconnection"/utf8>>};

        <<"08004"/utf8>> ->
            {ok, <<"sqlserver_rejected_establishment_of_sqlconnection"/utf8>>};

        <<"08007"/utf8>> ->
            {ok, <<"transaction_resolution_unknown"/utf8>>};

        <<"08P01"/utf8>> ->
            {ok, <<"protocol_violation"/utf8>>};

        <<"09000"/utf8>> ->
            {ok, <<"triggered_action_exception"/utf8>>};

        <<"0A000"/utf8>> ->
            {ok, <<"feature_not_supported"/utf8>>};

        <<"0B000"/utf8>> ->
            {ok, <<"invalid_transaction_initiation"/utf8>>};

        <<"0F000"/utf8>> ->
            {ok, <<"locator_exception"/utf8>>};

        <<"0F001"/utf8>> ->
            {ok, <<"invalid_locator_specification"/utf8>>};

        <<"0L000"/utf8>> ->
            {ok, <<"invalid_grantor"/utf8>>};

        <<"0LP01"/utf8>> ->
            {ok, <<"invalid_grant_operation"/utf8>>};

        <<"0P000"/utf8>> ->
            {ok, <<"invalid_role_specification"/utf8>>};

        <<"0Z000"/utf8>> ->
            {ok, <<"diagnostics_exception"/utf8>>};

        <<"0Z002"/utf8>> ->
            {ok, <<"stacked_diagnostics_accessed_without_active_handler"/utf8>>};

        <<"20000"/utf8>> ->
            {ok, <<"case_not_found"/utf8>>};

        <<"21000"/utf8>> ->
            {ok, <<"cardinality_violation"/utf8>>};

        <<"22000"/utf8>> ->
            {ok, <<"data_exception"/utf8>>};

        <<"2202E"/utf8>> ->
            {ok, <<"array_subscript_error"/utf8>>};

        <<"22021"/utf8>> ->
            {ok, <<"character_not_in_repertoire"/utf8>>};

        <<"22008"/utf8>> ->
            {ok, <<"datetime_field_overflow"/utf8>>};

        <<"22012"/utf8>> ->
            {ok, <<"division_by_zero"/utf8>>};

        <<"22005"/utf8>> ->
            {ok, <<"error_in_assignment"/utf8>>};

        <<"2200B"/utf8>> ->
            {ok, <<"escape_character_conflict"/utf8>>};

        <<"22022"/utf8>> ->
            {ok, <<"indicator_overflow"/utf8>>};

        <<"22015"/utf8>> ->
            {ok, <<"interval_field_overflow"/utf8>>};

        <<"2201E"/utf8>> ->
            {ok, <<"invalid_argument_for_logarithm"/utf8>>};

        <<"22014"/utf8>> ->
            {ok, <<"invalid_argument_for_ntile_function"/utf8>>};

        <<"22016"/utf8>> ->
            {ok, <<"invalid_argument_for_nth_value_function"/utf8>>};

        <<"2201F"/utf8>> ->
            {ok, <<"invalid_argument_for_power_function"/utf8>>};

        <<"2201G"/utf8>> ->
            {ok, <<"invalid_argument_for_width_bucket_function"/utf8>>};

        <<"22018"/utf8>> ->
            {ok, <<"invalid_character_value_for_cast"/utf8>>};

        <<"22007"/utf8>> ->
            {ok, <<"invalid_datetime_format"/utf8>>};

        <<"22019"/utf8>> ->
            {ok, <<"invalid_escape_character"/utf8>>};

        <<"2200D"/utf8>> ->
            {ok, <<"invalid_escape_octet"/utf8>>};

        <<"22025"/utf8>> ->
            {ok, <<"invalid_escape_sequence"/utf8>>};

        <<"22P06"/utf8>> ->
            {ok, <<"nonstandard_use_of_escape_character"/utf8>>};

        <<"22010"/utf8>> ->
            {ok, <<"invalid_indicator_parameter_value"/utf8>>};

        <<"22023"/utf8>> ->
            {ok, <<"invalid_parameter_value"/utf8>>};

        <<"22013"/utf8>> ->
            {ok, <<"invalid_preceding_or_following_size"/utf8>>};

        <<"2201B"/utf8>> ->
            {ok, <<"invalid_regular_expression"/utf8>>};

        <<"2201W"/utf8>> ->
            {ok, <<"invalid_row_count_in_limit_clause"/utf8>>};

        <<"2201X"/utf8>> ->
            {ok, <<"invalid_row_count_in_result_offset_clause"/utf8>>};

        <<"2202H"/utf8>> ->
            {ok, <<"invalid_tablesample_argument"/utf8>>};

        <<"2202G"/utf8>> ->
            {ok, <<"invalid_tablesample_repeat"/utf8>>};

        <<"22009"/utf8>> ->
            {ok, <<"invalid_time_zone_displacement_value"/utf8>>};

        <<"2200C"/utf8>> ->
            {ok, <<"invalid_use_of_escape_character"/utf8>>};

        <<"2200G"/utf8>> ->
            {ok, <<"most_specific_type_mismatch"/utf8>>};

        <<"22004"/utf8>> ->
            {ok, <<"null_value_not_allowed"/utf8>>};

        <<"22002"/utf8>> ->
            {ok, <<"null_value_no_indicator_parameter"/utf8>>};

        <<"22003"/utf8>> ->
            {ok, <<"numeric_value_out_of_range"/utf8>>};

        <<"2200H"/utf8>> ->
            {ok, <<"sequence_generator_limit_exceeded"/utf8>>};

        <<"22026"/utf8>> ->
            {ok, <<"string_data_length_mismatch"/utf8>>};

        <<"22001"/utf8>> ->
            {ok, <<"string_data_right_truncation"/utf8>>};

        <<"22011"/utf8>> ->
            {ok, <<"substring_error"/utf8>>};

        <<"22027"/utf8>> ->
            {ok, <<"trim_error"/utf8>>};

        <<"22024"/utf8>> ->
            {ok, <<"unterminated_c_string"/utf8>>};

        <<"2200F"/utf8>> ->
            {ok, <<"zero_length_character_string"/utf8>>};

        <<"22P01"/utf8>> ->
            {ok, <<"floating_point_exception"/utf8>>};

        <<"22P02"/utf8>> ->
            {ok, <<"invalid_text_representation"/utf8>>};

        <<"22P03"/utf8>> ->
            {ok, <<"invalid_binary_representation"/utf8>>};

        <<"22P04"/utf8>> ->
            {ok, <<"bad_copy_file_format"/utf8>>};

        <<"22P05"/utf8>> ->
            {ok, <<"untranslatable_character"/utf8>>};

        <<"2200L"/utf8>> ->
            {ok, <<"not_an_xml_document"/utf8>>};

        <<"2200M"/utf8>> ->
            {ok, <<"invalid_xml_document"/utf8>>};

        <<"2200N"/utf8>> ->
            {ok, <<"invalid_xml_content"/utf8>>};

        <<"2200S"/utf8>> ->
            {ok, <<"invalid_xml_comment"/utf8>>};

        <<"2200T"/utf8>> ->
            {ok, <<"invalid_xml_processing_instruction"/utf8>>};

        <<"22030"/utf8>> ->
            {ok, <<"duplicate_json_object_key_value"/utf8>>};

        <<"22031"/utf8>> ->
            {ok, <<"invalid_argument_for_sql_json_datetime_function"/utf8>>};

        <<"22032"/utf8>> ->
            {ok, <<"invalid_json_text"/utf8>>};

        <<"22033"/utf8>> ->
            {ok, <<"invalid_sql_json_subscript"/utf8>>};

        <<"22034"/utf8>> ->
            {ok, <<"more_than_one_sql_json_item"/utf8>>};

        <<"22035"/utf8>> ->
            {ok, <<"no_sql_json_item"/utf8>>};

        <<"22036"/utf8>> ->
            {ok, <<"non_numeric_sql_json_item"/utf8>>};

        <<"22037"/utf8>> ->
            {ok, <<"non_unique_keys_in_a_json_object"/utf8>>};

        <<"22038"/utf8>> ->
            {ok, <<"singleton_sql_json_item_required"/utf8>>};

        <<"22039"/utf8>> ->
            {ok, <<"sql_json_array_not_found"/utf8>>};

        <<"2203A"/utf8>> ->
            {ok, <<"sql_json_member_not_found"/utf8>>};

        <<"2203B"/utf8>> ->
            {ok, <<"sql_json_number_not_found"/utf8>>};

        <<"2203C"/utf8>> ->
            {ok, <<"sql_json_object_not_found"/utf8>>};

        <<"2203D"/utf8>> ->
            {ok, <<"too_many_json_array_elements"/utf8>>};

        <<"2203E"/utf8>> ->
            {ok, <<"too_many_json_object_members"/utf8>>};

        <<"2203F"/utf8>> ->
            {ok, <<"sql_json_scalar_required"/utf8>>};

        <<"23000"/utf8>> ->
            {ok, <<"integrity_constraint_violation"/utf8>>};

        <<"23001"/utf8>> ->
            {ok, <<"restrict_violation"/utf8>>};

        <<"23502"/utf8>> ->
            {ok, <<"not_null_violation"/utf8>>};

        <<"23503"/utf8>> ->
            {ok, <<"foreign_key_violation"/utf8>>};

        <<"23505"/utf8>> ->
            {ok, <<"unique_violation"/utf8>>};

        <<"23514"/utf8>> ->
            {ok, <<"check_violation"/utf8>>};

        <<"23P01"/utf8>> ->
            {ok, <<"exclusion_violation"/utf8>>};

        <<"24000"/utf8>> ->
            {ok, <<"invalid_cursor_state"/utf8>>};

        <<"25000"/utf8>> ->
            {ok, <<"invalid_transaction_state"/utf8>>};

        <<"25001"/utf8>> ->
            {ok, <<"active_sql_transaction"/utf8>>};

        <<"25002"/utf8>> ->
            {ok, <<"branch_transaction_already_active"/utf8>>};

        <<"25008"/utf8>> ->
            {ok, <<"held_cursor_requires_same_isolation_level"/utf8>>};

        <<"25003"/utf8>> ->
            {ok, <<"inappropriate_access_mode_for_branch_transaction"/utf8>>};

        <<"25004"/utf8>> ->
            {ok,
                <<"inappropriate_isolation_level_for_branch_transaction"/utf8>>};

        <<"25005"/utf8>> ->
            {ok, <<"no_active_sql_transaction_for_branch_transaction"/utf8>>};

        <<"25006"/utf8>> ->
            {ok, <<"read_only_sql_transaction"/utf8>>};

        <<"25007"/utf8>> ->
            {ok, <<"schema_and_data_statement_mixing_not_supported"/utf8>>};

        <<"25P01"/utf8>> ->
            {ok, <<"no_active_sql_transaction"/utf8>>};

        <<"25P02"/utf8>> ->
            {ok, <<"in_failed_sql_transaction"/utf8>>};

        <<"25P03"/utf8>> ->
            {ok, <<"idle_in_transaction_session_timeout"/utf8>>};

        <<"26000"/utf8>> ->
            {ok, <<"invalid_sql_statement_name"/utf8>>};

        <<"27000"/utf8>> ->
            {ok, <<"triggered_data_change_violation"/utf8>>};

        <<"28000"/utf8>> ->
            {ok, <<"invalid_authorization_specification"/utf8>>};

        <<"28P01"/utf8>> ->
            {ok, <<"invalid_password"/utf8>>};

        <<"2B000"/utf8>> ->
            {ok, <<"dependent_privilege_descriptors_still_exist"/utf8>>};

        <<"2BP01"/utf8>> ->
            {ok, <<"dependent_objects_still_exist"/utf8>>};

        <<"2D000"/utf8>> ->
            {ok, <<"invalid_transaction_termination"/utf8>>};

        <<"2F000"/utf8>> ->
            {ok, <<"sql_routine_exception"/utf8>>};

        <<"2F005"/utf8>> ->
            {ok, <<"function_executed_no_return_statement"/utf8>>};

        <<"2F002"/utf8>> ->
            {ok, <<"modifying_sql_data_not_permitted"/utf8>>};

        <<"2F003"/utf8>> ->
            {ok, <<"prohibited_sql_statement_attempted"/utf8>>};

        <<"2F004"/utf8>> ->
            {ok, <<"reading_sql_data_not_permitted"/utf8>>};

        <<"34000"/utf8>> ->
            {ok, <<"invalid_cursor_name"/utf8>>};

        <<"38000"/utf8>> ->
            {ok, <<"external_routine_exception"/utf8>>};

        <<"38001"/utf8>> ->
            {ok, <<"containing_sql_not_permitted"/utf8>>};

        <<"38002"/utf8>> ->
            {ok, <<"modifying_sql_data_not_permitted"/utf8>>};

        <<"38003"/utf8>> ->
            {ok, <<"prohibited_sql_statement_attempted"/utf8>>};

        <<"38004"/utf8>> ->
            {ok, <<"reading_sql_data_not_permitted"/utf8>>};

        <<"39000"/utf8>> ->
            {ok, <<"external_routine_invocation_exception"/utf8>>};

        <<"39001"/utf8>> ->
            {ok, <<"invalid_sqlstate_returned"/utf8>>};

        <<"39004"/utf8>> ->
            {ok, <<"null_value_not_allowed"/utf8>>};

        <<"39P01"/utf8>> ->
            {ok, <<"trigger_protocol_violated"/utf8>>};

        <<"39P02"/utf8>> ->
            {ok, <<"srf_protocol_violated"/utf8>>};

        <<"39P03"/utf8>> ->
            {ok, <<"event_trigger_protocol_violated"/utf8>>};

        <<"3B000"/utf8>> ->
            {ok, <<"savepoint_exception"/utf8>>};

        <<"3B001"/utf8>> ->
            {ok, <<"invalid_savepoint_specification"/utf8>>};

        <<"3D000"/utf8>> ->
            {ok, <<"invalid_catalog_name"/utf8>>};

        <<"3F000"/utf8>> ->
            {ok, <<"invalid_schema_name"/utf8>>};

        <<"40000"/utf8>> ->
            {ok, <<"transaction_rollback"/utf8>>};

        <<"40002"/utf8>> ->
            {ok, <<"transaction_integrity_constraint_violation"/utf8>>};

        <<"40001"/utf8>> ->
            {ok, <<"serialization_failure"/utf8>>};

        <<"40003"/utf8>> ->
            {ok, <<"statement_completion_unknown"/utf8>>};

        <<"40P01"/utf8>> ->
            {ok, <<"deadlock_detected"/utf8>>};

        <<"42000"/utf8>> ->
            {ok, <<"syntax_error_or_access_rule_violation"/utf8>>};

        <<"42601"/utf8>> ->
            {ok, <<"syntax_error"/utf8>>};

        <<"42501"/utf8>> ->
            {ok, <<"insufficient_privilege"/utf8>>};

        <<"42846"/utf8>> ->
            {ok, <<"cannot_coerce"/utf8>>};

        <<"42803"/utf8>> ->
            {ok, <<"grouping_error"/utf8>>};

        <<"42P20"/utf8>> ->
            {ok, <<"windowing_error"/utf8>>};

        <<"42P19"/utf8>> ->
            {ok, <<"invalid_recursion"/utf8>>};

        <<"42830"/utf8>> ->
            {ok, <<"invalid_foreign_key"/utf8>>};

        <<"42602"/utf8>> ->
            {ok, <<"invalid_name"/utf8>>};

        <<"42622"/utf8>> ->
            {ok, <<"name_too_long"/utf8>>};

        <<"42939"/utf8>> ->
            {ok, <<"reserved_name"/utf8>>};

        <<"42804"/utf8>> ->
            {ok, <<"datatype_mismatch"/utf8>>};

        <<"42P18"/utf8>> ->
            {ok, <<"indeterminate_datatype"/utf8>>};

        <<"42P21"/utf8>> ->
            {ok, <<"collation_mismatch"/utf8>>};

        <<"42P22"/utf8>> ->
            {ok, <<"indeterminate_collation"/utf8>>};

        <<"42809"/utf8>> ->
            {ok, <<"wrong_object_type"/utf8>>};

        <<"428C9"/utf8>> ->
            {ok, <<"generated_always"/utf8>>};

        <<"42703"/utf8>> ->
            {ok, <<"undefined_column"/utf8>>};

        <<"42883"/utf8>> ->
            {ok, <<"undefined_function"/utf8>>};

        <<"42P01"/utf8>> ->
            {ok, <<"undefined_table"/utf8>>};

        <<"42P02"/utf8>> ->
            {ok, <<"undefined_parameter"/utf8>>};

        <<"42704"/utf8>> ->
            {ok, <<"undefined_object"/utf8>>};

        <<"42701"/utf8>> ->
            {ok, <<"duplicate_column"/utf8>>};

        <<"42P03"/utf8>> ->
            {ok, <<"duplicate_cursor"/utf8>>};

        <<"42P04"/utf8>> ->
            {ok, <<"duplicate_database"/utf8>>};

        <<"42723"/utf8>> ->
            {ok, <<"duplicate_function"/utf8>>};

        <<"42P05"/utf8>> ->
            {ok, <<"duplicate_prepared_statement"/utf8>>};

        <<"42P06"/utf8>> ->
            {ok, <<"duplicate_schema"/utf8>>};

        <<"42P07"/utf8>> ->
            {ok, <<"duplicate_table"/utf8>>};

        <<"42712"/utf8>> ->
            {ok, <<"duplicate_alias"/utf8>>};

        <<"42710"/utf8>> ->
            {ok, <<"duplicate_object"/utf8>>};

        <<"42702"/utf8>> ->
            {ok, <<"ambiguous_column"/utf8>>};

        <<"42725"/utf8>> ->
            {ok, <<"ambiguous_function"/utf8>>};

        <<"42P08"/utf8>> ->
            {ok, <<"ambiguous_parameter"/utf8>>};

        <<"42P09"/utf8>> ->
            {ok, <<"ambiguous_alias"/utf8>>};

        <<"42P10"/utf8>> ->
            {ok, <<"invalid_column_reference"/utf8>>};

        <<"42611"/utf8>> ->
            {ok, <<"invalid_column_definition"/utf8>>};

        <<"42P11"/utf8>> ->
            {ok, <<"invalid_cursor_definition"/utf8>>};

        <<"42P12"/utf8>> ->
            {ok, <<"invalid_database_definition"/utf8>>};

        <<"42P13"/utf8>> ->
            {ok, <<"invalid_function_definition"/utf8>>};

        <<"42P14"/utf8>> ->
            {ok, <<"invalid_prepared_statement_definition"/utf8>>};

        <<"42P15"/utf8>> ->
            {ok, <<"invalid_schema_definition"/utf8>>};

        <<"42P16"/utf8>> ->
            {ok, <<"invalid_table_definition"/utf8>>};

        <<"42P17"/utf8>> ->
            {ok, <<"invalid_object_definition"/utf8>>};

        <<"44000"/utf8>> ->
            {ok, <<"with_check_option_violation"/utf8>>};

        <<"53000"/utf8>> ->
            {ok, <<"insufficient_resources"/utf8>>};

        <<"53100"/utf8>> ->
            {ok, <<"disk_full"/utf8>>};

        <<"53200"/utf8>> ->
            {ok, <<"out_of_memory"/utf8>>};

        <<"53300"/utf8>> ->
            {ok, <<"too_many_connections"/utf8>>};

        <<"53400"/utf8>> ->
            {ok, <<"configuration_limit_exceeded"/utf8>>};

        <<"54000"/utf8>> ->
            {ok, <<"program_limit_exceeded"/utf8>>};

        <<"54001"/utf8>> ->
            {ok, <<"statement_too_complex"/utf8>>};

        <<"54011"/utf8>> ->
            {ok, <<"too_many_columns"/utf8>>};

        <<"54023"/utf8>> ->
            {ok, <<"too_many_arguments"/utf8>>};

        <<"55000"/utf8>> ->
            {ok, <<"object_not_in_prerequisite_state"/utf8>>};

        <<"55006"/utf8>> ->
            {ok, <<"object_in_use"/utf8>>};

        <<"55P02"/utf8>> ->
            {ok, <<"cant_change_runtime_param"/utf8>>};

        <<"55P03"/utf8>> ->
            {ok, <<"lock_not_available"/utf8>>};

        <<"55P04"/utf8>> ->
            {ok, <<"unsafe_new_enum_value_usage"/utf8>>};

        <<"57000"/utf8>> ->
            {ok, <<"operator_intervention"/utf8>>};

        <<"57014"/utf8>> ->
            {ok, <<"query_canceled"/utf8>>};

        <<"57P01"/utf8>> ->
            {ok, <<"admin_shutdown"/utf8>>};

        <<"57P02"/utf8>> ->
            {ok, <<"crash_shutdown"/utf8>>};

        <<"57P03"/utf8>> ->
            {ok, <<"cannot_connect_now"/utf8>>};

        <<"57P04"/utf8>> ->
            {ok, <<"database_dropped"/utf8>>};

        <<"57P05"/utf8>> ->
            {ok, <<"idle_session_timeout"/utf8>>};

        <<"58000"/utf8>> ->
            {ok, <<"system_error"/utf8>>};

        <<"58030"/utf8>> ->
            {ok, <<"io_error"/utf8>>};

        <<"58P01"/utf8>> ->
            {ok, <<"undefined_file"/utf8>>};

        <<"58P02"/utf8>> ->
            {ok, <<"duplicate_file"/utf8>>};

        <<"72000"/utf8>> ->
            {ok, <<"snapshot_too_old"/utf8>>};

        <<"F0000"/utf8>> ->
            {ok, <<"config_file_error"/utf8>>};

        <<"F0001"/utf8>> ->
            {ok, <<"lock_file_exists"/utf8>>};

        <<"HV000"/utf8>> ->
            {ok, <<"fdw_error"/utf8>>};

        <<"HV005"/utf8>> ->
            {ok, <<"fdw_column_name_not_found"/utf8>>};

        <<"HV002"/utf8>> ->
            {ok, <<"fdw_dynamic_parameter_value_needed"/utf8>>};

        <<"HV010"/utf8>> ->
            {ok, <<"fdw_function_sequence_error"/utf8>>};

        <<"HV021"/utf8>> ->
            {ok, <<"fdw_inconsistent_descriptor_information"/utf8>>};

        <<"HV024"/utf8>> ->
            {ok, <<"fdw_invalid_attribute_value"/utf8>>};

        <<"HV007"/utf8>> ->
            {ok, <<"fdw_invalid_column_name"/utf8>>};

        <<"HV008"/utf8>> ->
            {ok, <<"fdw_invalid_column_number"/utf8>>};

        <<"HV004"/utf8>> ->
            {ok, <<"fdw_invalid_data_type"/utf8>>};

        <<"HV006"/utf8>> ->
            {ok, <<"fdw_invalid_data_type_descriptors"/utf8>>};

        <<"HV091"/utf8>> ->
            {ok, <<"fdw_invalid_descriptor_field_identifier"/utf8>>};

        <<"HV00B"/utf8>> ->
            {ok, <<"fdw_invalid_handle"/utf8>>};

        <<"HV00C"/utf8>> ->
            {ok, <<"fdw_invalid_option_index"/utf8>>};

        <<"HV00D"/utf8>> ->
            {ok, <<"fdw_invalid_option_name"/utf8>>};

        <<"HV090"/utf8>> ->
            {ok, <<"fdw_invalid_string_length_or_buffer_length"/utf8>>};

        <<"HV00A"/utf8>> ->
            {ok, <<"fdw_invalid_string_format"/utf8>>};

        <<"HV009"/utf8>> ->
            {ok, <<"fdw_invalid_use_of_null_pointer"/utf8>>};

        <<"HV014"/utf8>> ->
            {ok, <<"fdw_too_many_handles"/utf8>>};

        <<"HV001"/utf8>> ->
            {ok, <<"fdw_out_of_memory"/utf8>>};

        <<"HV00P"/utf8>> ->
            {ok, <<"fdw_no_schemas"/utf8>>};

        <<"HV00J"/utf8>> ->
            {ok, <<"fdw_option_name_not_found"/utf8>>};

        <<"HV00K"/utf8>> ->
            {ok, <<"fdw_reply_handle"/utf8>>};

        <<"HV00Q"/utf8>> ->
            {ok, <<"fdw_schema_not_found"/utf8>>};

        <<"HV00R"/utf8>> ->
            {ok, <<"fdw_table_not_found"/utf8>>};

        <<"HV00L"/utf8>> ->
            {ok, <<"fdw_unable_to_create_execution"/utf8>>};

        <<"HV00M"/utf8>> ->
            {ok, <<"fdw_unable_to_create_reply"/utf8>>};

        <<"HV00N"/utf8>> ->
            {ok, <<"fdw_unable_to_establish_connection"/utf8>>};

        <<"P0000"/utf8>> ->
            {ok, <<"plpgsql_error"/utf8>>};

        <<"P0001"/utf8>> ->
            {ok, <<"raise_exception"/utf8>>};

        <<"P0002"/utf8>> ->
            {ok, <<"no_data_found"/utf8>>};

        <<"P0003"/utf8>> ->
            {ok, <<"too_many_rows"/utf8>>};

        <<"P0004"/utf8>> ->
            {ok, <<"assert_failure"/utf8>>};

        <<"XX000"/utf8>> ->
            {ok, <<"internal_error"/utf8>>};

        <<"XX001"/utf8>> ->
            {ok, <<"data_corrupted"/utf8>>};

        <<"XX002"/utf8>> ->
            {ok, <<"index_corrupted"/utf8>>};

        _ ->
            {error, nil}
    end.

-file("src/pog.gleam", 873).
-spec calendar_date_decoder() -> gleam@dynamic@decode:decoder(gleam@time@calendar:date()).
calendar_date_decoder() ->
    gleam@dynamic@decode:field(
        0,
        {decoder, fun gleam@dynamic@decode:decode_int/1},
        fun(Year) ->
            gleam@dynamic@decode:field(
                1,
                {decoder, fun gleam@dynamic@decode:decode_int/1},
                fun(Month) ->
                    gleam@dynamic@decode:field(
                        2,
                        {decoder, fun gleam@dynamic@decode:decode_int/1},
                        fun(Day) ->
                            case gleam@time@calendar:month_from_int(Month) of
                                {ok, Month@1} ->
                                    gleam@dynamic@decode:success(
                                        {date, Year, Month@1, Day}
                                    );

                                {error, _} ->
                                    gleam@dynamic@decode:failure(
                                        {date, 0, january, 1},
                                        <<"Calendar date"/utf8>>
                                    )
                            end
                        end
                    )
                end
            )
        end
    ).

-file("src/pog.gleam", 891).
-spec seconds_decoder() -> gleam@dynamic@decode:decoder({integer(), integer()}).
seconds_decoder() ->
    Int = begin
        _pipe = {decoder, fun gleam@dynamic@decode:decode_int/1},
        gleam@dynamic@decode:map(_pipe, fun(I) -> {I, 0} end)
    end,
    Float = begin
        _pipe@1 = {decoder, fun gleam@dynamic@decode:decode_float/1},
        gleam@dynamic@decode:map(
            _pipe@1,
            fun(F) ->
                Floored = math:floor(F),
                Seconds = erlang:round(Floored),
                Microseconds = erlang:round((F - Floored) * 1000000000.0),
                {Seconds, Microseconds}
            end
        )
    end,
    gleam@dynamic@decode:one_of(Int, [Float]).

-file("src/pog.gleam", 884).
-spec calendar_time_of_day_decoder() -> gleam@dynamic@decode:decoder(gleam@time@calendar:time_of_day()).
calendar_time_of_day_decoder() ->
    gleam@dynamic@decode:field(
        0,
        {decoder, fun gleam@dynamic@decode:decode_int/1},
        fun(Hours) ->
            gleam@dynamic@decode:field(
                1,
                {decoder, fun gleam@dynamic@decode:decode_int/1},
                fun(Minutes) ->
                    gleam@dynamic@decode:field(
                        2,
                        seconds_decoder(),
                        fun(_use0) ->
                            {Seconds, Nanoseconds} = _use0,
                            gleam@dynamic@decode:success(
                                {time_of_day,
                                    Hours,
                                    Minutes,
                                    Seconds,
                                    Nanoseconds}
                            )
                        end
                    )
                end
            )
        end
    ).

-file("src/pog.gleam", 911).
?DOC(
    " Decode a PostgreSQL numeric, which is a union of PostgreSQL integers and\n"
    " float types. Int values are decoded as floats.\n"
).
-spec numeric_decoder() -> gleam@dynamic@decode:decoder(float()).
numeric_decoder() ->
    gleam@dynamic@decode:one_of(
        {decoder, fun gleam@dynamic@decode:decode_float/1},
        [begin
                _pipe = {decoder, fun gleam@dynamic@decode:decode_int/1},
                gleam@dynamic@decode:map(_pipe, fun erlang:float/1)
            end]
    ).

-file("src/pog.gleam", 224).
?DOC(
    " The default configuration for a connection pool, with a single connection.\n"
    " You will likely want to increase the size of the pool for your application.\n"
).
-spec default_config(gleam@erlang@process:name(message())) -> config().
default_config(Pool_name) ->
    {config,
        Pool_name,
        <<"127.0.0.1"/utf8>>,
        5432,
        <<"postgres"/utf8>>,
        <<"postgres"/utf8>>,
        none,
        ssl_disabled,
        [],
        10,
        50,
        1000,
        1000,
        false,
        ipv4,
        false}.

-file("src/pog.gleam", 245).
?DOC(" Parse a database url into configuration that can be used to start a pool.\n").
-spec url_config(gleam@erlang@process:name(message()), binary()) -> {ok,
        config()} |
    {error, nil}.
url_config(Name, Database_url) ->
    gleam@result:'try'(
        gleam_stdlib:uri_parse(Database_url),
        fun(Uri) ->
            Uri@1 = case erlang:element(5, Uri) of
                {some, _} ->
                    Uri;

                none ->
                    {uri,
                        erlang:element(2, Uri),
                        erlang:element(3, Uri),
                        erlang:element(4, Uri),
                        {some, 5432},
                        erlang:element(6, Uri),
                        erlang:element(7, Uri),
                        erlang:element(8, Uri)}
            end,
            gleam@result:'try'(case Uri@1 of
                    {uri,
                        {some, Scheme},
                        {some, Userinfo},
                        {some, Host},
                        {some, Db_port},
                        Path,
                        Query,
                        _} ->
                        case Scheme of
                            <<"postgres"/utf8>> ->
                                {ok, {Userinfo, Host, Path, Db_port, Query}};

                            <<"postgresql"/utf8>> ->
                                {ok, {Userinfo, Host, Path, Db_port, Query}};

                            _ ->
                                {error, nil}
                        end;

                    _ ->
                        {error, nil}
                end, fun(_use0) ->
                    {Userinfo@1, Host@1, Path@1, Db_port@1, Query@1} = _use0,
                    gleam@result:'try'(
                        extract_user_password(Userinfo@1),
                        fun(_use0@1) ->
                            {User, Password} = _use0@1,
                            gleam@result:'try'(
                                extract_ssl_mode(Query@1),
                                fun(Ssl) ->
                                    case gleam@string:split(
                                        Path@1,
                                        <<"/"/utf8>>
                                    ) of
                                        [<<""/utf8>>, Database] ->
                                            {ok,
                                                begin
                                                    _record = default_config(
                                                        Name
                                                    ),
                                                    {config,
                                                        erlang:element(
                                                            2,
                                                            _record
                                                        ),
                                                        Host@1,
                                                        Db_port@1,
                                                        Database,
                                                        User,
                                                        Password,
                                                        Ssl,
                                                        erlang:element(
                                                            9,
                                                            _record
                                                        ),
                                                        erlang:element(
                                                            10,
                                                            _record
                                                        ),
                                                        erlang:element(
                                                            11,
                                                            _record
                                                        ),
                                                        erlang:element(
                                                            12,
                                                            _record
                                                        ),
                                                        erlang:element(
                                                            13,
                                                            _record
                                                        ),
                                                        erlang:element(
                                                            14,
                                                            _record
                                                        ),
                                                        erlang:element(
                                                            15,
                                                            _record
                                                        ),
                                                        erlang:element(
                                                            16,
                                                            _record
                                                        )}
                                                end};

                                        _ ->
                                            {error, nil}
                                    end
                                end
                            )
                        end
                    )
                end)
        end
    ).
