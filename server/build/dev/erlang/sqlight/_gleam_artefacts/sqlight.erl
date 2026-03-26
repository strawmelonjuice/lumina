-module(sqlight).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/sqlight.gleam").
-export([error_code_to_int/1, error_code_from_int/1, open/1, close/1, with_connection/2, exec/2, int/1, float/1, text/1, blob/1, bool/1, null/0, nullable/2, decode_bool/0, 'query'/4]).
-export_type([connection/0, value/0, stats/0, error/0, error_code/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

-type connection() :: any().

-type value() :: any().

-type stats() :: {stats, integer(), integer()}.

-type error() :: {sqlight_error, error_code(), binary(), integer()}.

-type error_code() :: abort |
    auth |
    busy |
    cantopen |
    constraint |
    corrupt |
    done |
    empty |
    generic_error |
    format |
    full |
    internal |
    interrupt |
    ioerr |
    locked |
    mismatch |
    misuse |
    nolfs |
    nomem |
    notadb |
    notfound |
    notice |
    generic_ok |
    perm |
    protocol |
    range |
    readonly |
    row |
    schema |
    toobig |
    warning |
    abort_rollback |
    auth_user |
    busy_recovery |
    busy_snapshot |
    busy_timeout |
    cantopen_convpath |
    cantopen_dirtywal |
    cantopen_fullpath |
    cantopen_isdir |
    cantopen_notempdir |
    cantopen_symlink |
    constraint_check |
    constraint_commithook |
    constraint_datatype |
    constraint_foreignkey |
    constraint_function |
    constraint_notnull |
    constraint_pinned |
    constraint_primarykey |
    constraint_rowid |
    constraint_trigger |
    constraint_unique |
    constraint_vtab |
    corrupt_index |
    corrupt_sequence |
    corrupt_vtab |
    error_missing_collseq |
    error_retry |
    error_snapshot |
    ioerr_access |
    ioerr_auth |
    ioerr_begin_atomic |
    ioerr_blocked |
    ioerr_checkreservedlock |
    ioerr_close |
    ioerr_commit_atomic |
    ioerr_convpath |
    ioerr_corruptfs |
    ioerr_data |
    ioerr_delete |
    ioerr_delete_noent |
    ioerr_dir_close |
    ioerr_dir_fsync |
    ioerr_fstat |
    ioerr_fsync |
    ioerr_gettemppath |
    ioerr_lock |
    ioerr_mmap |
    ioerr_nomem |
    ioerr_rdlock.

-file("src/sqlight.gleam", 125).
?DOC(
    " Convert an `Error` to an error code int.\n"
    "\n"
    " See the SQLite documentation for the full list of error codes.\n"
    " <https://sqlite.org/rescode.html>\n"
).
-spec error_code_to_int(error_code()) -> integer().
error_code_to_int(Error) ->
    case Error of
        generic_error ->
            1;

        abort ->
            4;

        auth ->
            23;

        busy ->
            5;

        cantopen ->
            14;

        constraint ->
            19;

        corrupt ->
            11;

        done ->
            101;

        empty ->
            16;

        format ->
            24;

        full ->
            13;

        internal ->
            2;

        interrupt ->
            9;

        ioerr ->
            10;

        locked ->
            6;

        mismatch ->
            20;

        misuse ->
            21;

        nolfs ->
            22;

        nomem ->
            7;

        notadb ->
            26;

        notfound ->
            12;

        notice ->
            27;

        generic_ok ->
            0;

        perm ->
            3;

        protocol ->
            15;

        range ->
            25;

        readonly ->
            8;

        row ->
            100;

        schema ->
            17;

        toobig ->
            18;

        warning ->
            28;

        abort_rollback ->
            516;

        auth_user ->
            279;

        busy_recovery ->
            261;

        busy_snapshot ->
            517;

        busy_timeout ->
            773;

        cantopen_convpath ->
            1038;

        cantopen_dirtywal ->
            1294;

        cantopen_fullpath ->
            782;

        cantopen_isdir ->
            526;

        cantopen_notempdir ->
            270;

        cantopen_symlink ->
            1550;

        constraint_check ->
            275;

        constraint_commithook ->
            531;

        constraint_datatype ->
            3091;

        constraint_foreignkey ->
            787;

        constraint_function ->
            1043;

        constraint_notnull ->
            1299;

        constraint_pinned ->
            2835;

        constraint_primarykey ->
            1555;

        constraint_rowid ->
            2579;

        constraint_trigger ->
            1811;

        constraint_unique ->
            2067;

        constraint_vtab ->
            2323;

        corrupt_index ->
            779;

        corrupt_sequence ->
            523;

        corrupt_vtab ->
            267;

        error_missing_collseq ->
            257;

        error_retry ->
            513;

        error_snapshot ->
            769;

        ioerr_access ->
            3338;

        ioerr_auth ->
            7178;

        ioerr_begin_atomic ->
            7434;

        ioerr_blocked ->
            2826;

        ioerr_checkreservedlock ->
            3594;

        ioerr_close ->
            4106;

        ioerr_commit_atomic ->
            7690;

        ioerr_convpath ->
            6666;

        ioerr_corruptfs ->
            8458;

        ioerr_data ->
            8202;

        ioerr_delete ->
            2570;

        ioerr_delete_noent ->
            5898;

        ioerr_dir_close ->
            4362;

        ioerr_dir_fsync ->
            1290;

        ioerr_fstat ->
            1802;

        ioerr_fsync ->
            1034;

        ioerr_gettemppath ->
            6410;

        ioerr_lock ->
            3850;

        ioerr_mmap ->
            6154;

        ioerr_nomem ->
            3082;

        ioerr_rdlock ->
            2314
    end.

-file("src/sqlight.gleam", 215).
?DOC(
    " Convert an error code int to an `Error`.\n"
    "\n"
    " If the code is not a known error code, `GenericError` is returned.\n"
).
-spec error_code_from_int(integer()) -> error_code().
error_code_from_int(Code) ->
    case Code of
        4 ->
            abort;

        23 ->
            auth;

        5 ->
            busy;

        14 ->
            cantopen;

        19 ->
            constraint;

        11 ->
            corrupt;

        101 ->
            done;

        16 ->
            empty;

        1 ->
            generic_error;

        24 ->
            format;

        13 ->
            full;

        2 ->
            internal;

        9 ->
            interrupt;

        10 ->
            ioerr;

        6 ->
            locked;

        20 ->
            mismatch;

        21 ->
            misuse;

        22 ->
            nolfs;

        7 ->
            nomem;

        26 ->
            notadb;

        12 ->
            notfound;

        27 ->
            notice;

        0 ->
            generic_ok;

        3 ->
            perm;

        15 ->
            protocol;

        25 ->
            range;

        8 ->
            readonly;

        100 ->
            row;

        17 ->
            schema;

        18 ->
            toobig;

        28 ->
            warning;

        516 ->
            abort_rollback;

        279 ->
            auth_user;

        261 ->
            busy_recovery;

        517 ->
            busy_snapshot;

        773 ->
            busy_timeout;

        1038 ->
            cantopen_convpath;

        1294 ->
            cantopen_dirtywal;

        782 ->
            cantopen_fullpath;

        526 ->
            cantopen_isdir;

        270 ->
            cantopen_notempdir;

        1550 ->
            cantopen_symlink;

        275 ->
            constraint_check;

        531 ->
            constraint_commithook;

        3091 ->
            constraint_datatype;

        787 ->
            constraint_foreignkey;

        1043 ->
            constraint_function;

        1299 ->
            constraint_notnull;

        2835 ->
            constraint_pinned;

        1555 ->
            constraint_primarykey;

        2579 ->
            constraint_rowid;

        1811 ->
            constraint_trigger;

        2067 ->
            constraint_unique;

        2323 ->
            constraint_vtab;

        779 ->
            corrupt_index;

        523 ->
            corrupt_sequence;

        267 ->
            corrupt_vtab;

        257 ->
            error_missing_collseq;

        513 ->
            error_retry;

        769 ->
            error_snapshot;

        3338 ->
            ioerr_access;

        7178 ->
            ioerr_auth;

        7434 ->
            ioerr_begin_atomic;

        2826 ->
            ioerr_blocked;

        3594 ->
            ioerr_checkreservedlock;

        4106 ->
            ioerr_close;

        7690 ->
            ioerr_commit_atomic;

        6666 ->
            ioerr_convpath;

        8458 ->
            ioerr_corruptfs;

        8202 ->
            ioerr_data;

        2570 ->
            ioerr_delete;

        5898 ->
            ioerr_delete_noent;

        4362 ->
            ioerr_dir_close;

        1290 ->
            ioerr_dir_fsync;

        1802 ->
            ioerr_fstat;

        1034 ->
            ioerr_fsync;

        6410 ->
            ioerr_gettemppath;

        3850 ->
            ioerr_lock;

        6154 ->
            ioerr_mmap;

        3082 ->
            ioerr_nomem;

        2314 ->
            ioerr_rdlock;

        _ ->
            generic_error
    end.

-file("src/sqlight.gleam", 336).
?DOC(
    " Open a connection to a SQLite database.\n"
    "\n"
    " URI filenames are supported by SQLite, making it possible to open read-only\n"
    " databases, in memory databases, and more. Further information about this can\n"
    " be found in the SQLite documentation: <https://sqlite.org/uri.html>.\n"
    "\n"
    " # Examples\n"
    "\n"
    " ## Open \"data.db\" in the current working directory\n"
    "\n"
    " ```gleam\n"
    " let assert Ok(conn) = open(\"file:data.sqlite3\")\n"
    " ```\n"
    " \n"
    " ## Opens \"data.db\" in read only mode with a private cache\n"
    " \n"
    " ```gleam\n"
    " let assert Ok(conn) = open(\"file:data.db?mode=ro&cache=private\")\n"
    " ```\n"
    " \n"
    " Opens a shared memory database named memdb1 with a shared cache. \n"
    " \n"
    " ```gleam\n"
    " let assert Ok(conn) = open(\"file:memdb1?mode=memory&cache=shared\")\n"
    " ```\n"
).
-spec open(binary()) -> {ok, connection()} | {error, error()}.
open(Path) ->
    sqlight_ffi:open(Path).

-file("src/sqlight.gleam", 346).
?DOC(
    " Close a connection to a SQLite database.\n"
    "\n"
    " Ideally applications should finallise all prepared statements and other open\n"
    " resources before closing a connection. See the SQLite documentation for more\n"
    " information: <https://www.sqlite.org/c3ref/close.html>.\n"
).
-spec close(connection()) -> {ok, nil} | {error, error()}.
close(Connection) ->
    sqlight_ffi:close(Connection).

-file("src/sqlight.gleam", 367).
?DOC(
    " Open a connection to a SQLite database and execute a function with it,.try\n"
    " close the connection.\n"
    "\n"
    " This function works well with a `use` expression to automatically close the\n"
    " connection at the end of a block.\n"
    "\n"
    " # Crashes\n"
    "\n"
    " This function crashes if the connection cannot be opened or closed.\n"
    "\n"
    " # Examples\n"
    "\n"
    " ```gleam\n"
    " use conn <- with_connection(\"file:mydb?mode=memory\")\n"
    " // Use the connection here...\n"
    " ```\n"
).
-spec with_connection(binary(), fun((connection()) -> ADGI)) -> ADGI.
with_connection(Path, F) ->
    Connection@1 = case open(Path) of
        {ok, Connection} -> Connection;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sqlight"/utf8>>,
                        function => <<"with_connection"/utf8>>,
                        line => 368,
                        value => _assert_fail,
                        start => 8325,
                        'end' => 8363,
                        pattern_start => 8336,
                        pattern_end => 8350})
    end,
    Value = F(Connection@1),
    case close(Connection@1) of
        {ok, _} -> nil;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sqlight"/utf8>>,
                        function => <<"with_connection"/utf8>>,
                        line => 370,
                        value => _assert_fail@1,
                        start => 8394,
                        'end' => 8430,
                        pattern_start => 8405,
                        pattern_end => 8410})
    end,
    Value.

