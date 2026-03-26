-module(websocks).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/websocks.gleam").
-export([websocket_key/0, has_deflate/1, mask/2, create_context/2, close_context/1, decode_frame/2, decode_many_frames/2, encode_text_frame/3, encode_binary_frame/3, encode_ping_frame/2, encode_pong_frame/2, encode_close_frame/2, resolve_fragments/2, process_incoming_frames/4, extract_accumulating_frame/1, extract_buffer/1, is_empty_context/1, to_decoded_frame/3, compress_payload/1, compute_accept/1, get_compression_extensions/1]).
-export_type([role/0, compression_extensions/0, compression_context/0, compression/0, flush/0, deflated/0, default/0, context/0, frame/0, control/0, close_reason/0, internal_frame/0, decoded_frame/0, decode_error/0, resolve_error/0, resolve_next/1, process_error/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " <script>\n"
    " const docs = [\n"
    "   {\n"
    "     header: \"Handshake\",\n"
    "     functions: [\n"
    "       \"magic_string\",\n"
    "       \"compute_accept\",\n"
    "       \"has_deflate\",\n"
    "       \"get_compression_extensions\"\n"
    "     ]\n"
    "   },\n"
    "   {\n"
    "     header: \"Masking\",\n"
    "     functions: [\"mask\"]\n"
    "   },\n"
    "   {\n"
    "     header: \"Context\",\n"
    "     functions: [\"create_context\", \"close_context\"]\n"
    "   },\n"
    "   {\n"
    "     header: \"Decoding\",\n"
    "     functions: [\"decode_frame\", \"decode_many_frames\"]\n"
    "   },\n"
    "   {\n"
    "     header: \"Encoding\",\n"
    "     functions: [\n"
    "       \"encode_text_frame\",\n"
    "       \"encode_binary_frame\",\n"
    "       \"encode_ping_frame\",\n"
    "       \"encode_pong_frame\",\n"
    "       \"encode_close_frame\"\n"
    "     ]\n"
    "   },\n"
    "   {\n"
    "     header: \"Resolving fragments\",\n"
    "     functions: [\"resolve_fragments\"]\n"
    "   },\n"
    "   {\n"
    "     header: \"Processing\",\n"
    "     functions: [\"process_incoming_frames\"]\n"
    "   }\n"
    " ]\n"
    "\n"
    " const callback = () => {\n"
    "   const list = document.querySelector(\".sidebar > ul:last-of-type\")\n"
    "   const sortedLists = document.createDocumentFragment()\n"
    "   const sortedMembers = document.createDocumentFragment()\n"
    "\n"
    "   for (const section of docs) {\n"
    "     sortedLists.append((() => {\n"
    "       const node = document.createElement(\"h3\")\n"
    "       node.append(section.header)\n"
    "       return node\n"
    "     })())\n"
    "     sortedMembers.append((() => {\n"
    "       const node = document.createElement(\"h2\")\n"
    "       node.append(section.header)\n"
    "       return node\n"
    "     })())\n"
    "\n"
    "     const sortedList = document.createElement(\"ul\")\n"
    "     sortedLists.append(sortedList)\n"
    "\n"
    "     const sortedFunctions = [...section.functions].sort()\n"
    "\n"
    "     for (const funcName of sortedFunctions) {\n"
    "       const href = `#${funcName}`\n"
    "       const member = document.querySelector(\n"
    "         `.member:has(h2 > a[href=\"${href}\"])`\n"
    "       )\n"
    "       const sidebar = list.querySelector(`li:has(a[href=\"${href}\"])`)\n"
    "       sortedList.append(sidebar)\n"
    "       sortedMembers.append(member)\n"
    "     }\n"
    "   }\n"
    "\n"
    "   document.querySelector(\".sidebar\").insertBefore(sortedLists, list)\n"
    "   document\n"
    "     .querySelector(\".module-members:has(#module-values)\")\n"
    "     .insertBefore(\n"
    "       sortedMembers,\n"
    "       document.querySelector(\"#module-values\").nextSibling\n"
    "     )\n"
    " }\n"
    "\n"
    " document.readyState !== \"loading\"\n"
    "   ? callback()\n"
    "   : document.addEventListener(\n"
    "     \"DOMContentLoaded\",\n"
    "     callback,\n"
    "     { once: true }\n"
    "   )\n"
    " </script>\n"
).

-type role() :: client | server.

-type compression_extensions() :: {compression_extensions,
        boolean(),
        gleam@option:option(integer()),
        boolean(),
        gleam@option:option(integer())}.

-type compression_context() :: any().

-type compression() :: disabled |
    {enabled,
        compression_context(),
        integer(),
        compression_context(),
        integer(),
        boolean(),
        boolean()}.

-type flush() :: sync.

-type deflated() :: deflated.

-type default() :: default.

-opaque context() :: {empty, compression(), bitstring()} |
    {accumulating,
        compression(),
        bitstring(),
        fun((bitstring()) -> frame()),
        bitstring(),
        boolean()}.

-type frame() :: {continuation, bitstring()} |
    {text, bitstring()} |
    {binary, bitstring()} |
    {control, control()}.

-type control() :: {ping, bitstring()} |
    {pong, bitstring()} |
    {close, close_reason()}.

-type close_reason() :: {normal_closure, bitstring()} |
    {going_away, bitstring()} |
    {protocol_error, bitstring()} |
    {unsupported_data, bitstring()} |
    {invalid_payload_data, bitstring()} |
    {policy_violation, bitstring()} |
    {message_too_big, bitstring()} |
    {mandatory_extension, bitstring()} |
    {internal_error, bitstring()} |
    {service_restart, bitstring()} |
    {try_again_later, bitstring()} |
    {bad_gateway, bitstring()} |
    {t_l_s_handshake, bitstring()} |
    {custom_close_code, integer(), bitstring()} |
    no_close_reason.

-type internal_frame() :: {decoded_continuation, bitstring(), boolean()} |
    {decoded_text, bitstring(), boolean()} |
    {decoded_binary, bitstring(), boolean()} |
    {decoded_control, control()}.

-opaque decoded_frame() :: {complete, internal_frame()} |
    {incomplete, internal_frame()} |
    {resolved, frame()}.

-type decode_error() :: invalid_frame | {not_enough_data, bitstring()}.

-type resolve_error() :: not_utf8 |
    orphaned_continuation |
    control_frame_fragmented |
    fragmentation_interrupted |
    concurrent_fragmentation |
    compressed_continuation.

-type resolve_next(GNQ) :: {continue, GNQ} | {stop, GNQ}.

-type process_error() :: {decode_failed, decode_error()} |
    {resolve_failed, resolve_error()}.

-file("src/websocks.gleam", 130).
?DOC(
    " Generates a random WebSocket key for the `Sec-WebSocket-Key` header.\n"
    " Used by clients during the handshake.\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```gleam\n"
    " websocks.websocket_key()\n"
    " // => \"dGhlIHNhbXBsZSBub25jZQ==\"\n"
    " ```\n"
).
-spec websocket_key() -> binary().
websocket_key() ->
    _pipe = crypto:strong_rand_bytes(16),
    gleam_stdlib:base64_encode(_pipe, true).

-file("src/websocks.gleam", 168).
?DOC(
    " Checks if the `permessage-deflate` extension is present in the list of\n"
    " extensions.\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```gleam\n"
    " let extensions =\n"
    "    request.get_header(req, \"sec-websocket-extensions\")\n"
    "    |> result.map(string.split(_, \";\"))\n"
    "    |> result.unwrap([])\n"
    " // => [\"permessage-deflate\", \"client_no_context_takeover\"]\n"
    "\n"
    " websocks.has_deflate(extensions)\n"
    " // => True\n"
    " ```\n"
).
-spec has_deflate(list(binary())) -> boolean().
has_deflate(Extensions) ->
    gleam@list:any(
        Extensions,
        fun(Str) -> Str =:= <<"permessage-deflate"/utf8>> end
    ).

-file("src/websocks.gleam", 277).
-spec repeat_mask(bitstring(), integer()) -> bitstring().
repeat_mask(Mask, Payload_length) ->
    Mask_length = erlang:byte_size(Mask),
    case Payload_length of
        _ when Payload_length =< Mask_length ->
            _pipe = gleam_stdlib:bit_array_slice(Mask, 0, Payload_length),
            gleam@result:unwrap(_pipe, <<>>);

        _ ->
            Repeat = case Mask_length of
                0 -> 0;
                Gleam@denominator -> Payload_length div Gleam@denominator
            end,
            Remainder = case Mask_length of
                0 -> 0;
                Gleam@denominator@1 -> Payload_length rem Gleam@denominator@1
            end,
            Base = binary:copy(Mask, Repeat),
            case Remainder of
                0 ->
                    Base;

                N ->
                    Partial = begin
                        _pipe@1 = gleam_stdlib:bit_array_slice(Mask, 0, N),
                        gleam@result:unwrap(_pipe@1, <<>>)
                    end,
                    <<Base/bitstring, Partial/bitstring>>
            end
    end.

-file("src/websocks.gleam", 271).
?DOC(
    " Masks the payload of any length using the provided mask.\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```gleam\n"
    " let payload = bit_array.from_string(\"Hello\")\n"
    " // Original: H(0x48) e(0x65) l(0x6c) l(0x6c) o(0x6f)\n"
    " // Mask:     0x37     0xfa    0x21    0x3d    0x37\n"
    " // Masked:   0x7f     0x9f    0x4d    0x51    0x58\n"
    " websocks.mask(payload, <<0x37, 0xfa, 0x21, 0x3d>>)\n"
    " // => <<0x7f, 0x9f, 0x4d, 0x51, 0x58>>\n"
    " ```\n"
).
-spec mask(bitstring(), bitstring()) -> bitstring().
mask(Payload, Mask) ->
    Payload_length = erlang:byte_size(Payload),
    _pipe = repeat_mask(Mask, Payload_length),
    crypto:exor(Payload, _pipe).

-file("src/websocks.gleam", 375).
-spec init_compression(boolean(), boolean(), integer(), integer()) -> compression().
init_compression(
    Reset_on_compress,
    Reset_on_decompress,
    Deflate_window_bits,
    Inflate_window_bits
) ->
    Inflate_context = zlib:open(),
    zlib:'inflateInit'(Inflate_context, Inflate_window_bits),
    Deflate_context = zlib:open(),
    zlib:'deflateInit'(
        Deflate_context,
        default,
        deflated,
        Deflate_window_bits,
        8,
        default
    ),
    {enabled,
        Inflate_context,
        Inflate_window_bits,
        Deflate_context,
        Deflate_window_bits,
        Reset_on_compress,
        Reset_on_decompress}.

-file("src/websocks.gleam", 404).
-spec compress(compression(), bitstring()) -> bitstring().
compress(State, Payload) ->
    case State of
        disabled ->
            Payload;

        {enabled, _, _, Deflate_context, _, Reset_on_compress, _} ->
            Compressed = begin
                _pipe = zlib:deflate(
                    Deflate_context,
                    <<Payload/bitstring>>,
                    sync
                ),
                erlang:list_to_bitstring(_pipe)
            end,
            Size = erlang:byte_size(Compressed) - 4,
            Compressed@2 = case Compressed of
                <<Compressed@1:Size/binary, 16#00, 16#00, 16#ff, 16#ff>> ->
                    Compressed@1;

                _ ->
                    Compressed
            end,
            case Reset_on_compress of
                true ->
                    zlib:'deflateReset'(Deflate_context),
                    nil;

                false ->
                    nil
            end,
            Compressed@2
    end.

-file("src/websocks.gleam", 431).
-spec decompress(compression(), bitstring()) -> bitstring().
decompress(State, Payload) ->
    case State of
        disabled ->
            Payload;

        {enabled, Inflate_context, _, _, _, _, Reset_on_decompress} ->
            Decompressed = begin
                _pipe = zlib:inflate(
                    Inflate_context,
                    <<Payload/bitstring, 16#00, 16#00, 16#ff, 16#ff>>
                ),
                erlang:list_to_bitstring(_pipe)
            end,
            case Reset_on_decompress of
                true ->
                    zlib:'inflateReset'(Inflate_context),
                    nil;

                false ->
                    nil
            end,
            Decompressed
    end.

-file("src/websocks.gleam", 452).
-spec close_compression(compression()) -> nil.
close_compression(State) ->
    case State of
        disabled ->
            nil;

        {enabled, Inflate_context, _, Deflate_context, _, _, _} ->
            zlib:close(Inflate_context),
            zlib:close(Deflate_context),
            nil
    end.

-file("src/websocks.gleam", 497).
?DOC(
    " Creates a new context with optional compression settings and role\n"
    " specification. The role parameter determines how compression parameters are\n"
    " interpreted.\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```gleam\n"
    " let extensions = websocks.get_compression_extensions([\n"
    "   \"permessage-deflate\",\n"
    "   \"client_no_context_takeover\",\n"
    " ])\n"
    "\n"
    " websocks.create_context(Some(extensions), websocks.Client)\n"
    " // => Context\n"
    " ```\n"
).
-spec create_context(gleam@option:option(compression_extensions()), role()) -> context().
create_context(Extensions, Role) ->
    case Extensions of
        {some,
            {compression_extensions,
                Client_no_context_takeover,
                Client_max_window_bits,
                Server_no_context_takeover,
                Server_max_window_bits}} ->
            {Reset_on_compress, Reset_on_decompress} = case Role of
                client ->
                    {Client_no_context_takeover, Server_no_context_takeover};

                server ->
                    {Server_no_context_takeover, Client_no_context_takeover}
            end,
            Client_max_window_bits@1 = begin
                _pipe = gleam@option:map(
                    Client_max_window_bits,
                    fun gleam@int:negate/1
                ),
                gleam@option:unwrap(_pipe, -15)
            end,
            Server_max_window_bits@1 = begin
                _pipe@1 = gleam@option:map(
                    Server_max_window_bits,
                    fun gleam@int:negate/1
                ),
                gleam@option:unwrap(_pipe@1, -15)
            end,
            {Deflate_window_bits, Inflate_window_bits} = case Role of
                client ->
                    {Client_max_window_bits@1, Server_max_window_bits@1};

                server ->
                    {Server_max_window_bits@1, Client_max_window_bits@1}
            end,
            _pipe@2 = init_compression(
                Reset_on_compress,
                Reset_on_decompress,
                Deflate_window_bits,
                Inflate_window_bits
            ),
            {empty, _pipe@2, <<>>};

        none ->
            {empty, disabled, <<>>}
    end.

-file("src/websocks.gleam", 545).
?DOC(
    " Frees the compression resources. Should be called when the context is no\n"
    " longer needed.\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```gleam\n"
    " websocks.close_context(context)\n"
    " // => Nil\n"
    " ```\n"
).
-spec close_context(context()) -> nil.
close_context(Context) ->
    close_compression(erlang:element(2, Context)).

-file("src/websocks.gleam", 549).
-spec update_buffer(context(), bitstring()) -> context().
update_buffer(Context, Data) ->
    case Context of
        {empty, _, _} ->
            {empty, erlang:element(2, Context), Data};

        {accumulating, _, _, _, _, _} ->
            {accumulating,
                erlang:element(2, Context),
                Data,
                erlang:element(4, Context),
                erlang:element(5, Context),
                erlang:element(6, Context)}
    end.

-file("src/websocks.gleam", 556).
-spec apply_compression(gleam@option:option(compression()), bitstring()) -> bitstring().
apply_compression(Compression, Payload) ->
    case Compression of
        {some, {enabled, _, _, _, _, _, _} = Compression@1} ->
            compress(Compression@1, Payload);

        _ ->
            Payload
    end.

-file("src/websocks.gleam", 566).
-spec apply_decompression(compression(), bitstring(), boolean()) -> bitstring().
apply_decompression(Compression, Payload, Compressed) ->
    case Compressed of
        true ->
            decompress(Compression, Payload);

        false ->
            Payload
    end.

-file("src/websocks.gleam", 647).
-spec internal_frame_to_frame(internal_frame(), compression()) -> frame().
internal_frame_to_frame(Internal_frame, Compression) ->
    case Internal_frame of
        {decoded_continuation, Payload, Compressed} ->
            {continuation,
                apply_decompression(Compression, Payload, Compressed)};

        {decoded_text, Payload@1, Compressed@1} ->
            {text, apply_decompression(Compression, Payload@1, Compressed@1)};

        {decoded_binary, Payload@2, Compressed@2} ->
            {binary, apply_decompression(Compression, Payload@2, Compressed@2)};

        {decoded_control, Control} ->
            {control, Control}
    end.

-file("src/websocks.gleam", 719).
?DOC(
    " Decodes a single frame from the given data. For decoding multiple frames\n"
    " it is recommended to use `decode_many_frames` instead.\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```gleam\n"
    " // 0x81 : fin=1, rsv1-3=0, opcode=1\n"
    " // 0x05 : mask=0, payload length=5\n"
    " let frame = <<0x81, 0x05>>\n"
    " // 0x48 0x65 0x6c 0x6c 0x6f : \"Hello\"\n"
    " let payload = <<0x48, 0x65, 0x6c, 0x6c, 0x6f>>\n"
    "\n"
    " // Let's assume we have this buffer:\n"
    " let buffer = <<frame:bits, payload:bits, frame:bits>>\n"
    "\n"
    " // The first frame is decoded, and the remaining binary is returned.\n"
    " let decoded = websocks.decode_frame(buffer)\n"
    " // => Ok(#(DecodedFrame, <<129, 5>>))\n"
    "\n"
    " let assert Ok(#(_decoded_frame, rest)) = decoded\n"
    "\n"
    " // Remaining binary is not enough to decode the frame.\n"
    " websocks.decode_frame(rest)\n"
    " // => Error(NotEnoughData(<<129, 5>>))\n"
    "\n"
    " // If we add the remaining payload to the buffer, the frame is decoded.\n"
    " websocks.decode_frame(<<rest:bits, payload:bits>>)\n"
    " // => Ok(#(DecodedFrame, <<>>))\n"
    " ```\n"
).
-spec decode_frame(bitstring(), context()) -> {ok,
        {decoded_frame(), bitstring()}} |
    {error, decode_error()}.
decode_frame(Data, Context) ->
    case Data of
        <<Fin:1,
            Rsv1:1,
            Rsv2:1,
            Rsv3:1,
            Opcode:4,
            Mask:1,
            Payload_length:7,
            Rest/bitstring>> ->
            Compressed = Rsv1 =:= 1,
            gleam@result:'try'(case {Compressed, erlang:element(2, Context)} of
                    {true, disabled} ->
                        {error, invalid_frame};

                    {_, _} ->
                        {ok, nil}
                end, fun(_) ->
                    gleam@bool:guard(
                        (Rsv2 =:= 1) orelse (Rsv3 =:= 1),
                        {error, invalid_frame},
                        fun() ->
                            Extended_payload_length = case Payload_length of
                                126 ->
                                    {some, 16};

                                127 ->
                                    {some, 64};

                                _ ->
                                    none
                            end,
                            gleam@result:'try'(case Extended_payload_length of
                                    {some, Length} ->
                                        case Rest of
                                            <<Payload_length@1:Length,
                                                Rest@1/bitstring>> ->
                                                {ok, {Payload_length@1, Rest@1}};

                                            _ ->
                                                {error, {not_enough_data, Data}}
                                        end;

                                    none ->
                                        {ok, {Payload_length, Rest}}
                                end, fun(_use0) ->
                                    {Payload_length@2, Rest@2} = _use0,
                                    gleam@result:'try'(case {Mask, Rest@2} of
                                            {1,
                                                <<Mask@1:4/binary,
                                                    Payload:Payload_length@2/binary,
                                                    Rest@3/bitstring>>} ->
                                                Payload@1 = begin
                                                    _pipe = repeat_mask(
                                                        Mask@1,
                                                        Payload_length@2
                                                    ),
                                                    crypto:exor(Payload, _pipe)
                                                end,
                                                {ok, {Payload@1, Rest@3}};

                                            {1, _} ->
                                                {error, {not_enough_data, Data}};

                                            {0,
                                                <<Payload@2:Payload_length@2/binary,
                                                    Rest@4/bitstring>>} ->
                                                {ok, {Payload@2, Rest@4}};

                                            {0, _} ->
                                                {error, {not_enough_data, Data}};

                                            {_, _} ->
                                                {error, invalid_frame}
                                        end, fun(_use0@1) ->
                                            {Payload@3, Rest@5} = _use0@1,
                                            Frame = case Opcode of
                                                0 ->
                                                    {ok,
                                                        {decoded_continuation,
                                                            Payload@3,
                                                            Compressed}};

                                                1 ->
                                                    {ok,
                                                        {decoded_text,
                                                            Payload@3,
                                                            Compressed}};

                                                2 ->
                                                    {ok,
                                                        {decoded_binary,
                                                            Payload@3,
                                                            Compressed}};

                                                8 ->
                                                    case Payload@3 of
                                                        <<>> ->
                                                            {ok,
                                                                {decoded_control,
                                                                    {close,
                                                                        no_close_reason}}};

                                                        <<Code:16,
                                                            Data@1/bitstring>> ->
                                                            gleam@bool:guard(
                                                                not gleam@bit_array:is_utf8(
                                                                    Data@1
                                                                ),
                                                                {error,
                                                                    invalid_frame},
                                                                fun() ->
                                                                    case Code of
                                                                        1000 ->
                                                                            {ok,
                                                                                {decoded_control,
                                                                                    {close,
                                                                                        {normal_closure,
                                                                                            Data@1}}}};

                                                                        1001 ->
                                                                            {ok,
                                                                                {decoded_control,
                                                                                    {close,
                                                                                        {going_away,
                                                                                            Data@1}}}};

                                                                        1002 ->
                                                                            {ok,
                                                                                {decoded_control,
                                                                                    {close,
                                                                                        {protocol_error,
                                                                                            Data@1}}}};

                                                                        1003 ->
                                                                            {ok,
                                                                                {decoded_control,
                                                                                    {close,
                                                                                        {unsupported_data,
                                                                                            Data@1}}}};

                                                                        1007 ->
                                                                            {ok,
                                                                                {decoded_control,
                                                                                    {close,
                                                                                        {invalid_payload_data,
                                                                                            Data@1}}}};

                                                                        1008 ->
                                                                            {ok,
                                                                                {decoded_control,
                                                                                    {close,
                                                                                        {policy_violation,
                                                                                            Data@1}}}};

                                                                        1009 ->
                                                                            {ok,
                                                                                {decoded_control,
                                                                                    {close,
                                                                                        {message_too_big,
                                                                                            Data@1}}}};

                                                                        1010 ->
                                                                            {ok,
                                                                                {decoded_control,
                                                                                    {close,
                                                                                        {mandatory_extension,
                                                                                            Data@1}}}};

                                                                        1011 ->
                                                                            {ok,
                                                                                {decoded_control,
                                                                                    {close,
                                                                                        {internal_error,
                                                                                            Data@1}}}};

                                                                        1012 ->
                                                                            {ok,
                                                                                {decoded_control,
                                                                                    {close,
                                                                                        {service_restart,
                                                                                            Data@1}}}};

                                                                        1013 ->
                                                                            {ok,
                                                                                {decoded_control,
                                                                                    {close,
                                                                                        {try_again_later,
                                                                                            Data@1}}}};

                                                                        1014 ->
                                                                            {ok,
                                                                                {decoded_control,
                                                                                    {close,
                                                                                        {bad_gateway,
                                                                                            Data@1}}}};

                                                                        1015 ->
                                                                            {ok,
                                                                                {decoded_control,
                                                                                    {close,
                                                                                        {t_l_s_handshake,
                                                                                            Data@1}}}};

                                                                        Code@1 when (Code@1 >= 3000) andalso (Code@1 =< 4999) ->
                                                                            {ok,
                                                                                {decoded_control,
                                                                                    {close,
                                                                                        {custom_close_code,
                                                                                            Code@1,
                                                                                            Data@1}}}};

                                                                        _ ->
                                                                            {error,
                                                                                invalid_frame}
                                                                    end
                                                                end
                                                            );

                                                        _ ->
                                                            {error,
                                                                invalid_frame}
                                                    end;

                                                9 ->
                                                    {ok,
                                                        {decoded_control,
                                                            {ping, Payload@3}}};

                                                10 ->
                                                    {ok,
                                                        {decoded_control,
                                                            {pong, Payload@3}}};

                                                _ ->
                                                    {error, invalid_frame}
                                            end,
                                            case {Fin, Frame} of
                                                {1,
                                                    {ok,
                                                        {decoded_control,
                                                            Control}}} ->
                                                    {ok,
                                                        {{resolved,
                                                                {control,
                                                                    Control}},
                                                            Rest@5}};

                                                {0, {ok, {decoded_control, _}}} ->
                                                    {error, invalid_frame};

                                                {1, {ok, Frame@1}} ->
                                                    {ok,
                                                        {{complete, Frame@1},
                                                            Rest@5}};

                                                {0, {ok, Frame@2}} ->
                                                    {ok,
                                                        {{incomplete, Frame@2},
                                                            Rest@5}};

                                                {_, _} ->
                                                    {error, invalid_frame}
                                            end
                                        end)
                                end)
                        end
                    )
                end);

        _ ->
            {error, {not_enough_data, Data}}
    end.

-file("src/websocks.gleam", 881).
-spec do_decode_many_frames(bitstring(), context(), list(decoded_frame())) -> {ok,
        {list(decoded_frame()), context()}} |
    {error, nil}.
do_decode_many_frames(Data, Context, Decoded_frames) ->
    case decode_frame(Data, Context) of
        {ok, {Decoded_frame, <<>>}} ->
            {ok,
                {lists:reverse([Decoded_frame | Decoded_frames]),
                    update_buffer(Context, <<>>)}};

        {ok, {Decoded_frame@1, Rest}} ->
            do_decode_many_frames(
                Rest,
                Context,
                [Decoded_frame@1 | Decoded_frames]
            );

        {error, {not_enough_data, Data@1}} ->
            {ok,
                {lists:reverse(Decoded_frames), update_buffer(Context, Data@1)}};

        {error, invalid_frame} ->
            {error, nil}
    end.

-file("src/websocks.gleam", 874).
?DOC(
    " Decodes multiple frames from the given data until the buffer is empty or an\n"
    " error occurs. Returns the provided context with updated buffer.\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```gleam\n"
    " // 0x81 : fin=1, rsv1-3=0, opcode=1\n"
    " // 0x04 : mask=0, payload length=4\n"
    " let frame = <<0x81, 0x04>>\n"
    " // 0x48 0x65 0x6c 0x6c : \"Hell\"\n"
    " let payload1 = <<0x48, 0x65, 0x6c, 0x6c>>\n"
    " // 0x6f 0x20 0x57 0x6f : \"o Wo\"\n"
    " let payload2 = <<0x6f, 0x20, 0x57, 0x6f>>\n"
    " // 0x72 0x6c 0x64 0x21 : \"rld!\"\n"
    " let payload3 = <<0x72, 0x6c, 0x64, 0x21>>\n"
    "\n"
    " // Let's assume we have this buffer:\n"
    " let frames = <<\n"
    "   frame:bits,\n"
    "   payload1:bits,\n"
    "   frame:bits,\n"
    "   payload2:bits,\n"
    "   frame:bits,\n"
    " >>\n"
    "\n"
    " // The context is used to store the remaining bytes after decoding.\n"
    " let context = websocks.create_context(None)\n"
    "\n"
    " let decoded = websocks.decode_many_frames(frames, context)\n"
    " // => Ok(#([DecodedFrame, DecodedFrame], Context: <<0x81, 0x04>>))\n"
    "\n"
    " let assert Ok(#(_decoded_frames, updated_context)) = decoded\n"
    "\n"
    " // We can try to decode the remaining frames using the updated context.\n"
    " websocks.decode_many_frames(payload3, updated_context)\n"
    " // => Ok(#([DecodedFrame], Context: <<>>))\n"
    " ```\n"
).
-spec decode_many_frames(bitstring(), context()) -> {ok,
        {list(decoded_frame()), context()}} |
    {error, nil}.
decode_many_frames(Data, Context) ->
    do_decode_many_frames(
        <<(erlang:element(3, Context))/bitstring, Data/bitstring>>,
        Context,
        []
    ).

-file("src/websocks.gleam", 904).
-spec encode_frame(
    frame(),
    boolean(),
    gleam@option:option(compression()),
    gleam@option:option(bitstring())
) -> bitstring().
encode_frame(Frame, Final, Compression, Masking) ->
    {Opcode, Payload@6} = case Frame of
        {continuation, Payload} ->
            {0, Payload};

        {text, Payload@1} ->
            {1, apply_compression(Compression, Payload@1)};

        {binary, Payload@2} ->
            {2, apply_compression(Compression, Payload@2)};

        {control, {ping, Payload@3}} ->
            {9, Payload@3};

        {control, {pong, Payload@4}} ->
            {10, Payload@4};

        {control, {close, Reason}} ->
            Payload@5 = case Reason of
                no_close_reason ->
                    <<>>;

                {normal_closure, Data} ->
                    <<1000:16, Data/bitstring>>;

                {going_away, Data@1} ->
                    <<1001:16, Data@1/bitstring>>;

                {protocol_error, Data@2} ->
                    <<1002:16, Data@2/bitstring>>;

                {unsupported_data, Data@3} ->
                    <<1003:16, Data@3/bitstring>>;

                {invalid_payload_data, Data@4} ->
                    <<1007:16, Data@4/bitstring>>;

                {policy_violation, Data@5} ->
                    <<1008:16, Data@5/bitstring>>;

                {message_too_big, Data@6} ->
                    <<1009:16, Data@6/bitstring>>;

                {mandatory_extension, Data@7} ->
                    <<1010:16, Data@7/bitstring>>;

                {internal_error, Data@8} ->
                    <<1011:16, Data@8/bitstring>>;

                {service_restart, Data@9} ->
                    <<1012:16, Data@9/bitstring>>;

                {try_again_later, Data@10} ->
                    <<1013:16, Data@10/bitstring>>;

                {bad_gateway, Data@11} ->
                    <<1014:16, Data@11/bitstring>>;

                {t_l_s_handshake, Data@12} ->
                    <<1015:16, Data@12/bitstring>>;

                {custom_close_code, Code, Data@13} ->
                    <<Code:16, Data@13/bitstring>>
            end,
            {8, Payload@5}
    end,
    Payload_length = erlang:byte_size(Payload@6),
    Encoded_payload_length = case Payload_length of
        _ when Payload_length =< 125 ->
            Payload_length;

        _ when Payload_length =< 65535 ->
            126;

        _ ->
            127
    end,
    Extended_payload = case Encoded_payload_length of
        126 ->
            <<Payload_length:16>>;

        127 ->
            <<Payload_length:64>>;

        _ ->
            <<>>
    end,
    {Mask_bit, Mask, Payload@7} = case Masking of
        {some, Mask_bytes} ->
            {1, Mask_bytes, mask(Payload@6, Mask_bytes)};

        none ->
            {0, <<>>, Payload@6}
    end,
    Rsv1 = case Compression of
        {some, {enabled, _, _, _, _, _, _}} ->
            1;

        _ ->
            0
    end,
    Fin = case Final of
        true ->
            1;

        false ->
            0
    end,
    <<Fin:1,
        Rsv1:1,
        0:2,
        Opcode:4,
        Mask_bit:1,
        Encoded_payload_length:7,
        Extended_payload/bitstring,
        Mask/bitstring,
        Payload@7/bitstring>>.

-file("src/websocks.gleam", 983).
?DOC(
    " Encodes a text frame with the given payload, context and masking. If the\n"
    " context has compression enabled, the payload will be compressed.\n"
).
-spec encode_text_frame(
    bitstring(),
    context(),
    gleam@option:option(bitstring())
) -> bitstring().
encode_text_frame(Payload, Context, Masking) ->
    encode_frame(
        {text, Payload},
        true,
        {some, erlang:element(2, Context)},
        Masking
    ).

-file("src/websocks.gleam", 998).
?DOC(
    " Encodes a binary frame with the given payload, context and mask. If the\n"
    " context has compression enabled, the payload will be compressed.\n"
).
-spec encode_binary_frame(
    bitstring(),
    context(),
    gleam@option:option(bitstring())
) -> bitstring().
encode_binary_frame(Payload, Context, Masking) ->
    encode_frame(
        {binary, Payload},
        true,
        {some, erlang:element(2, Context)},
        Masking
    ).

-file("src/websocks.gleam", 1012).
?DOC(" Encodes a ping frame with the given payload and mask.\n").
-spec encode_ping_frame(bitstring(), gleam@option:option(bitstring())) -> bitstring().
encode_ping_frame(Payload, Masking) ->
    encode_frame({control, {ping, Payload}}, true, none, Masking).

-file("src/websocks.gleam", 1025).
?DOC(" Encodes a pong frame with the given payload and mask.\n").
-spec encode_pong_frame(bitstring(), gleam@option:option(bitstring())) -> bitstring().
encode_pong_frame(Payload, Masking) ->
    encode_frame({control, {pong, Payload}}, true, none, Masking).

-file("src/websocks.gleam", 1038).
?DOC(" Encodes a close frame with the given reason and mask.\n").
-spec encode_close_frame(close_reason(), gleam@option:option(bitstring())) -> bitstring().
encode_close_frame(Reason, Masking) ->
    encode_frame({control, {close, Reason}}, true, none, Masking).

-file("src/websocks.gleam", 1125).
-spec do_resolve_fragments(list(decoded_frame()), context(), list(frame())) -> {ok,
        {list(frame()), context()}} |
    {error, resolve_error()}.
do_resolve_fragments(Decoded_frames, Context, Resolved) ->
    case {Decoded_frames, Context} of
        {[], Context@1} ->
            {ok, {lists:reverse(Resolved), Context@1}};

        {[{resolved, {text, Payload}} | Rest], Context@2} ->
            case gleam@bit_array:is_utf8(Payload) of
                true ->
                    do_resolve_fragments(
                        Rest,
                        Context@2,
                        [{text, Payload} | Resolved]
                    );

                false ->
                    {error, not_utf8}
            end;

        {[{resolved, Frame} | Rest@1], Context@3} ->
            do_resolve_fragments(Rest@1, Context@3, [Frame | Resolved]);

        {[{complete, {decoded_continuation, _, _}} | _], {empty, _, _}} ->
            {error, orphaned_continuation};

        {[{complete, Frame@1} | Rest@2], {empty, _, _} = Context@4} ->
            Frame@2 = {resolved,
                internal_frame_to_frame(Frame@1, erlang:element(2, Context@4))},
            do_resolve_fragments([Frame@2 | Rest@2], Context@4, Resolved);

        {[{incomplete, {decoded_text, Payload@1, Compressed}} | Rest@3],
            {empty, Compression, Buffer}} ->
            do_resolve_fragments(
                Rest@3,
                {accumulating,
                    Compression,
                    Buffer,
                    fun(Field@0) -> {text, Field@0} end,
                    Payload@1,
                    Compressed},
                Resolved
            );

        {[{incomplete, {decoded_binary, Payload@2, Compressed@1}} | Rest@4],
            {empty, Compression@1, Buffer@1}} ->
            do_resolve_fragments(
                Rest@4,
                {accumulating,
                    Compression@1,
                    Buffer@1,
                    fun(Field@0) -> {binary, Field@0} end,
                    Payload@2,
                    Compressed@1},
                Resolved
            );

        {[{incomplete, {decoded_continuation, _, _}} | _], {empty, _, _}} ->
            {error, orphaned_continuation};

        {[{incomplete, _} | _], {empty, _, _}} ->
            {error, control_frame_fragmented};

        {[{incomplete, {decoded_continuation, Payload@3, Compressed@2}} |
                Rest@5],
            {accumulating, _, _, _, Accumulated_payload, _} = Context@5} ->
            gleam@bool:guard(
                Compressed@2,
                {error, compressed_continuation},
                fun() ->
                    do_resolve_fragments(
                        Rest@5,
                        {accumulating,
                            erlang:element(2, Context@5),
                            erlang:element(3, Context@5),
                            erlang:element(4, Context@5),
                            <<Accumulated_payload/bitstring,
                                Payload@3/bitstring>>,
                            erlang:element(6, Context@5)},
                        Resolved
                    )
                end
            );

        {[{incomplete, _} | _], {accumulating, _, _, _, _, _}} ->
            {error, concurrent_fragmentation};

        {[{complete, {decoded_continuation, Payload@4, Compressed@3}} | Rest@6],
            {accumulating, _, _, _, _, _} = Context@6} ->
            gleam@bool:guard(
                Compressed@3,
                {error, compressed_continuation},
                fun() ->
                    Payload@5 = apply_decompression(
                        erlang:element(2, Context@6),
                        <<(erlang:element(5, Context@6))/bitstring,
                            Payload@4/bitstring>>,
                        erlang:element(6, Context@6)
                    ),
                    do_resolve_fragments(
                        [{resolved, (erlang:element(4, Context@6))(Payload@5)} |
                            Rest@6],
                        {empty,
                            erlang:element(2, Context@6),
                            erlang:element(3, Context@6)},
                        Resolved
                    )
                end
            );

        {[{complete, _} | _], {accumulating, _, _, _, _, _}} ->
            {error, fragmentation_interrupted}
    end.

-file("src/websocks.gleam", 1118).
?DOC(
    " Resolves a list of decoded frames into a list of frames. If the context has\n"
    " compression enabled, the payload will be decompressed. Incomplete frames are\n"
    " stored in the updated context until the fragmentation is complete. If\n"
    " returns an error, the protocol is violated, and the implementation should\n"
    " consider closing the WebSocket connection.\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```gleam\n"
    " // Incomplete text frame:\n"
    " // 0x01 : fin=0, rsv1-3=0, opcode=1\n"
    " // 0x04 : mask=0, payload length=4\n"
    " let text = <<0x01, 0x04>>\n"
    " // 0x00 : fin=0, rsv1-3=0, opcode=0\n"
    " // 0x04 : mask=0, payload length=4\n"
    " let continuation_complete = <<0x80, 0x04>>\n"
    " // Complete continuation frame:\n"
    " // 0x80 : fin=1, rsv1-3=0, opcode=0\n"
    " // 0x04 : mask=0, payload length=4\n"
    " let continuation_incomplete = <<0x00, 0x04>>\n"
    " // 0x48 0x65 0x6c 0x6c : \"Hell\"\n"
    " let payload1 = <<0x48, 0x65, 0x6c, 0x6c>>\n"
    " // 0x6f 0x20 0x57 0x6f : \"o Wo\"\n"
    " let payload2 = <<0x6f, 0x20, 0x57, 0x6f>>\n"
    " // 0x72 0x6c 0x64 0x21 : \"rld!\"\n"
    " let payload3 = <<0x72, 0x6c, 0x64, 0x21>>\n"
    "\n"
    " // Let's assume we have this buffer:\n"
    " let frames = <<\n"
    "   text:bits,\n"
    "   payload1:bits,\n"
    "   continuation_incomplete:bits,\n"
    "   payload2:bits,\n"
    "   continuation_complete:bits,\n"
    "   payload3:bits,\n"
    " >>\n"
    "\n"
    " let context = websocks.create_context(None)\n"
    "\n"
    " // We assume that the frames have been successfully decoded.\n"
    " let assert Ok(#(decoded_frames, context)) =\n"
    "   websocks.decode_many_frames(frames, context)\n"
    "\n"
    " // Resolve the decoded frames.\n"
    " websocks.resolve_fragments(decoded_frames, context)\n"
    " // => Ok(#([Text(\"Hello World!\")], Context))\n"
    " ```\n"
).
-spec resolve_fragments(list(decoded_frame()), context()) -> {ok,
        {list(frame()), context()}} |
    {error, resolve_error()}.
resolve_fragments(Decoded_frames, Context) ->
    do_resolve_fragments(Decoded_frames, Context, []).

-file("src/websocks.gleam", 1332).
-spec resolve_and_handle_single_frame(
    decoded_frame(),
    context(),
    GPA,
    fun((GPA, context(), frame()) -> resolve_next(GPA))
) -> {ok, {resolve_next(GPA), context()}} | {error, resolve_error()}.
resolve_and_handle_single_frame(Decoded_frame, Context, State, Handler) ->
    case {Decoded_frame, Context} of
        {{resolved, {text, Payload}}, Context@1} ->
            case gleam@bit_array:is_utf8(Payload) of
                true ->
                    {ok,
                        {Handler(State, Context@1, {text, Payload}), Context@1}};

                false ->
                    {error, not_utf8}
            end;

        {{resolved, Frame}, Context@2} ->
            {ok, {Handler(State, Context@2, Frame), Context@2}};

        {{complete, {decoded_continuation, _, _}}, {empty, _, _}} ->
            {error, orphaned_continuation};

        {{complete, Frame@1}, {empty, _, _} = Context@3} ->
            _pipe = internal_frame_to_frame(
                Frame@1,
                erlang:element(2, Context@3)
            ),
            _pipe@1 = {resolved, _pipe},
            resolve_and_handle_single_frame(_pipe@1, Context@3, State, Handler);

        {{incomplete, {decoded_text, Payload@1, Compressed}},
            {empty, Compression, Buffer}} ->
            {ok,
                {{continue, State},
                    {accumulating,
                        Compression,
                        Buffer,
                        fun(Field@0) -> {text, Field@0} end,
                        Payload@1,
                        Compressed}}};

        {{incomplete, {decoded_binary, Payload@2, Compressed@1}},
            {empty, Compression@1, Buffer@1}} ->
            {ok,
                {{continue, State},
                    {accumulating,
                        Compression@1,
                        Buffer@1,
                        fun(Field@0) -> {binary, Field@0} end,
                        Payload@2,
                        Compressed@1}}};

        {{incomplete, {decoded_continuation, _, _}}, {empty, _, _}} ->
            {error, orphaned_continuation};

        {{incomplete, {decoded_control, _}}, {empty, _, _}} ->
            erlang:error(#{gleam_error => panic,
                    message => <<"Incomplete(DecodedControl(..)) is not allowed"/utf8>>,
                    file => <<?FILEPATH/utf8>>,
                    module => <<"websocks"/utf8>>,
                    function => <<"resolve_and_handle_single_frame"/utf8>>,
                    line => 1374});

        {{incomplete, {decoded_continuation, Payload@3, Compressed@2}},
            {accumulating, _, _, _, Accumulated_payload, _} = Context@4} ->
            case Compressed@2 of
                true ->
                    {error, compressed_continuation};

                false ->
                    {ok,
                        {{continue, State},
                            {accumulating,
                                erlang:element(2, Context@4),
                                erlang:element(3, Context@4),
                                erlang:element(4, Context@4),
                                <<Accumulated_payload/bitstring,
                                    Payload@3/bitstring>>,
                                erlang:element(6, Context@4)}}}
            end;

        {{incomplete, _}, {accumulating, _, _, _, _, _}} ->
            {error, concurrent_fragmentation};

        {{complete, {decoded_continuation, Payload@4, Compressed@3}},
            {accumulating, _, _, _, _, _} = Context@5} ->
            case Compressed@3 of
                true ->
                    {error, compressed_continuation};

                false ->
                    Complete_payload = apply_decompression(
                        erlang:element(2, Context@5),
                        <<(erlang:element(5, Context@5))/bitstring,
                            Payload@4/bitstring>>,
                        erlang:element(6, Context@5)
                    ),
                    Frame@2 = (erlang:element(4, Context@5))(Complete_payload),
                    New_context = {empty,
                        erlang:element(2, Context@5),
                        erlang:element(3, Context@5)},
                    resolve_and_handle_single_frame(
                        {resolved, Frame@2},
                        New_context,
                        State,
                        Handler
                    )
            end;

        {{complete, _}, {accumulating, _, _, _, _, _}} ->
            {error, fragmentation_interrupted}
    end.

