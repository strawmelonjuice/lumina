-module(ewe).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/ewe.gleam").
-export([ip_address_to_string/1, get_client_info/1, get_server_info/1, file/3, new/1, bind/2, listening/2, listening_random/1, enable_ipv6/1, enable_tls/3, with_name/2, on_start/2, quiet/1, on_crash/2, idle_timeout/2, start/1, supervised/1, read_body/2, stream_body/1, chunked_continue/1, chunked_stop/0, chunked_stop_abnormal/1, chunked_body/5, send_chunk/2, websocket_continue/1, websocket_continue_with_selector/2, websocket_stop/0, websocket_stop_abnormal/1, upgrade_websocket/4, send_binary_frame/2, send_text_frame/2, send_close_frame/2, sse_continue/1, sse_stop/0, sse_stop_abnormal/1, event_name/2, event_id/2, event_retry/2, sse/4, event/1, send_event/2]).
-export_type([ip_address/0, socket_address/0, response_body/0, file_error/0, builder/0, body_error/0, stream/0, chunked_next/1, websocket_next/2, websocket_message/1, close_code/0, s_s_e_next/1]).

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
    "     header: \"IP Address\",\n"
    "     functions: [\"ip_address_to_string\"]\n"
    "   },\n"
    "   {\n"
    "     header: \"Information\",\n"
    "     functions: [\n"
    "       \"get_client_info\",\n"
    "       \"get_server_info\"\n"
    "     ]\n"
    "   },\n"
    "   {\n"
    "     header: \"Builder\",\n"
    "     functions: [\n"
    "       \"new\",\n"
    "       \"bind\",\n"
    "       \"listening\",\n"
    "       \"listening_random\",\n"
    "       \"enable_ipv6\",\n"
    "       \"enable_tls\",\n"
    "       \"with_name\",\n"
    "       \"quiet\",\n"
    "       \"idle_timeout\",\n"
    "       \"on_start\",\n"
    "       \"on_crash\"\n"
    "     ]\n"
    "   },\n"
    "   {\n"
    "     header: \"Server\",\n"
    "     functions: [\n"
    "       \"start\",\n"
    "       \"supervised\"\n"
    "     ]\n"
    "   },\n"
    "   {\n"
    "     header: \"Request\",\n"
    "     functions: [\n"
    "       \"read_body\",\n"
    "       \"stream_body\"\n"
    "     ]\n"
    "   },\n"
    "   {\n"
    "     header: \"Response\",\n"
    "     functions: [\"file\"]\n"
    "   },\n"
    "   {\n"
    "     header: \"Chunked Response\",\n"
    "     functions: [\n"
    "       \"chunked_body\",\n"
    "       \"send_chunk\",\n"
    "       \"chunked_continue\",\n"
    "       \"chunked_stop\",\n"
    "       \"chunked_stop_abnormal\"\n"
    "     ]\n"
    "   },\n"
    "   {\n"
    "     header: \"Websocket\",\n"
    "     functions: [\n"
    "       \"upgrade_websocket\",\n"
    "       \"send_binary_frame\",\n"
    "       \"send_text_frame\",\n"
    "       \"send_close_frame\",\n"
    "       \"websocket_continue\",\n"
    "       \"websocket_continue_with_selector\",\n"
    "       \"websocket_stop\",\n"
    "       \"websocket_stop_abnormal\"\n"
    "     ]\n"
    "   },\n"
    "   {\n"
    "     header: \"Server-Sent Events\",\n"
    "     functions: [\n"
    "       \"sse\",\n"
    "       \"event\",\n"
    "       \"event_name\",\n"
    "       \"event_id\",\n"
    "       \"event_retry\",\n"
    "       \"send_event\",\n"
    "       \"sse_continue\",\n"
    "       \"sse_stop\",\n"
    "       \"sse_stop_abnormal\"\n"
    "     ]\n"
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

-type ip_address() :: {ip_v4, integer(), integer(), integer(), integer()} |
    {ip_v6,
        integer(),
        integer(),
        integer(),
        integer(),
        integer(),
        integer(),
        integer(),
        integer()}.

-type socket_address() :: {socket_address, ip_address(), integer()}.

-type response_body() :: {text_data, binary()} |
    {bytes_data, gleam@bytes_tree:bytes_tree()} |
    {bits_data, bitstring()} |
    {string_tree_data, gleam@string_tree:string_tree()} |
    empty |
    {file, ewe@internal@file:io_device(), integer(), integer()} |
    chunked |
    websocket |
    s_s_e.

-type file_error() :: no_entry |
    no_access |
    is_directory |
    {unknown_file_error, gleam@dynamic:dynamic_()}.

-opaque builder() :: {builder,
        fun((gleam@http@request:request(ewe@internal@http1:connection())) -> gleam@http@response:response(response_body())),
        integer(),
        binary(),
        boolean(),
        gleam@option:option({binary(), binary()}),
        fun((gleam@http:scheme(), socket_address()) -> nil),
        gleam@http@response:response(response_body()),
        gleam@erlang@process:name(glisten@internal@listener:message()),
        integer()}.

-type body_error() :: body_too_large | invalid_body.

-type stream() :: {consumed,
        bitstring(),
        fun((integer()) -> {ok, stream()} | {error, body_error()})} |
    done.

-opaque chunked_next(PMC) :: {chunked_continue, PMC} |
    chunked_stop |
    {chunked_abnormal_stop, binary()}.

