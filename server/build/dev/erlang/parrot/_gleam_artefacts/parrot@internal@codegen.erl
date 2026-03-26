-module(parrot@internal@codegen).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/parrot/internal/codegen.gleam").
-export([gleam_type_to_string/1, sqlc_col_to_gleam/2, gen_column_name/3, gen_query_type/2, gen_query_function/2, gen_query_decoder/2, comment_dont_edit/0, gen_gleam_module/1, codegen_from_config/1]).
-export_type([codegen/0, gleam_type/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-type codegen() :: {codegen, list(binary())}.

-type gleam_type() :: gleam_string |
    gleam_int |
    gleam_float |
    gleam_bool |
    gleam_timestamp |
    gleam_date |
    gleam_bit_array |
    {gleam_list, gleam_type()} |
    {gleam_enum, binary()} |
    {gleam_option, gleam_type()} |
    gleam_dynamic.

-file("src/parrot/internal/codegen.gleam", 91).
?DOC(false).
-spec gleam_type_to_string(gleam_type()) -> binary().
gleam_type_to_string(Gleamtype) ->
    case Gleamtype of
        gleam_bool ->
            <<"Bool"/utf8>>;

        gleam_float ->
            <<"Float"/utf8>>;

        gleam_int ->
            <<"Int"/utf8>>;

        gleam_string ->
            <<"String"/utf8>>;

        gleam_timestamp ->
            <<"Timestamp"/utf8>>;

        gleam_date ->
            <<"Date"/utf8>>;

        gleam_bit_array ->
            <<"BitArray"/utf8>>;

        {gleam_list, Sub} ->
            <<<<"List("/utf8, (gleam_type_to_string(Sub))/binary>>/binary,
                ")"/utf8>>;

        {gleam_option, Sub@1} ->
            <<<<"Option("/utf8, (gleam_type_to_string(Sub@1))/binary>>/binary,
                ")"/utf8>>;

        {gleam_enum, Name} ->
            parrot@internal@string_case:pascal_case(Name);

        gleam_dynamic ->
            <<"decode.Dynamic"/utf8>>
    end.

-file("src/parrot/internal/codegen.gleam", 107).
?DOC(false).
-spec normalise_col_type(parrot@internal@sqlc:table_column()) -> binary().
normalise_col_type(Col) ->
    Type_ = erlang:element(4, erlang:element(16, Col)),
    case Type_ of
        <<"pg_catalog."/utf8, X/binary>> ->
            X;

        <<"public."/utf8, X@1/binary>> ->
            X@1;

        X@2 ->
            X@2
    end.

-file("src/parrot/internal/codegen.gleam", 117).
?DOC(false).
-spec built_into_gleam(binary()) -> boolean().
built_into_gleam(Value) ->
    case Value of
        <<"as"/utf8>> ->
            true;

        <<"assert"/utf8>> ->
            true;

        <<"auto"/utf8>> ->
            true;

        <<"case"/utf8>> ->
            true;

        <<"const"/utf8>> ->
            true;

        <<"delegate"/utf8>> ->
            true;

        <<"derive"/utf8>> ->
            true;

        <<"echo"/utf8>> ->
            true;

        <<"else"/utf8>> ->
            true;

        <<"fn"/utf8>> ->
            true;

        <<"if"/utf8>> ->
            true;

        <<"implement"/utf8>> ->
            true;

        <<"import"/utf8>> ->
            true;

        <<"let"/utf8>> ->
            true;

        <<"macro"/utf8>> ->
            true;

        <<"opaque"/utf8>> ->
            true;

        <<"panic"/utf8>> ->
            true;

        <<"pub"/utf8>> ->
            true;

        <<"test"/utf8>> ->
            true;

        <<"todo"/utf8>> ->
            true;

        <<"type"/utf8>> ->
            true;

        <<"use"/utf8>> ->
            true;

        _ ->
            false
    end.

-file("src/parrot/internal/codegen.gleam", 262).
?DOC(false).
-spec find_col_schema(
    parrot@internal@sqlc:table_column(),
    parrot@internal@sqlc:s_q_l_c()
) -> parrot@internal@sqlc:schema().
find_col_schema(Col, Context) ->
    Schema_name = erlang:element(3, erlang:element(16, Col)),
    Schema_name@1 = case Schema_name of
        <<""/utf8>> ->
            erlang:element(3, erlang:element(5, Context));

        <<"pg_catalog"/utf8>> ->
            erlang:element(3, erlang:element(5, Context));

        _ ->
            Schema_name
    end,
    Schema@1 = case gleam@list:find(
        erlang:element(5, erlang:element(5, Context)),
        fun(S) -> erlang:element(3, S) =:= Schema_name@1 end
    ) of
        {ok, Schema} -> Schema;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"parrot/internal/codegen"/utf8>>,
                        function => <<"find_col_schema"/utf8>>,
                        line => 270,
                        value => _assert_fail,
                        start => 7049,
                        'end' => 7144,
                        pattern_start => 7060,
                        pattern_end => 7070})
    end,
    Schema@1.

