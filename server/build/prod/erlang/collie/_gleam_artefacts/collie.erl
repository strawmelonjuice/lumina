-module(collie).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/collie.gleam").
-export([continue/1, continue_with_selector/2, stop/0, stop_abnormal/1, initialised/1, selecting/2, socket_reason_to_string/1, close_reason_to_string/1, new/2, new_with_initialiser/2, with_connection_timeout/2, named/2, on_message/2, on_close/2, to_user_message/1, send_ping/2, send_text_frame/2, send_binary_frame/2, send_close_frame/2, start/1, supervised/1]).
-export_type([next/2, initialised/2, message/1, connection/0, socket_reason/0, close_reason/0, builder/3, websocket_state/2, websocket_message/1, select_record/0, resolve_state/2]).

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
    "     header: \"Builder\",\n"
    "     functions: [\n"
    "       \"new\",\n"
    "       \"new_with_initialiser\",\n"
    "       \"with_connection_timeout\",\n"
    "       \"named\",\n"
    "       \"on_message\",\n"
    "       \"on_close\"\n"
    "     ]\n"
    "   },\n"
    "   {\n"
    "     header: \"Initialiser\",\n"
    "     functions: [\"initialised\", \"selecting\"]\n"
    "   },\n"
    "   {\n"
    "     header: \"Client\",\n"
    "     functions: [\"start\", \"supervised\"]\n"
    "   },\n"
    "   {\n"
    "     header: \"Handler\",\n"
    "     functions: [\n"
    "       \"continue\",\n"
    "       \"continue_with_selector\",\n"
    "       \"stop\",\n"
    "       \"stop_abnormal\",\n"
    "       \"send_ping\",\n"
    "       \"send_text_frame\",\n"
    "       \"send_binary_frame\",\n"
    "       \"send_close_frame\"\n"
    "     ]\n"
    "   },\n"
    "   {\n"
    "     header: \"User messages\",\n"
    "     functions: [\"to_user_message\"]\n"
    "   },\n"
    "   {\n"
    "     header: \"To string\",\n"
    "     functions: [\"close_reason_to_string\", \"socket_reason_to_string\"]\n"
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

-opaque next(HMG, HMH) :: {continue,
        HMG,
        gleam@option:option(gleam@erlang@process:selector(HMH))} |
    normal_stop |
    {abnormal_stop, binary()}.

-opaque initialised(HMI, HMJ) :: {initialised,
        HMI,
        gleam@option:option(gleam@erlang@process:selector(HMJ))}.

-type message(HMK) :: {text, binary()} | {binary, bitstring()} | {user, HMK}.

-opaque connection() :: {connection,
        collie@internal@socket:transport(),
        collie@internal@socket:socket(),
        websocks:context()}.

-type socket_reason() :: closed |
    timeout |
    badarg |
    terminated |
    eaddrinuse |
    eaddrnotavail |
    eafnosupport |
    ealready |
    econnaborted |
    econnrefused |
    econnreset |
    edestaddrreq |
    ehostdown |
    ehostunreach |
    einprogress |
    eisconn |
    emsgsize |
    enetdown |
    enetunreach |
    enopkg |
    enoprotoopt |
    enotconn |
    enotty |
    enotsock |
    eproto |
    eprotonosupport |
    eprototype |
    esocktnosupport |
    etimedout |
    ewouldblock |
    exbadport |
    exbadseq.

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

-opaque builder(HML, HMM, HMN) :: {builder,
        gleam@http@request:request(HML),
        gleam@option:option(gleam@erlang@process:name(websocket_message(HMN))),
        integer(),
        fun((gleam@erlang@process:subject(websocket_message(HMN))) -> {ok,
                initialised(HMM, HMN)} |
            {error, binary()}),
        fun((connection(), HMM, message(HMN)) -> next(HMM, HMN)),
        fun((HMM, close_reason()) -> nil)}.

-type websocket_state(HMO, HMP) :: {websocket_state,
        connection(),
        HMO,
        websocks:context(),
        fun((connection(), HMO, message(HMP)) -> next(HMO, HMP)),
        fun((HMO, close_reason()) -> nil)}.

-opaque websocket_message(HMQ) :: {packet, bitstring()} |
    {user_message, HMQ} |
    passive |
    {socket_error, collie@internal@socket:socket_reason()} |
    close.

-type select_record() :: tcp |
    ssl |
    tcp_closed |
    ssl_closed |
    tcp_passive |
    ssl_passive |
    tcp_error |
    ssl_error.

-type resolve_state(HMR, HMS) :: {resolve_state,
        connection(),
        fun((connection(), HMR, message(HMS)) -> next(HMR, HMS)),
        next(HMR, HMS),
        gleam@option:option(close_reason())}.

-file("src/collie.gleam", 131).
?DOC(" Instructs WebSocket connection to continue processing.\n").
-spec continue(HMT) -> next(HMT, any()).
continue(State) ->
    {continue, State, none}.

-file("src/collie.gleam", 138).
?DOC(
    " Instructs WebSocket connection to continue processing, with selector for\n"
    " custom messages. New selector replaces any existing one that was previously\n"
    " given.\n"
).
-spec continue_with_selector(HMX, gleam@erlang@process:selector(HMY)) -> next(HMX, HMY).
continue_with_selector(State, Selector) ->
    {continue, State, {some, Selector}}.

-file("src/collie.gleam", 146).
?DOC(" Instructs WebSocket connection to stop.\n").
-spec stop() -> next(any(), any()).
stop() ->
    normal_stop.