-opaque websocket_next(PMD, PME) :: {websocket_continue,
        PMD,
        gleam@option:option(gleam@erlang@process:selector(PME))} |
    websocket_normal_stop |
    {websocket_abnormal_stop, binary()}.

-type websocket_message(PMF) :: {text, binary()} |
    {binary, bitstring()} |
    {user, PMF}.

-type close_code() :: {normal_closure, binary()} |
    {invalid_payload_data, binary()} |
    {policy_violation, binary()} |
    {message_too_big, binary()} |
    {internal_error, binary()} |
    {service_restart, binary()} |
    {try_again_later, binary()} |
    {bad_gateway, binary()} |
    {custom_close_code, integer(), binary()} |
    no_close_reason.

-opaque s_s_e_next(PMG) :: {s_s_e_continue, PMG} |
    s_s_e_normal_stop |
    {s_s_e_abnormal_stop, binary()}.

-file("src/ewe.gleam", 189).
-spec glisten_to_ewe_ip(glisten:ip_address()) -> ip_address().
glisten_to_ewe_ip(Ip) ->
    case Ip of
        {ip_v4, N1, N2, N3, N4} ->
            {ip_v4, N1, N2, N3, N4};

        {ip_v6, N1@1, N2@1, N3@1, N4@1, N5, N6, N7, N8} ->
            {ip_v6, N1@1, N2@1, N3@1, N4@1, N5, N6, N7, N8}
    end.

-file("src/ewe.gleam", 197).
-spec glisten_options_to_ewe_ip(glisten@socket@options:ip_address()) -> ip_address().
glisten_options_to_ewe_ip(Ip) ->
    case Ip of
        {ip_v4, N1, N2, N3, N4} ->
            {ip_v4, N1, N2, N3, N4};

        {ip_v6, N1@1, N2@1, N3@1, N4@1, N5, N6, N7, N8} ->
            {ip_v6, N1@1, N2@1, N3@1, N4@1, N5, N6, N7, N8}
    end.

-file("src/ewe.gleam", 205).
-spec ewe_to_glisten_ip(ip_address()) -> glisten:ip_address().
ewe_to_glisten_ip(Ip) ->
    case Ip of
        {ip_v4, N1, N2, N3, N4} ->
            {ip_v4, N1, N2, N3, N4};

        {ip_v6, N1@1, N2@1, N3@1, N4@1, N5, N6, N7, N8} ->
            {ip_v6, N1@1, N2@1, N3@1, N4@1, N5, N6, N7, N8}
    end.

-file("src/ewe.gleam", 184).
?DOC(" Converts an `IpAddress` to its string representation.\n").
-spec ip_address_to_string(ip_address()) -> binary().
ip_address_to_string(Address) ->
    _pipe = ewe_to_glisten_ip(Address),
    glisten:ip_address_to_string(_pipe).

-file("src/ewe.gleam", 225).
?DOC(
    " Retrieves the client's socket address from the connection. Returns error if\n"
    " the socket information is unavailable.\n"
).
-spec get_client_info(ewe@internal@http1:connection()) -> {ok, socket_address()} |
    {error, nil}.
get_client_info(Connection) ->
    _pipe = glisten@transport:peername(
        erlang:element(2, Connection),
        erlang:element(3, Connection)
    ),
    gleam@result:map(
        _pipe,
        fun(Server_info) ->
            {socket_address,
                glisten_options_to_ewe_ip(erlang:element(1, Server_info)),
                erlang:element(2, Server_info)}
        end
    ).

-file("src/ewe.gleam", 236).
?DOC(
    " Gets the server's bound address and port. Requires the server to be running\n"
    " and the listener name to match the one set in `ewe.with_name`.\n"
).
-spec get_server_info(
    gleam@erlang@process:name(glisten@internal@listener:message())
) -> socket_address().
get_server_info(Name) ->
    Server_info = glisten:get_server_info(Name, 10000),
    Ip_address = glisten_to_ewe_ip(erlang:element(3, Server_info)),
    {socket_address, Ip_address, erlang:element(2, Server_info)}.

-file("src/ewe.gleam", 293).
-spec transform_response_body(gleam@http@response:response(response_body())) -> gleam@http@response:response(ewe@internal@http1:response_body()).
transform_response_body(Resp) ->
    gleam@http@response:set_body(Resp, case erlang:element(4, Resp) of
            {text_data, Text} ->
                {text_data, Text};

            {bytes_data, Bytes} ->
                {bytes_data, Bytes};

            {bits_data, Bits} ->
                {bits_data, Bits};

            {string_tree_data, String_tree} ->
                {string_tree_data, String_tree};

            chunked ->
                chunked;

            {file, Descriptor, Offset, Size} ->
                {file, Descriptor, Offset, Size};

            websocket ->
                websocket;

            s_s_e ->
                s_s_e;

            empty ->
                empty
        end).

-file("src/ewe.gleam", 325).
-spec internal_to_file_error(ewe@internal@file:file_error()) -> file_error().
internal_to_file_error(Error) ->
    case Error of
        enoent ->
            no_entry;

        eacces ->
            no_access;

        eisdir ->
            is_directory;

        {eunknown, Error@1} ->
            {unknown_file_error, Error@1}
    end.