-file("src/parrot/internal/codegen.gleam", 276).
?DOC(false).
-spec sqlc_col_to_gleam(
    parrot@internal@sqlc:table_column(),
    parrot@internal@sqlc:s_q_l_c()
) -> gleam_type().
sqlc_col_to_gleam(Col, Context) ->
    gleam@bool:lazy_guard(
        not erlang:element(3, Col),
        fun() ->
            Col@1 = {table_column,
                erlang:element(2, Col),
                true,
                erlang:element(4, Col),
                erlang:element(5, Col),
                erlang:element(6, Col),
                erlang:element(7, Col),
                erlang:element(8, Col),
                erlang:element(9, Col),
                erlang:element(10, Col),
                erlang:element(11, Col),
                erlang:element(12, Col),
                erlang:element(13, Col),
                erlang:element(14, Col),
                erlang:element(15, Col),
                erlang:element(16, Col)},
            Type_ = sqlc_col_to_gleam(Col@1, Context),
            {gleam_option, Type_}
        end,
        fun() ->
            gleam@bool:lazy_guard(
                erlang:element(4, Col),
                fun() ->
                    Col@2 = {table_column,
                        erlang:element(2, Col),
                        erlang:element(3, Col),
                        false,
                        erlang:element(5, Col),
                        erlang:element(6, Col),
                        erlang:element(7, Col),
                        erlang:element(8, Col),
                        erlang:element(9, Col),
                        erlang:element(10, Col),
                        erlang:element(11, Col),
                        erlang:element(12, Col),
                        erlang:element(13, Col),
                        erlang:element(14, Col),
                        erlang:element(15, Col),
                        erlang:element(16, Col)},
                    Type_@1 = sqlc_col_to_gleam(Col@2, Context),
                    {gleam_list, Type_@1}
                end,
                fun() ->
                    gleam@bool:lazy_guard(
                        erlang:element(11, Col),
                        fun() ->
                            Col@3 = {table_column,
                                erlang:element(2, Col),
                                erlang:element(3, Col),
                                erlang:element(4, Col),
                                erlang:element(5, Col),
                                erlang:element(6, Col),
                                erlang:element(7, Col),
                                erlang:element(8, Col),
                                erlang:element(9, Col),
                                erlang:element(10, Col),
                                false,
                                erlang:element(12, Col),
                                erlang:element(13, Col),
                                erlang:element(14, Col),
                                erlang:element(15, Col),
                                erlang:element(16, Col)},
                            Type_@2 = sqlc_col_to_gleam(Col@3, Context),
                            {gleam_list, Type_@2}
                        end,
                        fun() ->
                            Sqltype = normalise_col_type(Col),
                            Schema = find_col_schema(Col, Context),
                            Enum = begin
                                _pipe = erlang:element(5, Schema),
                                gleam@list:find(
                                    _pipe,
                                    fun(E) ->
                                        erlang:element(2, E) =:= Sqltype
                                    end
                                )
                            end,
                            gleam@bool:lazy_guard(
                                gleam@result:is_ok(Enum),
                                fun() ->
                                    Enum@2 = case Enum of
                                        {ok, Enum@1} -> Enum@1;
                                        _assert_fail ->
                                            erlang:error(
                                                    #{gleam_error => let_assert,
                                                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                                        file => <<?FILEPATH/utf8>>,
                                                        module => <<"parrot/internal/codegen"/utf8>>,
                                                        function => <<"sqlc_col_to_gleam"/utf8>>,
                                                        line => 303,
                                                        value => _assert_fail,
                                                        start => 8051,
                                                        'end' => 8077,
                                                        pattern_start => 8062,
                                                        pattern_end => 8070}
                                                )
                                    end,
                                    {gleam_enum, erlang:element(2, Enum@2)}
                                end,
                                fun() ->
                                    Sqltype@1 = string:lowercase(Sqltype),
                                    Tiny_bool = (Sqltype@1 =:= <<"tinyint"/utf8>>)
                                    andalso (erlang:element(6, Col) =:= 1),
                                    gleam@bool:guard(
                                        Tiny_bool,
                                        gleam_bool,
                                        fun() -> case Sqltype@1 of
                                                <<"int"/utf8, _/binary>> ->
                                                    gleam_int;

                                                <<"tinyint"/utf8>> ->
                                                    gleam_int;

                                                <<"smallint"/utf8>> ->
                                                    gleam_int;

                                                <<"mediumint"/utf8>> ->
                                                    gleam_int;

                                                <<"bigint"/utf8>> ->
                                                    gleam_int;

                                                <<"serial"/utf8, _/binary>> ->
                                                    gleam_int;

                                                <<"smallserial"/utf8>> ->
                                                    gleam_int;

                                                <<"bigserial"/utf8>> ->
                                                    gleam_int;

                                                <<"year"/utf8>> ->
                                                    gleam_int;

                                                <<"float"/utf8, _/binary>> ->
                                                    gleam_float;

                                                <<"dec"/utf8, _/binary>> ->
                                                    gleam_float;

                                                <<"fixed"/utf8>> ->
                                                    gleam_float;

                                                <<"real"/utf8>> ->
                                                    gleam_float;

                                                <<"numeric"/utf8>> ->
                                                    gleam_float;

                                                <<"double"/utf8>> ->
                                                    gleam_float;

                                                <<"money"/utf8, _/binary>> ->
                                                    gleam_float;

                                                <<"char"/utf8, _/binary>> ->
                                                    gleam_string;

                                                <<"varchar"/utf8, _/binary>> ->
                                                    gleam_string;

                                                <<"text"/utf8, _/binary>> ->
                                                    gleam_string;

                                                <<"mediumtext"/utf8, _/binary>> ->
                                                    gleam_string;

                                                <<"longtext"/utf8, _/binary>> ->
                                                    gleam_string;

                                                <<"citext"/utf8, _/binary>> ->
                                                    gleam_string;

                                                <<"json"/utf8, _/binary>> ->
                                                    gleam_string;

                                                <<"uuid"/utf8>> ->
                                                    gleam_bit_array;

                                                <<"bit"/utf8>> ->
                                                    gleam_bit_array;

                                                <<"blob"/utf8>> ->
                                                    gleam_bit_array;

                                                <<"tinyblob"/utf8>> ->
                                                    gleam_bit_array;

                                                <<"smallblob"/utf8>> ->
                                                    gleam_bit_array;

                                                <<"mediumblob"/utf8>> ->
                                                    gleam_bit_array;

                                                <<"longblob"/utf8>> ->
                                                    gleam_bit_array;

                                                <<"binary"/utf8>> ->
                                                    gleam_bit_array;

                                                <<"varbinary"/utf8>> ->
                                                    gleam_bit_array;

                                                <<"byte"/utf8, _/binary>> ->
                                                    gleam_bit_array;

                                                <<"datetime"/utf8, _/binary>> ->
                                                    gleam_timestamp;

                                                <<"time"/utf8, _/binary>> ->
                                                    gleam_timestamp;

                                                <<"date"/utf8, _/binary>> ->
                                                    gleam_date;

                                                <<"bool"/utf8, _/binary>> ->
                                                    gleam_bool;

                                                _ ->
                                                    gleam_dynamic
                                            end end
                                    )
                                end
                            )
                        end
                    )
                end
            )
        end
    ).

-file("src/parrot/internal/codegen.gleam", 145).
?DOC(false).
-spec find_duplicates(parrot@internal@sqlc:s_q_l_c()) -> {ok, nil} |
    {error, parrot@internal@errors:parrot_error()}.
