-module(humanise@bytes1024).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch]).

-export([to_string/1, as_bytes/1, as_kibibytes/1, as_mebibytes/1, as_gibibytes/1, as_tebibytes/1, humanise/1]).
-export_type([bytes/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " This module contains functions for formatting 1024-multiple amounts of data to `String`s (e.g. `\"100.0B\"`, `\"1.5GiB\"`).\n"
    "\n"
    " Usage generally looks like this:\n"
    " ```\n"
    " bytes1024.Kibibytes(2048.0) |> bytes1024.humanise |> bytes1024.to_string // \"2.0MiB\"\n"
    " \n"
    " // or, if you don't want to change the unit\n"
    " bytes1024.Kilobytes(2048.0) |> bytes1024.to_string // \"2048.0KiB\"\n"
    " ```\n"
    "\n"
    " *Note: This module is for 1024-multiple units! (kibibyte, megbibyte, etc.)*\n"
    " *If you're looking for 1000-multiple units (kilobyte, megabyte, etc.), look at the `bytes` module instead.*\n"
).

-type bytes() :: {bytes, float()} |
    {kibibytes, float()} |
    {mebibytes, float()} |
    {gibibytes, float()} |
    {tebibytes, float()}.

-file("src/humanise/bytes1024.gleam", 118).
?DOC(
    " Format a value as a `String`, rounded to at most 2 decimal places, followed by a unit suffix.\n"
    "\n"
    " Example:\n"
    " ```\n"
    " bytes1024.Gibibytes(30.125) |> bytes1024.to_string // \"30.13GiB\"\n"
    " ```\n"
).
-spec to_string(bytes()) -> binary().
to_string(Bytes) ->
    {N@5, Suffix} = case Bytes of
        {bytes, N} ->
            {N, <<"B"/utf8>>};

        {kibibytes, N@1} ->
            {N@1, <<"KiB"/utf8>>};

        {mebibytes, N@2} ->
            {N@2, <<"MiB"/utf8>>};

        {gibibytes, N@3} ->
            {N@3, <<"GiB"/utf8>>};

        {tebibytes, N@4} ->
            {N@4, <<"TiB"/utf8>>}
    end,
    humanise@util:format(N@5, Suffix).

-file("src/humanise/bytes1024.gleam", 44).
?DOC(
    " Convert a value to bytes.\n"
    "\n"
    " Example:\n"
    " ```\n"
    " bytes1024.Kibibytes(1.0) |> bytes1024.as_bytes // 1024.0\n"
    " ```\n"
).
-spec as_bytes(bytes()) -> float().
as_bytes(Bytes) ->
    case Bytes of
        {bytes, N} ->
            N;

        {kibibytes, N@1} ->
            N@1 * 1024.0;

        {mebibytes, N@2} ->
            N@2 * 1048576.0;

        {gibibytes, N@3} ->
            N@3 * 1073741824.0;

        {tebibytes, N@4} ->
            N@4 * 1099511627776.0
    end.

-file("src/humanise/bytes1024.gleam", 60).
?DOC(
    " Convert a value to kibibytes.\n"
    "\n"
    " Example:\n"
    " ```\n"
    " bytes1024.Bytes(1024.0) |> bytes1024.as_kibibytes // 1.0\n"
    " ```\n"
).
-spec as_kibibytes(bytes()) -> float().
as_kibibytes(Bytes) ->
    case 1024.0 of
        +0.0 -> +0.0;
        -0.0 -> -0.0;
        Gleam@denominator -> as_bytes(Bytes) / Gleam@denominator
    end.

-file("src/humanise/bytes1024.gleam", 70).
?DOC(
    " Convert a value to mebibytes.\n"
    "\n"
    " Example:\n"
    " ```\n"
    " bytes1024.Kibibytes(1024.0) |> bytes1024.as_mebibytes // 1.0\n"
    " ```\n"
).
-spec as_mebibytes(bytes()) -> float().
as_mebibytes(Bytes) ->
    case 1048576.0 of
        +0.0 -> +0.0;
        -0.0 -> -0.0;
        Gleam@denominator -> as_bytes(Bytes) / Gleam@denominator
    end.

-file("src/humanise/bytes1024.gleam", 80).
?DOC(
    " Convert a value to gibibytes.\n"
    "\n"
    " Example:\n"
    " ```\n"
    " bytes1024.Mebibytes(1024.0) |> bytes1024.as_gibibytes // 1.0\n"
    " ```\n"
).
-spec as_gibibytes(bytes()) -> float().
as_gibibytes(Bytes) ->
    case 1073741824.0 of
        +0.0 -> +0.0;
        -0.0 -> -0.0;
        Gleam@denominator -> as_bytes(Bytes) / Gleam@denominator
    end.

-file("src/humanise/bytes1024.gleam", 90).
?DOC(
    " Convert a value to tebibytes.\n"
    "\n"
    " Example:\n"
    " ```\n"
    " bytes1024.Gibibytes(1024.0) |> bytes1024.as_tebibytes // 1.0\n"
    " ```\n"
).
-spec as_tebibytes(bytes()) -> float().
as_tebibytes(Bytes) ->
    case 1099511627776.0 of
        +0.0 -> +0.0;
        -0.0 -> -0.0;
        Gleam@denominator -> as_bytes(Bytes) / Gleam@denominator
    end.

-file("src/humanise/bytes1024.gleam", 100).
?DOC(
    " Convert a value to a more optimal unit, if possible.\n"
    "\n"
    " Example:\n"
    " ```\n"
    " bytes1024.Mebibytes(0.5) |> bytes1024.humanise // bytes1024.Kibibytes(512.0)\n"
    " ```\n"
).
-spec humanise(bytes()) -> bytes().
humanise(Bytes) ->
    Abs = fun gleam@float:absolute_value/1,
    B = as_bytes(Bytes),
    gleam@bool:guard(
        Abs(B) < 1024.0,
        {bytes, B},
        fun() -> gleam@bool:guard(Abs(B) < 1048576.0, {kibibytes, case 1024.0 of
                        +0.0 -> +0.0;
                        -0.0 -> -0.0;
                        Gleam@denominator -> B / Gleam@denominator
                    end}, fun() ->
                    gleam@bool:guard(
                        Abs(B) < 1073741824.0,
                        {mebibytes, case 1048576.0 of
                                +0.0 -> +0.0;
                                -0.0 -> -0.0;
                                Gleam@denominator@1 -> B / Gleam@denominator@1
                            end},
                        fun() ->
                            gleam@bool:guard(
                                Abs(B) < 1099511627776.0,
                                {gibibytes, case 1073741824.0 of
                                        +0.0 -> +0.0;
                                        -0.0 -> -0.0;
                                        Gleam@denominator@2 -> B / Gleam@denominator@2
                                    end},
                                fun() -> {tebibytes, case 1099511627776.0 of
                                            +0.0 -> +0.0;
                                            -0.0 -> -0.0;
                                            Gleam@denominator@3 -> B / Gleam@denominator@3
                                        end} end
                            )
                        end
                    )
                end) end
    ).