-file("src/collie.gleam", 151).
?DOC(" Instructs WebSocket connection to stop with abnormal reason.\n").
-spec stop_abnormal(binary()) -> next(any(), any()).
stop_abnormal(Reason) ->
    {abnormal_stop, Reason}.

-file("src/collie.gleam", 165).
?DOC(
    " Takes the post-initialisation state. This state will be passed to the\n"
    " `on_message` callback each time the message is received.\n"
).
-spec initialised(HNK) -> initialised(HNK, any()).
initialised(State) ->
    {initialised, State, none}.

-file("src/collie.gleam", 170).
?DOC(" Adds a selector to receive messages with.\n").
-spec selecting(initialised(HNO, any()), gleam@erlang@process:selector(HNS)) -> initialised(HNO, HNS).
selecting(Initialised, Selector) ->
    {initialised, erlang:element(2, Initialised), {some, Selector}}.

-file("src/collie.gleam", 265).
-spec to_socket_reason(collie@internal@socket:socket_reason()) -> socket_reason().
to_socket_reason(Reason) ->
    case Reason of
        closed ->
            closed;

        timeout ->
            timeout;

        badarg ->
            badarg;

        terminated ->
            terminated;

        eaddrinuse ->
            eaddrinuse;

        eaddrnotavail ->
            eaddrnotavail;

        eafnosupport ->
            eafnosupport;

        ealready ->
            ealready;

        econnaborted ->
            econnaborted;

        econnrefused ->
            econnrefused;

        econnreset ->
            econnreset;

        edestaddrreq ->
            edestaddrreq;

        ehostdown ->
            ehostdown;

        ehostunreach ->
            ehostunreach;

        einprogress ->
            einprogress;

        eisconn ->
            eisconn;

        emsgsize ->
            emsgsize;

        enetdown ->
            enetdown;

        enetunreach ->
            enetunreach;

        enopkg ->
            enopkg;

        enoprotoopt ->
            enoprotoopt;

        enotconn ->
            enotconn;

        enotty ->
            enotty;

        enotsock ->
            enotsock;

        eproto ->
            eproto;

        eprotonosupport ->
            eprotonosupport;

        eprototype ->
            eprototype;

        esocktnosupport ->
            esocktnosupport;

        etimedout ->
            etimedout;

        ewouldblock ->
            ewouldblock;

        exbadport ->
            exbadport;

        exbadseq ->
            exbadseq
    end.

-file("src/collie.gleam", 303).
?DOC(" Converts a socket error to a human-readable string.\n").
-spec socket_reason_to_string(socket_reason()) -> binary().
socket_reason_to_string(Reason) ->
    case Reason of
        closed ->
            <<"connection closed"/utf8>>;

        timeout ->
            <<"operation timed out"/utf8>>;

        badarg ->
            <<"bad argument"/utf8>>;

        terminated ->
            <<"process terminated"/utf8>>;

        eaddrinuse ->
            <<"address already in use"/utf8>>;

        eaddrnotavail ->
            <<"address not available"/utf8>>;

        eafnosupport ->
            <<"address family not supported"/utf8>>;

        ealready ->
            <<"operation already in progress"/utf8>>;

        econnaborted ->
            <<"connection aborted"/utf8>>;

        econnrefused ->
            <<"connection refused"/utf8>>;

        econnreset ->
            <<"connection reset by peer"/utf8>>;

        edestaddrreq ->
            <<"destination address required"/utf8>>;

        ehostdown ->
            <<"host is down"/utf8>>;

        ehostunreach ->
            <<"host is unreachable"/utf8>>;

        einprogress ->
            <<"operation in progress"/utf8>>;

        eisconn ->
            <<"already connected"/utf8>>;

        emsgsize ->
            <<"message too long"/utf8>>;

        enetdown ->
            <<"network is down"/utf8>>;

        enetunreach ->
            <<"network is unreachable"/utf8>>;

        enopkg ->
            <<"package not installed"/utf8>>;

        enoprotoopt ->
            <<"protocol not available"/utf8>>;

        enotconn ->
            <<"not connected"/utf8>>;

        enotty ->
            <<"inappropriate ioctl for device"/utf8>>;

        enotsock ->
            <<"not a socket"/utf8>>;

        eproto ->
            <<"protocol error"/utf8>>;

        eprotonosupport ->
            <<"protocol not supported"/utf8>>;

        eprototype ->
            <<"wrong protocol type for socket"/utf8>>;

        esocktnosupport ->
            <<"socket type not supported"/utf8>>;

        etimedout ->
            <<"connection timed out"/utf8>>;

        ewouldblock ->
            <<"operation would block"/utf8>>;

        exbadport ->
            <<"bad port"/utf8>>;

        exbadseq ->
            <<"bad sequence"/utf8>>
    end.

-file("src/collie.gleam", 377).
-spec to_close_reason(websocks:close_reason()) -> close_reason().
to_close_reason(Reason) ->
    case Reason of
        {normal_closure, Data} ->
            {normal_closure, Data};

        {going_away, Data@1} ->
            {going_away, Data@1};

        {protocol_error, Data@2} ->
            {protocol_error, Data@2};

        {unsupported_data, Data@3} ->
            {unsupported_data, Data@3};

        {invalid_payload_data, Data@4} ->
            {invalid_payload_data, Data@4};

        {policy_violation, Data@5} ->
            {policy_violation, Data@5};

        {message_too_big, Data@6} ->
            {message_too_big, Data@6};

        {mandatory_extension, Data@7} ->
            {mandatory_extension, Data@7};

        {internal_error, Data@8} ->
            {internal_error, Data@8};

        {service_restart, Data@9} ->
            {service_restart, Data@9};

        {try_again_later, Data@10} ->
            {try_again_later, Data@10};

        {bad_gateway, Data@11} ->
            {bad_gateway, Data@11};

        {t_l_s_handshake, Data@12} ->
            {t_l_s_handshake, Data@12};

        {custom_close_code, Code, Data@13} ->
            {custom_close_code, Code, Data@13};

        no_close_reason ->
            no_close_reason
    end.