-file("src/ewe.gleam", 336).
?DOC(
    " Creates a file response body. Use `offset` to skip bytes from the start, and\n"
    " `limit` to send only a portion of the file.\n"
).
-spec file(
    binary(),
    gleam@option:option(integer()),
    gleam@option:option(integer())
) -> {ok, response_body()} | {error, file_error()}.
file(Path, Offset, Limit) ->
    case ewe_ffi:open_file(Path) of
        {ok, File} ->
            {ok,
                {file,
                    erlang:element(2, File),
                    gleam@option:unwrap(Offset, 0),
                    gleam@option:unwrap(Limit, erlang:element(3, File))}};

        {error, Error} ->
            {error, internal_to_file_error(Error)}
    end.

-file("src/ewe.gleam", 373).
?DOC(" Creates new server builder with handler provided.\n").
-spec new(
    fun((gleam@http@request:request(ewe@internal@http1:connection())) -> gleam@http@response:response(response_body()))
) -> builder().
new(Handler) ->
    {builder,
        Handler,
        8080,
        <<"127.0.0.1"/utf8>>,
        false,
        none,
        fun(Scheme, Server) ->
            Address = case erlang:element(2, Server) of
                {ip_v6, _, _, _, _, _, _, _, _} ->
                    <<<<"["/utf8,
                            (ip_address_to_string(erlang:element(2, Server)))/binary>>/binary,
                        "]"/utf8>>;

                {ip_v4, _, _, _, _} ->
                    ip_address_to_string(erlang:element(2, Server))
            end,
            Url = <<<<<<<<(gleam@http:scheme_to_string(Scheme))/binary,
                            "://"/utf8>>/binary,
                        Address/binary>>/binary,
                    ":"/utf8>>/binary,
                (erlang:integer_to_binary(erlang:element(3, Server)))/binary>>,
            gleam_stdlib:println(<<"Listening on "/utf8, Url/binary>>)
        end,
        begin
            _pipe = gleam@http@response:new(500),
            gleam@http@response:set_body(_pipe, empty)
        end,
        gleam_erlang_ffi:new_name(<<"glisten_listener"/utf8>>),
        10000}.

-file("src/ewe.gleam", 405).
?DOC(
    " Binds server to a specific network interface (e.g., \"0.0.0.0\" for all IPv4\n"
    " interfaces or \"127.0.0.1\" for localhost). To bind to IPv6 addresses like\n"
    " \"::\" or \"::1\", you must use `ewe.enable_ipv6`. Crashes the program if the\n"
    " interface is invalid.\n"
).
-spec bind(builder(), binary()) -> builder().
bind(Builder, Interface) ->
    {builder,
        erlang:element(2, Builder),
        erlang:element(3, Builder),
        Interface,
        erlang:element(5, Builder),
        erlang:element(6, Builder),
        erlang:element(7, Builder),
        erlang:element(8, Builder),
        erlang:element(9, Builder),
        erlang:element(10, Builder)}.

-file("src/ewe.gleam", 410).
?DOC(" Sets the listening port for server.\n").
-spec listening(builder(), integer()) -> builder().
listening(Builder, Port) ->
    {builder,
        erlang:element(2, Builder),
        Port,
        erlang:element(4, Builder),
        erlang:element(5, Builder),
        erlang:element(6, Builder),
        erlang:element(7, Builder),
        erlang:element(8, Builder),
        erlang:element(9, Builder),
        erlang:element(10, Builder)}.

-file("src/ewe.gleam", 416).
?DOC(
    " Sets the listening port to 0, which causes the OS to assign a random\n"
    " available port.\n"
).
-spec listening_random(builder()) -> builder().
listening_random(Builder) ->
    {builder,
        erlang:element(2, Builder),
        0,
        erlang:element(4, Builder),
        erlang:element(5, Builder),
        erlang:element(6, Builder),
        erlang:element(7, Builder),
        erlang:element(8, Builder),
        erlang:element(9, Builder),
        erlang:element(10, Builder)}.

-file("src/ewe.gleam", 422).
?DOC(
    " Enables IPv6 support, allowing the server to accept connections over IPv6\n"
    " addresses. Must be called for binding to IPv6 addresses via `ewe.bind`.\n"
).
-spec enable_ipv6(builder()) -> builder().
enable_ipv6(Builder) ->
    {builder,
        erlang:element(2, Builder),
        erlang:element(3, Builder),
        erlang:element(4, Builder),
        true,
        erlang:element(6, Builder),
        erlang:element(7, Builder),
        erlang:element(8, Builder),
        erlang:element(9, Builder),
        erlang:element(10, Builder)}.

-file("src/ewe.gleam", 428).
?DOC(
    " Enables TLS (HTTPS) support, with provided certificate and key files.\n"
    " Crashes the program if the files don't exist or are invalid.\n"
).
-spec enable_tls(builder(), binary(), binary()) -> builder().
enable_tls(Builder, Certificate_file, Key_file) ->
    {builder,
        erlang:element(2, Builder),
        erlang:element(3, Builder),
        erlang:element(4, Builder),
        erlang:element(5, Builder),
        {some, {Certificate_file, Key_file}},
        erlang:element(7, Builder),
        erlang:element(8, Builder),
        erlang:element(9, Builder),
        erlang:element(10, Builder)}.

