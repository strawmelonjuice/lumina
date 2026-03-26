-module(youid@uuid).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/youid/uuid.gleam").
-export([time/1, clock_sequence/1, node/1, dns_uuid/0, url_uuid/0, oid_uuid/0, x500_uuid/0, to_bit_array/1, to_base64/1, from_base64/1, version/1, from_bit_array/1, variant/1, from_string/1, time_posix_microsec/1, time_posix_millisec/1, format/2, to_string/1, v1/0, v1_string/0, v1_custom/2, v3/2, v4/0, v4_string/0, v5/2, v7_from_millisec/1, v7/0, v7_string/0]).
-export_type([uuid/0, version/0, variant/0, format/0, v1_node/0, v1_clock_seq/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " Spec conformant UUID v1, v3, v4, and v5 generation.\n"
    "\n"
    " Spec conformant UUID decoding for all versions and variants.\n"
    "\n"
    " Spec: [https://www.ietf.org/rfc/rfc4122.txt](https://www.ietf.org/rfc/rfc4122.txt)\n"
    "\n"
    " Wikipedia: [https://en.wikipedia.org/wiki/uuid](https://en.wikipedia.org/wiki/uuid)\n"
    "\n"
    " Unless you have a specific reason otherwise, you probably either want the\n"
    " random v4 or the time-based v1 version.\n"
).

-opaque uuid() :: {uuid, bitstring()}.

-type version() :: v1 | v2 | v3 | v4 | v5 | v7 | v_unknown.

-type variant() :: reserved_future | reserved_microsoft | reserved_ncs | rfc4122.

-type format() :: string | hex | urn.

-type v1_node() :: default_node | random_node | {custom_node, binary()}.

-type v1_clock_seq() :: random_clock_seq | {custom_clock_seq, bitstring()}.

-file("src/youid/uuid.gleam", 180).
-spec random_uuid1_clockseq() -> bitstring().
random_uuid1_clockseq() ->
    Clock_seq@1 = case crypto:strong_rand_bytes(2) of
        <<Clock_seq:14, _:2>> -> Clock_seq;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"youid/uuid"/utf8>>,
                        function => <<"random_uuid1_clockseq"/utf8>>,
                        line => 181,
                        value => _assert_fail,
                        start => 4541,
                        'end' => 4617,
                        pattern_start => 4552,
                        pattern_end => 4585})
    end,
    <<Clock_seq@1:14>>.

-file("src/youid/uuid.gleam", 156).
-spec validate_clock_seq(v1_clock_seq()) -> {ok, bitstring()} | {error, nil}.
validate_clock_seq(Clock_seq) ->
    case Clock_seq of
        random_clock_seq ->
            {ok, random_uuid1_clockseq()};

        {custom_clock_seq, Bs} ->
            case erlang:bit_size(Bs) =:= 14 of
                true ->
                    {ok, Bs};

                false ->
                    {error, nil}
            end
    end.

-file("src/youid/uuid.gleam", 196).
-spec random_uuid1_node() -> bitstring().
random_uuid1_node() ->
    {Rnd_hi@1, Rnd_low@1} = case crypto:strong_rand_bytes(6) of
        <<Rnd_hi:7, _:1, Rnd_low:40>> -> {Rnd_hi, Rnd_low};
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"youid/uuid"/utf8>>,
                        function => <<"random_uuid1_node"/utf8>>,
                        line => 197,
                        value => _assert_fail,
                        start => 5032,
                        'end' => 5126,
                        pattern_start => 5043,
                        pattern_end => 5090})
    end,
    <<Rnd_hi@1:7, 1:1, Rnd_low@1:40>>.

-file("src/youid/uuid.gleam", 219).
-spec md5(bitstring()) -> bitstring().
md5(Data) ->
    gleam@crypto:hash(md5, Data).

-file("src/youid/uuid.gleam", 279).
-spec sha1(bitstring()) -> bitstring().
sha1(Data) ->
    Data@2 = case gleam@crypto:hash(sha1, Data) of
        <<Data@1:128/bitstring, _:32>> -> Data@1;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"youid/uuid"/utf8>>,
                        function => <<"sha1"/utf8>>,
                        line => 280,
                        value => _assert_fail,
                        start => 6838,
                        'end' => 6911,
                        pattern_start => 6849,
                        pattern_end => 6878})
    end,
    Data@2.

