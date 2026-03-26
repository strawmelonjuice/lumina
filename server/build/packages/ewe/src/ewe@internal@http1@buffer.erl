-module(ewe@internal@http1@buffer).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/ewe/internal/http1/buffer.gleam").
-export([append/2, split/2]).
-export_type([buffer/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-type buffer() :: {buffer, bitstring(), integer()}.

-file("src/ewe/internal/http1/buffer.gleam", 13).
?DOC(false).
-spec append(buffer(), bitstring()) -> buffer().
append(Buffer, Data) ->
    Pending = gleam@int:max(
        0,
        erlang:element(3, Buffer) - erlang:byte_size(Data)
    ),
    {buffer, <<(erlang:element(2, Buffer))/bitstring, Data/bitstring>>, Pending}.

-file("src/ewe/internal/http1/buffer.gleam", 21).
?DOC(false).
-spec split(buffer(), integer()) -> {bitstring(), bitstring()}.
split(Buffer, Bytes) ->
    case erlang:element(2, Buffer) of
        <<Partition:Bytes/binary, Rest/bitstring>> ->
            {Partition, Rest};

        _ ->
            {erlang:element(2, Buffer), <<>>}
    end.