-file("src/collie.gleam", 397).
-spec to_internal_close_reason(close_reason()) -> websocks:close_reason().
to_internal_close_reason(Reason) ->
    case Reason of
        {normal_closure, Data} ->
            {normal_closure, Data};

        {going_away, Data@1} ->
            {going_away, Data@1};

        {protocol_error, Data@2} ->
            {protocol_error, Data@2};

        {unsupported_data, Data@3} ->
            {unsupported_data, Data@3};

        {invalid_payload_data, Data@4} ->
            {invalid_payload_data, Data@4};

        {policy_violation, Data@5} ->
            {policy_violation, Data@5};

        {message_too_big, Data@6} ->
            {message_too_big, Data@6};

        {mandatory_extension, Data@7} ->
            {mandatory_extension, Data@7};

        {internal_error, Data@8} ->
            {internal_error, Data@8};

        {service_restart, Data@9} ->
            {service_restart, Data@9};

        {try_again_later, Data@10} ->
            {try_again_later, Data@10};

        {bad_gateway, Data@11} ->
            {bad_gateway, Data@11};

        {t_l_s_handshake, Data@12} ->
            {t_l_s_handshake, Data@12};

        {custom_close_code, Code, Data@13} ->
            {custom_close_code, Code, Data@13};

        no_close_reason ->
            no_close_reason
    end.

-file("src/collie.gleam", 418).
?DOC(" Converts a close reason to a human-readable string.\n").
-spec close_reason_to_string(close_reason()) -> binary().
close_reason_to_string(Reason) ->
    case Reason of
        {normal_closure, _} ->
            <<"normal closure"/utf8>>;

        {going_away, _} ->
            <<"going away"/utf8>>;

        {protocol_error, _} ->
            <<"protocol error"/utf8>>;

        {unsupported_data, _} ->
            <<"unsupported data"/utf8>>;

        {invalid_payload_data, _} ->
            <<"invalid payload data"/utf8>>;

        {policy_violation, _} ->
            <<"policy violation"/utf8>>;

        {message_too_big, _} ->
            <<"message too big"/utf8>>;

        {mandatory_extension, _} ->
            <<"mandatory extension"/utf8>>;

        {internal_error, _} ->
            <<"internal error"/utf8>>;

        {service_restart, _} ->
            <<"service restart"/utf8>>;

        {try_again_later, _} ->
            <<"try again later"/utf8>>;

        {bad_gateway, _} ->
            <<"bad gateway"/utf8>>;

        {t_l_s_handshake, _} ->
            <<"TLS handshake failure"/utf8>>;

        {custom_close_code, Code, _} ->
            <<"custom close code "/utf8,
                (erlang:integer_to_binary(Code))/binary>>;

        no_close_reason ->
            <<"no close reason"/utf8>>
    end.

-file("src/collie.gleam", 456).
?DOC(
    " Creates a new builder to set up WebSocket client with default configuration\n"
    " without a custom initialiser. Use `new_with_initialiser` to create a builder\n"
    " with some initialisation logic that runs before the client starts handling\n"
    " messages.\n"
).
-spec new(gleam@http@request:request(HNW), HNY) -> builder(HNW, HNY, any()).
new(Request, State) ->
    {builder,
        Request,
        none,
        5000,
        fun(_) -> {ok, initialised(State)} end,
        fun(_, State@1, _) -> continue(State@1) end,
        fun(_, _) -> nil end}.

-file("src/collie.gleam", 479).
?DOC(
    " Creates a new builder to set up WebSocket client with a custom initialiser\n"
    " that runs before the client starts handling messages.\n"
    "\n"
    " The actor's default subject is passed to the initialiser function. You can\n"
    " use it to send custom messages via `to_user_message` or ignore it\n"
    " completely.\n"
    "\n"
    " If a custom selector is given using the `selecting` function, this expands\n"
    " the default selector to handle custom messages.\n"
).
-spec new_with_initialiser(
    gleam@http@request:request(HOD),
    fun((gleam@erlang@process:subject(websocket_message(HOF))) -> {ok,
            initialised(HOI, HOF)} |
        {error, binary()})
) -> builder(HOD, HOI, HOF).
new_with_initialiser(Request, Initialise) ->
    {builder,
        Request,
        none,
        5000,
        Initialise,
        fun(_, State, _) -> continue(State) end,
        fun(_, _) -> nil end}.

-file("src/collie.gleam", 497).
?DOC(
    " Sets the maximum amount of time for the handshake to happen in milliseconds.\n"
    " The initialiser function also has `timeout + 1000` milliseconds to run.\n"
    " Default value is `5000`.\n"
).
-spec with_connection_timeout(builder(HOQ, HOR, HOS), integer()) -> builder(HOQ, HOR, HOS).
with_connection_timeout(Builder, Connection_timeout) ->
    {builder,
        erlang:element(2, Builder),
        erlang:element(3, Builder),
        Connection_timeout,
        erlang:element(5, Builder),
        erlang:element(6, Builder),
        erlang:element(7, Builder)}.

