-module(humanise@bytes).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/humanise/bytes.gleam").
-export([to_string/1, as_bytes/1, as_kilobytes/1, as_megabytes/1, as_gigabytes/1, as_terabytes/1, humanise/1]).
-export_type([bytes/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " This module contains functions for formatting amounts of data to `String`s (e.g. `\"100.0B\"`, `\"1.5GB\"`).\n"
    "\n"
    " Usage generally looks like this:\n"
    " ```\n"
    " bytes.Kilobytes(2000.0) |> bytes.humanise |> bytes.to_string // \"2.0MB\"\n"
    " \n"
    " // or, if you don't want to change the unit\n"
    " bytes.Kilobytes(2000.0) |> bytes.to_string // \"2000.0KB\"\n"
    " ```\n"
    "\n"
    " *Note: This module is for 1000-multiple units! (kilobyte, megabyte, etc.)*\n"
    " *If you're looking for 1024-multiple units (kibibyte, mebibyte, etc.), look at the `bytes1024` module instead.*\n"
).

-type bytes() :: {bytes, float()} |
    {kilobytes, float()} |
    {megabytes, float()} |
    {gigabytes, float()} |
    {terabytes, float()}.

-file("src/humanise/bytes.gleam", 118).
?DOC(
    " Format a value as a `String`, rounded to at most 2 decimal places, followed by a unit suffix.\n"
    "\n"
    " Example:\n"
    " ```\n"
    " bytes.Gigabytes(30.125) |> bytes.to_string // \"30.13GB\"\n"
    " ```\n"
).
-spec to_string(bytes()) -> binary().
to_string(Bytes) ->
    {N@5, Suffix} = case Bytes of
        {bytes, N} ->
            {N, <<"B"/utf8>>};

        {kilobytes, N@1} ->
            {N@1, <<"KB"/utf8>>};

        {megabytes, N@2} ->
            {N@2, <<"MB"/utf8>>};

        {gigabytes, N@3} ->
            {N@3, <<"GB"/utf8>>};

        {terabytes, N@4} ->
            {N@4, <<"TB"/utf8>>}
    end,
    humanise@util:format(N@5, Suffix).

-file("src/humanise/bytes.gleam", 44).
?DOC(
    " Convert a value to bytes.\n"
    "\n"
    " Example:\n"
    " ```\n"
    " bytes.Kilobytes(1.0) |> bytes.as_bytes // 1000.0\n"
    " ```\n"
).
-spec as_bytes(bytes()) -> float().
as_bytes(Bytes) ->
    case Bytes of
        {bytes, N} ->
            N;

        {kilobytes, N@1} ->
            N@1 * 1000.0;

        {megabytes, N@2} ->
            N@2 * 1000000.0;

        {gigabytes, N@3} ->
            N@3 * 1000000000.0;

        {terabytes, N@4} ->
            N@4 * 1000000000000.0
    end.

-file("src/humanise/bytes.gleam", 60).
?DOC(
    " Convert a value to kilobytes.\n"
    "\n"
    " Example:\n"
    " ```\n"
    " bytes.Bytes(1000.0) |> bytes.as_kilobytes // 1.0\n"
    " ```\n"
).
-spec as_kilobytes(bytes()) -> float().
as_kilobytes(Bytes) ->
    case 1000.0 of
        +0.0 -> +0.0;
        -0.0 -> -0.0;
        Gleam@denominator -> as_bytes(Bytes) / Gleam@denominator
    end.

-file("src/humanise/bytes.gleam", 70).
?DOC(
    " Convert a value to megabytes.\n"
    "\n"
    " Example:\n"
    " ```\n"
    " bytes.Kilobytes(1000.0) |> bytes.as_megabytes // 1.0\n"
    " ```\n"
).
-spec as_megabytes(bytes()) -> float().
as_megabytes(Bytes) ->
    case 1000000.0 of
        +0.0 -> +0.0;
        -0.0 -> -0.0;
        Gleam@denominator -> as_bytes(Bytes) / Gleam@denominator
    end.

-file("src/humanise/bytes.gleam", 80).
?DOC(
    " Convert a value to gigabytes.\n"
    "\n"
    " Example:\n"
    " ```\n"
    " bytes.Megabytes(1000.0) |> bytes.as_gigabytes // 1.0\n"
    " ```\n"
).
-spec as_gigabytes(bytes()) -> float().
as_gigabytes(Bytes) ->
    case 1000000000.0 of
        +0.0 -> +0.0;
        -0.0 -> -0.0;
        Gleam@denominator -> as_bytes(Bytes) / Gleam@denominator
    end.

-file("src/humanise/bytes.gleam", 90).
?DOC(
    " Convert a value to terabytes.\n"
    "\n"
    " Example:\n"
    " ```\n"
    " bytes.Gigabytes(1000.0) |> bytes.as_terabytes // 1.0\n"
    " ```\n"
).
-spec as_terabytes(bytes()) -> float().
as_terabytes(Bytes) ->
    case 1000000000000.0 of
        +0.0 -> +0.0;
        -0.0 -> -0.0;
        Gleam@denominator -> as_bytes(Bytes) / Gleam@denominator
    end.

-file("src/humanise/bytes.gleam", 100).
?DOC(
    " Convert a value to a more optimal unit, if possible.\n"
    "\n"
    " Example:\n"
    " ```\n"
    " bytes.Megabytes(0.5) |> bytes.humanise // bytes.Kilobytes(500.0)\n"
    " ```\n"
).
-spec humanise(bytes()) -> bytes().
humanise(Bytes) ->
    Abs = fun gleam@float:absolute_value/1,
    B = as_bytes(Bytes),
    gleam@bool:guard(
        Abs(B) < 1000.0,
        {bytes, B},
        fun() -> gleam@bool:guard(Abs(B) < 1000000.0, {kilobytes, case 1000.0 of
                        +0.0 -> +0.0;
                        -0.0 -> -0.0;
                        Gleam@denominator -> B / Gleam@denominator
                    end}, fun() ->
                    gleam@bool:guard(
                        Abs(B) < 1000000000.0,
                        {megabytes, case 1000000.0 of
                                +0.0 -> +0.0;
                                -0.0 -> -0.0;
                                Gleam@denominator@1 -> B / Gleam@denominator@1
                            end},
                        fun() ->
                            gleam@bool:guard(
                                Abs(B) < 1000000000000.0,
                                {gigabytes, case 1000000000.0 of
                                        +0.0 -> +0.0;
                                        -0.0 -> -0.0;
                                        Gleam@denominator@2 -> B / Gleam@denominator@2
                                    end},
                                fun() -> {terabytes, case 1000000000000.0 of
                                            +0.0 -> +0.0;
                                            -0.0 -> -0.0;
                                            Gleam@denominator@3 -> B / Gleam@denominator@3
                                        end} end
                            )
                        end
                    )
                end) end
    ).