find_duplicates(Context) ->
    Enums_for_duplicate_check = begin
        _pipe@1 = gleam@list:flat_map(
            erlang:element(6, Context),
            fun(Query) ->
                _pipe = gleam@list:filter_map(
                    erlang:element(6, Query),
                    fun(Col) -> case sqlc_col_to_gleam(Col, Context) of
                            {gleam_option, {gleam_enum, _}} ->
                                Type_ = normalise_col_type(Col),
                                Schema = find_col_schema(Col, Context),
                                case gleam@list:find(
                                    erlang:element(5, Schema),
                                    fun(E) -> erlang:element(2, E) =:= Type_ end
                                ) of
                                    {ok, Enum} ->
                                        {ok,
                                            {parrot@internal@string_case:pascal_case(
                                                    erlang:element(2, Enum)
                                                ),
                                                erlang:element(3, Enum)}};

                                    {error, _} ->
                                        {error, nil}
                                end;

                            {gleam_enum, _} ->
                                Type_ = normalise_col_type(Col),
                                Schema = find_col_schema(Col, Context),
                                case gleam@list:find(
                                    erlang:element(5, Schema),
                                    fun(E) -> erlang:element(2, E) =:= Type_ end
                                ) of
                                    {ok, Enum} ->
                                        {ok,
                                            {parrot@internal@string_case:pascal_case(
                                                    erlang:element(2, Enum)
                                                ),
                                                erlang:element(3, Enum)}};

                                    {error, _} ->
                                        {error, nil}
                                end;

                            _ ->
                                {error, nil}
                        end end
                ),
                lists:append(
                    _pipe,
                    gleam@list:filter_map(
                        erlang:element(9, Query),
                        fun(Param) ->
                            case sqlc_col_to_gleam(
                                erlang:element(3, Param),
                                Context
                            ) of
                                {gleam_option, {gleam_enum, _}} ->
                                    Type_@1 = normalise_col_type(
                                        erlang:element(3, Param)
                                    ),
                                    Schema@1 = find_col_schema(
                                        erlang:element(3, Param),
                                        Context
                                    ),
                                    case gleam@list:find(
                                        erlang:element(5, Schema@1),
                                        fun(E@1) ->
                                            erlang:element(2, E@1) =:= Type_@1
                                        end
                                    ) of
                                        {ok, Enum@1} ->
                                            {ok,
                                                {parrot@internal@string_case:pascal_case(
                                                        erlang:element(
                                                            2,
                                                            Enum@1
                                                        )
                                                    ),
                                                    erlang:element(3, Enum@1)}};

                                        {error, _} ->
                                            {error, nil}
                                    end;

                                {gleam_enum, _} ->
                                    Type_@1 = normalise_col_type(
                                        erlang:element(3, Param)
                                    ),
                                    Schema@1 = find_col_schema(
                                        erlang:element(3, Param),
                                        Context
                                    ),
                                    case gleam@list:find(
                                        erlang:element(5, Schema@1),
                                        fun(E@1) ->
                                            erlang:element(2, E@1) =:= Type_@1
                                        end
                                    ) of
                                        {ok, Enum@1} ->
                                            {ok,
                                                {parrot@internal@string_case:pascal_case(
                                                        erlang:element(
                                                            2,
                                                            Enum@1
                                                        )
                                                    ),
                                                    erlang:element(3, Enum@1)}};

                                        {error, _} ->
                                            {error, nil}
                                    end;

                                _ ->
                                    {error, nil}
                            end
                        end
                    )
                )
            end
        ),
        gleam@list:unique(_pipe@1)
    end,
    Query_names = begin
        _pipe@2 = gleam@list:map(
            erlang:element(6, Context),
            fun(Q) ->
                parrot@internal@string_case:pascal_case(erlang:element(3, Q))
            end
        ),
        _pipe@3 = gleam@set:from_list(_pipe@2),
        gleam@set:to_list(_pipe@3)
    end,
    Has_duplicate = gleam@list:any(
        Enums_for_duplicate_check,
        fun(Item) -> case Item of
                {Enum_name, _} ->
                    gleam@list:any(
                        Query_names,
                        fun(Query_name) -> Enum_name =:= Query_name end
                    )
            end end
    ),
    case Has_duplicate of
        true ->
            First@1 = case gleam@list:find(
                Enums_for_duplicate_check,
                fun(Item@1) -> case Item@1 of
                        {Enum_name@1, _} ->
                            gleam@list:any(
                                Query_names,
                                fun(Query_name@1) ->
                                    Enum_name@1 =:= Query_name@1
                                end
                            )
                    end end
            ) of
                {ok, {First, _}} -> First;
                _assert_fail ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"parrot/internal/codegen"/utf8>>,
                                function => <<"find_duplicates"/utf8>>,
                                line => 194,
                                value => _assert_fail,
                                start => 4887,
                                'end' => 5127,
                                pattern_start => 4898,
                                pattern_end => 4913})
            end,
            Query@2 = case gleam@list:find(
                erlang:element(6, Context),
                fun(Q@1) ->
                    parrot@internal@string_case:pascal_case(
                        erlang:element(3, Q@1)
                    )
                    =:= First@1
                end
            ) of
                {ok, Query@1} -> Query@1;
                _assert_fail@1 ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"parrot/internal/codegen"/utf8>>,
                                function => <<"find_duplicates"/utf8>>,
                                line => 201,
                                value => _assert_fail@1,
                                start => 5134,
                                'end' => 5261,
                                pattern_start => 5145,
                                pattern_end => 5154})
            end,
            {error,
                {duplicate_definition_error,
                    First@1,
                    erlang:element(3, Query@2)}};

        false ->
            case gleam@list:find(
                Enums_for_duplicate_check,
                fun(Item@2) -> case Item@2 of
                        {_, Vals} ->
                            gleam@list:is_empty(Vals)
                    end end
            ) of
                {ok, {Name, _}} ->
                    {error, {empty_enum_error, Name}};

                {error, _} ->
                    All_enum_values = gleam@list:flat_map(
                        Enums_for_duplicate_check,
                        fun(Item@3) -> case Item@3 of
                                {Enum_name@2, Vals@1} ->
                                    gleam@list:map(
                                        Vals@1,
                                        fun(Val) ->
                                            {parrot@internal@string_case:pascal_case(
                                                    Val
                                                ),
                                                Enum_name@2}
                                        end
                                    )
                            end end
                    ),
                    case gleam@list:find(
                        All_enum_values,
                        fun(Item@4) -> case Item@4 of
                                {Val_name, _} ->
                                    gleam@list:count(
                                        All_enum_values,
                                        fun(I) -> case I of
                                                {V, _} ->
                                                    V =:= Val_name
                                            end end
                                    )
                                    > 1
                            end end
                    ) of
                        {ok, {Val_name@1, First_enum}} ->
                            Second_enum@1 = case gleam@list:find(
                                All_enum_values,
                                fun(Item@5) -> case Item@5 of
                                        {V@1, Enum@2} ->
                                            (V@1 =:= Val_name@1) andalso (Enum@2
                                            /= First_enum)
                                    end end
                            ) of
                                {ok, {_, Second_enum}} -> Second_enum;
                                _assert_fail@2 ->
                                    erlang:error(#{gleam_error => let_assert,
                                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                                file => <<?FILEPATH/utf8>>,
                                                module => <<"parrot/internal/codegen"/utf8>>,
                                                function => <<"find_duplicates"/utf8>>,
                                                line => 242,
                                                value => _assert_fail@2,
                                                start => 6357,
                                                'end' => 6584,
                                                pattern_start => 6368,
                                                pattern_end => 6389})
                            end,
                            {error,
                                {duplicate_enum_value_error,
                                    Val_name@1,
                                    First_enum,
                                    Second_enum@1}};

                        {error, _} ->
                            {ok, nil}
                    end
            end
    end.

-file("src/parrot/internal/codegen.gleam", 352).
?DOC(false).
-spec gen_column_name(
    integer(),
    parrot@internal@sqlc:'query'(),
    parrot@internal@sqlc:table_column()
) -> binary().
gen_column_name(Index, Query, Col) ->
    Occ = begin
        _pipe = erlang:element(6, Query),
        gleam@list:count(
            _pipe,
            fun(Col2) -> erlang:element(2, Col) =:= erlang:element(2, Col2) end
        )
    end,
    Result = case Occ of
        0 ->
            erlang:error(#{gleam_error => panic,
                    message => (<<"could not find column name: "/utf8,
                        (erlang:element(2, Col))/binary>>),
                    file => <<?FILEPATH/utf8>>,
                    module => <<"parrot/internal/codegen"/utf8>>,
                    function => <<"gen_column_name"/utf8>>,
                    line => 361});

        1 ->
            erlang:element(2, Col);

        _ ->
            case erlang:element(15, Col) of
                none ->
                    erlang:element(2, Col);

                {some, T} ->
                    <<<<(erlang:element(4, T))/binary, "_"/utf8>>/binary,
                        (erlang:element(2, Col))/binary>>
            end
    end,
    Result@1 = case parrot@internal@string_case:snake_case(Result) of
        <<""/utf8>> ->
            <<"col_"/utf8, (erlang:integer_to_binary(Index))/binary>>;

        X ->
            X
    end,
    case built_into_gleam(Result@1) of
        false ->
            Result@1;

        true ->
            <<Result@1/binary, "_"/utf8>>
    end.

-file("src/parrot/internal/codegen.gleam", 380).
?DOC(false).
-spec gen_query_type(
    parrot@internal@sqlc:'query'(),
    parrot@internal@sqlc:s_q_l_c()
) -> binary().
gen_query_type(Query, Context) ->
    Name = parrot@internal@string_case:pascal_case(erlang:element(3, Query)),
    Args = begin
        _pipe = erlang:element(6, Query),
        _pipe@1 = gleam@list:index_map(
            _pipe,
            fun(Col, Index) ->
                Gleam_type = sqlc_col_to_gleam(Col, Context),
                Col_type = gleam_type_to_string(Gleam_type),
                Col_name = gen_column_name(Index, Query, Col),
                <<<<Col_name/binary, ": "/utf8>>/binary, Col_type/binary>>
            end
        ),
        _pipe@2 = gleam@list:map(
            _pipe@1,
            fun(Str) -> <<"    "/utf8, Str/binary>> end
        ),
        gleam@string:join(_pipe@2, <<",\n"/utf8>>)
    end,
    _pipe@3 = [<<<<"pub type "/utf8, Name/binary>>/binary, " {"/utf8>>,
        <<<<"  "/utf8, Name/binary>>/binary, "("/utf8>>,
        Args,
        <<"  )"/utf8>>,
        <<"}"/utf8>>],
    gleam@string:join(_pipe@3, <<"\n"/utf8>>).