-file("src/collie.gleam", 506).
?DOC(
    " Provides a name for the client actor to be registered, enabling it to\n"
    " receive messages via a named subject.\n"
).
-spec named(
    builder(HOZ, HPA, HPB),
    gleam@erlang@process:name(websocket_message(HPB))
) -> builder(HOZ, HPA, HPB).
named(Builder, Name) ->
    {builder,
        erlang:element(2, Builder),
        {some, Name},
        erlang:element(4, Builder),
        erlang:element(5, Builder),
        erlang:element(6, Builder),
        erlang:element(7, Builder)}.

-file("src/collie.gleam", 516).
?DOC(
    " Sets the message handler for the client. The callback function will be\n"
    " called each time the client receives a message. It must return an\n"
    " instruction on how the WebSocket connection should proceed.\n"
).
-spec on_message(
    builder(HPK, HPL, HPM),
    fun((connection(), HPL, message(HPM)) -> next(HPL, HPM))
) -> builder(HPK, HPL, HPM).
on_message(Builder, Handler) ->
    {builder,
        erlang:element(2, Builder),
        erlang:element(3, Builder),
        erlang:element(4, Builder),
        erlang:element(5, Builder),
        Handler,
        erlang:element(7, Builder)}.

-file("src/collie.gleam", 525).
?DOC(
    " Sets the handler that is called when the connection is closed. The callback\n"
    " accepts the last value for the state and the closing reason.\n"
).
-spec on_close(builder(HPW, HPX, HPY), fun((HPX, close_reason()) -> nil)) -> builder(HPW, HPX, HPY).
on_close(Builder, On_close) ->
    {builder,
        erlang:element(2, Builder),
        erlang:element(3, Builder),
        erlang:element(4, Builder),
        erlang:element(5, Builder),
        erlang:element(6, Builder),
        On_close}.

-file("src/collie.gleam", 555).
?DOC(
    " Maps custom message to the `WebsocketMessage` opaque type, allowing to send\n"
    " custom messages to the client's process.\n"
).
-spec to_user_message(HQF) -> websocket_message(HQF).
to_user_message(Message) ->
    {user_message, Message}.

-file("src/collie.gleam", 559).
-spec create_socket_selector(
    gleam@erlang@process:subject(websocket_message(HQH)),
    gleam@option:option(gleam@erlang@process:selector(HQH))
) -> gleam@erlang@process:selector(websocket_message(HQH)).
create_socket_selector(Self, User) ->
    Selector = begin
        _pipe = gleam_erlang_ffi:new_selector(),
        _pipe@1 = gleam@erlang@process:select(_pipe, Self),
        _pipe@2 = gleam@erlang@process:select_record(
            _pipe@1,
            tcp,
            2,
            fun collie_ffi:coerce_socket_message/1
        ),
        _pipe@3 = gleam@erlang@process:select_record(
            _pipe@2,
            ssl,
            2,
            fun collie_ffi:coerce_socket_message/1
        ),
        _pipe@4 = gleam@erlang@process:select_record(
            _pipe@3,
            tcp_closed,
            1,
            fun collie_ffi:coerce_socket_message/1
        ),
        _pipe@5 = gleam@erlang@process:select_record(
            _pipe@4,
            ssl_closed,
            1,
            fun collie_ffi:coerce_socket_message/1
        ),
        _pipe@6 = gleam@erlang@process:select_record(
            _pipe@5,
            tcp_passive,
            1,
            fun collie_ffi:coerce_socket_message/1
        ),
        _pipe@7 = gleam@erlang@process:select_record(
            _pipe@6,
            ssl_passive,
            1,
            fun collie_ffi:coerce_socket_message/1
        ),
        _pipe@8 = gleam@erlang@process:select_record(
            _pipe@7,
            tcp_error,
            2,
            fun collie_ffi:coerce_socket_message/1
        ),
        gleam@erlang@process:select_record(
            _pipe@8,
            ssl_error,
            2,
            fun collie_ffi:coerce_socket_message/1
        )
    end,
    case User of
        {some, User@1} ->
            _pipe@9 = gleam_erlang_ffi:map_selector(
                User@1,
                fun(Field@0) -> {user_message, Field@0} end
            ),
            gleam_erlang_ffi:merge_selector(_pipe@9, Selector);

        none ->
            Selector
    end.

-file("src/collie.gleam", 735).
-spec unwrap_socket(
    {ok, HRS} | {error, collie@internal@socket:socket_reason()},
    fun((HRS) -> {ok, HRV} | {error, binary()})
) -> {ok, HRV} | {error, binary()}.
unwrap_socket(Result, Handle_return) ->
    case Result of
        {ok, Return} ->
            Handle_return(Return);

        {error, Reason} ->
            Message = <<"Websocket handshake failed due to socket: "/utf8,
                (collie@internal@socket:reason_to_string(Reason))/binary>>,
            logging:log(error, Message),
            {error, Message}
    end.