-file("src/ewe.gleam", 438).
?DOC(
    " Sets a custom listener process name. This name is required when calling\n"
    " `ewe.get_server_info` to retrieve the server's bound address and port.\n"
).
-spec with_name(
    builder(),
    gleam@erlang@process:name(glisten@internal@listener:message())
) -> builder().
with_name(Builder, Name) ->
    {builder,
        erlang:element(2, Builder),
        erlang:element(3, Builder),
        erlang:element(4, Builder),
        erlang:element(5, Builder),
        erlang:element(6, Builder),
        erlang:element(7, Builder),
        erlang:element(8, Builder),
        Name,
        erlang:element(10, Builder)}.

-file("src/ewe.gleam", 447).
?DOC(
    " Sets a callback function called after the server starts. Receives the scheme\n"
    " and server's socket address.\n"
).
-spec on_start(builder(), fun((gleam@http:scheme(), socket_address()) -> nil)) -> builder().
on_start(Builder, On_start) ->
    {builder,
        erlang:element(2, Builder),
        erlang:element(3, Builder),
        erlang:element(4, Builder),
        erlang:element(5, Builder),
        erlang:element(6, Builder),
        On_start,
        erlang:element(8, Builder),
        erlang:element(9, Builder),
        erlang:element(10, Builder)}.

-file("src/ewe.gleam", 455).
?DOC(" Sets an empty `on_start` function.\n").
-spec quiet(builder()) -> builder().
quiet(Builder) ->
    {builder,
        erlang:element(2, Builder),
        erlang:element(3, Builder),
        erlang:element(4, Builder),
        erlang:element(5, Builder),
        erlang:element(6, Builder),
        fun(_, _) -> nil end,
        erlang:element(8, Builder),
        erlang:element(9, Builder),
        erlang:element(10, Builder)}.

-file("src/ewe.gleam", 460).
?DOC(" Sets a custom response that will be sent when server crashes.\n").
-spec on_crash(builder(), gleam@http@response:response(response_body())) -> builder().
on_crash(Builder, On_crash) ->
    {builder,
        erlang:element(2, Builder),
        erlang:element(3, Builder),
        erlang:element(4, Builder),
        erlang:element(5, Builder),
        erlang:element(6, Builder),
        erlang:element(7, Builder),
        On_crash,
        erlang:element(9, Builder),
        erlang:element(10, Builder)}.

-file("src/ewe.gleam", 466).
?DOC(
    " Sets the idle timeout in milliseconds. Connections are closed after this\n"
    " period of inactivity. Defaults to 10_000ms if the value is negative.\n"
).
-spec idle_timeout(builder(), integer()) -> builder().
idle_timeout(Builder, Idle_timeout) ->
    case Idle_timeout of
        Idle_timeout@1 when Idle_timeout@1 >= 0 ->
            {builder,
                erlang:element(2, Builder),
                erlang:element(3, Builder),
                erlang:element(4, Builder),
                erlang:element(5, Builder),
                erlang:element(6, Builder),
                erlang:element(7, Builder),
                erlang:element(8, Builder),
                erlang:element(9, Builder),
                Idle_timeout@1};

        _ ->
            {builder,
                erlang:element(2, Builder),
                erlang:element(3, Builder),
                erlang:element(4, Builder),
                erlang:element(5, Builder),
                erlang:element(6, Builder),
                erlang:element(7, Builder),
                erlang:element(8, Builder),
                erlang:element(9, Builder),
                10000}
    end.

-file("src/ewe.gleam", 477).
?DOC(" Starts the server with the provided configuration.\n").
-spec start(builder()) -> {ok,
        gleam@otp@actor:started(gleam@otp@static_supervisor:supervisor())} |
    {error, gleam@otp@actor:start_error()}.
start(Builder) ->
    Handler = fun(Req) ->
        transform_response_body((erlang:element(2, Builder))(Req))
    end,
    On_crash = transform_response_body(erlang:element(8, Builder)),
    Factory_name = gleam_erlang_ffi:new_name(<<"ewe_streams"/utf8>>),
    Factory_child = begin
        _pipe = gleam@otp@factory_supervisor:worker_child(
            fun(Start) -> Start() end
        ),
        _pipe@1 = gleam@otp@factory_supervisor:restart_strategy(
            _pipe,
            temporary
        ),
        _pipe@2 = gleam@otp@factory_supervisor:named(_pipe@1, Factory_name),
        gleam@otp@factory_supervisor:supervised(_pipe@2)
    end,
    Glisten = begin
        _pipe@3 = glisten:new(
            fun ewe@internal@handler:init/1,
            ewe@internal@handler:loop(
                Handler,
                On_crash,
                Factory_name,
                erlang:element(10, Builder)
            )
        ),
        _pipe@4 = glisten:bind(_pipe@3, erlang:element(4, Builder)),
        glisten:with_listener_name(_pipe@4, erlang:element(9, Builder))
    end,
    Glisten@1 = case erlang:element(5, Builder) of
        true ->
            glisten:with_ipv6(Glisten);

        false ->
            Glisten
    end,
    Glisten@2 = case erlang:element(6, Builder) of
        {some, {Cert, Key}} ->
            glisten:with_tls(Glisten@1, Cert, Key);

        none ->
            Glisten@1
    end,
    _pipe@5 = gleam@otp@static_supervisor:new(one_for_all),
    _pipe@6 = gleam@otp@static_supervisor:add(
        _pipe@5,
        glisten:supervised(Glisten@2, erlang:element(3, Builder))
    ),
    _pipe@7 = gleam@otp@static_supervisor:add(_pipe@6, Factory_child),
    _pipe@8 = gleam@otp@static_supervisor:start(_pipe@7),
    gleam@result:map(
        _pipe@8,
        fun(Started) ->
            Scheme = case erlang:element(6, Builder) of
                {some, {_, _}} ->
                    https;

                none ->
                    http
            end,
            Server_info = glisten:get_server_info(
                erlang:element(9, Builder),
                10000
            ),
            Ip_address = glisten_to_ewe_ip(erlang:element(3, Server_info)),
            Server = {socket_address,
                Ip_address,
                erlang:element(2, Server_info)},
            (erlang:element(7, Builder))(Scheme, Server),
            Started
        end
    ).