-file("src/websocks.gleam", 1304).
-spec do_process_incoming_frames(
    bitstring(),
    context(),
    GOX,
    fun((GOX, context(), frame()) -> resolve_next(GOX))
) -> {ok, {GOX, context()}} | {error, process_error()}.
do_process_incoming_frames(Data, Context, State, Handler) ->
    case decode_frame(Data, Context) of
        {ok, {Decoded_frame, Rest}} ->
            Result = resolve_and_handle_single_frame(
                Decoded_frame,
                Context,
                State,
                Handler
            ),
            case Result of
                {ok, {{continue, New_state}, New_context}} ->
                    case Rest of
                        <<>> ->
                            {ok, {New_state, update_buffer(New_context, <<>>)}};

                        _ ->
                            do_process_incoming_frames(
                                Rest,
                                New_context,
                                New_state,
                                Handler
                            )
                    end;

                {ok, {{stop, New_state@1}, New_context@1}} ->
                    {ok, {New_state@1, update_buffer(New_context@1, Rest)}};

                {error, E} ->
                    {error, {resolve_failed, E}}
            end;

        {error, {not_enough_data, Remaining}} ->
            {ok, {State, update_buffer(Context, Remaining)}};

        {error, E@1} ->
            {error, {decode_failed, E@1}}
    end.