-file("src/collie.gleam", 679).
-spec handshake(
    gleam@http@request:request(any()),
    integer(),
    collie@internal@socket:transport(),
    fun(({gleam@http@response:response(bitstring()),
        collie@internal@socket:socket(),
        bitstring()}) -> {ok, HRN} | {error, binary()})
) -> {ok, HRN} | {error, binary()}.
handshake(Request, Connection_timeout, Transport, Handle_response) ->
    {Options, Default_port} = case Transport of
        ssl ->
            {[{cacerts, public_key:cacerts_get()},
                    {customize_hostname_check, collie_ffi:custom_sni_matcher()}],
                443};

        tcp ->
            {[], 80}
    end,
    unwrap_socket(
        collie@internal@socket:connect(
            Transport,
            unicode:characters_to_list(erlang:element(6, Request)),
            gleam@option:unwrap(erlang:element(7, Request), Default_port),
            lists:append(
                [{active_mode, passive},
                    {mode, binary},
                    {send_timeout, 30000},
                    {send_timeout_close, true},
                    {reuseaddr, true},
                    {nodelay, true}],
                Options
            ),
            Connection_timeout
        ),
        fun(Socket) ->
            Data = collie@internal@http:construct_upgrade(Request),
            unwrap_socket(
                collie@internal@socket:send(Transport, Socket, Data),
                fun(_) ->
                    case collie@internal@http:decode_response(
                        Transport,
                        Socket,
                        Connection_timeout
                    ) of
                        {ok, {Response, Remaining}} ->
                            case erlang:element(2, Response) of
                                101 ->
                                    Handle_response(
                                        {Response, Socket, Remaining}
                                    );

                                Status ->
                                    Message = <<"WebSocket handshake failed with status "/utf8,
                                        (erlang:integer_to_binary(Status))/binary>>,
                                    logging:log(error, Message),
                                    {error, Message}
                            end;

                        {error, {socket_failed, Reason}} ->
                            Message@1 = <<"WebSocket handshake failed due to socket: "/utf8,
                                (collie@internal@socket:reason_to_string(Reason))/binary>>,
                            logging:log(error, Message@1),
                            {error, Message@1};

                        {error, malformed_request} ->
                            Message@2 = <<"WebSocket handshake failed due to malformed request"/utf8>>,
                            logging:log(error, Message@2),
                            {error, Message@2}
                    end
                end
            )
        end
    ).

-file("src/collie.gleam", 801).
-spec new_resolve_state(websocket_state(HSK, HSL)) -> resolve_state(HSK, HSL).
new_resolve_state(State) ->
    {resolve_state,
        erlang:element(2, State),
        erlang:element(5, State),
        {continue, erlang:element(3, State), none},
        none}.

-file("src/collie.gleam", 890).
-spec handle_close(
    websocket_state(any(), any()),
    close_reason(),
    gleam@option:option(binary())
) -> gleam@otp@actor:next(any(), any()).
handle_close(State, Reason, Abnormal) ->
    Stop = case Abnormal of
        {some, Reason@1} ->
            logging:log(
                warning,
                <<"Closing connection abnormally: "/utf8, Reason@1/binary>>
            ),
            gleam@otp@actor:stop_abnormal(Reason@1);

        none ->
            logging:log(
                debug,
                <<"Closing connection: "/utf8,
                    (close_reason_to_string(Reason))/binary>>
            ),
            gleam@otp@actor:stop()
    end,
    websocks:close_context(erlang:element(4, State)),
    (erlang:element(6, State))(erlang:element(3, State), Reason),
    Stop.

-file("src/collie.gleam", 864).
-spec resolve_next(resolve_state(HSY, HSZ), websocket_state(HSY, HSZ)) -> gleam@otp@actor:next(websocket_state(HSY, HSZ), websocket_message(HSZ)).
resolve_next(Resolved, State) ->
    case erlang:element(4, Resolved) of
        {continue, User, Selector} ->
            Next = gleam@otp@actor:continue(
                {websocket_state,
                    erlang:element(2, State),
                    User,
                    erlang:element(4, State),
                    erlang:element(5, State),
                    erlang:element(6, State)}
            ),
            case Selector of
                {some, Selector@1} ->
                    _pipe = gleam_erlang_ffi:map_selector(
                        Selector@1,
                        fun(Field@0) -> {user_message, Field@0} end
                    ),
                    gleam@otp@actor:with_selector(Next, _pipe);

                none ->
                    Next
            end;

        normal_stop ->
            Reason = gleam@option:unwrap(
                erlang:element(5, Resolved),
                no_close_reason
            ),
            handle_close(State, Reason, none);

        {abnormal_stop, Reason_string} ->
            Reason@1 = gleam@option:unwrap(
                erlang:element(5, Resolved),
                {internal_error, <<Reason_string/binary>>}
            ),
            handle_close(State, Reason@1, {some, Reason_string})
    end.

-file("src/collie.gleam", 995).
-spec call_handler(resolve_state(HTW, HTX), message(HTX)) -> websocks:resolve_next(resolve_state(HTW, HTX)).
call_handler(State, Message) ->
    {User_state@1, Selector@1} = case erlang:element(4, State) of
        {continue, User_state, Selector} -> {User_state, Selector};
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"collie"/utf8>>,
                        function => <<"call_handler"/utf8>>,
                        line => 999,
                        value => _assert_fail,
                        start => 32232,
                        'end' => 32286,
                        pattern_start => 32243,
                        pattern_end => 32273})
    end,
    Call = exception_ffi:rescue(
        fun() ->
            (erlang:element(3, State))(
                erlang:element(2, State),
                User_state@1,
                Message
            )
        end
    ),
    case Call of
        {ok, {continue, User_state@2, New_selector}} ->
            Selector@2 = gleam@option:'or'(New_selector, Selector@1),
            _pipe = {resolve_state,
                erlang:element(2, State),
                erlang:element(3, State),
                {continue, User_state@2, Selector@2},
                erlang:element(5, State)},
            {continue, _pipe};

        {ok, normal_stop} ->
            {stop,
                {resolve_state,
                    erlang:element(2, State),
                    erlang:element(3, State),
                    normal_stop,
                    erlang:element(5, State)}};

        {ok, {abnormal_stop, Reason}} ->
            {stop,
                {resolve_state,
                    erlang:element(2, State),
                    erlang:element(3, State),
                    {abnormal_stop, Reason},
                    erlang:element(5, State)}};

        {error, Exception} ->
            Reason@1 = case Exception of
                {errored, _} ->
                    <<"An error was raised in the handler. This can be caused by calling the erlang:error/1 function, or some other runtime error."/utf8>>;

                {thrown, _} ->
                    <<"A value was thrown in the handler. This can be caused by calling the erlang:throw/1 function."/utf8>>;

                {exited, _} ->
                    <<"A process exited in the handler. This can be caused by calling the erlang:exit/1 function."/utf8>>
            end,
            logging:log(error, <<"Handler exception: "/utf8, Reason@1/binary>>),
            Next = {abnormal_stop, Reason@1},
            Reason@2 = {some, {internal_error, <<Reason@1/binary>>}},
            {stop,
                {resolve_state,
                    erlang:element(2, State),
                    erlang:element(3, State),
                    Next,
                    Reason@2}}
    end.