-file("src/ewe.gleam", 533).
?DOC(" Returns a child specification for use in a supervision tree.\n").
-spec supervised(builder()) -> gleam@otp@supervision:child_specification(gleam@otp@static_supervisor:supervisor()).
supervised(Builder) ->
    gleam@otp@supervision:supervisor(fun() -> start(Builder) end).

-file("src/ewe.gleam", 557).
?DOC(
    " Reads body from the request. Returns `BodyTooLarge` if body exceeds\n"
    " `bytes_limit`, or `InvalidBody` if malformed. Supports both chunked and\n"
    " content-length bodies.\n"
).
-spec read_body(
    gleam@http@request:request(ewe@internal@http1:connection()),
    integer()
) -> {ok, gleam@http@request:request(bitstring())} | {error, body_error()}.
read_body(Req, Bytes_limit) ->
    case ewe@internal@http1:read_body(Req, Bytes_limit) of
        {ok, Req@1} ->
            {ok, Req@1};

        {error, body_too_large} ->
            {error, body_too_large};

        {error, _} ->
            {error, invalid_body}
    end.

-file("src/ewe.gleam", 589).
-spec consumer_adapter(
    fun((integer()) -> {ok, ewe@internal@http1:stream()} |
        {error, ewe@internal@http1:parse_error()})
) -> fun((integer()) -> {ok, stream()} | {error, body_error()}).
consumer_adapter(Internal_consumer) ->
    fun(Size) -> case Internal_consumer(Size) of
            {ok, done} ->
                {ok, done};

            {ok, {consumed, Data, Next}} ->
                {ok, {consumed, Data, consumer_adapter(Next)}};

            {error, _} ->
                {error, invalid_body}
        end end.

-file("src/ewe.gleam", 582).
?DOC(" Returns a consumer for streaming the request body in chunks.\n").
-spec stream_body(gleam@http@request:request(ewe@internal@http1:connection())) -> {ok,
        fun((integer()) -> {ok, stream()} | {error, body_error()})} |
    {error, body_error()}.
stream_body(Req) ->
    case ewe@internal@http1:stream_body(Req) of
        {ok, Consumer} ->
            {ok, consumer_adapter(Consumer)};

        {error, _} ->
            {error, invalid_body}
    end.

-file("src/ewe.gleam", 623).
?DOC(" Instructs chunked response to continue processing.\n").
-spec chunked_continue(PNF) -> chunked_next(PNF).
chunked_continue(User_state) ->
    {chunked_continue, User_state}.

-file("src/ewe.gleam", 628).
?DOC(" Instructs chunked response to stop normally.\n").
-spec chunked_stop() -> chunked_next(any()).
chunked_stop() ->
    chunked_stop.

-file("src/ewe.gleam", 633).
?DOC(" Instructs chunked response to stop with abnormal reason.\n").
-spec chunked_stop_abnormal(binary()) -> chunked_next(any()).
chunked_stop_abnormal(Reason) ->
    {chunked_abnormal_stop, Reason}.

-file("src/ewe.gleam", 637).
-spec to_internal_chunked_next(chunked_next(PNL)) -> ewe@internal@stream@chunked:chunked_next(PNL).
to_internal_chunked_next(Next) ->
    case Next of
        {chunked_continue, User_state} ->
            {continue, User_state};

        chunked_stop ->
            normal_stop;

        {chunked_abnormal_stop, Reason} ->
            {abnormal_stop, Reason}
    end.

-file("src/ewe.gleam", 657).
?DOC(
    " Sets up the connection for chunked response.\n"
    "\n"
    " `on_init` function is called once the chunked response process is\n"
    " initialized. The argument is subject that can be used to send chunks to the\n"
    " client. It must return initial state.\n"
    "\n"
    " `handler` function is called for every message received. It must return\n"
    " instruction on how chunked response should proceed.\n"
    "\n"
    " `on_close` function is called when the chunked response process is going to be stopped.\n"
).
-spec chunked_body(
    gleam@http@request:request(ewe@internal@http1:connection()),
    gleam@http@response:response(any()),
    fun((gleam@erlang@process:subject(PNQ)) -> PNS),
    fun((ewe@internal@stream@chunked:chunked_body(), PNS, PNQ) -> chunked_next(PNS)),
    fun((ewe@internal@stream@chunked:chunked_body(), PNS) -> nil)
) -> gleam@http@response:response(response_body()).
chunked_body(Req, Resp, On_init, Handler, On_close) ->
    Handler@1 = fun(Conn, State, Msg) -> _pipe = Handler(Conn, State, Msg),
        to_internal_chunked_next(_pipe) end,
    Transport = erlang:element(2, erlang:element(4, Req)),
    Socket = erlang:element(3, erlang:element(4, Req)),
    case ewe@internal@stream@chunked:send_response(Resp, Transport, Socket) of
        {ok, nil} ->
            Started = begin
                _pipe@1 = gleam@otp@factory_supervisor:get_by_name(
                    erlang:element(5, erlang:element(4, Req))
                ),
                gleam@otp@factory_supervisor:start_child(
                    _pipe@1,
                    fun() ->
                        ewe@internal@stream@chunked:start(
                            Transport,
                            Socket,
                            On_init,
                            Handler@1,
                            On_close
                        )
                    end
                )
            end,
            case Started of
                {ok, Started@1} ->
                    _ = glisten@transport:controlling_process(
                        Transport,
                        Socket,
                        erlang:element(2, Started@1)
                    ),
                    _pipe@2 = gleam@http@response:new(200),
                    gleam@http@response:set_body(_pipe@2, chunked);

                {error, _} ->
                    _pipe@3 = gleam@http@response:new(400),
                    gleam@http@response:set_body(_pipe@3, empty)
            end;

        {error, nil} ->
            _pipe@4 = gleam@http@response:new(400),
            gleam@http@response:set_body(_pipe@4, empty)
    end.

