-module(parrot@internal@errors).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/parrot/internal/errors.gleam").
-export([err_to_string/1]).
-export_type([parrot_error/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-type parrot_error() :: {unknown_engine, binary()} |
    {sqlite_d_b_not_found, binary()} |
    {my_sql_d_b_not_found, binary()} |
    {postgre_sql_d_b_not_found, binary()} |
    {sqlc_download_error, binary()} |
    {sqlc_version_error, binary()} |
    {sqlc_generate_error, binary()} |
    {gleam_format_error, binary()} |
    no_queries_found |
    mysqldump_error |
    {pgdump_error, binary()} |
    codegen_error |
    {duplicate_definition_error, binary(), binary()} |
    {empty_enum_error, binary()} |
    {duplicate_enum_value_error, binary(), binary(), binary()}.

-file("src/parrot/internal/errors.gleam", 24).
?DOC(false).
-spec err_to_string(parrot_error()) -> binary().
err_to_string(Error) ->
    case Error of
        {my_sql_d_b_not_found, _} ->
            <<"mysql db not found"/utf8>>;

        {postgre_sql_d_b_not_found, _} ->
            <<"postgresql db not found"/utf8>>;

        {sqlite_d_b_not_found, _} ->
            <<"sqlite db not found"/utf8>>;

        mysqldump_error ->
            <<"there was an error with mysqldump"/utf8>>;

        {sqlc_download_error, E} ->
            <<"there was an error downloading sqlc: "/utf8, E/binary>>;

        {sqlc_version_error, E@1} ->
            <<"incompatible sqlc version found: "/utf8, E@1/binary>>;

        {sqlc_generate_error, E@2} ->
            <<"could not call `sqlc generate`:\n"/utf8, E@2/binary>>;

        {pgdump_error, E@3} ->
            E@3;

        no_queries_found ->
            <<"no queries were found to codegen"/utf8>>;

        {unknown_engine, Engine} ->
            <<"unknown engine: "/utf8, Engine/binary>>;

        codegen_error ->
            <<"there was an error during codegen"/utf8>>;

        {gleam_format_error, Err} ->
            <<"there was an error formatting the generated code:"/utf8,
                Err/binary>>;

        {duplicate_definition_error, Name, _} ->
            <<<<<<<<<<<<<<"duplicate definition found: '"/utf8, Name/binary>>/binary,
                                    "' is defined both as an enum and as a query. "/utf8>>/binary,
                                "Consider renaming your query (e.g., to 'Get"/utf8>>/binary,
                            Name/binary>>/binary,
                        "' or 'List"/utf8>>/binary,
                    Name/binary>>/binary,
                "') to avoid the collision."/utf8>>;

        {empty_enum_error, Name@1} ->
            <<<<<<<<"enum '"/utf8, Name@1/binary>>/binary,
                        "' has no variants. "/utf8>>/binary,
                    "Empty enums cannot be represented in Gleam. "/utf8>>/binary,
                "Please add values to the enum or remove it from your schema."/utf8>>;

        {duplicate_enum_value_error, Val_name, Enum1, Enum2} ->
            <<<<<<<<<<<<<<"duplicate enum value '"/utf8, Val_name/binary>>/binary,
                                    "' found in both '"/utf8>>/binary,
                                Enum1/binary>>/binary,
                            "' and '"/utf8>>/binary,
                        Enum2/binary>>/binary,
                    "'. "/utf8>>/binary,
                "Enum values must be unique across all enums to avoid naming conflicts in generated Gleam code."/utf8>>
    end.
