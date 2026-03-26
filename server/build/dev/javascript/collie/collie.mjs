import * as $exception from "../exception/exception.mjs";
import * as $crypto from "../gleam_crypto/gleam/crypto.mjs";
import * as $charlist from "../gleam_erlang/gleam/erlang/charlist.mjs";
import * as $process from "../gleam_erlang/gleam/erlang/process.mjs";
import * as $http from "../gleam_http/gleam/http.mjs";
import * as $request from "../gleam_http/gleam/http/request.mjs";
import * as $response from "../gleam_http/gleam/http/response.mjs";
import * as $actor from "../gleam_otp/gleam/otp/actor.mjs";
import * as $supervision from "../gleam_otp/gleam/otp/supervision.mjs";
import * as $bit_array from "../gleam_stdlib/gleam/bit_array.mjs";
import * as $bytes_tree from "../gleam_stdlib/gleam/bytes_tree.mjs";
import * as $dynamic from "../gleam_stdlib/gleam/dynamic.mjs";
import * as $int from "../gleam_stdlib/gleam/int.mjs";
import * as $list from "../gleam_stdlib/gleam/list.mjs";
import * as $option from "../gleam_stdlib/gleam/option.mjs";
import * as $result from "../gleam_stdlib/gleam/result.mjs";
import * as $string from "../gleam_stdlib/gleam/string.mjs";
import * as $logging from "../logging/logging.mjs";
import * as $websocks from "../websocks/websocks.mjs";
import * as $http_ from "./collie/internal/http.mjs";
import * as $socket from "./collie/internal/socket.mjs";
import { Ok, toList, CustomType as $CustomType } from "./gleam.mjs";

class Continue extends $CustomType {
  constructor(state, selector) {
    super();
    this.state = state;
    this.selector = selector;
  }
}

class NormalStop extends $CustomType {}

class AbnormalStop extends $CustomType {
  constructor(reason) {
    super();
    this.reason = reason;
  }
}

class Initialised extends $CustomType {
  constructor(state, selector) {
    super();
    this.state = state;
    this.selector = selector;
  }
}

/**
 * Indicates that text frame has been received.
 */
export class Text extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Message$Text = ($0) => new Text($0);
export const Message$isText = (value) => value instanceof Text;
export const Message$Text$0 = (value) => value[0];

/**
 * Indicates that binary frame has been received.
 */
export class Binary extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Message$Binary = ($0) => new Binary($0);
export const Message$isBinary = (value) => value instanceof Binary;
export const Message$Binary$0 = (value) => value[0];

/**
 * Indicates that user message has been received from WebSocket selector.
 */
export class User extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Message$User = ($0) => new User($0);
export const Message$isUser = (value) => value instanceof User;
export const Message$User$0 = (value) => value[0];

class Connection extends $CustomType {
  constructor(transport, socket, context) {
    super();
    this.transport = transport;
    this.socket = socket;
    this.context = context;
  }
}

export class Closed extends $CustomType {}
export const SocketReason$Closed = () => new Closed();
export const SocketReason$isClosed = (value) => value instanceof Closed;

export class Timeout extends $CustomType {}
export const SocketReason$Timeout = () => new Timeout();
export const SocketReason$isTimeout = (value) => value instanceof Timeout;

export class Badarg extends $CustomType {}
export const SocketReason$Badarg = () => new Badarg();
export const SocketReason$isBadarg = (value) => value instanceof Badarg;

export class Terminated extends $CustomType {}
export const SocketReason$Terminated = () => new Terminated();
export const SocketReason$isTerminated = (value) => value instanceof Terminated;

export class Eaddrinuse extends $CustomType {}
export const SocketReason$Eaddrinuse = () => new Eaddrinuse();
export const SocketReason$isEaddrinuse = (value) => value instanceof Eaddrinuse;

export class Eaddrnotavail extends $CustomType {}
export const SocketReason$Eaddrnotavail = () => new Eaddrnotavail();
export const SocketReason$isEaddrnotavail = (value) =>
  value instanceof Eaddrnotavail;