-file("src/ewe.gleam", 694).
?DOC(" Sends a chunk to the client.\n").
-spec send_chunk(ewe@internal@stream@chunked:chunked_body(), bitstring()) -> {ok,
        nil} |
    {error, glisten@socket:socket_reason()}.
send_chunk(Body, Chunk) ->
    ewe@internal@stream@chunked:send_chunk(
        erlang:element(2, Body),
        erlang:element(3, Body),
        Chunk
    ).

-file("src/ewe.gleam", 722).
?DOC(" Instructs WebSocket connection to continue processing.\n").
-spec websocket_continue(PNW) -> websocket_next(PNW, any()).
websocket_continue(User_state) ->
    {websocket_continue, User_state, none}.

-file("src/ewe.gleam", 730).
?DOC(
    " Instructs WebSocket connection to continue processing, including selector\n"
    " for custom messages.\n"
).
-spec websocket_continue_with_selector(POA, gleam@erlang@process:selector(POB)) -> websocket_next(POA, POB).
websocket_continue_with_selector(User_state, Selector) ->
    {websocket_continue, User_state, {some, Selector}}.

-file("src/ewe.gleam", 738).
?DOC(" Instructs WebSocket connection to stop.\n").
-spec websocket_stop() -> websocket_next(any(), any()).
websocket_stop() ->
    websocket_normal_stop.

-file("src/ewe.gleam", 743).
?DOC(" Instructs WebSocket connection to stop with abnormal reason.\n").
-spec websocket_stop_abnormal(binary()) -> websocket_next(any(), any()).
websocket_stop_abnormal(Reason) ->
    {websocket_abnormal_stop, Reason}.

-file("src/ewe.gleam", 749).
-spec to_websocket_next(ewe@internal@stream@websocket:websocket_next(PON, POO)) -> websocket_next(PON, POO).
to_websocket_next(Next) ->
    case Next of
        {continue, User_state, Selector} ->
            {websocket_continue, User_state, Selector};

        normal_stop ->
            websocket_normal_stop;

        {abnormal_stop, Reason} ->
            {websocket_abnormal_stop, Reason}
    end.

-file("src/ewe.gleam", 760).
-spec to_internal_websocket_next(websocket_next(POT, POU)) -> ewe@internal@stream@websocket:websocket_next(POT, POU).
to_internal_websocket_next(Next) ->
    case Next of
        {websocket_continue, User_state, Selector} ->
            {continue, User_state, Selector};

        websocket_normal_stop ->
            normal_stop;

        {websocket_abnormal_stop, Reason} ->
            {abnormal_stop, Reason}
    end.

-file("src/ewe.gleam", 781).
-spec transform_websocket_message(
    ewe@internal@stream@websocket:websocket_message(POZ)
) -> {ok, websocket_message(POZ)} | {error, nil}.
transform_websocket_message(Message) ->
    case Message of
        {frame, {text, Payload}} ->
            {ok, {text, gleam_stdlib:identity(Payload)}};

        {frame, {binary, Payload@1}} ->
            {ok, {binary, Payload@1}};

        {user_message, User_message} ->
            {ok, {user, User_message}};

        _ ->
            {error, nil}
    end.