-file("src/youid/uuid.gleam", 355).
?DOC(
    " Determine the time a UUID was created with Gregorian Epoch.\n"
    "\n"
    " This is only relevant to a V1 UUID.\n"
    "\n"
    " UUID's use 15 Oct 1582 as Epoch and time is measured in 100ns intervals.\n"
    " This value is useful for comparing V1 UUIDs but not so much for\n"
    " telling what time a UUID was created. See time_posix_microsec and clock_sequence.\n"
).
-spec time(uuid()) -> integer().
time(Uuid) ->
    {T_low@1, T_mid@1, T_hi@1} = case erlang:element(2, Uuid) of
        <<T_low:32, T_mid:16, _:4, T_hi:12, _:64>> -> {T_low, T_mid, T_hi};
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"youid/uuid"/utf8>>,
                        function => <<"time"/utf8>>,
                        line => 356,
                        value => _assert_fail,
                        start => 9014,
                        'end' => 9080,
                        pattern_start => 9025,
                        pattern_end => 9067})
    end,
    T@1 = case <<T_hi@1:12, T_mid@1:16, T_low@1:32>> of
        <<T:60>> -> T;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"youid/uuid"/utf8>>,
                        function => <<"time"/utf8>>,
                        line => 357,
                        value => _assert_fail@1,
                        start => 9083,
                        'end' => 9136,
                        pattern_start => 9094,
                        pattern_end => 9102})
    end,
    T@1.

-file("src/youid/uuid.gleam", 378).
?DOC(
    " Determine the clock sequence of a UUID\n"
    " This is only relevant to a V1 UUID\n"
).
-spec clock_sequence(uuid()) -> integer().
clock_sequence(Uuid) ->
    Clock_seq@1 = case erlang:element(2, Uuid) of
        <<_:66, Clock_seq:14, _:48>> -> Clock_seq;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"youid/uuid"/utf8>>,
                        function => <<"clock_sequence"/utf8>>,
                        line => 379,
                        value => _assert_fail,
                        start => 9668,
                        'end' => 9720,
                        pattern_start => 9679,
                        pattern_end => 9707})
    end,
    Clock_seq@1.

-file("src/youid/uuid.gleam", 385).
?DOC(
    " Determine the node of a UUID\n"
    " This is only relevant to a V1 UUID\n"
).
-spec node(uuid()) -> binary().
node(Uuid) ->
    {A@1, B@1, C@1, D@1, E@1, F@1, G@1, H@1, I@1, J@1, K@1, L@1} = case erlang:element(
        2,
        Uuid
    ) of
        <<_:80, A:4, B:4, C:4, D:4, E:4, F:4, G:4, H:4, I:4, J:4, K:4, L:4>> -> {
        A,
            B,
            C,
            D,
            E,
            F,
            G,
            H,
            I,
            J,
            K,
            L};
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"youid/uuid"/utf8>>,
                        function => <<"node"/utf8>>,
                        line => 386,
                        value => _assert_fail,
                        start => 9846,
                        'end' => 9995,
                        pattern_start => 9857,
                        pattern_end => 9982})
    end,
    _pipe = [A@1, B@1, C@1, D@1, E@1, F@1, G@1, H@1, I@1, J@1, K@1, L@1],
    _pipe@1 = gleam@list:map(_pipe, fun gleam@int:to_base16/1),
    erlang:list_to_binary(_pipe@1).

-file("src/youid/uuid.gleam", 441).
-spec to_string_help(bitstring(), integer(), binary(), binary()) -> binary().
to_string_help(Ints, Position, Acc, Separator) ->
    case Position of
        8 ->
            to_string_help(
                Ints,
                Position + 1,
                <<Acc/binary, Separator/binary>>,
                Separator
            );

        13 ->
            to_string_help(
                Ints,
                Position + 1,
                <<Acc/binary, Separator/binary>>,
                Separator
            );

        18 ->
            to_string_help(
                Ints,
                Position + 1,
                <<Acc/binary, Separator/binary>>,
                Separator
            );

        23 ->
            to_string_help(
                Ints,
                Position + 1,
                <<Acc/binary, Separator/binary>>,
                Separator
            );

        _ ->
            case Ints of
                <<I:4, Rest/bitstring>> ->
                    String = begin
                        _pipe = gleam@int:to_base16(I),
                        string:lowercase(_pipe)
                    end,
                    to_string_help(
                        Rest,
                        Position + 1,
                        <<Acc/binary, String/binary>>,
                        Separator
                    );

                _ ->
                    Acc
            end
    end.