-file("src/websocks.gleam", 1294).
?DOC(
    " Processes incoming WebSocket frames from the given data. This function\n"
    " combines the context buffer with the new data, decodes frames, resolves\n"
    " fragments, and calls the handler function for each resolved frame. The\n"
    " handler returns `ResolveNext` to control the processing flow. If there's not\n"
    " enough data to decode a complete frame, the remaining data is stored in the\n"
    " context buffer for the next call.\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```gleam\n"
    " // 0x81 : fin=1, rsv1-3=0, opcode=1\n"
    " // 0x05 : mask=0, payload length=5\n"
    " let frame = <<0x81, 0x05>>\n"
    " // 0x48 0x65 0x6c 0x6c 0x6f : \"Hello\"\n"
    " let payload = <<0x48, 0x65, 0x6c, 0x6c, 0x6f>>\n"
    "\n"
    " // let's assume we have this buffer:\n"
    " let data = <<frame:bits, payload:bits, frame:bits>>\n"
    "\n"
    " let context = websocks.create_context(None)\n"
    " let initial_state = 0\n"
    "\n"
    " // Handler that collects all text frames\n"
    " let handler = fn(state, _context, frame) {\n"
    "   case frame {\n"
    "     websocks.Continuation(payload) ->\n"
    "       echo #(\"received continuation frame\", payload)\n"
    "     websocks.Text(payload) -> echo #(\"received text frame\", payload)\n"
    "     websocks.Binary(payload) -> echo #(\"received binary frame\", payload)\n"
    "     websocks.Control(websocks.Ping(payload)) ->\n"
    "       echo #(\"received ping frame\", payload)\n"
    "     websocks.Control(websocks.Pong(payload)) ->\n"
    "       echo #(\"received pong frame\", payload)\n"
    "     websocks.Control(websocks.Close(reason)) ->\n"
    "       echo #(\n"
    "         \"received close frame\",\n"
    "         bit_array.from_string(string.inspect(reason)),\n"
    "       )\n"
    "   }\n"
    "\n"
    "   websocks.Continue(state + 1)\n"
    " }\n"
    "\n"
    " let processed =\n"
    "   websocks.process_incoming_frames(data, context, initial_state, handler)\n"
    "   // => #(\"received text frame\", \"Hello\")\n"
    "\n"
    " echo processed\n"
    " // => Ok(#(1, context: <<0x81, 0x05>>))\n"
    " ```\n"
).
-spec process_incoming_frames(
    bitstring(),
    context(),
    GOU,
    fun((GOU, context(), frame()) -> resolve_next(GOU))
) -> {ok, {GOU, context()}} | {error, process_error()}.
process_incoming_frames(Data, Context, State, Handler) ->
    Data@1 = <<(erlang:element(3, Context))/bitstring, Data/bitstring>>,
    do_process_incoming_frames(Data@1, Context, State, Handler).