-file("src/parrot/internal/codegen.gleam", 398).
?DOC(false).
-spec gleam_type_to_param(gleam_type()) -> binary().
gleam_type_to_param(Gtype) ->
    case Gtype of
        gleam_int ->
            <<"dev.ParamInt"/utf8>>;

        gleam_string ->
            <<"dev.ParamString"/utf8>>;

        gleam_float ->
            <<"dev.ParamFloat"/utf8>>;

        gleam_bool ->
            <<"dev.ParamBool"/utf8>>;

        gleam_timestamp ->
            <<"dev.ParamTimestamp"/utf8>>;

        gleam_date ->
            <<"dev.ParamDate"/utf8>>;

        gleam_bit_array ->
            <<"dev.ParamBitArray"/utf8>>;

        gleam_dynamic ->
            <<"dev.ParamDynamic"/utf8>>;

        {gleam_enum, _} ->
            <<"dev.ParamString"/utf8>>;

        {gleam_option, Sub} ->
            <<<<"dev.ParamNullable("/utf8, (gleam_type_to_param(Sub))/binary>>/binary,
                ")"/utf8>>;

        {gleam_list, Sub@1} ->
            <<<<"dev.ParamList("/utf8, (gleam_type_to_param(Sub@1))/binary>>/binary,
                ")"/utf8>>
    end.

-file("src/parrot/internal/codegen.gleam", 414).
?DOC(false).
-spec gleam_type_to_slice_param(gleam_type()) -> binary().
gleam_type_to_slice_param(Gtype) ->
    case Gtype of
        {gleam_list, Sub} ->
            gleam_type_to_param(Sub);

        _ ->
            gleam_type_to_param(Gtype)
    end.

-file("src/parrot/internal/codegen.gleam", 421).
?DOC(false).
-spec gleam_type_to_return_type(binary(), gleam_type()) -> binary().
gleam_type_to_return_type(Variable, Gt) ->
    Variable@1 = case built_into_gleam(Variable) of
        false ->
            Variable;

        true ->
            <<Variable/binary, "_"/utf8>>
    end,
    Value = case Gt of
        {gleam_enum, Name} ->
            Name@1 = parrot@internal@string_case:snake_case(Name),
            <<<<<<Name@1/binary, "_to_string("/utf8>>/binary,
                    Variable@1/binary>>/binary,
                ")"/utf8>>;

        _ ->
            Variable@1
    end,
    case Gt of
        {gleam_list, Sub_type} ->
            Sub_param = gleam_type_to_param(Sub_type),
            <<<<<<<<"dev.ParamList(list.map("/utf8, Value/binary>>/binary,
                        ", "/utf8>>/binary,
                    Sub_param/binary>>/binary,
                "))"/utf8>>;

        {gleam_option, Sub_type@1} ->
            <<<<<<<<"dev.ParamNullable(option.map("/utf8, Value/binary>>/binary,
                        ", fn (v) { "/utf8>>/binary,
                    (gleam_type_to_return_type(<<"v"/utf8>>, Sub_type@1))/binary>>/binary,
                " }))"/utf8>>;

        _ ->
            Param = gleam_type_to_param(Gt),
            <<<<<<Param/binary, "("/utf8>>/binary, Value/binary>>/binary,
                ")"/utf8>>
    end.