export class Eafnosupport extends $CustomType {}
export const SocketReason$Eafnosupport = () => new Eafnosupport();
export const SocketReason$isEafnosupport = (value) =>
  value instanceof Eafnosupport;

export class Ealready extends $CustomType {}
export const SocketReason$Ealready = () => new Ealready();
export const SocketReason$isEalready = (value) => value instanceof Ealready;

export class Econnaborted extends $CustomType {}
export const SocketReason$Econnaborted = () => new Econnaborted();
export const SocketReason$isEconnaborted = (value) =>
  value instanceof Econnaborted;

export class Econnrefused extends $CustomType {}
export const SocketReason$Econnrefused = () => new Econnrefused();
export const SocketReason$isEconnrefused = (value) =>
  value instanceof Econnrefused;

export class Econnreset extends $CustomType {}
export const SocketReason$Econnreset = () => new Econnreset();
export const SocketReason$isEconnreset = (value) => value instanceof Econnreset;

export class Edestaddrreq extends $CustomType {}
export const SocketReason$Edestaddrreq = () => new Edestaddrreq();
export const SocketReason$isEdestaddrreq = (value) =>
  value instanceof Edestaddrreq;

export class Ehostdown extends $CustomType {}
export const SocketReason$Ehostdown = () => new Ehostdown();
export const SocketReason$isEhostdown = (value) => value instanceof Ehostdown;

export class Ehostunreach extends $CustomType {}
export const SocketReason$Ehostunreach = () => new Ehostunreach();
export const SocketReason$isEhostunreach = (value) =>
  value instanceof Ehostunreach;

export class Einprogress extends $CustomType {}
export const SocketReason$Einprogress = () => new Einprogress();
export const SocketReason$isEinprogress = (value) =>
  value instanceof Einprogress;

export class Eisconn extends $CustomType {}
export const SocketReason$Eisconn = () => new Eisconn();
export const SocketReason$isEisconn = (value) => value instanceof Eisconn;

export class Emsgsize extends $CustomType {}
export const SocketReason$Emsgsize = () => new Emsgsize();
export const SocketReason$isEmsgsize = (value) => value instanceof Emsgsize;

export class Enetdown extends $CustomType {}
export const SocketReason$Enetdown = () => new Enetdown();
export const SocketReason$isEnetdown = (value) => value instanceof Enetdown;

export class Enetunreach extends $CustomType {}
export const SocketReason$Enetunreach = () => new Enetunreach();
export const SocketReason$isEnetunreach = (value) =>
  value instanceof Enetunreach;

export class Enopkg extends $CustomType {}
export const SocketReason$Enopkg = () => new Enopkg();
export const SocketReason$isEnopkg = (value) => value instanceof Enopkg;

export class Enoprotoopt extends $CustomType {}
export const SocketReason$Enoprotoopt = () => new Enoprotoopt();
export const SocketReason$isEnoprotoopt = (value) =>
  value instanceof Enoprotoopt;

export class Enotconn extends $CustomType {}
export const SocketReason$Enotconn = () => new Enotconn();
export const SocketReason$isEnotconn = (value) => value instanceof Enotconn;

export class Enotty extends $CustomType {}
export const SocketReason$Enotty = () => new Enotty();
export const SocketReason$isEnotty = (value) => value instanceof Enotty;

export class Enotsock extends $CustomType {}
export const SocketReason$Enotsock = () => new Enotsock();
export const SocketReason$isEnotsock = (value) => value instanceof Enotsock;

export class Eproto extends $CustomType {}
export const SocketReason$Eproto = () => new Eproto();
export const SocketReason$isEproto = (value) => value instanceof Eproto;

export class Eprotonosupport extends $CustomType {}
export const SocketReason$Eprotonosupport = () => new Eprotonosupport();
export const SocketReason$isEprotonosupport = (value) =>
  value instanceof Eprotonosupport;