-file("src/websocks.gleam", 1436).
?DOC(false).
-spec extract_accumulating_frame(context()) -> {ok, frame()} | {error, nil}.
extract_accumulating_frame(Context) ->
    case Context of
        {accumulating, _, _, Frame_builder, Accumulated_payload, _} ->
            {ok, Frame_builder(Accumulated_payload)};

        {empty, _, _} ->
            {error, nil}
    end.

-file("src/websocks.gleam", 1445).
?DOC(false).
-spec extract_buffer(context()) -> bitstring().
extract_buffer(Context) ->
    erlang:element(3, Context).

-file("src/websocks.gleam", 1450).
?DOC(false).
-spec is_empty_context(context()) -> boolean().
is_empty_context(Context) ->
    case Context of
        {empty, _, _} ->
            true;

        {accumulating, _, _, _, _, _} ->
            false
    end.

-file("src/websocks.gleam", 1477).
-spec wrap_decoded_frame(internal_frame(), boolean()) -> decoded_frame().
wrap_decoded_frame(Internal, Final) ->
    case Final of
        true ->
            {complete, Internal};

        false ->
            {incomplete, Internal}
    end.

-file("src/websocks.gleam", 1458).
?DOC(false).
-spec to_decoded_frame(frame(), boolean(), boolean()) -> decoded_frame().
to_decoded_frame(Frame, Final, Compressed) ->
    case Frame of
        {continuation, Payload} ->
            _pipe = {decoded_continuation, Payload, Compressed},
            wrap_decoded_frame(_pipe, Final);

        {text, Payload@1} ->
            _pipe@1 = {decoded_text, Payload@1, Compressed},
            wrap_decoded_frame(_pipe@1, Final);

        {binary, Payload@2} ->
            _pipe@2 = {decoded_binary, Payload@2, Compressed},
            wrap_decoded_frame(_pipe@2, Final);

        {control, Control} ->
            {resolved, {control, Control}}
    end.