-file("src/parrot/internal/codegen.gleam", 453).
?DOC(false).
-spec gen_query_function(
    parrot@internal@sqlc:'query'(),
    parrot@internal@sqlc:s_q_l_c()
) -> binary().
gen_query_function(Query, Context) ->
    Fn_name = parrot@internal@string_case:snake_case(erlang:element(3, Query)),
    Def_fn_args = begin
        _pipe = erlang:element(9, Query),
        _pipe@1 = gleam@list:map(
            _pipe,
            fun(P) ->
                Gleam_type = sqlc_col_to_gleam(erlang:element(3, P), Context),
                Name = erlang:element(2, erlang:element(3, P)),
                Name@1 = case built_into_gleam(Name) of
                    false ->
                        Name;

                    true ->
                        <<Name/binary, "_"/utf8>>
                end,
                case Name@1 of
                    <<""/utf8>> ->
                        erlang:error(#{gleam_error => panic,
                                message => (<<<<"Parameter name for "/utf8,
                                        Fn_name/binary>>/binary,
                                    " is empty! Please use a named parameter instead (f.e. \"sqlc.arg(name)\" or \"@arg\")"/utf8>>),
                                file => <<?FILEPATH/utf8>>,
                                module => <<"parrot/internal/codegen"/utf8>>,
                                function => <<"gen_query_function"/utf8>>,
                                line => 468});

                    _ ->
                        nil
                end,
                <<<<<<<<Name@1/binary, " "/utf8>>/binary, Name@1/binary>>/binary,
                        ": "/utf8>>/binary,
                    (gleam_type_to_string(Gleam_type))/binary>>
            end
        ),
        gleam@string:join(_pipe@1, <<", "/utf8>>)
    end,
    Has_slices = gleam@list:any(
        erlang:element(9, Query),
        fun(P@1) -> erlang:element(11, erlang:element(3, P@1)) end
    ),
    Slice_decls = case Has_slices of
        true ->
            _pipe@2 = erlang:element(9, Query),
            _pipe@3 = gleam@list:filter(
                _pipe@2,
                fun(P@2) -> erlang:element(11, erlang:element(3, P@2)) end
            ),
            _pipe@4 = gleam@list:map(
                _pipe@3,
                fun(P@3) ->
                    Name@2 = erlang:element(2, erlang:element(3, P@3)),
                    Safe_name = case built_into_gleam(Name@2) of
                        false ->
                            Name@2;

                        true ->
                            <<Name@2/binary, "_"/utf8>>
                    end,
                    <<<<<<<<"let "/utf8, Safe_name/binary>>/binary,
                                "_slice = string.repeat(\",?\", list.length("/utf8>>/binary,
                            Safe_name/binary>>/binary,
                        "))"/utf8>>
                end
            ),
            gleam@string:join(_pipe@4, <<"\n  "/utf8>>);

        false ->
            <<""/utf8>>
    end,
    Text = case Has_slices of
        true ->
            Escaped = gleam@string:replace(
                erlang:element(2, Query),
                <<"\""/utf8>>,
                <<"\\\""/utf8>>
            ),
            gleam@list:fold(
                erlang:element(9, Query),
                Escaped,
                fun(Acc, P@4) ->
                    case erlang:element(11, erlang:element(3, P@4)) of
                        true ->
                            Name@3 = erlang:element(2, erlang:element(3, P@4)),
                            Safe_name@1 = case built_into_gleam(Name@3) of
                                false ->
                                    Name@3;

                                true ->
                                    <<Name@3/binary, "_"/utf8>>
                            end,
                            gleam@string:replace(
                                Acc,
                                <<<<"/*SLICE:"/utf8, Name@3/binary>>/binary,
                                    "*/?"/utf8>>,
                                <<<<"\" <> "/utf8, Safe_name@1/binary>>/binary,
                                    "_slice <> \""/utf8>>
                            );

                        false ->
                            Acc
                    end
                end
            );

        false ->
            gleam@string:replace(
                erlang:element(2, Query),
                <<"\""/utf8>>,
                <<"\\\""/utf8>>
            )
    end,
    Def_return_params = case erlang:element(9, Query) of
        [] ->
            <<"[]"/utf8>>;

        Args ->
            case Has_slices of
                false ->
                    <<<<"["/utf8,
                            (begin
                                _pipe@5 = Args,
                                _pipe@6 = gleam@list:map(
                                    _pipe@5,
                                    fun(Arg) ->
                                        Arg_type = sqlc_col_to_gleam(
                                            erlang:element(3, Arg),
                                            Context
                                        ),
                                        gleam_type_to_return_type(
                                            erlang:element(
                                                2,
                                                erlang:element(3, Arg)
                                            ),
                                            Arg_type
                                        )
                                    end
                                ),
                                gleam@string:join(_pipe@6, <<", "/utf8>>)
                            end)/binary>>/binary,
                        "]"/utf8>>;

                true ->
                    All_slice = gleam@list:all(
                        Args,
                        fun(A) -> erlang:element(11, erlang:element(3, A)) end
                    ),
                    case All_slice of
                        true ->
                            _pipe@7 = Args,
                            _pipe@8 = gleam@list:map(
                                _pipe@7,
                                fun(Arg@1) ->
                                    Arg_type@1 = sqlc_col_to_gleam(
                                        erlang:element(3, Arg@1),
                                        Context
                                    ),
                                    Sub_param = gleam_type_to_slice_param(
                                        Arg_type@1
                                    ),
                                    <<<<<<<<"list.map("/utf8,
                                                    (erlang:element(
                                                        2,
                                                        erlang:element(3, Arg@1)
                                                    ))/binary>>/binary,
                                                ", "/utf8>>/binary,
                                            Sub_param/binary>>/binary,
                                        ")"/utf8>>
                                end
                            ),
                            _pipe@9 = gleam@string:join(_pipe@8, <<", "/utf8>>),
                            (fun(Joined) ->
                                <<<<"list.flatten(["/utf8, Joined/binary>>/binary,
                                    "])"/utf8>>
                            end)(_pipe@9);

                        false ->
                            _pipe@10 = Args,
                            _pipe@11 = gleam@list:map(
                                _pipe@10,
                                fun(Arg@2) ->
                                    Arg_type@2 = sqlc_col_to_gleam(
                                        erlang:element(3, Arg@2),
                                        Context
                                    ),
                                    case erlang:element(
                                        11,
                                        erlang:element(3, Arg@2)
                                    ) of
                                        true ->
                                            Sub_param@1 = gleam_type_to_slice_param(
                                                Arg_type@2
                                            ),
                                            <<<<<<<<"list.map("/utf8,
                                                            (erlang:element(
                                                                2,
                                                                erlang:element(
                                                                    3,
                                                                    Arg@2
                                                                )
                                                            ))/binary>>/binary,
                                                        ", "/utf8>>/binary,
                                                    Sub_param@1/binary>>/binary,
                                                ")"/utf8>>;

                                        false ->
                                            gleam_type_to_return_type(
                                                erlang:element(
                                                    2,
                                                    erlang:element(3, Arg@2)
                                                ),
                                                Arg_type@2
                                            )
                                    end
                                end
                            ),
                            gleam@list:fold(
                                _pipe@11,
                                <<"list.new()"/utf8>>,
                                fun(Acc@1, Code) ->
                                    case gleam_stdlib:string_starts_with(
                                        Code,
                                        <<"list.map"/utf8>>
                                    ) of
                                        true ->
                                            <<<<<<Acc@1/binary,
                                                        " |> list.append("/utf8>>/binary,
                                                    Code/binary>>/binary,
                                                ")"/utf8>>;

                                        false ->
                                            <<<<<<Acc@1/binary,
                                                        " |> list.append(["/utf8>>/binary,
                                                    Code/binary>>/binary,
                                                "])"/utf8>>
                                    end
                                end
                            )
                    end
            end
    end,
    Def_fn = <<<<<<<<"pub fn "/utf8, Fn_name/binary>>/binary, "("/utf8>>/binary,
            Def_fn_args/binary>>/binary,
        ")"/utf8>>,
    Def_sql = case Has_slices of
        true ->
            Escaped_text = gleam@string:replace(
                erlang:element(2, Query),
                <<"\""/utf8>>,
                <<"\\\""/utf8>>
            ),
            Modified_sql = begin
                _pipe@12 = erlang:element(9, Query),
                gleam@list:fold(
                    _pipe@12,
                    Escaped_text,
                    fun(Acc@2, P@5) ->
                        case erlang:element(11, erlang:element(3, P@5)) of
                            false ->
                                Acc@2;

                            true ->
                                Name@4 = erlang:element(
                                    2,
                                    erlang:element(3, P@5)
                                ),
                                Safe_name@2 = case built_into_gleam(Name@4) of
                                    false ->
                                        Name@4;

                                    true ->
                                        <<Name@4/binary, "_"/utf8>>
                                end,
                                gleam@string:replace(
                                    Acc@2,
                                    <<<<"/*SLICE:"/utf8, Name@4/binary>>/binary,
                                        "*/?"/utf8>>,
                                    <<<<"\" <> "/utf8, Safe_name@2/binary>>/binary,
                                        "_slice <> \""/utf8>>
                                )
                        end
                    end
                )
            end,
            <<<<"let sql = \""/utf8, Modified_sql/binary>>/binary, "\""/utf8>>;

        false ->
            <<<<"let sql = \""/utf8, Text/binary>>/binary, "\""/utf8>>
    end,
    Def_exp = case erlang:element(4, Query) of
        exec ->
            <<""/utf8>>;

        exec_result ->
            <<""/utf8>>;

        many ->
            <<Fn_name/binary, "_decoder()"/utf8>>;

        one ->
            <<Fn_name/binary, "_decoder()"/utf8>>;

        exec_rows ->
            erlang:error(#{gleam_error => panic,
                    message => (<<"parrot does not support this query annotation: "/utf8,
                        (parrot@internal@sqlc:query_cmd_to_string(
                            erlang:element(4, Query)
                        ))/binary>>),
                    file => <<?FILEPATH/utf8>>,
                    module => <<"parrot/internal/codegen"/utf8>>,
                    function => <<"gen_query_function"/utf8>>,
                    line => 612});

        exec_last_id ->
            erlang:error(#{gleam_error => panic,
                    message => (<<"parrot does not support this query annotation: "/utf8,
                        (parrot@internal@sqlc:query_cmd_to_string(
                            erlang:element(4, Query)
                        ))/binary>>),
                    file => <<?FILEPATH/utf8>>,
                    module => <<"parrot/internal/codegen"/utf8>>,
                    function => <<"gen_query_function"/utf8>>,
                    line => 612});

        batch_exec ->
            erlang:error(#{gleam_error => panic,
                    message => (<<"parrot does not support this query annotation: "/utf8,
                        (parrot@internal@sqlc:query_cmd_to_string(
                            erlang:element(4, Query)
                        ))/binary>>),
                    file => <<?FILEPATH/utf8>>,
                    module => <<"parrot/internal/codegen"/utf8>>,
                    function => <<"gen_query_function"/utf8>>,
                    line => 612});

        batch_many ->
            erlang:error(#{gleam_error => panic,
                    message => (<<"parrot does not support this query annotation: "/utf8,
                        (parrot@internal@sqlc:query_cmd_to_string(
                            erlang:element(4, Query)
                        ))/binary>>),
                    file => <<?FILEPATH/utf8>>,
                    module => <<"parrot/internal/codegen"/utf8>>,
                    function => <<"gen_query_function"/utf8>>,
                    line => 612});

        batch_one ->
            erlang:error(#{gleam_error => panic,
                    message => (<<"parrot does not support this query annotation: "/utf8,
                        (parrot@internal@sqlc:query_cmd_to_string(
                            erlang:element(4, Query)
                        ))/binary>>),
                    file => <<?FILEPATH/utf8>>,
                    module => <<"parrot/internal/codegen"/utf8>>,
                    function => <<"gen_query_function"/utf8>>,
                    line => 612});

        copy_from ->
            erlang:error(#{gleam_error => panic,
                    message => (<<"parrot does not support this query annotation: "/utf8,
                        (parrot@internal@sqlc:query_cmd_to_string(
                            erlang:element(4, Query)
                        ))/binary>>),
                    file => <<?FILEPATH/utf8>>,
                    module => <<"parrot/internal/codegen"/utf8>>,
                    function => <<"gen_query_function"/utf8>>,
                    line => 612})
    end,
    Def_return = <<<<<<<<"#(sql, "/utf8, Def_return_params/binary>>/binary,
                ", "/utf8>>/binary,
            Def_exp/binary>>/binary,
        ")"/utf8>>,
    case Has_slices of
        true ->
            _pipe@13 = [<<Def_fn/binary, "{"/utf8>>,
                <<"  "/utf8, Slice_decls/binary>>,
                <<"  "/utf8, Def_sql/binary>>,
                <<"  "/utf8, Def_return/binary>>,
                <<"}"/utf8>>],
            gleam@string:join(_pipe@13, <<"\n"/utf8>>);

        false ->
            _pipe@14 = [<<Def_fn/binary, "{"/utf8>>,
                <<"  "/utf8, Def_sql/binary>>,
                <<"  "/utf8, Def_return/binary>>,
                <<"}"/utf8>>],
            gleam@string:join(_pipe@14, <<"\n"/utf8>>)
    end.