-file("src/collie.gleam", 915).
-spec handle_frame(
    resolve_state(HTP, HTQ),
    websocks:context(),
    websocks:frame()
) -> websocks:resolve_next(resolve_state(HTP, HTQ)).
handle_frame(State, Context, Frame) ->
    Conn = begin
        _record = erlang:element(2, State),
        {connection,
            erlang:element(2, _record),
            erlang:element(3, _record),
            Context}
    end,
    State@1 = {resolve_state,
        Conn,
        erlang:element(3, State),
        erlang:element(4, State),
        erlang:element(5, State)},
    case Frame of
        {control, {ping, Payload}} ->
            logging:log(debug, <<"Received ping frame"/utf8>>),
            case erlang:byte_size(Payload) of
                Size when Size > 125 ->
                    logging:log(
                        warning,
                        <<"Ping payload exceeds 125 bytes"/utf8>>
                    ),
                    Next = {abnormal_stop,
                        <<"control frame payload exceeds 125 octets"/utf8>>},
                    Reason = begin
                        _pipe = {protocol_error,
                            <<"control frame payload exceeds 125 octets"/utf8>>},
                        {some, _pipe}
                    end,
                    {stop,
                        {resolve_state,
                            erlang:element(2, State@1),
                            erlang:element(3, State@1),
                            Next,
                            Reason}};

                _ ->
                    Pong = begin
                        _pipe@1 = {some, crypto:strong_rand_bytes(4)},
                        _pipe@2 = websocks:encode_pong_frame(Payload, _pipe@1),
                        gleam@bytes_tree:from_bit_array(_pipe@2)
                    end,
                    case collie@internal@socket:send(
                        erlang:element(2, erlang:element(2, State@1)),
                        erlang:element(3, erlang:element(2, State@1)),
                        Pong
                    ) of
                        {ok, nil} ->
                            logging:log(debug, <<"Sent pong frame"/utf8>>),
                            {continue, State@1};

                        {error, Reason@1} ->
                            Reason@2 = <<"failed to send pong: "/utf8,
                                (collie@internal@socket:reason_to_string(
                                    Reason@1
                                ))/binary>>,
                            logging:log(error, Reason@2),
                            Next@1 = {abnormal_stop, Reason@2},
                            Reason@3 = {some,
                                {internal_error, <<Reason@2/binary>>}},
                            {stop,
                                {resolve_state,
                                    erlang:element(2, State@1),
                                    erlang:element(3, State@1),
                                    Next@1,
                                    Reason@3}}
                    end
            end;

        {control, {close, Reason@4}} ->
            logging:log(
                debug,
                <<"Received close frame: "/utf8,
                    (close_reason_to_string(to_close_reason(Reason@4)))/binary>>
            ),
            _ = begin
                _pipe@3 = {some, crypto:strong_rand_bytes(4)},
                _pipe@4 = websocks:encode_close_frame(Reason@4, _pipe@3),
                _pipe@5 = gleam@bytes_tree:from_bit_array(_pipe@4),
                collie@internal@socket:send(
                    erlang:element(2, erlang:element(2, State@1)),
                    erlang:element(3, erlang:element(2, State@1)),
                    _pipe@5
                )
            end,
            Reason@5 = {some, to_close_reason(Reason@4)},
            {stop,
                {resolve_state,
                    erlang:element(2, State@1),
                    erlang:element(3, State@1),
                    normal_stop,
                    Reason@5}};

        {control, {pong, _}} ->
            logging:log(debug, <<"Received pong frame"/utf8>>),
            {continue, State@1};

        {text, Payload@1} ->
            call_handler(State@1, {text, gleam_stdlib:identity(Payload@1)});

        {binary, Payload@2} ->
            call_handler(State@1, {binary, Payload@2});

        {continuation, _} ->
            {continue, State@1}
    end.