export class Eprototype extends $CustomType {}
export const SocketReason$Eprototype = () => new Eprototype();
export const SocketReason$isEprototype = (value) => value instanceof Eprototype;

export class Esocktnosupport extends $CustomType {}
export const SocketReason$Esocktnosupport = () => new Esocktnosupport();
export const SocketReason$isEsocktnosupport = (value) =>
  value instanceof Esocktnosupport;

export class Etimedout extends $CustomType {}
export const SocketReason$Etimedout = () => new Etimedout();
export const SocketReason$isEtimedout = (value) => value instanceof Etimedout;

export class Ewouldblock extends $CustomType {}
export const SocketReason$Ewouldblock = () => new Ewouldblock();
export const SocketReason$isEwouldblock = (value) =>
  value instanceof Ewouldblock;

export class Exbadport extends $CustomType {}
export const SocketReason$Exbadport = () => new Exbadport();
export const SocketReason$isExbadport = (value) => value instanceof Exbadport;

export class Exbadseq extends $CustomType {}
export const SocketReason$Exbadseq = () => new Exbadseq();
export const SocketReason$isExbadseq = (value) => value instanceof Exbadseq;

/**
 * The connection successfully completed its purpose and is closing normally.
 */
export class NormalClosure extends $CustomType {
  constructor(data) {
    super();
    this.data = data;
  }
}
export const CloseReason$NormalClosure = (data) => new NormalClosure(data);
export const CloseReason$isNormalClosure = (value) =>
  value instanceof NormalClosure;
export const CloseReason$NormalClosure$data = (value) => value.data;
export const CloseReason$NormalClosure$0 = (value) => value.data;

/**
 * The endpoint is going away, either due to server shutdown or browser
 * navigation.
 */
export class GoingAway extends $CustomType {
  constructor(data) {
    super();
    this.data = data;
  }
}
export const CloseReason$GoingAway = (data) => new GoingAway(data);
export const CloseReason$isGoingAway = (value) => value instanceof GoingAway;
export const CloseReason$GoingAway$data = (value) => value.data;
export const CloseReason$GoingAway$0 = (value) => value.data;

/**
 * A WebSocket protocol violation was detected.
 */
export class ProtocolError extends $CustomType {
  constructor(data) {
    super();
    this.data = data;
  }
}
export const CloseReason$ProtocolError = (data) => new ProtocolError(data);
export const CloseReason$isProtocolError = (value) =>
  value instanceof ProtocolError;
export const CloseReason$ProtocolError$data = (value) => value.data;
export const CloseReason$ProtocolError$0 = (value) => value.data;

/**
 * The endpoint received data it cannot accept.
 */
export class UnsupportedData extends $CustomType {
  constructor(data) {
    super();
    this.data = data;
  }
}
export const CloseReason$UnsupportedData = (data) => new UnsupportedData(data);
export const CloseReason$isUnsupportedData = (value) =>
  value instanceof UnsupportedData;
export const CloseReason$UnsupportedData$data = (value) => value.data;
export const CloseReason$UnsupportedData$0 = (value) => value.data;

/**
 * The message data doesn’t match the declared type.
 */
export class InvalidPayloadData extends $CustomType {
  constructor(data) {
    super();
    this.data = data;
  }
}
export const CloseReason$InvalidPayloadData = (data) =>
  new InvalidPayloadData(data);
export const CloseReason$isInvalidPayloadData = (value) =>
  value instanceof InvalidPayloadData;
export const CloseReason$InvalidPayloadData$data = (value) => value.data;
export const CloseReason$InvalidPayloadData$0 = (value) => value.data;

/**
 * Generic status for policy violations when no other code applies.
 */
export class PolicyViolation extends $CustomType {
  constructor(data) {
    super();
    this.data = data;
  }
}
export const CloseReason$PolicyViolation = (data) => new PolicyViolation(data);
export const CloseReason$isPolicyViolation = (value) =>
  value instanceof PolicyViolation;