-file("src/ewe.gleam", 808).
?DOC(
    " Upgrade request to a WebSocket connection. If the initial request is not\n"
    " valid for WebSocket upgrade, 400 response is sent.\n"
    "\n"
    " `on_init` function is called once process that handles WebSocket connection\n"
    " is initialized. It must return a tuple with initial state and selector for\n"
    " custom messages. If there is no custom messages, user can pass the same\n"
    " selector from the argument\n"
    "\n"
    " `handler` function is called for every WebSocket message received. It must\n"
    " return instruction on how WebSocket connection should proceed.\n"
    "\n"
    " `on_close` function is called when WebSocket process is going to be stopped.\n"
).
-spec upgrade_websocket(
    gleam@http@request:request(ewe@internal@http1:connection()),
    fun((ewe@internal@stream@websocket:websocket_connection(), gleam@erlang@process:selector(PPE)) -> {PPG,
        gleam@erlang@process:selector(PPE)}),
    fun((ewe@internal@stream@websocket:websocket_connection(), PPG, websocket_message(PPE)) -> websocket_next(PPG, PPE)),
    fun((ewe@internal@stream@websocket:websocket_connection(), PPG) -> nil)
) -> gleam@http@response:response(response_body()).
upgrade_websocket(Req, On_init, Handler, On_close) ->
    Handler@1 = fun(Conn, State, Msg) ->
        _pipe = transform_websocket_message(Msg),
        _pipe@1 = gleam@result:map(
            _pipe,
            fun(_capture) -> Handler(Conn, State, _capture) end
        ),
        _pipe@2 = gleam@result:unwrap(_pipe@1, websocket_continue(State)),
        to_internal_websocket_next(_pipe@2)
    end,
    Transport = erlang:element(2, erlang:element(4, Req)),
    Socket = erlang:element(3, erlang:element(4, Req)),
    case ewe@internal@http1:upgrade_websocket(Req, Transport, Socket) of
        {ok, {Extensions, Per_message_deflate}} ->
            Started = begin
                _pipe@3 = gleam@otp@factory_supervisor:get_by_name(
                    erlang:element(5, erlang:element(4, Req))
                ),
                gleam@otp@factory_supervisor:start_child(
                    _pipe@3,
                    fun() ->
                        ewe@internal@stream@websocket:start(
                            Transport,
                            Socket,
                            On_init,
                            Handler@1,
                            On_close,
                            Extensions,
                            Per_message_deflate
                        )
                    end
                )
            end,
            case Started of
                {ok, {started, Pid, _}} ->
                    _ = glisten@transport:controlling_process(
                        Transport,
                        Socket,
                        Pid
                    ),
                    _pipe@4 = gleam@http@response:new(200),
                    gleam@http@response:set_body(_pipe@4, websocket);

                {error, _} ->
                    _pipe@5 = gleam@http@response:new(500),
                    gleam@http@response:set_body(_pipe@5, empty)
            end;

        {error, _} ->
            _pipe@6 = gleam@http@response:new(400),
            gleam@http@response:set_body(_pipe@6, empty)
    end.

-file("src/ewe.gleam", 859).
?DOC(" Sends a binary frame to the websocket client.\n").
-spec send_binary_frame(
    ewe@internal@stream@websocket:websocket_connection(),
    bitstring()
) -> {ok, nil} | {error, glisten@socket:socket_reason()}.
send_binary_frame(Conn, Bits) ->
    _pipe = fun websocks:encode_binary_frame/3,
    ewe@internal@stream@websocket:send_frame(
        _pipe,
        erlang:element(2, Conn),
        erlang:element(3, Conn),
        erlang:element(4, Conn),
        Bits
    ).

-file("src/ewe.gleam", 868).
?DOC(" Sends a text frame to the websocket client.\n").
-spec send_text_frame(
    ewe@internal@stream@websocket:websocket_connection(),
    binary()
) -> {ok, nil} | {error, glisten@socket:socket_reason()}.
send_text_frame(Conn, Text) ->
    ewe@internal@stream@websocket:send_frame(
        fun websocks:encode_text_frame/3,
        erlang:element(2, Conn),
        erlang:element(3, Conn),
        erlang:element(4, Conn),
        gleam_stdlib:identity(Text)
    ).

-file("src/ewe.gleam", 914).
-spec to_internal_close_code(close_code()) -> websocks:close_reason().
to_internal_close_code(Code) ->
    case Code of
        {normal_closure, Data} ->
            {normal_closure, gleam_stdlib:identity(Data)};

        {invalid_payload_data, Data@1} ->
            {invalid_payload_data, gleam_stdlib:identity(Data@1)};

        {policy_violation, Data@2} ->
            {policy_violation, gleam_stdlib:identity(Data@2)};

        {message_too_big, Data@3} ->
            {message_too_big, gleam_stdlib:identity(Data@3)};

        {internal_error, Data@4} ->
            {internal_error, gleam_stdlib:identity(Data@4)};

        {service_restart, Data@5} ->
            {service_restart, gleam_stdlib:identity(Data@5)};

        {try_again_later, Data@6} ->
            {try_again_later, gleam_stdlib:identity(Data@6)};

        {bad_gateway, Data@7} ->
            {bad_gateway, gleam_stdlib:identity(Data@7)};

        {custom_close_code, Code@1, Data@8} ->
            {custom_close_code, Code@1, gleam_stdlib:identity(Data@8)};

        no_close_reason ->
            no_close_reason
    end.

-file("src/ewe.gleam", 935).
?DOC(
    " Sends a close frame to the websocket client. Once this function is called,\n"
    " no other frames can be sent on this connection. Returns how the WebSocket\n"
    " connection should proceed - make sure your handler returns this value.\n"
).
-spec send_close_frame(
    ewe@internal@stream@websocket:websocket_connection(),
    close_code()
) -> websocket_next(any(), any()).
send_close_frame(Conn, Code) ->
    _pipe = to_internal_close_code(Code),
    _pipe@1 = ewe@internal@stream@websocket:send_close_frame(
        erlang:element(2, Conn),
        erlang:element(3, Conn),
        _pipe
    ),
    to_websocket_next(_pipe@1).

-file("src/ewe.gleam", 964).
?DOC(" Instructs Server-Sent Events connection to continue processing.\n").
-spec sse_continue(PPT) -> s_s_e_next(PPT).
sse_continue(User_state) ->
    {s_s_e_continue, User_state}.

-file("src/ewe.gleam", 969).
?DOC(" Instructs Server-Sent Events connection to stop.\n").
-spec sse_stop() -> s_s_e_next(any()).
sse_stop() ->
    s_s_e_normal_stop.