-file("src/collie.gleam", 810).
-spec handle_packet(bitstring(), websocket_state(HSP, HSQ)) -> gleam@otp@actor:next(websocket_state(HSP, HSQ), websocket_message(HSQ)).
handle_packet(Data, State) ->
    Processed = begin
        _pipe = new_resolve_state(State),
        websocks:process_incoming_frames(
            Data,
            erlang:element(4, State),
            _pipe,
            fun handle_frame/3
        )
    end,
    case Processed of
        {ok, {Resolved, Context}} ->
            Conn = begin
                _record = erlang:element(2, State),
                {connection,
                    erlang:element(2, _record),
                    erlang:element(3, _record),
                    Context}
            end,
            resolve_next(
                Resolved,
                {websocket_state,
                    Conn,
                    erlang:element(3, State),
                    Context,
                    erlang:element(5, State),
                    erlang:element(6, State)}
            );

        {error, Violation} ->
            {Variant, Reason} = case Violation of
                {decode_failed, invalid_frame} ->
                    {fun(Field@0) -> {protocol_error, Field@0} end,
                        <<"Malformed wire format"/utf8>>};

                {decode_failed, {not_enough_data, _}} ->
                    erlang:error(#{gleam_error => panic,
                            message => <<"Unreachable branch for `process_incoming_frames`!"/utf8>>,
                            file => <<?FILEPATH/utf8>>,
                            module => <<"collie"/utf8>>,
                            function => <<"handle_packet"/utf8>>,
                            line => 830});

                {resolve_failed, not_utf8} ->
                    {fun(Field@0) -> {invalid_payload_data, Field@0} end,
                        <<"Text frame payload isn't valid UTF-8"/utf8>>};

                {resolve_failed, orphaned_continuation} ->
                    {fun(Field@0) -> {protocol_error, Field@0} end,
                        <<"Continuation frame without a preceding fragmented start"/utf8>>};

                {resolve_failed, control_frame_fragmented} ->
                    {fun(Field@0) -> {protocol_error, Field@0} end,
                        <<"Control frame was fragmented"/utf8>>};

                {resolve_failed, fragmentation_interrupted} ->
                    {fun(Field@0) -> {protocol_error, Field@0} end,
                        <<"Complete text/binary frame received mid-fragmentation"/utf8>>};

                {resolve_failed, concurrent_fragmentation} ->
                    {fun(Field@0) -> {protocol_error, Field@0} end,
                        <<"New fragmented frame started while another is in progress"/utf8>>};

                {resolve_failed, compressed_continuation} ->
                    {fun(Field@0) -> {protocol_error, Field@0} end,
                        <<"Continuation frame has RSV1 set"/utf8>>}
            end,
            logging:log(warning, <<"Protocol violation: "/utf8, Reason/binary>>),
            handle_close(State, Variant(<<Reason/binary>>), {some, Reason})
    end.

-file("src/collie.gleam", 1031).
?DOC(" Sends a ping frame to the WebSocket server.\n").
-spec send_ping(connection(), bitstring()) -> {ok, nil} |
    {error, socket_reason()}.
send_ping(Conn, Data) ->
    _pipe = {some, crypto:strong_rand_bytes(4)},
    _pipe@1 = websocks:encode_ping_frame(Data, _pipe),
    _pipe@2 = gleam@bytes_tree:from_bit_array(_pipe@1),
    _pipe@3 = collie@internal@socket:send(
        erlang:element(2, Conn),
        erlang:element(3, Conn),
        _pipe@2
    ),
    gleam@result:map_error(_pipe@3, fun to_socket_reason/1).

-file("src/collie.gleam", 1040).
?DOC(" Sends a text frame to the WebSocket server.\n").
-spec send_text_frame(connection(), binary()) -> {ok, nil} |
    {error, socket_reason()}.
send_text_frame(Conn, Text) ->
    _pipe = {some, crypto:strong_rand_bytes(4)},
    _pipe@1 = websocks:encode_text_frame(
        <<Text/binary>>,
        erlang:element(4, Conn),
        _pipe
    ),
    _pipe@2 = gleam@bytes_tree:from_bit_array(_pipe@1),
    _pipe@3 = collie@internal@socket:send(
        erlang:element(2, Conn),
        erlang:element(3, Conn),
        _pipe@2
    ),
    gleam@result:map_error(_pipe@3, fun to_socket_reason/1).

-file("src/collie.gleam", 1052).
?DOC(" Sends a binary frame to the WebSocket server.\n").
-spec send_binary_frame(connection(), bitstring()) -> {ok, nil} |
    {error, socket_reason()}.
send_binary_frame(Conn, Bits) ->
    _pipe = {some, crypto:strong_rand_bytes(4)},
    _pipe@1 = websocks:encode_binary_frame(Bits, erlang:element(4, Conn), _pipe),
    _pipe@2 = gleam@bytes_tree:from_bit_array(_pipe@1),
    _pipe@3 = collie@internal@socket:send(
        erlang:element(2, Conn),
        erlang:element(3, Conn),
        _pipe@2
    ),
    gleam@result:map_error(_pipe@3, fun to_socket_reason/1).

-file("src/collie.gleam", 1066).
?DOC(
    " Sends a close frame to the websocket client. Once this function is called,\n"
    " no other frames can be sent on this connection. Returns how the WebSocket\n"
    " connection should proceed - make sure your handler returns this value.\n"
).
-spec send_close_frame(connection(), close_reason()) -> next(any(), any()).
send_close_frame(Conn, Reason) ->
    Sent = begin
        _pipe = to_internal_close_reason(Reason),
        _pipe@1 = websocks:encode_close_frame(
            _pipe,
            {some, crypto:strong_rand_bytes(4)}
        ),
        _pipe@2 = gleam@bytes_tree:from_bit_array(_pipe@1),
        collie@internal@socket:send(
            erlang:element(2, Conn),
            erlang:element(3, Conn),
            _pipe@2
        )
    end,
    case Sent of
        {ok, nil} ->
            normal_stop;

        {error, Reason@1} ->
            Reason@2 = collie@internal@socket:reason_to_string(Reason@1),
            {abnormal_stop,
                <<"Errored while trying to send close frame: "/utf8,
                    Reason@2/binary>>}
    end.