export const CloseReason$PolicyViolation$data = (value) => value.data;
export const CloseReason$PolicyViolation$0 = (value) => value.data;

/**
 * Message exceeds the maximum size the endpoint can handle.
 */
export class MessageTooBig extends $CustomType {
  constructor(data) {
    super();
    this.data = data;
  }
}
export const CloseReason$MessageTooBig = (data) => new MessageTooBig(data);
export const CloseReason$isMessageTooBig = (value) =>
  value instanceof MessageTooBig;
export const CloseReason$MessageTooBig$data = (value) => value.data;
export const CloseReason$MessageTooBig$0 = (value) => value.data;

/**
 * The server encountered an unexpected condition preventing request
 * fulfillment.
 */
export class MandatoryExtension extends $CustomType {
  constructor(data) {
    super();
    this.data = data;
  }
}
export const CloseReason$MandatoryExtension = (data) =>
  new MandatoryExtension(data);
export const CloseReason$isMandatoryExtension = (value) =>
  value instanceof MandatoryExtension;
export const CloseReason$MandatoryExtension$data = (value) => value.data;
export const CloseReason$MandatoryExtension$0 = (value) => value.data;

/**
 * The server encountered an unexpected error.
 */
export class InternalError extends $CustomType {
  constructor(data) {
    super();
    this.data = data;
  }
}
export const CloseReason$InternalError = (data) => new InternalError(data);
export const CloseReason$isInternalError = (value) =>
  value instanceof InternalError;
export const CloseReason$InternalError$data = (value) => value.data;
export const CloseReason$InternalError$0 = (value) => value.data;

/**
 * Server is restarting.
 */
export class ServiceRestart extends $CustomType {
  constructor(data) {
    super();
    this.data = data;
  }
}
export const CloseReason$ServiceRestart = (data) => new ServiceRestart(data);
export const CloseReason$isServiceRestart = (value) =>
  value instanceof ServiceRestart;
export const CloseReason$ServiceRestart$data = (value) => value.data;
export const CloseReason$ServiceRestart$0 = (value) => value.data;

/**
 * Temporary server overload.
 */
export class TryAgainLater extends $CustomType {
  constructor(data) {
    super();
    this.data = data;
  }
}
export const CloseReason$TryAgainLater = (data) => new TryAgainLater(data);
export const CloseReason$isTryAgainLater = (value) =>
  value instanceof TryAgainLater;
export const CloseReason$TryAgainLater$data = (value) => value.data;
export const CloseReason$TryAgainLater$0 = (value) => value.data;

/**
 * Gateway/proxy received invalid response.
 */
export class BadGateway extends $CustomType {
  constructor(data) {
    super();
    this.data = data;
  }
}
export const CloseReason$BadGateway = (data) => new BadGateway(data);
export const CloseReason$isBadGateway = (value) => value instanceof BadGateway;
export const CloseReason$BadGateway$data = (value) => value.data;
export const CloseReason$BadGateway$0 = (value) => value.data;

/**
 * TLS/SSL handshake failure.
 */
export class TLSHandshake extends $CustomType {
  constructor(data) {
    super();
    this.data = data;
  }
}
export const CloseReason$TLSHandshake = (data) => new TLSHandshake(data);
export const CloseReason$isTLSHandshake = (value) =>
  value instanceof TLSHandshake;
export const CloseReason$TLSHandshake$data = (value) => value.data;
export const CloseReason$TLSHandshake$0 = (value) => value.data;

/**
 * Custom close codes for application-specific use cases.
 */
export class CustomCloseCode extends $CustomType {
  constructor(code, data) {
    super();
    this.code = code;
    this.data = data;
  }
}
export const CloseReason$CustomCloseCode = (code, data) =>
  new CustomCloseCode(code, data);
export const CloseReason$isCustomCloseCode = (value) =>
  value instanceof CustomCloseCode;