-file("src/youid/uuid.gleam", 480).
?DOC(" dns namespace UUID provided by the spec, only useful for v3 and v5\n").
-spec dns_uuid() -> uuid().
dns_uuid() ->
    {uuid,
        <<107,
            167,
            184,
            16,
            157,
            173,
            17,
            209,
            128,
            180,
            0,
            192,
            79,
            212,
            48,
            200>>}.

-file("src/youid/uuid.gleam", 487).
?DOC(" url namespace UUID provided by the spec, only useful for v3 and v5\n").
-spec url_uuid() -> uuid().
url_uuid() ->
    {uuid,
        <<107,
            167,
            184,
            17,
            157,
            173,
            17,
            209,
            128,
            180,
            0,
            192,
            79,
            212,
            48,
            200>>}.

-file("src/youid/uuid.gleam", 494).
?DOC(" oid namespace UUID provided by the spec, only useful for v3 and v5\n").
-spec oid_uuid() -> uuid().
oid_uuid() ->
    {uuid,
        <<107,
            167,
            184,
            18,
            157,
            173,
            17,
            209,
            128,
            180,
            0,
            192,
            79,
            212,
            48,
            200>>}.

-file("src/youid/uuid.gleam", 501).
?DOC(" x500 namespace UUID provided by the spec, only useful for v3 and v5\n").
-spec x500_uuid() -> uuid().
x500_uuid() ->
    {uuid,
        <<107,
            167,
            184,
            19,
            157,
            173,
            17,
            209,
            128,
            180,
            0,
            192,
            79,
            212,
            48,
            200>>}.

-file("src/youid/uuid.gleam", 508).
?DOC(" Convert a UUID to a bit array\n").
-spec to_bit_array(uuid()) -> bitstring().
to_bit_array(Uuid) ->
    erlang:element(2, Uuid).

-file("src/youid/uuid.gleam", 532).
?DOC(
    " Convert a UUID to a URL-safe base-64 string.\n"
    "\n"
    " The output is 22 characters long and URL-safe, making it an ideal format\n"
    " for ids in paths and APIs.\n"
).
-spec to_base64(uuid()) -> binary().
to_base64(Uuid) ->
    gleam@bit_array:base64_url_encode(erlang:element(2, Uuid), false).

-file("src/youid/uuid.gleam", 540).
?DOC(
    " Attempt to decode a UUID from a URL-safe base-64 string.\n"
    "\n"
    " Supports unpadded 22 character uuids and padded 24 character uuids.\n"
).
-spec from_base64(binary()) -> {ok, uuid()} | {error, nil}.
from_base64(In) ->
    gleam@result:'try'(case erlang:byte_size(In) of
            22 ->
                {ok, <<In/binary, "=="/utf8>>};

            24 ->
                {ok, In};

            _ ->
                {error, nil}
        end, fun(Padded) ->
            gleam@result:'try'(
                gleam@bit_array:base64_url_decode(Padded),
                fun(Bits) -> case erlang:byte_size(Bits) of
                        16 ->
                            {ok, {uuid, Bits}};

                        _ ->
                            {error, nil}
                    end end
            )
        end).

-file("src/youid/uuid.gleam", 577).
-spec decode_version(integer()) -> version().
decode_version(Int) ->
    case Int of
        1 ->
            v1;

        2 ->
            v2;

        3 ->
            v3;

        4 ->
            v4;

        5 ->
            v5;

        7 ->
            v7;

        _ ->
            v_unknown
    end.

-file("src/youid/uuid.gleam", 337).
?DOC(" Determine the Version of a UUID\n").
-spec version(uuid()) -> version().
version(Uuid) ->
    Ver@1 = case erlang:element(2, Uuid) of
        <<_:48, Ver:4, _:76>> -> Ver;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"youid/uuid"/utf8>>,
                        function => <<"version"/utf8>>,
                        line => 338,
                        value => _assert_fail,
                        start => 8410,
                        'end' => 8455,
                        pattern_start => 8421,
                        pattern_end => 8442})
    end,
    decode_version(Ver@1).

