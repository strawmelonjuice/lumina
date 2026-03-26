-module(ewe@internal@file).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/ewe/internal/file.gleam").
-export([open/1, close/1, send/5]).
-export_type([io_device/0, file_error/0, file/0, send_error/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-type io_device() :: any().

-type file_error() :: enoent |
    eacces |
    eisdir |
    {eunknown, gleam@dynamic:dynamic_()}.

-type file() :: {file, io_device(), integer()}.

-type send_error() :: {file_issue, file_error()} |
    {socket_issue, glisten@socket:socket_reason()}.

-file("src/ewe/internal/file.gleam", 60).
?DOC(false).
-spec open(binary()) -> {ok, file()} | {error, file_error()}.
open(Path) ->
    ewe_ffi:open_file(Path).

-file("src/ewe/internal/file.gleam", 63).
?DOC(false).
-spec close(io_device()) -> {ok, nil} | {error, file_error()}.
close(File) ->
    ewe_ffi:close_file(File).

-file("src/ewe/internal/file.gleam", 36).
?DOC(false).
-spec send(
    glisten@transport:transport(),
    glisten@socket:socket(),
    io_device(),
    integer(),
    integer()
) -> {ok, nil} | {error, send_error()}.
send(Transport, Socket, Descriptor, Offset, Size) ->
    case Transport of
        tcp ->
            _pipe = file:sendfile(Descriptor, Socket, Offset, Size, []),
            gleam@result:map_error(
                _pipe,
                fun(Field@0) -> {socket_issue, Field@0} end
            );

        ssl ->
            _pipe@1 = file:pread(Descriptor, Offset, Size),
            _pipe@2 = gleam@result:map_error(
                _pipe@1,
                fun(Field@0) -> {file_issue, Field@0} end
            ),
            gleam@result:'try'(
                _pipe@2,
                fun(Bits) ->
                    _pipe@3 = glisten@transport:send(
                        Transport,
                        Socket,
                        gleam@bytes_tree:from_bit_array(Bits)
                    ),
                    gleam@result:map_error(
                        _pipe@3,
                        fun(Field@0) -> {socket_issue, Field@0} end
                    )
                end
            )
    end.