export const CloseReason$CustomCloseCode$code = (value) => value.code;
export const CloseReason$CustomCloseCode$0 = (value) => value.code;
export const CloseReason$CustomCloseCode$data = (value) => value.data;
export const CloseReason$CustomCloseCode$1 = (value) => value.data;

export class NoCloseReason extends $CustomType {}
export const CloseReason$NoCloseReason = () => new NoCloseReason();
export const CloseReason$isNoCloseReason = (value) =>
  value instanceof NoCloseReason;

class Builder extends $CustomType {
  constructor(request, named, connection_timeout, initialise, handler, on_close) {
    super();
    this.request = request;
    this.named = named;
    this.connection_timeout = connection_timeout;
    this.initialise = initialise;
    this.handler = handler;
    this.on_close = on_close;
  }
}

class WebsocketState extends $CustomType {
  constructor(conn, user, context, handler, on_close) {
    super();
    this.conn = conn;
    this.user = user;
    this.context = context;
    this.handler = handler;
    this.on_close = on_close;
  }
}

class Packet extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}

class UserMessage extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}

class Passive extends $CustomType {}

class SocketError extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}

class Close extends $CustomType {}

class Tcp extends $CustomType {}

class Ssl extends $CustomType {}

class TcpClosed extends $CustomType {}

class SslClosed extends $CustomType {}

class TcpPassive extends $CustomType {}

class SslPassive extends $CustomType {}

class TcpError extends $CustomType {}

class SslError extends $CustomType {}

class ResolveState extends $CustomType {
  constructor(conn, handler, next, reason) {
    super();
    this.conn = conn;
    this.handler = handler;
    this.next = next;
    this.reason = reason;
  }
}

const socket_mode = /* @__PURE__ */ toList([
  /* @__PURE__ */ new $socket.ActiveMode(/* @__PURE__ */ new $socket.Count(100)),
]);

/**
 * Instructs WebSocket connection to continue processing.
 */
export function continue$(state) {
  return new Continue(state, new $option.None());
}

/**
 * Instructs WebSocket connection to continue processing, with selector for
 * custom messages. New selector replaces any existing one that was previously
 * given.
 */
export function continue_with_selector(state, selector) {
  return new Continue(state, new $option.Some(selector));
}

/**
 * Instructs WebSocket connection to stop.
 */
export function stop() {
  return new NormalStop();
}

/**
 * Instructs WebSocket connection to stop with abnormal reason.
 */
export function stop_abnormal(reason) {
  return new AbnormalStop(reason);
}

/**
 * Takes the post-initialisation state. This state will be passed to the
 * `on_message` callback each time the message is received.
 */
export function initialised(state) {
  return new Initialised(state, new $option.None());
}

/**
 * Adds a selector to receive messages with.
 */
export function selecting(initialised, selector) {
  return new Initialised(initialised.state, new $option.Some(selector));
}