-file("src/youid/uuid.gleam", 514).
?DOC(
    " Attemts to convert a bit array to a UUID.\n"
    " Will fail if the bit array is not 16 bytes long or has an invalid version.\n"
).
-spec from_bit_array(bitstring()) -> {ok, uuid()} | {error, nil}.
from_bit_array(Bit_array) ->
    Uuid = {uuid, Bit_array},
    case erlang:byte_size(Bit_array) of
        16 ->
            case version(Uuid) of
                v_unknown ->
                    {error, nil};

                _ ->
                    {ok, Uuid}
            end;

        _ ->
            {error, nil}
    end.

-file("src/youid/uuid.gleam", 589).
-spec decode_variant(bitstring()) -> variant().
decode_variant(Variant_bits) ->
    case Variant_bits of
        <<1:1, 1:1, 1:1>> ->
            reserved_future;

        <<1:1, 1:1, 0:1>> ->
            reserved_microsoft;

        <<1:1, 0:1, _:1>> ->
            rfc4122;

        <<0:1, _:1, _:1>> ->
            reserved_ncs;

        _ ->
            reserved_ncs
    end.

-file("src/youid/uuid.gleam", 343).
?DOC(" Determine the Variant of a UUID\n").
-spec variant(uuid()) -> variant().
variant(Uuid) ->
    Var@1 = case erlang:element(2, Uuid) of
        <<_:64, Var:3, _:61>> -> Var;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"youid/uuid"/utf8>>,
                        function => <<"variant"/utf8>>,
                        line => 344,
                        value => _assert_fail,
                        start => 8559,
                        'end' => 8604,
                        pattern_start => 8570,
                        pattern_end => 8591})
    end,
    decode_variant(<<Var@1:3>>).

-file("src/youid/uuid.gleam", 600).
-spec hex_to_int(binary()) -> {ok, integer()} | {error, nil}.
hex_to_int(C) ->
    I = case C of
        <<"0"/utf8>> ->
            0;

        <<"1"/utf8>> ->
            1;

        <<"2"/utf8>> ->
            2;

        <<"3"/utf8>> ->
            3;

        <<"4"/utf8>> ->
            4;

        <<"5"/utf8>> ->
            5;

        <<"6"/utf8>> ->
            6;

        <<"7"/utf8>> ->
            7;

        <<"8"/utf8>> ->
            8;

        <<"9"/utf8>> ->
            9;

        <<"a"/utf8>> ->
            10;

        <<"A"/utf8>> ->
            10;

        <<"b"/utf8>> ->
            11;

        <<"B"/utf8>> ->
            11;

        <<"c"/utf8>> ->
            12;

        <<"C"/utf8>> ->
            12;

        <<"d"/utf8>> ->
            13;

        <<"D"/utf8>> ->
            13;

        <<"e"/utf8>> ->
            14;

        <<"E"/utf8>> ->
            14;

        <<"f"/utf8>> ->
            15;

        <<"F"/utf8>> ->
            15;

        _ ->
            16
    end,
    case I of
        16 ->
            {error, nil};

        X ->
            {ok, X}
    end.

-file("src/youid/uuid.gleam", 138).
-spec validate_custom_node(binary(), integer(), bitstring()) -> {ok,
        bitstring()} |
    {error, nil}.
validate_custom_node(Str, Index, Acc) ->
    case gleam_stdlib:string_pop_grapheme(Str) of
        {error, nil} when Index =:= 12 ->
            {ok, Acc};

        {ok, {<<":"/utf8>>, Rest}} ->
            validate_custom_node(Rest, Index, Acc);

        {ok, {C, Rest@1}} ->
            case hex_to_int(C) of
                {ok, I} when Index < 12 ->
                    validate_custom_node(
                        Rest@1,
                        Index + 1,
                        <<Acc/bitstring, I:4>>
                    );

                _ ->
                    {error, nil}
            end;

        _ ->
            {error, nil}
    end.

-file("src/youid/uuid.gleam", 560).
-spec to_bitstring_help(binary(), integer(), bitstring()) -> {ok, bitstring()} |
    {error, nil}.
to_bitstring_help(Str, Index, Acc) ->
    case gleam_stdlib:string_pop_grapheme(Str) of
        {error, nil} when Index =:= 32 ->
            {ok, Acc};

        {ok, {<<"-"/utf8>>, Rest}} when Index < 32 ->
            to_bitstring_help(Rest, Index, Acc);

        {ok, {C, Rest@1}} when Index < 32 ->
            case hex_to_int(C) of
                {ok, I} ->
                    to_bitstring_help(Rest@1, Index + 1, <<Acc/bitstring, I:4>>);

                {error, _} ->
                    {error, nil}
            end;

        _ ->
            {error, nil}
    end.