-file("src/parrot/internal/codegen.gleam", 635).
?DOC(false).
-spec gleam_type_to_decoder(gleam_type()) -> binary().
gleam_type_to_decoder(Gtype) ->
    case Gtype of
        gleam_int ->
            <<"decode.int"/utf8>>;

        gleam_string ->
            <<"decode.string"/utf8>>;

        gleam_bool ->
            <<"dev.bool_decoder()"/utf8>>;

        gleam_float ->
            <<"decode.float"/utf8>>;

        gleam_timestamp ->
            <<"dev.datetime_decoder()"/utf8>>;

        gleam_date ->
            <<"dev.calendar_date_decoder()"/utf8>>;

        gleam_bit_array ->
            <<"decode.bit_array"/utf8>>;

        {gleam_option, X} ->
            <<<<"decode.optional("/utf8, (gleam_type_to_decoder(X))/binary>>/binary,
                ")"/utf8>>;

        {gleam_list, X@1} ->
            <<<<"decode.list(of: "/utf8, (gleam_type_to_decoder(X@1))/binary>>/binary,
                ")"/utf8>>;

        {gleam_enum, Name} ->
            Name@1 = parrot@internal@string_case:snake_case(Name),
            <<Name@1/binary, "_decoder()"/utf8>>;

        gleam_dynamic ->
            <<"decode.dynamic"/utf8>>
    end.

-file("src/parrot/internal/codegen.gleam", 654).
?DOC(false).
-spec gen_query_decoder(
    parrot@internal@sqlc:'query'(),
    parrot@internal@sqlc:s_q_l_c()
) -> binary().
gen_query_decoder(Query, Context) ->
    case erlang:length(erlang:element(6, Query)) of
        0 ->
            <<""/utf8>>;

        _ ->
            Type_name = parrot@internal@string_case:pascal_case(
                erlang:element(3, Query)
            ),
            Fn_name = <<(parrot@internal@string_case:snake_case(
                    erlang:element(3, Query)
                ))/binary,
                "_decoder"/utf8>>,
            Decoder_fields = begin
                _pipe = erlang:element(6, Query),
                _pipe@1 = gleam@list:index_map(
                    _pipe,
                    fun(Col, Index) ->
                        Col_type = sqlc_col_to_gleam(Col, Context),
                        Decoder_type = gleam_type_to_decoder(Col_type),
                        Col_name = gen_column_name(Index, Query, Col),
                        <<<<<<<<<<<<"  use "/utf8, Col_name/binary>>/binary,
                                            " <- decode.field("/utf8>>/binary,
                                        (erlang:integer_to_binary(Index))/binary>>/binary,
                                    ", "/utf8>>/binary,
                                Decoder_type/binary>>/binary,
                            ")"/utf8>>
                    end
                ),
                gleam@string:join(_pipe@1, <<"\n"/utf8>>)
            end,
            Constructor_args = begin
                _pipe@2 = erlang:element(6, Query),
                _pipe@3 = gleam@list:index_map(
                    _pipe@2,
                    fun(Col@1, Index@1) ->
                        <<(gen_column_name(Index@1, Query, Col@1))/binary,
                            ": "/utf8>>
                    end
                ),
                gleam@string:join(_pipe@3, <<", "/utf8>>)
            end,
            Success_line = <<<<<<<<"  decode.success("/utf8, Type_name/binary>>/binary,
                        "("/utf8>>/binary,
                    Constructor_args/binary>>/binary,
                "))"/utf8>>,
            <<<<<<<<<<<<<<<<"\n\npub fn "/utf8, Fn_name/binary>>/binary,
                                        "() -> decode.Decoder("/utf8>>/binary,
                                    Type_name/binary>>/binary,
                                ") {\n"/utf8>>/binary,
                            Decoder_fields/binary>>/binary,
                        "\n"/utf8>>/binary,
                    Success_line/binary>>/binary,
                "\n}"/utf8>>
    end.

-file("src/parrot/internal/codegen.gleam", 66).
?DOC(false).
-spec gen_query(parrot@internal@sqlc:'query'(), parrot@internal@sqlc:s_q_l_c()) -> binary().
gen_query(Query, Context) ->
    Type_str = case erlang:length(erlang:element(6, Query)) of
        0 ->
            <<""/utf8>>;

        _ ->
            <<(gen_query_type(Query, Context))/binary, "\n\n"/utf8>>
    end,
    Func = gen_query_function(Query, Context),
    Deco = gen_query_decoder(Query, Context),
    <<<<Type_str/binary, Func/binary>>/binary, Deco/binary>>.

-file("src/parrot/internal/codegen.gleam", 702).
?DOC(false).
-spec uses_gleam_type(
    fun((parrot@internal@sqlc:table_column()) -> boolean()),
    parrot@internal@sqlc:s_q_l_c()
) -> boolean().
uses_gleam_type(Case_fn, Context) ->
    gleam@list:any(
        erlang:element(6, Context),
        fun(Query) ->
            Col_ts = gleam@list:any(
                erlang:element(6, Query),
                fun(Col) -> Case_fn(Col) end
            ),
            Param_ts = gleam@list:any(
                erlang:element(9, Query),
                fun(Param) -> Case_fn(erlang:element(3, Param)) end
            ),
            gleam@bool:'or'(Col_ts, Param_ts)
        end
    ).

-file("src/parrot/internal/codegen.gleam", 887).
?DOC(false).
-spec comment_dont_edit() -> binary().
comment_dont_edit() ->
    _pipe = <<"
//// Code generated by parrot. DO NOT EDIT.
////
  "/utf8>>,
    gleam@string:trim(_pipe).

-file("src/parrot/internal/codegen.gleam", 710).
?DOC(false).
-spec gen_gleam_module(parrot@internal@sqlc:s_q_l_c()) -> {ok, binary()} |
    {error, parrot@internal@errors:parrot_error()}.