function to_socket_reason(reason) {
  if (reason instanceof $socket.Closed) {
    return new Closed();
  } else if (reason instanceof $socket.Timeout) {
    return new Timeout();
  } else if (reason instanceof $socket.Badarg) {
    return new Badarg();
  } else if (reason instanceof $socket.Terminated) {
    return new Terminated();
  } else if (reason instanceof $socket.Eaddrinuse) {
    return new Eaddrinuse();
  } else if (reason instanceof $socket.Eaddrnotavail) {
    return new Eaddrnotavail();
  } else if (reason instanceof $socket.Eafnosupport) {
    return new Eafnosupport();
  } else if (reason instanceof $socket.Ealready) {
    return new Ealready();
  } else if (reason instanceof $socket.Econnaborted) {
    return new Econnaborted();
  } else if (reason instanceof $socket.Econnrefused) {
    return new Econnrefused();
  } else if (reason instanceof $socket.Econnreset) {
    return new Econnreset();
  } else if (reason instanceof $socket.Edestaddrreq) {
    return new Edestaddrreq();
  } else if (reason instanceof $socket.Ehostdown) {
    return new Ehostdown();
  } else if (reason instanceof $socket.Ehostunreach) {
    return new Ehostunreach();
  } else if (reason instanceof $socket.Einprogress) {
    return new Einprogress();
  } else if (reason instanceof $socket.Eisconn) {
    return new Eisconn();
  } else if (reason instanceof $socket.Emsgsize) {
    return new Emsgsize();
  } else if (reason instanceof $socket.Enetdown) {
    return new Enetdown();
  } else if (reason instanceof $socket.Enetunreach) {
    return new Enetunreach();
  } else if (reason instanceof $socket.Enopkg) {
    return new Enopkg();
  } else if (reason instanceof $socket.Enoprotoopt) {
    return new Enoprotoopt();
  } else if (reason instanceof $socket.Enotconn) {
    return new Enotconn();
  } else if (reason instanceof $socket.Enotty) {
    return new Enotty();
  } else if (reason instanceof $socket.Enotsock) {
    return new Enotsock();
  } else if (reason instanceof $socket.Eproto) {
    return new Eproto();
  } else if (reason instanceof $socket.Eprotonosupport) {
    return new Eprotonosupport();
  } else if (reason instanceof $socket.Eprototype) {
    return new Eprototype();
  } else if (reason instanceof $socket.Esocktnosupport) {
    return new Esocktnosupport();
  } else if (reason instanceof $socket.Etimedout) {
    return new Etimedout();
  } else if (reason instanceof $socket.Ewouldblock) {
    return new Ewouldblock();
  } else if (reason instanceof $socket.Exbadport) {
    return new Exbadport();
  } else {
    return new Exbadseq();
  }
}

/**
 * Converts a socket error to a human-readable string.
 */
export function socket_reason_to_string(reason) {
  if (reason instanceof Closed) {
    return "connection closed";
  } else if (reason instanceof Timeout) {
    return "operation timed out";
  } else if (reason instanceof Badarg) {
    return "bad argument";
  } else if (reason instanceof Terminated) {
    return "process terminated";
  } else if (reason instanceof Eaddrinuse) {
    return "address already in use";
  } else if (reason instanceof Eaddrnotavail) {
    return "address not available";
  } else if (reason instanceof Eafnosupport) {
    return "address family not supported";
  } else if (reason instanceof Ealready) {
    return "operation already in progress";
  } else if (reason instanceof Econnaborted) {
    return "connection aborted";
  } else if (reason instanceof Econnrefused) {
    return "connection refused";
  } else if (reason instanceof Econnreset) {
    return "connection reset by peer";
  } else if (reason instanceof Edestaddrreq) {
    return "destination address required";
  } else if (reason instanceof Ehostdown) {
    return "host is down";
  } else if (reason instanceof Ehostunreach) {
    return "host is unreachable";
  } else if (reason instanceof Einprogress) {
    return "operation in progress";
  } else if (reason instanceof Eisconn) {
    return "already connected";
  } else if (reason instanceof Emsgsize) {
    return "message too long";
  } else if (reason instanceof Enetdown) {
    return "network is down";
  } else if (reason instanceof Enetunreach) {
    return "network is unreachable";
  } else if (reason instanceof Enopkg) {
    return "package not installed";
  } else if (reason instanceof Enoprotoopt) {
    return "protocol not available";
  } else if (reason instanceof Enotconn) {
    return "not connected";
  } else if (reason instanceof Enotty) {
    return "inappropriate ioctl for device";
  } else if (reason instanceof Enotsock) {
    return "not a socket";
  } else if (reason instanceof Eproto) {
    return "protocol error";
  } else if (reason instanceof Eprotonosupport) {
    return "protocol not supported";
  } else if (reason instanceof Eprototype) {
    return "wrong protocol type for socket";
  } else if (reason instanceof Esocktnosupport) {
    return "socket type not supported";
  } else if (reason instanceof Etimedout) {
    return "connection timed out";
  } else if (reason instanceof Ewouldblock) {
    return "operation would block";
  } else if (reason instanceof Exbadport) {
    return "bad port";
  } else {
    return "bad sequence";
  }
}