-file("src/youid/uuid.gleam", 556).
-spec to_bit_array_helper(binary()) -> {ok, bitstring()} | {error, nil}.
to_bit_array_helper(Str) ->
    to_bitstring_help(Str, 0, <<>>).

-file("src/youid/uuid.gleam", 464).
?DOC(
    " Attempt to decode a UUID from a string. Supports strings formatted in the same\n"
    " ways this library will output them. Hex with dashes, hex without dashes and\n"
    " hex with or without dashes prepended with \"urn:uuid:\"\n"
).
-spec from_string(binary()) -> {ok, uuid()} | {error, nil}.
from_string(In) ->
    Hex = case In of
        <<"urn:uuid:"/utf8, In@1/binary>> ->
            In@1;

        _ ->
            In
    end,
    case to_bit_array_helper(Hex) of
        {ok, Bits} ->
            {ok, {uuid, Bits}};

        {error, _} ->
            {error, nil}
    end.

-file("src/youid/uuid.gleam", 189).
-spec default_uuid1_node() -> bitstring().
default_uuid1_node() ->
    case youid_ffi:mac_address() of
        {ok, Node} ->
            Node;

        _ ->
            random_uuid1_node()
    end.

-file("src/youid/uuid.gleam", 130).
-spec validate_node(v1_node()) -> {ok, bitstring()} | {error, nil}.
validate_node(Node) ->
    case Node of
        default_node ->
            {ok, default_uuid1_node()};

        random_node ->
            {ok, random_uuid1_node()};

        {custom_node, Str} ->
            validate_custom_node(Str, 0, <<>>)
    end.

-file("src/youid/uuid.gleam", 169).
-spec uuid1_time() -> bitstring().
uuid1_time() ->
    {Sec, Ns} = begin
        _pipe = gleam@time@timestamp:system_time(),
        gleam@time@timestamp:to_unix_seconds_and_nanoseconds(_pipe)
    end,
    Time = ((Sec * 10000000) + (Ns div 100)) + (122192928000000 * 1000),
    <<Time:60>>.

-file("src/youid/uuid.gleam", 366).
?DOC(
    " Determine the time a UUID was created with.\n"
    "\n"
    " This is only relevant to V1 and V7 UUIDs.\n"
    "\n"
    " Value is the number of micro seconds since Unix Epoch.\n"
).
-spec time_posix_microsec(uuid()) -> integer().
time_posix_microsec(Uuid) ->
    case version(Uuid) of
        v7 ->
            T@1 = case erlang:element(2, Uuid) of
                <<T:48, _:80>> -> T;
                _assert_fail ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"youid/uuid"/utf8>>,
                                function => <<"time_posix_microsec"/utf8>>,
                                line => 369,
                                value => _assert_fail,
                                start => 9394,
                                'end' => 9432,
                                pattern_start => 9405,
                                pattern_end => 9419})
            end,
            T@1 * 1000;

        _ ->
            case 10 of
                0 -> 0;
                Gleam@denominator -> (time(Uuid) - (122192928000000 * 1000)) div Gleam@denominator
            end
    end.

-file("src/youid/uuid.gleam", 409).
?DOC(
    " Determine the time a UUID was created with Unix Epoch\n"
    " This is only relevant to V1 and V7 UUIDs\n"
    " Value is the number of milli seconds since Unix Epoch\n"
).
-spec time_posix_millisec(uuid()) -> integer().
time_posix_millisec(Uuid) ->
    case version(Uuid) of
        v1 ->
            (case 10 of
                0 -> 0;
                Gleam@denominator -> (time(Uuid) - (122192928000000 * 1000)) div Gleam@denominator
            end) div 1000;

        _ ->
            T@1 = case erlang:element(2, Uuid) of
                <<T:48, _:80>> -> T;
                _assert_fail ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"youid/uuid"/utf8>>,
                                function => <<"time_posix_millisec"/utf8>>,
                                line => 415,
                                value => _assert_fail,
                                start => 10441,
                                'end' => 10479,
                                pattern_start => 10452,
                                pattern_end => 10466})
            end,
            T@1
    end.