-file("src/ewe.gleam", 974).
?DOC(" Instructs Server-Sent Events connection to stop with abnormal reason.\n").
-spec sse_stop_abnormal(binary()) -> s_s_e_next(any()).
sse_stop_abnormal(Reason) ->
    {s_s_e_abnormal_stop, Reason}.

-file("src/ewe.gleam", 1005).
?DOC(" Sets the name of the event.\n").
-spec event_name(ewe@internal@stream@sse:s_s_e_event(), binary()) -> ewe@internal@stream@sse:s_s_e_event().
event_name(Event, Name) ->
    {s_s_e_event,
        {some, Name},
        erlang:element(3, Event),
        erlang:element(4, Event),
        erlang:element(5, Event)}.

-file("src/ewe.gleam", 1010).
?DOC(" Sets the ID of the event.\n").
-spec event_id(ewe@internal@stream@sse:s_s_e_event(), binary()) -> ewe@internal@stream@sse:s_s_e_event().
event_id(Event, Id) ->
    {s_s_e_event,
        erlang:element(2, Event),
        erlang:element(3, Event),
        {some, Id},
        erlang:element(5, Event)}.

-file("src/ewe.gleam", 1015).
?DOC(" Sets the retry time of the event.\n").
-spec event_retry(ewe@internal@stream@sse:s_s_e_event(), integer()) -> ewe@internal@stream@sse:s_s_e_event().
event_retry(Event, Retry) ->
    {s_s_e_event,
        erlang:element(2, Event),
        erlang:element(3, Event),
        erlang:element(4, Event),
        {some, Retry}}.

-file("src/ewe.gleam", 1029).
?DOC(
    " Sets up the connection for Server-Sent Events.\n"
    "\n"
    " `on_init` function is called once process that handles SSE connection\n"
    " is initialized. The argument is subject that can be used to send messages\n"
    " to the client. It must return initial state.\n"
    "\n"
    " `handler` function is called for every subject's message received. It must\n"
    " return instruction on how SSE connection should proceed.\n"
    "\n"
    " `on_close` function is called when SSE process is going to be stopped.\n"
).
-spec sse(
    gleam@http@request:request(ewe@internal@http1:connection()),
    fun((gleam@erlang@process:subject(PQC)) -> PQE),
    fun((ewe@internal@stream@sse:s_s_e_connection(), PQE, PQC) -> s_s_e_next(PQE)),
    fun((ewe@internal@stream@sse:s_s_e_connection(), PQE) -> nil)
) -> gleam@http@response:response(response_body()).
sse(Req, On_init, Handler, On_close) ->
    Handler@1 = fun(Conn, State, Msg) -> _pipe = Handler(Conn, State, Msg),
        to_internal_sse_next(_pipe) end,
    Transport = erlang:element(2, erlang:element(4, Req)),
    Socket = erlang:element(3, erlang:element(4, Req)),
    case ewe@internal@stream@sse:send_response(Transport, Socket) of
        {ok, nil} ->
            Started = begin
                _pipe@1 = gleam@otp@factory_supervisor:get_by_name(
                    erlang:element(5, erlang:element(4, Req))
                ),
                gleam@otp@factory_supervisor:start_child(
                    _pipe@1,
                    fun() ->
                        ewe@internal@stream@sse:start(
                            Transport,
                            Socket,
                            On_init,
                            Handler@1,
                            On_close
                        )
                    end
                )
            end,
            case Started of
                {ok, {started, Pid, _}} ->
                    _ = glisten@transport:controlling_process(
                        Transport,
                        Socket,
                        Pid
                    ),
                    _pipe@2 = gleam@http@response:new(200),
                    gleam@http@response:set_body(_pipe@2, s_s_e);

                {error, _} ->
                    _pipe@3 = gleam@http@response:new(400),
                    gleam@http@response:set_body(_pipe@3, empty)
            end;

        {error, nil} ->
            _pipe@4 = gleam@http@response:new(400),
            gleam@http@response:set_body(_pipe@4, empty)
    end.

-file("src/ewe.gleam", 978).
-spec to_internal_sse_next(s_s_e_next(PPZ)) -> ewe@internal@stream@sse:s_s_e_next(PPZ).
to_internal_sse_next(Next) ->
    case Next of
        {s_s_e_continue, User_state} ->
            {continue, User_state};

        s_s_e_normal_stop ->
            normal_stop;

        {s_s_e_abnormal_stop, Reason} ->
            {abnormal_stop, Reason}
    end.

-file("src/ewe.gleam", 1000).
?DOC(
    " Creates a new SSE event with the given data. Use `ewe.event_name`,\n"
    " `ewe.event_id`, and `ewe.event_retry` to modify other fields of the event.\n"
).
-spec event(binary()) -> ewe@internal@stream@sse:s_s_e_event().
event(Data) ->
    {s_s_e_event, none, Data, none, none}.

-file("src/ewe.gleam", 1065).
?DOC(" Sends a Server-Sent Events event to the client.\n").
-spec send_event(
    ewe@internal@stream@sse:s_s_e_connection(),
    ewe@internal@stream@sse:s_s_e_event()
) -> {ok, nil} | {error, glisten@socket:socket_reason()}.
send_event(Conn, Event) ->
    ewe@internal@stream@sse:send_event(
        erlang:element(2, Conn),
        erlang:element(3, Conn),
        Event
    ).