function to_close_reason(reason) {
  if (reason instanceof $websocks.NormalClosure) {
    let data = reason.data;
    return new NormalClosure(data);
  } else if (reason instanceof $websocks.GoingAway) {
    let data = reason.data;
    return new GoingAway(data);
  } else if (reason instanceof $websocks.ProtocolError) {
    let data = reason.data;
    return new ProtocolError(data);
  } else if (reason instanceof $websocks.UnsupportedData) {
    let data = reason.data;
    return new UnsupportedData(data);
  } else if (reason instanceof $websocks.InvalidPayloadData) {
    let data = reason.data;
    return new InvalidPayloadData(data);
  } else if (reason instanceof $websocks.PolicyViolation) {
    let data = reason.data;
    return new PolicyViolation(data);
  } else if (reason instanceof $websocks.MessageTooBig) {
    let data = reason.data;
    return new MessageTooBig(data);
  } else if (reason instanceof $websocks.MandatoryExtension) {
    let data = reason.data;
    return new MandatoryExtension(data);
  } else if (reason instanceof $websocks.InternalError) {
    let data = reason.data;
    return new InternalError(data);
  } else if (reason instanceof $websocks.ServiceRestart) {
    let data = reason.data;
    return new ServiceRestart(data);
  } else if (reason instanceof $websocks.TryAgainLater) {
    let data = reason.data;
    return new TryAgainLater(data);
  } else if (reason instanceof $websocks.BadGateway) {
    let data = reason.data;
    return new BadGateway(data);
  } else if (reason instanceof $websocks.TLSHandshake) {
    let data = reason.data;
    return new TLSHandshake(data);
  } else if (reason instanceof $websocks.CustomCloseCode) {
    let code = reason.code;
    let data = reason.data;
    return new CustomCloseCode(code, data);
  } else {
    return new NoCloseReason();
  }
}

function to_internal_close_reason(reason) {
  if (reason instanceof NormalClosure) {
    let data = reason.data;
    return new $websocks.NormalClosure(data);
  } else if (reason instanceof GoingAway) {
    let data = reason.data;
    return new $websocks.GoingAway(data);
  } else if (reason instanceof ProtocolError) {
    let data = reason.data;
    return new $websocks.ProtocolError(data);
  } else if (reason instanceof UnsupportedData) {
    let data = reason.data;
    return new $websocks.UnsupportedData(data);
  } else if (reason instanceof InvalidPayloadData) {
    let data = reason.data;
    return new $websocks.InvalidPayloadData(data);
  } else if (reason instanceof PolicyViolation) {
    let data = reason.data;
    return new $websocks.PolicyViolation(data);
  } else if (reason instanceof MessageTooBig) {
    let data = reason.data;
    return new $websocks.MessageTooBig(data);
  } else if (reason instanceof MandatoryExtension) {
    let data = reason.data;
    return new $websocks.MandatoryExtension(data);
  } else if (reason instanceof InternalError) {
    let data = reason.data;
    return new $websocks.InternalError(data);
  } else if (reason instanceof ServiceRestart) {
    let data = reason.data;
    return new $websocks.ServiceRestart(data);
  } else if (reason instanceof TryAgainLater) {
    let data = reason.data;
    return new $websocks.TryAgainLater(data);
  } else if (reason instanceof BadGateway) {
    let data = reason.data;
    return new $websocks.BadGateway(data);
  } else if (reason instanceof TLSHandshake) {
    let data = reason.data;
    return new $websocks.TLSHandshake(data);
  } else if (reason instanceof CustomCloseCode) {
    let code = reason.code;
    let data = reason.data;
    return new $websocks.CustomCloseCode(code, data);
  } else {
    return new $websocks.NoCloseReason();
  }
}

/**
 * Converts a close reason to a human-readable string.
 */