-file("src/youid/uuid.gleam", 223).
-spec hash_to_uuid_value(bitstring(), integer()) -> bitstring().
hash_to_uuid_value(Hash, Ver) ->
    {
    Time_low@1,
        Time_mid@1,
        Time_hi@1,
        Clock_seq_hi@1,
        Clock_seq_low@1,
        Node@1} = case Hash of
        <<Time_low:32,
            Time_mid:16,
            _:4,
            Time_hi:12,
            _:2,
            Clock_seq_hi:6,
            Clock_seq_low:8,
            Node:48>> -> {
        Time_low,
            Time_mid,
            Time_hi,
            Clock_seq_hi,
            Clock_seq_low,
            Node};
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"youid/uuid"/utf8>>,
                        function => <<"hash_to_uuid_value"/utf8>>,
                        line => 224,
                        value => _assert_fail,
                        start => 5703,
                        'end' => 5850,
                        pattern_start => 5714,
                        pattern_end => 5843})
    end,
    <<Time_low@1:32,
        Time_mid@1:16,
        Ver:4,
        Time_hi@1:12,
        2:2,
        Clock_seq_hi@1:6,
        Clock_seq_low@1:8,
        Node@1:48>>.

-file("src/youid/uuid.gleam", 427).
?DOC(" Convert a UUID to one of the supported string formats\n").
-spec format(uuid(), format()) -> binary().
format(Uuid, Format) ->
    Separator = case Format of
        string ->
            <<"-"/utf8>>;

        _ ->
            <<""/utf8>>
    end,
    Start = case Format of
        urn ->
            <<"urn:uuid:"/utf8>>;

        _ ->
            <<""/utf8>>
    end,
    to_string_help(erlang:element(2, Uuid), 0, Start, Separator).

-file("src/youid/uuid.gleam", 422).
?DOC(" Convert a UUID to a standard string\n").
-spec to_string(uuid()) -> binary().
to_string(Uuid) ->
    format(Uuid, string).

-file("src/youid/uuid.gleam", 118).
-spec do_v1(bitstring(), bitstring()) -> uuid().
do_v1(Node, Clock_seq) ->
    Node@2 = case Node of
        <<Node@1:48>> -> Node@1;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"youid/uuid"/utf8>>,
                        function => <<"do_v1"/utf8>>,
                        line => 119,
                        value => _assert_fail,
                        start => 2902,
                        'end' => 2931,
                        pattern_start => 2913,
                        pattern_end => 2924})
    end,
    {Time_hi@1, Time_mid@1, Time_low@1} = case uuid1_time() of
        <<Time_hi:12, Time_mid:16, Time_low:32>> -> {
        Time_hi,
            Time_mid,
            Time_low};
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"youid/uuid"/utf8>>,
                        function => <<"do_v1"/utf8>>,
                        line => 120,
                        value => _assert_fail@1,
                        start => 2934,
                        'end' => 3000,
                        pattern_start => 2945,
                        pattern_end => 2985})
    end,
    Clock_seq@2 = case Clock_seq of
        <<Clock_seq@1:14>> -> Clock_seq@1;
        _assert_fail@2 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"youid/uuid"/utf8>>,
                        function => <<"do_v1"/utf8>>,
                        line => 121,
                        value => _assert_fail@2,
                        start => 3003,
                        'end' => 3042,
                        pattern_start => 3014,
                        pattern_end => 3030})
    end,
    Value = <<Time_low@1:32,
        Time_mid@1:16,
        1:4,
        Time_hi@1:12,
        2:2,
        Clock_seq@2:14,
        Node@2:48>>,
    {uuid, Value}.

-file("src/youid/uuid.gleam", 100).
?DOC(" Create a V1 (time-based) UUID with default node and random clock sequence.\n").
-spec v1() -> uuid().
v1() ->
    do_v1(default_uuid1_node(), random_uuid1_clockseq()).

-file("src/youid/uuid.gleam", 105).
?DOC(" Convenience for quickly creating a time-based UUID String with default settings.\n").
-spec v1_string() -> binary().
v1_string() ->
    _pipe = v1(),
    to_string(_pipe).