-file("src/collie.gleam", 751).
-spec handle_message(websocket_state(HSA, HSB), websocket_message(HSB)) -> gleam@otp@actor:next(websocket_state(HSA, HSB), websocket_message(HSB)).
handle_message(State, Message) ->
    case Message of
        {packet, Data} ->
            handle_packet(Data, State);

        {user_message, Message@1} ->
            logging:log(debug, <<"Received user message from selector"/utf8>>),
            Resolved = call_handler(new_resolve_state(State), {user, Message@1}),
            resolve_next(erlang:element(2, Resolved), State);

        passive ->
            Options = collie@internal@socket:set_opts(
                erlang:element(2, erlang:element(2, State)),
                erlang:element(3, erlang:element(2, State)),
                [{active_mode, {count, 100}}]
            ),
            case Options of
                {ok, nil} ->
                    gleam@otp@actor:continue(State);

                {error, Reason} ->
                    Reason@1 = collie@internal@socket:reason_to_string(Reason),
                    logging:log(
                        error,
                        <<"Failed to set socket options: "/utf8,
                            Reason@1/binary>>
                    ),
                    _pipe = {internal_error, gleam_stdlib:identity(Reason@1)},
                    handle_close(State, _pipe, {some, Reason@1})
            end;

        {socket_error, Reason@2} ->
            Reason@3 = collie@internal@socket:reason_to_string(Reason@2),
            logging:log(error, <<"Socket error: "/utf8, Reason@3/binary>>),
            _pipe@1 = {internal_error, gleam_stdlib:identity(Reason@3)},
            handle_close(State, _pipe@1, {some, Reason@3});

        close ->
            logging:log(debug, <<"Socket closed by remote peer"/utf8>>),
            handle_close(State, no_close_reason, none)
    end.

-file("src/collie.gleam", 600).
?DOC(" Starts the WebSocket connection with the provided configurations.\n").
-spec start(builder(any(), any(), HQS)) -> {ok,
        gleam@otp@actor:started(gleam@erlang@process:subject(websocket_message(HQS)))} |
    {error, gleam@otp@actor:start_error()}.
start(Builder) ->
    Transport = case erlang:element(5, erlang:element(2, Builder)) of
        https ->
            ssl;

        http ->
            tcp
    end,
    Actor = begin
        _pipe@7 = gleam@otp@actor:new_with_initialiser(
            erlang:element(4, Builder) + 1000,
            fun(Self) ->
                handshake(
                    erlang:element(2, Builder),
                    erlang:element(4, Builder),
                    Transport,
                    fun(_use0) ->
                        {Response, Socket, Remaining} = _use0,
                        logging:log(
                            debug,
                            <<"WebSocket handshake completed successfully"/utf8>>
                        ),
                        case Remaining of
                            <<>> ->
                                nil;

                            Remaining@1 ->
                                gleam@otp@actor:send(
                                    Self,
                                    {packet, Remaining@1}
                                )
                        end,
                        unwrap_socket(
                            collie@internal@socket:set_opts(
                                Transport,
                                Socket,
                                [{active_mode, {count, 100}}]
                            ),
                            fun(_) ->
                                Extensions = begin
                                    _pipe = gleam@http@response:get_header(
                                        Response,
                                        <<"sec-websocket-extensions"/utf8>>
                                    ),
                                    _pipe@1 = gleam@result:map(
                                        _pipe,
                                        fun(_capture) ->
                                            gleam@string:split(
                                                _capture,
                                                <<";"/utf8>>
                                            )
                                        end
                                    ),
                                    _pipe@2 = gleam@result:unwrap(_pipe@1, []),
                                    gleam@list:map(
                                        _pipe@2,
                                        fun gleam@string:trim/1
                                    )
                                end,
                                logging:log(
                                    debug,
                                    <<"Calling initialiser function"/utf8>>
                                ),
                                gleam@result:'try'(
                                    (erlang:element(5, Builder))(Self),
                                    fun(_use0@1) ->
                                        {initialised, State, Selector} = _use0@1,
                                        logging:log(
                                            debug,
                                            <<"Initialiser returned successfully"/utf8>>
                                        ),
                                        Compression = case websocks:has_deflate(
                                            Extensions
                                        ) of
                                            true ->
                                                logging:log(
                                                    debug,
                                                    <<"Using permessage-deflate for the WebSocket connection"/utf8>>
                                                ),
                                                {some,
                                                    websocks:get_compression_extensions(
                                                        Extensions
                                                    )};

                                            false ->
                                                none
                                        end,
                                        Context = websocks:create_context(
                                            Compression,
                                            client
                                        ),
                                        _pipe@3 = {websocket_state,
                                            {connection,
                                                Transport,
                                                Socket,
                                                Context},
                                            State,
                                            Context,
                                            erlang:element(6, Builder),
                                            erlang:element(7, Builder)},
                                        _pipe@4 = gleam@otp@actor:initialised(
                                            _pipe@3
                                        ),
                                        _pipe@5 = gleam@otp@actor:selecting(
                                            _pipe@4,
                                            create_socket_selector(
                                                Self,
                                                Selector
                                            )
                                        ),
                                        _pipe@6 = gleam@otp@actor:returning(
                                            _pipe@5,
                                            Self
                                        ),
                                        {ok, _pipe@6}
                                    end
                                )
                            end
                        )
                    end
                )
            end
        ),
        gleam@otp@actor:on_message(_pipe@7, fun handle_message/2)
    end,
    Actor@1 = case erlang:element(3, Builder) of
        {some, Name} ->
            gleam@otp@actor:named(Actor, Name);

        none ->
            Actor
    end,
    gleam@otp@actor:start(Actor@1).

-file("src/collie.gleam", 673).
?DOC(" Returns a child specification for use in a supervision tree.\n").
-spec supervised(builder(any(), any(), HRD)) -> gleam@otp@supervision:child_specification(gleam@erlang@process:subject(websocket_message(HRD))).
supervised(Builder) ->
    gleam@otp@supervision:supervisor(fun() -> start(Builder) end).