export function close_reason_to_string(reason) {
  if (reason instanceof NormalClosure) {
    return "normal closure";
  } else if (reason instanceof GoingAway) {
    return "going away";
  } else if (reason instanceof ProtocolError) {
    return "protocol error";
  } else if (reason instanceof UnsupportedData) {
    return "unsupported data";
  } else if (reason instanceof InvalidPayloadData) {
    return "invalid payload data";
  } else if (reason instanceof PolicyViolation) {
    return "policy violation";
  } else if (reason instanceof MessageTooBig) {
    return "message too big";
  } else if (reason instanceof MandatoryExtension) {
    return "mandatory extension";
  } else if (reason instanceof InternalError) {
    return "internal error";
  } else if (reason instanceof ServiceRestart) {
    return "service restart";
  } else if (reason instanceof TryAgainLater) {
    return "try again later";
  } else if (reason instanceof BadGateway) {
    return "bad gateway";
  } else if (reason instanceof TLSHandshake) {
    return "TLS handshake failure";
  } else if (reason instanceof CustomCloseCode) {
    let code = reason.code;
    return "custom close code " + $int.to_string(code);
  } else {
    return "no close reason";
  }
}

/**
 * Creates a new builder to set up WebSocket client with default configuration
 * without a custom initialiser. Use `new_with_initialiser` to create a builder
 * with some initialisation logic that runs before the client starts handling
 * messages.
 */
export function new$(request, state) {
  return new Builder(
    request,
    new $option.None(),
    5000,
    (_) => { return new Ok(initialised(state)); },
    (_, state, _1) => { return continue$(state); },
    (_, _1) => { return undefined; },
  );
}

/**
 * Creates a new builder to set up WebSocket client with a custom initialiser
 * that runs before the client starts handling messages.
 *
 * The actor's default subject is passed to the initialiser function. You can
 * use it to send custom messages via `to_user_message` or ignore it
 * completely.
 *
 * If a custom selector is given using the `selecting` function, this expands
 * the default selector to handle custom messages.
 */
export function new_with_initialiser(request, initialise) {
  return new Builder(
    request,
    new $option.None(),
    5000,
    initialise,
    (_, state, _1) => { return continue$(state); },
    (_, _1) => { return undefined; },
  );
}

/**
 * Sets the maximum amount of time for the handshake to happen in milliseconds.
 * The initialiser function also has `timeout + 1000` milliseconds to run.
 * Default value is `5000`.
 */
export function with_connection_timeout(builder, connection_timeout) {
  return new Builder(
    builder.request,
    builder.named,
    connection_timeout,
    builder.initialise,
    builder.handler,
    builder.on_close,
  );
}

/**
 * Provides a name for the client actor to be registered, enabling it to
 * receive messages via a named subject.
 */
export function named(builder, name) {
  return new Builder(
    builder.request,
    new $option.Some(name),
    builder.connection_timeout,
    builder.initialise,
    builder.handler,
    builder.on_close,
  );
}

/**
 * Sets the message handler for the client. The callback function will be
 * called each time the client receives a message. It must return an
 * instruction on how the WebSocket connection should proceed.
 */
export function on_message(builder, handler) {
  return new Builder(
    builder.request,
    builder.named,
    builder.connection_timeout,
    builder.initialise,
    handler,
    builder.on_close,
  );
}

/**
 * Sets the handler that is called when the connection is closed. The callback
 * accepts the last value for the state and the closing reason.
 */
export function on_close(builder, on_close) {
  return new Builder(
    builder.request,
    builder.named,
    builder.connection_timeout,
    builder.initialise,
    builder.handler,
    on_close,
  );
}

/**
 * Maps custom message to the `WebsocketMessage` opaque type, allowing to send
 * custom messages to the client's process.
 */
export function to_user_message(message) {
  return new UserMessage(message);
}

function new_resolve_state(state) {
  return new ResolveState(
    state.conn,
    state.handler,
    new Continue(state.user, new $option.None()),
    new $option.None(),
  );
}