gen_gleam_module(Context) ->
    gleam@result:'try'(
        find_duplicates(Context),
        fun(_) ->
            Queries = begin
                _pipe = erlang:element(6, Context),
                _pipe@1 = gleam@list:map(
                    _pipe,
                    fun(_capture) -> gen_query(_capture, Context) end
                ),
                gleam@string:join(_pipe@1, <<"\n\n"/utf8>>)
            end,
            Uses_timestamp = begin
                _pipe@2 = fun(Col) -> case sqlc_col_to_gleam(Col, Context) of
                        {gleam_option, gleam_timestamp} ->
                            true;

                        gleam_timestamp ->
                            true;

                        _ ->
                            false
                    end end,
                uses_gleam_type(_pipe@2, Context)
            end,
            Uses_date = begin
                _pipe@3 = fun(Col@1) ->
                    case sqlc_col_to_gleam(Col@1, Context) of
                        {gleam_option, gleam_date} ->
                            true;

                        gleam_date ->
                            true;

                        _ ->
                            false
                    end
                end,
                uses_gleam_type(_pipe@3, Context)
            end,
            Uses_list = begin
                _pipe@4 = fun(Col@2) ->
                    case sqlc_col_to_gleam(Col@2, Context) of
                        {gleam_option, {gleam_list, _}} ->
                            true;

                        {gleam_list, _} ->
                            true;

                        _ ->
                            false
                    end
                end,
                uses_gleam_type(_pipe@4, Context)
            end,
            Timestamp_import = case Uses_timestamp of
                false ->
                    <<""/utf8>>;

                true ->
                    <<"import gleam/time/timestamp.{type Timestamp}\n"/utf8>>
            end,
            Date_import = case Uses_date of
                false ->
                    <<""/utf8>>;

                true ->
                    <<"import gleam/time/calendar.{type Date}\n"/utf8>>
            end,
            List_import = case Uses_list of
                false ->
                    <<""/utf8>>;

                true ->
                    <<"import gleam/list\n"/utf8>>
            end,
            Uses_slice = gleam@list:any(
                erlang:element(6, Context),
                fun(Query) ->
                    gleam@list:any(
                        erlang:element(9, Query),
                        fun(Param) ->
                            erlang:element(11, erlang:element(3, Param))
                        end
                    )
                end
            ),
            String_import = case Uses_slice of
                false ->
                    <<""/utf8>>;

                true ->
                    <<"import gleam/string\n"/utf8>>
            end,
            Imports = <<<<<<<<<<<<<<<<"import gleam/dynamic/decode"/utf8,
                                            "\n"/utf8>>/binary,
                                        "import gleam/option.{type Option}"/utf8>>/binary,
                                    "\n"/utf8>>/binary,
                                Date_import/binary>>/binary,
                            Timestamp_import/binary>>/binary,
                        List_import/binary>>/binary,
                    String_import/binary>>/binary,
                "import parrot/dev"/utf8>>,
            Enums = begin
                _pipe@7 = gleam@list:flat_map(
                    erlang:element(6, Context),
                    fun(Query@1) ->
                        Columns = gleam@list:filter_map(
                            erlang:element(6, Query@1),
                            fun(Col@3) ->
                                case sqlc_col_to_gleam(Col@3, Context) of
                                    {gleam_option, {gleam_enum, _}} ->
                                        Type_ = normalise_col_type(Col@3),
                                        Schema = find_col_schema(Col@3, Context),
                                        Enum@1 = case begin
                                            _pipe@5 = erlang:element(5, Schema),
                                            gleam@list:find(
                                                _pipe@5,
                                                fun(E) ->
                                                    erlang:element(2, E) =:= Type_
                                                end
                                            )
                                        end of
                                            {ok, Enum} -> Enum;
                                            _assert_fail ->
                                                erlang:error(
                                                        #{gleam_error => let_assert,
                                                            message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                                            file => <<?FILEPATH/utf8>>,
                                                            module => <<"parrot/internal/codegen"/utf8>>,
                                                            function => <<"gen_gleam_module"/utf8>>,
                                                            line => 793,
                                                            value => _assert_fail,
                                                            start => 21379,
                                                            'end' => 21485,
                                                            pattern_start => 21390,
                                                            pattern_end => 21398}
                                                    )
                                        end,
                                        {ok, Enum@1};

                                    {gleam_enum, _} ->
                                        Type_ = normalise_col_type(Col@3),
                                        Schema = find_col_schema(Col@3, Context),
                                        Enum@1 = case begin
                                            _pipe@5 = erlang:element(5, Schema),
                                            gleam@list:find(
                                                _pipe@5,
                                                fun(E) ->
                                                    erlang:element(2, E) =:= Type_
                                                end
                                            )
                                        end of
                                            {ok, Enum} -> Enum;
                                            _assert_fail ->
                                                erlang:error(
                                                        #{gleam_error => let_assert,
                                                            message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                                            file => <<?FILEPATH/utf8>>,
                                                            module => <<"parrot/internal/codegen"/utf8>>,
                                                            function => <<"gen_gleam_module"/utf8>>,
                                                            line => 793,
                                                            value => _assert_fail,
                                                            start => 21379,
                                                            'end' => 21485,
                                                            pattern_start => 21390,
                                                            pattern_end => 21398}
                                                    )
                                        end,
                                        {ok, Enum@1};

                                    _ ->
                                        {error, nil}
                                end
                            end
                        ),
                        Params = gleam@list:filter_map(
                            erlang:element(9, Query@1),
                            fun(Param@1) ->
                                case sqlc_col_to_gleam(
                                    erlang:element(3, Param@1),
                                    Context
                                ) of
                                    {gleam_option, {gleam_enum, _}} ->
                                        Type_@1 = normalise_col_type(
                                            erlang:element(3, Param@1)
                                        ),
                                        Schema@1 = find_col_schema(
                                            erlang:element(3, Param@1),
                                            Context
                                        ),
                                        Enum@3 = case begin
                                            _pipe@6 = erlang:element(
                                                5,
                                                Schema@1
                                            ),
                                            gleam@list:find(
                                                _pipe@6,
                                                fun(E@1) ->
                                                    erlang:element(2, E@1) =:= Type_@1
                                                end
                                            )
                                        end of
                                            {ok, Enum@2} -> Enum@2;
                                            _assert_fail@1 ->
                                                erlang:error(
                                                        #{gleam_error => let_assert,
                                                            message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                                            file => <<?FILEPATH/utf8>>,
                                                            module => <<"parrot/internal/codegen"/utf8>>,
                                                            function => <<"gen_gleam_module"/utf8>>,
                                                            line => 809,
                                                            value => _assert_fail@1,
                                                            start => 21900,
                                                            'end' => 22006,
                                                            pattern_start => 21911,
                                                            pattern_end => 21919}
                                                    )
                                        end,
                                        {ok, Enum@3};

                                    {gleam_enum, _} ->
                                        Type_@1 = normalise_col_type(
                                            erlang:element(3, Param@1)
                                        ),
                                        Schema@1 = find_col_schema(
                                            erlang:element(3, Param@1),
                                            Context
                                        ),
                                        Enum@3 = case begin
                                            _pipe@6 = erlang:element(
                                                5,
                                                Schema@1
                                            ),
                                            gleam@list:find(
                                                _pipe@6,
                                                fun(E@1) ->
                                                    erlang:element(2, E@1) =:= Type_@1
                                                end
                                            )
                                        end of
                                            {ok, Enum@2} -> Enum@2;
                                            _assert_fail@1 ->
                                                erlang:error(
                                                        #{gleam_error => let_assert,
                                                            message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                                            file => <<?FILEPATH/utf8>>,
                                                            module => <<"parrot/internal/codegen"/utf8>>,
                                                            function => <<"gen_gleam_module"/utf8>>,
                                                            line => 809,
                                                            value => _assert_fail@1,
                                                            start => 21900,
                                                            'end' => 22006,
                                                            pattern_start => 21911,
                                                            pattern_end => 21919}
                                                    )
                                        end,
                                        {ok, Enum@3};

                                    _ ->
                                        {error, nil}
                                end
                            end
                        ),
                        lists:append(Columns, Params)
                    end
                ),
                gleam@list:unique(_pipe@7)
            end,
            Enums@1 = begin
                _pipe@8 = gleam@list:map(
                    Enums,
                    fun(Enum@4) ->
                        Record_name = parrot@internal@string_case:pascal_case(
                            erlang:element(2, Enum@4)
                        ),
                        Fn_name = parrot@internal@string_case:snake_case(
                            erlang:element(2, Enum@4)
                        ),
                        Values = gleam@list:map(
                            erlang:element(3, Enum@4),
                            fun(Val) ->
                                <<"  "/utf8,
                                    (parrot@internal@string_case:pascal_case(
                                        Val
                                    ))/binary>>
                            end
                        ),
                        To_str_vals = gleam@list:map(
                            erlang:element(3, Enum@4),
                            fun(Val@1) ->
                                Type_@2 = parrot@internal@string_case:pascal_case(
                                    Val@1
                                ),
                                <<<<<<<<<<"    "/utf8, Type_@2/binary>>/binary,
                                                " -> "/utf8>>/binary,
                                            "\""/utf8>>/binary,
                                        Val@1/binary>>/binary,
                                    "\""/utf8>>
                            end
                        ),
                        Decode_str_vals = gleam@list:map(
                            erlang:element(3, Enum@4),
                            fun(Val@2) ->
                                Type_@3 = parrot@internal@string_case:pascal_case(
                                    Val@2
                                ),
                                <<<<<<<<<<"    \""/utf8, Val@2/binary>>/binary,
                                                "\" -> "/utf8>>/binary,
                                            "decode.success("/utf8>>/binary,
                                        Type_@3/binary>>/binary,
                                    ")"/utf8>>
                            end
                        ),
                        First_value@1 = case gleam@list:first(
                            erlang:element(3, Enum@4)
                        ) of
                            {ok, First_value} -> First_value;
                            _assert_fail@2 ->
                                erlang:error(#{gleam_error => let_assert,
                                            message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                            file => <<?FILEPATH/utf8>>,
                                            module => <<"parrot/internal/codegen"/utf8>>,
                                            function => <<"gen_gleam_module"/utf8>>,
                                            line => 843,
                                            value => _assert_fail@2,
                                            start => 22812,
                                            'end' => 22862,
                                            pattern_start => 22823,
                                            pattern_end => 22838})
                        end,
                        Zero_value = parrot@internal@string_case:pascal_case(
                            First_value@1
                        ),
                        <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"pub type "/utf8,
                                                                                                                                Record_name/binary>>/binary,
                                                                                                                            " {\n"/utf8>>/binary,
                                                                                                                        (gleam@string:join(
                                                                                                                            Values,
                                                                                                                            <<"\n"/utf8>>
                                                                                                                        ))/binary>>/binary,
                                                                                                                    "\n}\n\n"/utf8>>/binary,
                                                                                                                "pub fn "/utf8>>/binary,
                                                                                                            Fn_name/binary>>/binary,
                                                                                                        "_decoder() {\n"/utf8>>/binary,
                                                                                                    "  use variant <- decode.then(decode.string)\n"/utf8>>/binary,
                                                                                                "  case variant {\n"/utf8>>/binary,
                                                                                            (gleam@string:join(
                                                                                                Decode_str_vals,
                                                                                                <<"\n"/utf8>>
                                                                                            ))/binary>>/binary,
                                                                                        "\n    _ -> decode.failure("/utf8>>/binary,
                                                                                    Zero_value/binary>>/binary,
                                                                                ", \""/utf8>>/binary,
                                                                            Record_name/binary>>/binary,
                                                                        "\")\n"/utf8>>/binary,
                                                                    "  }\n"/utf8>>/binary,
                                                                "}\n\n"/utf8>>/binary,
                                                            "pub fn "/utf8>>/binary,
                                                        Fn_name/binary>>/binary,
                                                    "_to_string(val: "/utf8>>/binary,
                                                Record_name/binary>>/binary,
                                            ") {\n"/utf8>>/binary,
                                        "  case val {\n"/utf8>>/binary,
                                    (gleam@string:join(
                                        To_str_vals,
                                        <<"\n"/utf8>>
                                    ))/binary>>/binary,
                                "\n  }\n"/utf8>>/binary,
                            "}"/utf8>>
                    end
                ),
                gleam@string:join(_pipe@8, <<"\n\n"/utf8>>)
            end,
            {ok,
                <<<<<<<<<<<<(comment_dont_edit())/binary, "\n\n"/utf8>>/binary,
                                    Imports/binary>>/binary,
                                "\n\n"/utf8>>/binary,
                            Enums@1/binary>>/binary,
                        "\n\n"/utf8>>/binary,
                    Queries/binary>>}
        end
    ).