-file("src/sqlight.gleam", 374).
-spec exec(binary(), connection()) -> {ok, nil} | {error, error()}.
exec(Sql, Connection) ->
    sqlight_ffi:exec(Sql, Connection).

-file("src/sqlight.gleam", 421).
?DOC(
    " Convert a Gleam `Int` to an SQLite int, to be used an argument to a\n"
    " query.\n"
).
-spec int(integer()) -> value().
int(Value) ->
    sqlight_ffi:coerce_value(Value).

-file("src/sqlight.gleam", 428).
?DOC(
    " Convert a Gleam `Float` to an SQLite float, to be used an argument to a\n"
    " query.\n"
).
-spec float(float()) -> value().
float(Value) ->
    sqlight_ffi:coerce_value(Value).

-file("src/sqlight.gleam", 435).
?DOC(
    " Convert a Gleam `String` to an SQLite text, to be used an argument to a\n"
    " query.\n"
).
-spec text(binary()) -> value().
text(Value) ->
    sqlight_ffi:coerce_value(Value).

-file("src/sqlight.gleam", 444).
?DOC(
    " Convert a Gleam `BitString` to an SQLite blob, to be used an argument to a\n"
    " query.\n"
).
-spec blob(bitstring()) -> value().
blob(Value) ->
    sqlight_ffi:coerce_blob(Value).