-file("src/youid/uuid.gleam", 111).
?DOC(" Create a V1 (time-based) UUID with custom node and clock sequence.\n").
-spec v1_custom(v1_node(), v1_clock_seq()) -> {ok, uuid()} | {error, nil}.
v1_custom(Node, Clock_seq) ->
    case {validate_node(Node), validate_clock_seq(Clock_seq)} of
        {{ok, N}, {ok, Cs}} ->
            {ok, do_v1(N, Cs)};

        {_, _} ->
            {error, nil}
    end.

-file("src/youid/uuid.gleam", 207).
?DOC(
    " Generates a version 3 (name-based, md5 hashed) UUID.\n"
    " Name must be a valid sequence of bytes\n"
).
-spec v3(uuid(), bitstring()) -> {ok, uuid()} | {error, nil}.
v3(Namespace, Name) ->
    case (erlang:bit_size(Name) rem 8) =:= 0 of
        true ->
            _pipe = <<(erlang:element(2, Namespace))/bitstring, Name/bitstring>>,
            _pipe@1 = md5(_pipe),
            _pipe@2 = hash_to_uuid_value(_pipe@1, 3),
            _pipe@3 = {uuid, _pipe@2},
            {ok, _pipe@3};

        false ->
            {error, nil}
    end.

-file("src/youid/uuid.gleam", 245).
?DOC(" Generates a version 4 (random) UUID.\n").
-spec v4() -> uuid().
v4() ->
    {A@1, B@1, C@1} = case crypto:strong_rand_bytes(16) of
        <<A:48, _:4, B:12, _:2, C:62>> -> {A, B, C};
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"youid/uuid"/utf8>>,
                        function => <<"v4"/utf8>>,
                        line => 246,
                        value => _assert_fail,
                        start => 6052,
                        'end' => 6160,
                        pattern_start => 6063,
                        pattern_end => 6123})
    end,
    Value = <<A@1:48, 4:4, B@1:12, 2:2, C@1:62>>,
    {uuid, Value}.

-file("src/youid/uuid.gleam", 257).
?DOC(" Convenience for quickly creating a random UUID String\n").
-spec v4_string() -> binary().
v4_string() ->
    _pipe = v4(),
    format(_pipe, string).

-file("src/youid/uuid.gleam", 267).
?DOC(
    " Generates a version 5 (name-based, sha1 hashed) UUID.\n"
    " name must be a valid sequence of bytes\n"
).
-spec v5(uuid(), bitstring()) -> {ok, uuid()} | {error, nil}.
v5(Namespace, Name) ->
    case (erlang:bit_size(Name) rem 8) =:= 0 of
        true ->
            _pipe = <<(erlang:element(2, Namespace))/bitstring, Name/bitstring>>,
            _pipe@1 = sha1(_pipe),
            _pipe@2 = hash_to_uuid_value(_pipe@1, 5),
            _pipe@3 = {uuid, _pipe@2},
            {ok, _pipe@3};

        false ->
            {error, nil}
    end.

-file("src/youid/uuid.gleam", 298).
?DOC(
    " Creates a version 7 UUID from a specific UNIX timestamp.\n"
    " Integer should be milliseconds from UNIX epoch.\n"
).
-spec v7_from_millisec(integer()) -> uuid().
v7_from_millisec(Timestamp) ->
    {A@1, B@1} = case crypto:strong_rand_bytes(10) of
        <<A:12, B:62, _:6>> -> {A, B};
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"youid/uuid"/utf8>>,
                        function => <<"v7_from_millisec"/utf8>>,
                        line => 299,
                        value => _assert_fail,
                        start => 7321,
                        'end' => 7406,
                        pattern_start => 7332,
                        pattern_end => 7369})
    end,
    Value = <<Timestamp:48, 7:4, A@1:12, 2:2, B@1:62>>,
    {uuid, Value}.

-file("src/youid/uuid.gleam", 288).
?DOC(" Generates a version 7 (timestamp-based) UUID.\n").
-spec v7() -> uuid().
v7() ->
    {Sec, Ns} = begin
        _pipe = gleam@time@timestamp:system_time(),
        gleam@time@timestamp:to_unix_seconds_and_nanoseconds(_pipe)
    end,
    v7_from_millisec((Sec * 1000) + (Ns div 1000000)).

-file("src/youid/uuid.gleam", 307).
?DOC(
    " Convenience function for quickly creating a timestamp-based\n"
    " version 7 UUID\n"
).
-spec v7_string() -> binary().
v7_string() ->
    _pipe = v7(),
    format(_pipe, string).