-file("src/websocks.gleam", 1485).
?DOC(false).
-spec compress_payload(bitstring()) -> bitstring().
compress_payload(Payload) ->
    compress(init_compression(false, false, -15, -15), Payload).

-file("src/websocks.gleam", 145).
?DOC(
    " Computes the value of the `Sec-WebSocket-Accept` header during the handshake.\n"
    " Requires `Sec-WebSocket-Key` header value to be present.\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```gleam\n"
    " websocks.compute_accept(\"dGhlIHNhbXBsZSBub25jZQ==\")\n"
    " // => \"s3pPLMBiTxaQ9kYGzzhZRbK+xOo=\"\n"
    " ```\n"
).
-spec compute_accept(binary()) -> binary().
compute_accept(Key) ->
    _pipe = gleam@string:append(
        Key,
        <<"258EAFA5-E914-47DA-95CA-C5AB0DC85B11"/utf8>>
    ),
    _pipe@1 = gleam_stdlib:identity(_pipe),
    _pipe@2 = gleam@crypto:hash(sha1, _pipe@1),
    gleam_stdlib:base64_encode(_pipe@2, true).

-file("src/websocks.gleam", 234).
?DOC(
    " Parses compression extension parameters from the handshake extension list.\n"
    " Extracts context takeover settings as well as window bits.\n"
    "\n"
    " ### Example\n"
    "\n"
    " ```gleam\n"
    " let extensions = [\n"
    "   \"permessage-deflate\",\n"
    "   \"client_no_context_takeover\",\n"
    "   \"client_max_window_bits=15\",\n"
    " ]\n"
    "\n"
    " websocks.get_compression_extensions(extensions)\n"
    " // => CompressionExtensions(\n"
    " //      client_no_context_takeover: True,\n"
    " //      client_max_window_bits: Some(15),\n"
    " //      server_no_context_takeover: False,\n"
    " //      server_max_window_bits: None,\n"
    " //    )\n"
    " ```\n"
).
-spec get_compression_extensions(list(binary())) -> compression_extensions().
get_compression_extensions(Extensions) ->
    gleam@list:fold(
        Extensions,
        {compression_extensions, false, none, false, none},
        fun(Acc, Extension) -> case Extension of
                <<"client_no_context_takeover"/utf8>> ->
                    {compression_extensions,
                        true,
                        erlang:element(3, Acc),
                        erlang:element(4, Acc),
                        erlang:element(5, Acc)};

                <<"client_max_window_bits="/utf8, Bits/binary>> ->
                    Client_max_window_bits = gleam@option:from_result(
                        gleam_stdlib:parse_int(Bits)
                    ),
                    {compression_extensions,
                        erlang:element(2, Acc),
                        Client_max_window_bits,
                        erlang:element(4, Acc),
                        erlang:element(5, Acc)};

                <<"server_no_context_takeover"/utf8>> ->
                    {compression_extensions,
                        erlang:element(2, Acc),
                        erlang:element(3, Acc),
                        true,
                        erlang:element(5, Acc)};

                <<"server_max_window_bits="/utf8, Bits@1/binary>> ->
                    Server_max_window_bits = gleam@option:from_result(
                        gleam_stdlib:parse_int(Bits@1)
                    ),
                    {compression_extensions,
                        erlang:element(2, Acc),
                        erlang:element(3, Acc),
                        erlang:element(4, Acc),
                        Server_max_window_bits};

                _ ->
                    Acc
            end end
    ).