-file("src/sqlight.gleam", 454).
?DOC(
    " Convert a Gleam `Bool` to an SQLite int, to be used an argument to a\n"
    " query.\n"
    "\n"
    " SQLite does not have a native boolean type. Instead, it uses ints, where 0\n"
    " is False and 1 is True. Because of this the Gleam stdlib decoder for bools\n"
    " will not work, instead the `decode_bool` function should be used as it\n"
    " supports both ints and bools.\n"
).
-spec bool(boolean()) -> value().
bool(Value) ->
    int(case Value of
            true ->
                1;

            false ->
                0
        end).

-file("src/sqlight.gleam", 465).
?DOC(" Construct an SQLite null, to be used an argument to a query.\n").
-spec null() -> value().
null() ->
    sqlight_ffi:null().

-file("src/sqlight.gleam", 411).
?DOC(
    " Convert a Gleam `Option` to an SQLite nullable value, to be used an argument\n"
    " to a query.\n"
).
-spec nullable(fun((ADGY) -> value()), gleam@option:option(ADGY)) -> value().
nullable(Inner_type, Value) ->
    case Value of
        {some, Value@1} ->
            Inner_type(Value@1);

        none ->
            sqlight_ffi:null()
    end.

-file("src/sqlight.gleam", 471).
?DOC(
    " Decode an SQLite boolean value.\n"
    "\n"
    " Decodes 0 as `False` and any other integer as `True`.\n"
).
-spec decode_bool() -> gleam@dynamic@decode:decoder(boolean()).
decode_bool() ->
    gleam@dynamic@decode:then(
        {decoder, fun gleam@dynamic@decode:decode_int/1},
        fun(B) -> case B of
                0 ->
                    gleam@dynamic@decode:success(false);

                _ ->
                    gleam@dynamic@decode:success(true)
            end end
    ).

