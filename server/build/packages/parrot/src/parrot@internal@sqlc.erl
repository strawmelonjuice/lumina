-module(parrot@internal@sqlc).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/parrot/internal/sqlc.gleam").
-export([query_cmd_to_string/1, decode_sqlc/1, gen_sqlc_json/2, sqlc_binary_path/0, get_os/0, get_cpu/0, download_zip/1, extract_sqlc_binary/1, verify_binary/0, download_binary/0]).
-export_type([engine/0, queries/0, gen_json/0, gen/0, sql/0, version2/0, config/0, type_ref/0, table_column/0, table_ref/0, table/0, schema/0, enum/0, catalog/0, query_cmd/0, query_param/0, 'query'/0, s_q_l_c/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-type engine() :: s_q_lite | my_s_q_l | postgre_s_q_l.

-type queries() :: {queries_single, binary()} |
    {queries_multiple, list(binary())}.

-type gen_json() :: {gen_json,
        gleam@option:option(binary()),
        gleam@option:option(binary()),
        gleam@option:option(binary())}.

-type gen() :: {gen, gleam@option:option(gen_json())}.

-type sql() :: {sql,
        gleam@option:option(binary()),
        gleam@option:option(queries()),
        engine(),
        gleam@option:option(gen())}.

-type version2() :: version2.

-type config() :: {config, version2(), list(sql())}.

-type type_ref() :: {type_ref, binary(), binary(), binary()}.

-type table_column() :: {table_column,
        binary(),
        boolean(),
        boolean(),
        binary(),
        integer(),
        boolean(),
        boolean(),
        binary(),
        binary(),
        boolean(),
        binary(),
        boolean(),
        integer(),
        gleam@option:option(table_ref()),
        type_ref()}.

-type table_ref() :: {table_ref, binary(), binary(), binary()}.

-type table() :: {table, table_ref(), binary(), list(table_column())}.

-type schema() :: {schema, binary(), binary(), list(table()), list(enum())}.

-type enum() :: {enum, binary(), list(binary()), binary()}.

-type catalog() :: {catalog, binary(), binary(), binary(), list(schema())}.

-type query_cmd() :: one |
    many |
    exec |
    exec_result |
    exec_rows |
    exec_last_id |
    batch_exec |
    batch_many |
    batch_one |
    copy_from.

-type query_param() :: {query_param, integer(), table_column()}.

-type 'query'() :: {'query',
        binary(),
        binary(),
        query_cmd(),
        binary(),
        list(table_column()),
        gleam@option:option(table_ref()),
        list(binary()),
        list(query_param())}.

-type s_q_l_c() :: {s_q_l_c,
        binary(),
        binary(),
        binary(),
        catalog(),
        list('query'())}.

-file("src/parrot/internal/sqlc.gleam", 56).
?DOC(false).
-spec queries_to_json(queries()) -> gleam@json:json().
queries_to_json(Queries) ->
    case Queries of
        {queries_single, Query} ->
            gleam@json:string(Query);

        {queries_multiple, Queries@1} ->
            gleam@json:array(Queries@1, fun gleam@json:string/1)
    end.

-file("src/parrot/internal/sqlc.gleam", 63).
?DOC(false).
-spec engine_to_json(engine()) -> gleam@json:json().
engine_to_json(Engine) ->
    Engine@1 = case Engine of
        s_q_lite ->
            <<"sqlite"/utf8>>;

        my_s_q_l ->
            <<"mysql"/utf8>>;

        postgre_s_q_l ->
            <<"postgresql"/utf8>>
    end,
    gleam@json:string(Engine@1).

-file("src/parrot/internal/sqlc.gleam", 72).
?DOC(false).
-spec gen_json_to_json(gen_json()) -> gleam@json:json().
gen_json_to_json(Gen_json) ->
    {gen_json, Out, Indent, Filename} = Gen_json,
    Json_object = case Out of
        none ->
            [];

        {some, Out@1} ->
            [{<<"out"/utf8>>, gleam@json:string(Out@1)}]
    end,
    Json_object@1 = case Indent of
        none ->
            Json_object;

        {some, Indent@1} ->
            [{<<"indent"/utf8>>, gleam@json:string(Indent@1)} | Json_object]
    end,
    Json_object@2 = case Filename of
        none ->
            Json_object@1;

        {some, Filename@1} ->
            [{<<"filename"/utf8>>, gleam@json:string(Filename@1)} |
                Json_object@1]
    end,
    gleam@json:object(Json_object@2).

-file("src/parrot/internal/sqlc.gleam", 113).
?DOC(false).
-spec gen_to_json(gen()) -> gleam@json:json().
gen_to_json(Gen) ->
    {gen, Json} = Gen,
    Json_object = case Json of
        none ->
            [];

        {some, Json@1} ->
            [{<<"json"/utf8>>, gen_json_to_json(Json@1)}]
    end,
    gleam@json:object(Json_object).

-file("src/parrot/internal/sqlc.gleam", 92).
?DOC(false).
-spec sql_to_json(sql()) -> gleam@json:json().
sql_to_json(Sql) ->
    {sql, Schema, Queries, Engine, Gen} = Sql,
    Json_object = [{<<"engine"/utf8>>, engine_to_json(Engine)}],
    Json_object@1 = case Schema of
        none ->
            Json_object;

        {some, Schema@1} ->
            [{<<"schema"/utf8>>, gleam@json:string(Schema@1)} | Json_object]
    end,
    Json_object@2 = case Queries of
        none ->
            Json_object@1;

        {some, Queries@1} ->
            [{<<"queries"/utf8>>, queries_to_json(Queries@1)} | Json_object@1]
    end,
    Json_object@3 = case Gen of
        none ->
            Json_object@2;

        {some, Gen@1} ->
            [{<<"gen"/utf8>>, gen_to_json(Gen@1)} | Json_object@2]
    end,
    gleam@json:object(Json_object@3).

-file("src/parrot/internal/sqlc.gleam", 122).
?DOC(false).
-spec version2_to_json(version2()) -> gleam@json:json().
version2_to_json(_) ->
    gleam@json:string(<<"2"/utf8>>).

-file("src/parrot/internal/sqlc.gleam", 126).
?DOC(false).
-spec config_to_json(config()) -> gleam@json:json().
config_to_json(Config) ->
    case Config of
        {config, Version, Sql} ->
            gleam@json:object(
                [{<<"version"/utf8>>, version2_to_json(Version)},
                    {<<"sql"/utf8>>, gleam@json:array(Sql, fun sql_to_json/1)}]
            )
    end.

-file("src/parrot/internal/sqlc.gleam", 136).
?DOC(false).
-spec config_to_json_string(config()) -> binary().
config_to_json_string(Config) ->
    _pipe = config_to_json(Config),
    gleam@json:to_string(_pipe).

-file("src/parrot/internal/sqlc.gleam", 202).
?DOC(false).
-spec query_cmd_to_string(query_cmd()) -> binary().
query_cmd_to_string(Query_cmd) ->
    case Query_cmd of
        one ->
            <<"one"/utf8>>;

        many ->
            <<"many"/utf8>>;

        exec ->
            <<"exec"/utf8>>;

        exec_result ->
            <<"exec_result"/utf8>>;

        exec_rows ->
            <<"exec_rows"/utf8>>;

        exec_last_id ->
            <<"exec_last_id"/utf8>>;

        batch_exec ->
            <<"batch_exec"/utf8>>;

        batch_many ->
            <<"batch_many"/utf8>>;

        batch_one ->
            <<"batch_one"/utf8>>;

        copy_from ->
            <<"copy_from"/utf8>>
    end.

-file("src/parrot/internal/sqlc.gleam", 244).
?DOC(false).
-spec decode_sqlc(gleam@dynamic:dynamic_()) -> {ok, s_q_l_c()} |
    {error, list(gleam@dynamic@decode:decode_error())}.
decode_sqlc(Data) ->
    Table_ref_decoder = begin
        gleam@dynamic@decode:field(
            <<"name"/utf8>>,
            {decoder, fun gleam@dynamic@decode:decode_string/1},
            fun(Name) ->
                gleam@dynamic@decode:field(
                    <<"schema"/utf8>>,
                    {decoder, fun gleam@dynamic@decode:decode_string/1},
                    fun(Schema) ->
                        gleam@dynamic@decode:field(
                            <<"catalog"/utf8>>,
                            {decoder, fun gleam@dynamic@decode:decode_string/1},
                            fun(Catalog) ->
                                gleam@dynamic@decode:success(
                                    {table_ref, Catalog, Schema, Name}
                                )
                            end
                        )
                    end
                )
            end
        )
    end,
    Type_ref_decoder = begin
        gleam@dynamic@decode:field(
            <<"schema"/utf8>>,
            {decoder, fun gleam@dynamic@decode:decode_string/1},
            fun(Schema@1) ->
                gleam@dynamic@decode:field(
                    <<"catalog"/utf8>>,
                    {decoder, fun gleam@dynamic@decode:decode_string/1},
                    fun(Catalog@1) ->
                        gleam@dynamic@decode:field(
                            <<"name"/utf8>>,
                            {decoder, fun gleam@dynamic@decode:decode_string/1},
                            fun(Name@1) ->
                                gleam@dynamic@decode:success(
                                    {type_ref, Catalog@1, Schema@1, Name@1}
                                )
                            end
                        )
                    end
                )
            end
        )
    end,
    Table_col_decoder = begin
        gleam@dynamic@decode:field(
            <<"name"/utf8>>,
            {decoder, fun gleam@dynamic@decode:decode_string/1},
            fun(Name@2) ->
                gleam@dynamic@decode:field(
                    <<"not_null"/utf8>>,
                    {decoder, fun gleam@dynamic@decode:decode_bool/1},
                    fun(Not_null) ->
                        gleam@dynamic@decode:field(
                            <<"is_array"/utf8>>,
                            {decoder, fun gleam@dynamic@decode:decode_bool/1},
                            fun(Is_array) ->
                                gleam@dynamic@decode:field(
                                    <<"comment"/utf8>>,
                                    {decoder,
                                        fun gleam@dynamic@decode:decode_string/1},
                                    fun(Comment) ->
                                        gleam@dynamic@decode:field(
                                            <<"length"/utf8>>,
                                            {decoder,
                                                fun gleam@dynamic@decode:decode_int/1},
                                            fun(Length) ->
                                                gleam@dynamic@decode:field(
                                                    <<"is_named_param"/utf8>>,
                                                    {decoder,
                                                        fun gleam@dynamic@decode:decode_bool/1},
                                                    fun(Is_named_param) ->
                                                        gleam@dynamic@decode:field(
                                                            <<"is_func_call"/utf8>>,
                                                            {decoder,
                                                                fun gleam@dynamic@decode:decode_bool/1},
                                                            fun(Is_func_call) ->
                                                                gleam@dynamic@decode:field(
                                                                    <<"scope"/utf8>>,
                                                                    {decoder,
                                                                        fun gleam@dynamic@decode:decode_string/1},
                                                                    fun(Scope) ->
                                                                        gleam@dynamic@decode:field(
                                                                            <<"table_alias"/utf8>>,
                                                                            {decoder,
                                                                                fun gleam@dynamic@decode:decode_string/1},
                                                                            fun(
                                                                                Table_alias
                                                                            ) ->
                                                                                gleam@dynamic@decode:field(
                                                                                    <<"is_sqlc_slice"/utf8>>,
                                                                                    {decoder,
                                                                                        fun gleam@dynamic@decode:decode_bool/1},
                                                                                    fun(
                                                                                        Is_sqlc_slice
                                                                                    ) ->
                                                                                        gleam@dynamic@decode:field(
                                                                                            <<"original_name"/utf8>>,
                                                                                            {decoder,
                                                                                                fun gleam@dynamic@decode:decode_string/1},
                                                                                            fun(
                                                                                                Original_name
                                                                                            ) ->
                                                                                                gleam@dynamic@decode:field(
                                                                                                    <<"unsigned"/utf8>>,
                                                                                                    {decoder,
                                                                                                        fun gleam@dynamic@decode:decode_bool/1},
                                                                                                    fun(
                                                                                                        Unsigned
                                                                                                    ) ->
                                                                                                        gleam@dynamic@decode:field(
                                                                                                            <<"array_dims"/utf8>>,
                                                                                                            {decoder,
                                                                                                                fun gleam@dynamic@decode:decode_int/1},
                                                                                                            fun(
                                                                                                                Array_dims
                                                                                                            ) ->
                                                                                                                gleam@dynamic@decode:field(
                                                                                                                    <<"table"/utf8>>,
                                                                                                                    gleam@dynamic@decode:optional(
                                                                                                                        Table_ref_decoder
                                                                                                                    ),
                                                                                                                    fun(
                                                                                                                        Table
                                                                                                                    ) ->
                                                                                                                        gleam@dynamic@decode:field(
                                                                                                                            <<"type"/utf8>>,
                                                                                                                            Type_ref_decoder,
                                                                                                                            fun(
                                                                                                                                Type_ref
                                                                                                                            ) ->
                                                                                                                                _pipe = {table_column,
                                                                                                                                    Name@2,
                                                                                                                                    Not_null,
                                                                                                                                    Is_array,
                                                                                                                                    Comment,
                                                                                                                                    Length,
                                                                                                                                    Is_named_param,
                                                                                                                                    Is_func_call,
                                                                                                                                    Scope,
                                                                                                                                    Table_alias,
                                                                                                                                    Is_sqlc_slice,
                                                                                                                                    Original_name,
                                                                                                                                    Unsigned,
                                                                                                                                    Array_dims,
                                                                                                                                    Table,
                                                                                                                                    Type_ref},
                                                                                                                                gleam@dynamic@decode:success(
                                                                                                                                    _pipe
                                                                                                                                )
                                                                                                                            end
                                                                                                                        )
                                                                                                                    end
                                                                                                                )
                                                                                                            end
                                                                                                        )
                                                                                                    end
                                                                                                )
                                                                                            end
                                                                                        )
                                                                                    end
                                                                                )
                                                                            end
                                                                        )
                                                                    end
                                                                )
                                                            end
                                                        )
                                                    end
                                                )
                                            end
                                        )
                                    end
                                )
                            end
                        )
                    end
                )
            end
        )
    end,
    Table_decoder = begin
        gleam@dynamic@decode:field(
            <<"rel"/utf8>>,
            Table_ref_decoder,
            fun(Rel) ->
                gleam@dynamic@decode:field(
                    <<"comment"/utf8>>,
                    {decoder, fun gleam@dynamic@decode:decode_string/1},
                    fun(Comment@1) ->
                        gleam@dynamic@decode:field(
                            <<"columns"/utf8>>,
                            gleam@dynamic@decode:list(Table_col_decoder),
                            fun(Columns) ->
                                gleam@dynamic@decode:success(
                                    {table, Rel, Comment@1, Columns}
                                )
                            end
                        )
                    end
                )
            end
        )
    end,
    Enum_decoder = begin
        gleam@dynamic@decode:field(
            <<"name"/utf8>>,
            {decoder, fun gleam@dynamic@decode:decode_string/1},
            fun(Name@3) ->
                gleam@dynamic@decode:field(
                    <<"vals"/utf8>>,
                    gleam@dynamic@decode:list(
                        {decoder, fun gleam@dynamic@decode:decode_string/1}
                    ),
                    fun(Vals) ->
                        gleam@dynamic@decode:field(
                            <<"comment"/utf8>>,
                            {decoder, fun gleam@dynamic@decode:decode_string/1},
                            fun(Comment@2) ->
                                gleam@dynamic@decode:success(
                                    {enum, Name@3, Vals, Comment@2}
                                )
                            end
                        )
                    end
                )
            end
        )
    end,
    Schema_decoder = begin
        gleam@dynamic@decode:field(
            <<"comment"/utf8>>,
            {decoder, fun gleam@dynamic@decode:decode_string/1},
            fun(Comment@3) ->
                gleam@dynamic@decode:field(
                    <<"name"/utf8>>,
                    {decoder, fun gleam@dynamic@decode:decode_string/1},
                    fun(Name@4) ->
                        gleam@dynamic@decode:field(
                            <<"tables"/utf8>>,
                            gleam@dynamic@decode:list(Table_decoder),
                            fun(Tables) ->
                                gleam@dynamic@decode:field(
                                    <<"enums"/utf8>>,
                                    gleam@dynamic@decode:list(Enum_decoder),
                                    fun(Enums) ->
                                        gleam@dynamic@decode:success(
                                            {schema,
                                                Comment@3,
                                                Name@4,
                                                Tables,
                                                Enums}
                                        )
                                    end
                                )
                            end
                        )
                    end
                )
            end
        )
    end,
    Catalog_decoder = begin
        gleam@dynamic@decode:field(
            <<"comment"/utf8>>,
            {decoder, fun gleam@dynamic@decode:decode_string/1},
            fun(Comment@4) ->
                gleam@dynamic@decode:field(
                    <<"default_schema"/utf8>>,
                    {decoder, fun gleam@dynamic@decode:decode_string/1},
                    fun(Default_schema) ->
                        gleam@dynamic@decode:field(
                            <<"name"/utf8>>,
                            {decoder, fun gleam@dynamic@decode:decode_string/1},
                            fun(Name@5) ->
                                gleam@dynamic@decode:field(
                                    <<"schemas"/utf8>>,
                                    gleam@dynamic@decode:list(Schema_decoder),
                                    fun(Schemas) ->
                                        gleam@dynamic@decode:success(
                                            {catalog,
                                                Comment@4,
                                                Default_schema,
                                                Name@5,
                                                Schemas}
                                        )
                                    end
                                )
                            end
                        )
                    end
                )
            end
        )
    end,
    Params_decoder = begin
        gleam@dynamic@decode:field(
            <<"number"/utf8>>,
            {decoder, fun gleam@dynamic@decode:decode_int/1},
            fun(Number) ->
                gleam@dynamic@decode:field(
                    <<"column"/utf8>>,
                    Table_col_decoder,
                    fun(Column) ->
                        gleam@dynamic@decode:success(
                            {query_param, Number, Column}
                        )
                    end
                )
            end
        )
    end,
    Cmd_decoder = begin
        gleam@dynamic@decode:then(
            {decoder, fun gleam@dynamic@decode:decode_string/1},
            fun(Cmd) -> case Cmd of
                    <<":one"/utf8>> ->
                        gleam@dynamic@decode:success(one);

                    <<":many"/utf8>> ->
                        gleam@dynamic@decode:success(many);

                    <<":exec"/utf8>> ->
                        gleam@dynamic@decode:success(exec_result);

                    <<":execresult"/utf8>> ->
                        gleam@dynamic@decode:success(exec_result);

                    <<":execrows"/utf8>> ->
                        gleam@dynamic@decode:success(exec_rows);

                    <<":execlastid"/utf8>> ->
                        gleam@dynamic@decode:success(exec_last_id);

                    <<":batchexec"/utf8>> ->
                        gleam@dynamic@decode:success(batch_exec);

                    <<":batchmany"/utf8>> ->
                        gleam@dynamic@decode:success(batch_many);

                    <<":batchone"/utf8>> ->
                        gleam@dynamic@decode:success(batch_one);

                    <<":copyfrom"/utf8>> ->
                        gleam@dynamic@decode:success(copy_from);

                    _ ->
                        gleam@dynamic@decode:failure(one, <<"QueryCmd"/utf8>>)
                end end
        )
    end,
    Query_decoder = begin
        gleam@dynamic@decode:field(
            <<"text"/utf8>>,
            {decoder, fun gleam@dynamic@decode:decode_string/1},
            fun(Text) ->
                gleam@dynamic@decode:field(
                    <<"name"/utf8>>,
                    {decoder, fun gleam@dynamic@decode:decode_string/1},
                    fun(Name@6) ->
                        gleam@dynamic@decode:field(
                            <<"cmd"/utf8>>,
                            Cmd_decoder,
                            fun(Cmd@1) ->
                                gleam@dynamic@decode:field(
                                    <<"filename"/utf8>>,
                                    {decoder,
                                        fun gleam@dynamic@decode:decode_string/1},
                                    fun(Filename) ->
                                        gleam@dynamic@decode:field(
                                            <<"columns"/utf8>>,
                                            gleam@dynamic@decode:list(
                                                Table_col_decoder
                                            ),
                                            fun(Columns@1) ->
                                                gleam@dynamic@decode:field(
                                                    <<"insert_into_table"/utf8>>,
                                                    gleam@dynamic@decode:optional(
                                                        Table_ref_decoder
                                                    ),
                                                    fun(Insert_into_table) ->
                                                        gleam@dynamic@decode:field(
                                                            <<"comments"/utf8>>,
                                                            gleam@dynamic@decode:list(
                                                                {decoder,
                                                                    fun gleam@dynamic@decode:decode_string/1}
                                                            ),
                                                            fun(Comments) ->
                                                                gleam@dynamic@decode:field(
                                                                    <<"params"/utf8>>,
                                                                    gleam@dynamic@decode:list(
                                                                        Params_decoder
                                                                    ),
                                                                    fun(Params) ->
                                                                        _pipe@1 = {'query',
                                                                            Text,
                                                                            Name@6,
                                                                            Cmd@1,
                                                                            Filename,
                                                                            Columns@1,
                                                                            Insert_into_table,
                                                                            Comments,
                                                                            Params},
                                                                        gleam@dynamic@decode:success(
                                                                            _pipe@1
                                                                        )
                                                                    end
                                                                )
                                                            end
                                                        )
                                                    end
                                                )
                                            end
                                        )
                                    end
                                )
                            end
                        )
                    end
                )
            end
        )
    end,
    Decoder = begin
        gleam@dynamic@decode:field(
            <<"sqlc_version"/utf8>>,
            {decoder, fun gleam@dynamic@decode:decode_string/1},
            fun(Sqlc_version) ->
                gleam@dynamic@decode:field(
                    <<"plugin_options"/utf8>>,
                    {decoder, fun gleam@dynamic@decode:decode_string/1},
                    fun(Plugin_options) ->
                        gleam@dynamic@decode:field(
                            <<"global_options"/utf8>>,
                            {decoder, fun gleam@dynamic@decode:decode_string/1},
                            fun(Global_options) ->
                                gleam@dynamic@decode:field(
                                    <<"catalog"/utf8>>,
                                    Catalog_decoder,
                                    fun(Catalog@2) ->
                                        gleam@dynamic@decode:field(
                                            <<"queries"/utf8>>,
                                            gleam@dynamic@decode:list(
                                                Query_decoder
                                            ),
                                            fun(Queries) ->
                                                _pipe@2 = {s_q_l_c,
                                                    Sqlc_version,
                                                    Plugin_options,
                                                    Global_options,
                                                    Catalog@2,
                                                    Queries},
                                                gleam@dynamic@decode:success(
                                                    _pipe@2
                                                )
                                            end
                                        )
                                    end
                                )
                            end
                        )
                    end
                )
            end
        )
    end,
    gleam@dynamic@decode:run(Data, Decoder).

-file("src/parrot/internal/sqlc.gleam", 389).
?DOC(false).
-spec gen_sqlc_json(engine(), list(binary())) -> binary().
gen_sqlc_json(Engine, Queries) ->
    Config = {config,
        version2,
        [{sql,
                {some, <<"schema.sql"/utf8>>},
                {some, {queries_multiple, Queries}},
                Engine,
                {some,
                    {gen,
                        {some,
                            {gen_json,
                                {some, <<"."/utf8>>},
                                {some, <<"  "/utf8>>},
                                {some, <<"queries.json"/utf8>>}}}}}}]},
    config_to_json_string(Config).

-file("src/parrot/internal/sqlc.gleam", 410).
?DOC(false).
-spec sqlc_binary_path() -> binary().
sqlc_binary_path() ->
    filepath:join(parrot@internal@project:root(), <<"build/.parrot/sqlc"/utf8>>).

-file("src/parrot/internal/sqlc.gleam", 414).
?DOC(false).
-spec binary_exists(binary()) -> boolean().
binary_exists(Path) ->
    case simplifile_erl:is_file(Path) of
        {ok, true} ->
            true;

        {ok, false} ->
            false;

        {error, _} ->
            false
    end.

-file("src/parrot/internal/sqlc.gleam", 471).
?DOC(false).
-spec check_sqlc_integrity(bitstring(), binary()) -> nil.
check_sqlc_integrity(Bin, Expected_hash) ->
    Hash = gleam@crypto:hash(sha256, Bin),
    Hash_string = gleam_stdlib:base16_encode(Hash),
    case string:lowercase(Hash_string) =:= string:lowercase(Expected_hash) of
        true ->
            nil;

        false ->
            erlang:error(#{gleam_error => panic,
                    message => <<"sqlc binary hash did not match expected hash!"/utf8>>,
                    file => <<?FILEPATH/utf8>>,
                    module => <<"parrot/internal/sqlc"/utf8>>,
                    function => <<"check_sqlc_integrity"/utf8>>,
                    line => 476})
    end.

-file("src/parrot/internal/sqlc.gleam", 578).
?DOC(false).
-spec get_os() -> binary().
get_os() ->
    parrot_ffi:get_os().

-file("src/parrot/internal/sqlc.gleam", 581).
?DOC(false).
-spec get_cpu() -> binary().
get_cpu() ->
    parrot_ffi:get_cpu().

-file("src/parrot/internal/sqlc.gleam", 584).
?DOC(false).
-spec download_zip(binary()) -> {ok, bitstring()} |
    {error, gleam@dynamic:dynamic_()}.
download_zip(Url) ->
    parrot_ffi:download_zip(Url).

-file("src/parrot/internal/sqlc.gleam", 587).
?DOC(false).
-spec extract_sqlc_binary(bitstring()) -> {ok, bitstring()} |
    {error, gleam@dynamic:dynamic_()}.
extract_sqlc_binary(Tarball) ->
    parrot_ffi:extract_sqlc_binary(Tarball).

-file("src/parrot/internal/sqlc.gleam", 423).
?DOC(false).
-spec get_download_path_and_hash() -> {ok, {binary(), binary()}} |
    {error, parrot@internal@errors:parrot_error()}.
get_download_path_and_hash() ->
    Base = <<"https://downloads.sqlc.dev/sqlc_"/utf8, "1.30.0"/utf8>>,
    Os = parrot_ffi:get_os(),
    Cpu = parrot_ffi:get_cpu(),
    Platform = case {Os, Cpu} of
        {<<"darwin"/utf8>>, <<"arm64"/utf8>>} ->
            {ok,
                {<<"_darwin_arm64.tar.gz"/utf8>>,
                    <<"d8e6153c9a6c74fa178abc4465c13ac008c06d64f50720c4b7c7203f98c8cfc6"/utf8>>}};

        {<<"darwin"/utf8>>, <<"aarch64"/utf8>>} ->
            {ok,
                {<<"_darwin_arm64.tar.gz"/utf8>>,
                    <<"d8e6153c9a6c74fa178abc4465c13ac008c06d64f50720c4b7c7203f98c8cfc6"/utf8>>}};

        {<<"darwin"/utf8>>, <<"amd64"/utf8>>} ->
            {ok,
                {<<"_darwin_amd64.tar.gz"/utf8>>,
                    <<"7473103d9148b218a57e15a53b562c285c916fdedd85f6053ce9feaa714dcfd5"/utf8>>}};

        {<<"darwin"/utf8>>, <<"x86_64"/utf8>>} ->
            {ok,
                {<<"_darwin_amd64.tar.gz"/utf8>>,
                    <<"7473103d9148b218a57e15a53b562c285c916fdedd85f6053ce9feaa714dcfd5"/utf8>>}};

        {<<"darwin"/utf8>>, <<"x64"/utf8>>} ->
            {ok,
                {<<"_darwin_amd64.tar.gz"/utf8>>,
                    <<"7473103d9148b218a57e15a53b562c285c916fdedd85f6053ce9feaa714dcfd5"/utf8>>}};

        {<<"linux"/utf8>>, <<"arm64"/utf8>>} ->
            {ok,
                {<<"_linux_arm64.tar.gz"/utf8>>,
                    <<"845fb31828129f3ecd3442f24e3ac0e8b1188660bf6807b8c652bd7acece0af7"/utf8>>}};

        {<<"linux"/utf8>>, <<"aarch64"/utf8>>} ->
            {ok,
                {<<"_linux_arm64.tar.gz"/utf8>>,
                    <<"845fb31828129f3ecd3442f24e3ac0e8b1188660bf6807b8c652bd7acece0af7"/utf8>>}};

        {<<"linux"/utf8>>, <<"amd64"/utf8>>} ->
            {ok,
                {<<"_linux_amd64.tar.gz"/utf8>>,
                    <<"e47db21025595d7e77b1260b2f97b6793401a4cba047d42e635c347e8443b5f4"/utf8>>}};

        {<<"linux"/utf8>>, <<"x86_64"/utf8>>} ->
            {ok,
                {<<"_linux_amd64.tar.gz"/utf8>>,
                    <<"e47db21025595d7e77b1260b2f97b6793401a4cba047d42e635c347e8443b5f4"/utf8>>}};

        {<<"linux"/utf8>>, <<"x64"/utf8>>} ->
            {ok,
                {<<"_linux_amd64.tar.gz"/utf8>>,
                    <<"e47db21025595d7e77b1260b2f97b6793401a4cba047d42e635c347e8443b5f4"/utf8>>}};

        {<<"win32"/utf8>>, <<"amd64"/utf8>>} ->
            {ok,
                {<<"_windows_amd64.tar.gz"/utf8>>,
                    <<"3fd5852bb05bd77d2bf4184984784844b55c1aa1f64ed69099d5fc528a10307e"/utf8>>}};

        {<<"win32"/utf8>>, <<"x86_64"/utf8>>} ->
            {ok,
                {<<"_windows_amd64.tar.gz"/utf8>>,
                    <<"3fd5852bb05bd77d2bf4184984784844b55c1aa1f64ed69099d5fc528a10307e"/utf8>>}};

        {<<"win32"/utf8>>, <<"x64"/utf8>>} ->
            {ok,
                {<<"_windows_amd64.tar.gz"/utf8>>,
                    <<"3fd5852bb05bd77d2bf4184984784844b55c1aa1f64ed69099d5fc528a10307e"/utf8>>}};

        {_, _} ->
            {error, nil}
    end,
    gleam@result:'try'(
        gleam@result:replace_error(
            Platform,
            {sqlc_download_error,
                <<<<<<"unsupported platform: "/utf8, Os/binary>>/binary,
                        ", "/utf8>>/binary,
                    Cpu/binary>>}
        ),
        fun(_use0) ->
            {Platform@1, Hash} = _use0,
            {ok, {<<Base/binary, Platform@1/binary>>, Hash}}
        end
    ).

-file("src/parrot/internal/sqlc.gleam", 480).
?DOC(false).
-spec verify_binary() -> {ok, nil} |
    {error, parrot@internal@errors:parrot_error()}.
verify_binary() ->
    gleam@result:'try'(
        get_download_path_and_hash(),
        fun(_use0) ->
            {Download, _} = _use0,
            Path = sqlc_binary_path(),
            Dir = filepath:directory_name(Path),
            Gen_res = parrot@internal@shellout:command(
                <<"./sqlc"/utf8>>,
                [<<"version"/utf8>>],
                Dir,
                []
            ),
            case Gen_res of
                {error, _} ->
                    Information = begin
                        _pipe = [<<"download path: "/utf8, Download/binary>>,
                            <<"os: "/utf8, (parrot_ffi:get_os())/binary>>,
                            <<"cpu: "/utf8, (parrot_ffi:get_cpu())/binary>>,
                            <<"sqlc binary path: "/utf8, Path/binary>>],
                        gleam@string:join(_pipe, <<"\n"/utf8>>)
                    end,
                    {error,
                        {sqlc_download_error,
                            <<"could not verify sqlc binary. information:\n"/utf8,
                                Information/binary>>}};

                {ok, V} ->
                    Sqlc_version = <<"v"/utf8, "1.30.0"/utf8>>,
                    V@1 = gleam@string:trim(V),
                    case V@1 =:= Sqlc_version of
                        true ->
                            {ok, nil};

                        false ->
                            {error,
                                {sqlc_version_error,
                                    <<<<<<"Could not match sqlc version. Wanted "/utf8,
                                                Sqlc_version/binary>>/binary,
                                            ". Received "/utf8>>/binary,
                                        V@1/binary>>}}
                    end
            end
        end
    ).

-file("src/parrot/internal/sqlc.gleam", 519).
?DOC(false).
-spec download_binary() -> {ok, nil} |
    {error, parrot@internal@errors:parrot_error()}.
download_binary() ->
    Path = sqlc_binary_path(),
    Dir = filepath:directory_name(Path),
    case simplifile:create_directory_all(Dir) of
        {ok, _} -> nil;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"parrot/internal/sqlc"/utf8>>,
                        function => <<"download_binary"/utf8>>,
                        line => 522,
                        value => _assert_fail,
                        start => 13675,
                        'end' => 13730,
                        pattern_start => 13686,
                        pattern_end => 13691})
    end,
    gleam@result:'try'(
        get_download_path_and_hash(),
        fun(_use0) ->
            {Download, Hash} = _use0,
            _ = case binary_exists(Path) of
                true ->
                    {ok, nil};

                false ->
                    case verify_binary() of
                        {error, {sqlc_version_error, _}} ->
                            _assert_subject = simplifile_erl:delete(Path),
                            case _assert_subject of
                                {ok, _} -> _assert_subject;
                                _assert_fail@1 ->
                                    erlang:error(#{gleam_error => let_assert,
                                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                                file => <<?FILEPATH/utf8>>,
                                                module => <<"parrot/internal/sqlc"/utf8>>,
                                                function => <<"download_binary"/utf8>>,
                                                line => 532,
                                                value => _assert_fail@1,
                                                start => 14013,
                                                'end' => 14055,
                                                pattern_start => 14024,
                                                pattern_end => 14029})
                            end;

                        _ ->
                            {ok, nil}
                    end
            end,
            Exists = binary_exists(Path),
            gleam@bool:lazy_guard(
                Exists,
                fun() ->
                    gleam@result:'try'(
                        begin
                            _pipe = simplifile_erl:read_bits(Path),
                            gleam@result:map_error(
                                _pipe,
                                fun(_) ->
                                    {sqlc_download_error,
                                        <<"could not verify"/utf8>>}
                                end
                            )
                        end,
                        fun(Bin) ->
                            check_sqlc_integrity(Bin, Hash),
                            {ok, nil}
                        end
                    )
                end,
                fun() ->
                    gleam@result:'try'(
                        begin
                            _pipe@1 = parrot_ffi:download_zip(Download),
                            gleam@result:map_error(
                                _pipe@1,
                                fun(_) ->
                                    {sqlc_download_error,
                                        <<"could not curl the sqlc binary"/utf8>>}
                                end
                            )
                        end,
                        fun(Tarball) ->
                            gleam@result:'try'(
                                begin
                                    _pipe@2 = parrot_ffi:extract_sqlc_binary(
                                        Tarball
                                    ),
                                    gleam@result:map_error(
                                        _pipe@2,
                                        fun(_) ->
                                            {sqlc_download_error,
                                                <<"could not unzip the sqlc binary"/utf8>>}
                                        end
                                    )
                                end,
                                fun(Bin@1) ->
                                    check_sqlc_integrity(Bin@1, Hash),
                                    case simplifile_erl:write_bits(Path, Bin@1) of
                                        {ok, _} -> nil;
                                        _assert_fail@2 ->
                                            erlang:error(
                                                    #{gleam_error => let_assert,
                                                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                                        file => <<?FILEPATH/utf8>>,
                                                        module => <<"parrot/internal/sqlc"/utf8>>,
                                                        function => <<"download_binary"/utf8>>,
                                                        line => 564,
                                                        value => _assert_fail@2,
                                                        start => 14769,
                                                        'end' => 14820,
                                                        pattern_start => 14780,
                                                        pattern_end => 14785}
                                                )
                                    end,
                                    Permissions = {file_permissions,
                                        gleam@set:from_list(
                                            [read, write, execute]
                                        ),
                                        gleam@set:from_list([read, execute]),
                                        gleam@set:from_list([read, execute])},
                                    _ = simplifile:set_permissions(
                                        Path,
                                        Permissions
                                    ),
                                    {ok, nil}
                                end
                            )
                        end
                    )
                end
            )
        end
    ).