-file("src/parrot/internal/codegen.gleam", 22).
?DOC(false).
-spec codegen_from_config(parrot@internal@config:config()) -> {ok, codegen()} |
    {error, parrot@internal@errors:parrot_error()}.
codegen_from_config(Config) ->
    gleam@result:'try'(
        begin
            _pipe = parrot@internal@config:get_json_file(Config),
            gleam@result:map_error(_pipe, fun(_) -> codegen_error end)
        end,
        fun(Json_string) ->
            gleam@result:'try'(
                begin
                    _pipe@1 = gleam@json:parse(
                        Json_string,
                        {decoder, fun gleam@dynamic@decode:decode_dynamic/1}
                    ),
                    gleam@result:map_error(_pipe@1, fun(_) -> codegen_error end)
                end,
                fun(Dyn_json) ->
                    Context@1 = case parrot@internal@sqlc:decode_sqlc(Dyn_json) of
                        {ok, Context} -> Context;
                        _assert_fail ->
                            erlang:error(#{gleam_error => let_assert,
                                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                        file => <<?FILEPATH/utf8>>,
                                        module => <<"parrot/internal/codegen"/utf8>>,
                                        function => <<"codegen_from_config"/utf8>>,
                                        line => 35,
                                        value => _assert_fail,
                                        start => 823,
                                        'end' => 874,
                                        pattern_start => 834,
                                        pattern_end => 845})
                    end,
                    Unknowns = begin
                        _pipe@2 = gleam@list:flat_map(
                            erlang:element(6, Context@1),
                            fun(Query) ->
                                gleam@list:map(
                                    erlang:element(6, Query),
                                    fun(Col) ->
                                        case sqlc_col_to_gleam(Col, Context@1) of
                                            gleam_dynamic ->
                                                {some,
                                                    erlang:element(
                                                        4,
                                                        erlang:element(16, Col)
                                                    )};

                                            _ ->
                                                none
                                        end
                                    end
                                )
                            end
                        ),
                        _pipe@3 = gleam@list:filter(
                            _pipe@2,
                            fun gleam@option:is_some/1
                        ),
                        gleam@list:map(
                            _pipe@3,
                            fun(_capture) ->
                                gleam@option:unwrap(_capture, <<""/utf8>>)
                            end
                        )
                    end,
                    gleam@result:'try'(
                        gen_gleam_module(Context@1),
                        fun(Module_contents) ->
                            gleam@result:'try'(
                                begin
                                    _pipe@4 = parrot@internal@config:get_module_directory(
                                        Config
                                    ),
                                    _pipe@5 = simplifile:create_directory_all(
                                        _pipe@4
                                    ),
                                    gleam@result:map_error(
                                        _pipe@5,
                                        fun(_) -> codegen_error end
                                    )
                                end,
                                fun(_) ->
                                    gleam@result:'try'(
                                        begin
                                            _pipe@6 = simplifile:write(
                                                parrot@internal@config:get_module_path(
                                                    Config
                                                ),
                                                Module_contents
                                            ),
                                            gleam@result:map_error(
                                                _pipe@6,
                                                fun(_) -> codegen_error end
                                            )
                                        end,
                                        fun(_) -> {ok, {codegen, Unknowns}} end
                                    )
                                end
                            )
                        end
                    )
                end
            )
        end
    ).