-file("src/sqlight.gleam", 480).
-spec decode_error(list(gleam@dynamic@decode:decode_error())) -> error().
decode_error(Errors) ->
    {Expected@1, Actual@1, Path@1} = case Errors of
        [{decode_error, Expected, Actual, Path} | _] -> {Expected, Actual, Path};
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sqlight"/utf8>>,
                        function => <<"decode_error"/utf8>>,
                        line => 481,
                        value => _assert_fail,
                        start => 11296,
                        'end' => 11364,
                        pattern_start => 11307,
                        pattern_end => 11355})
    end,
    Path@2 = gleam@string:join(Path@1, <<"."/utf8>>),
    Message = <<<<<<<<<<"Decoder failed, expected "/utf8, Expected@1/binary>>/binary,
                    ", got "/utf8>>/binary,
                Actual@1/binary>>/binary,
            " in "/utf8>>/binary,
        Path@2/binary>>,
    {sqlight_error, generic_error, Message, -1}.

-file("src/sqlight.gleam", 378).
-spec 'query'(
    binary(),
    connection(),
    list(value()),
    gleam@dynamic@decode:decoder(ADGM)
) -> {ok, list(ADGM)} | {error, error()}.
'query'(Sql, Connection, Arguments, Decoder) ->
    gleam@result:'try'(
        sqlight_ffi:'query'(Sql, Connection, Arguments),
        fun(Rows) ->
            gleam@result:'try'(
                begin
                    _pipe = gleam@list:try_map(
                        Rows,
                        fun(Row) -> gleam@dynamic@decode:run(Row, Decoder) end
                    ),
                    gleam@result:map_error(_pipe, fun decode_error/1)
                end,
                fun(Rows@1) -> {ok, Rows@1} end
            )
        end
    ).
