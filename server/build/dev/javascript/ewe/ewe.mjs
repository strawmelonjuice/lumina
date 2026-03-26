import * as $process from "../gleam_erlang/gleam/erlang/process.mjs";
import * as $http from "../gleam_http/gleam/http.mjs";
import * as $request from "../gleam_http/gleam/http/request.mjs";
import * as $response from "../gleam_http/gleam/http/response.mjs";
import * as $actor from "../gleam_otp/gleam/otp/actor.mjs";
import * as $factory from "../gleam_otp/gleam/otp/factory_supervisor.mjs";
import * as $supervisor from "../gleam_otp/gleam/otp/static_supervisor.mjs";
import * as $supervision from "../gleam_otp/gleam/otp/supervision.mjs";
import * as $bit_array from "../gleam_stdlib/gleam/bit_array.mjs";
import * as $bytes_tree from "../gleam_stdlib/gleam/bytes_tree.mjs";
import * as $dynamic from "../gleam_stdlib/gleam/dynamic.mjs";
import * as $int from "../gleam_stdlib/gleam/int.mjs";
import * as $io from "../gleam_stdlib/gleam/io.mjs";
import * as $option from "../gleam_stdlib/gleam/option.mjs";
import { None, Some } from "../gleam_stdlib/gleam/option.mjs";
import * as $result from "../gleam_stdlib/gleam/result.mjs";
import * as $string_tree from "../gleam_stdlib/gleam/string_tree.mjs";
import * as $glisten from "../glisten/glisten.mjs";
import * as $listener from "../glisten/glisten/internal/listener.mjs";
import * as $glisten_options from "../glisten/glisten/socket/options.mjs";
import * as $transport from "../glisten/glisten/transport.mjs";
import * as $websocks from "../websocks/websocks.mjs";
import * as $file from "./ewe/internal/file.mjs";
import * as $handler from "./ewe/internal/handler.mjs";
import * as $ewe_http from "./ewe/internal/http1.mjs";
import * as $chunked from "./ewe/internal/stream/chunked.mjs";
import * as $sse from "./ewe/internal/stream/sse.mjs";
import * as $websocket from "./ewe/internal/stream/websocket.mjs";
import { Ok, Error, CustomType as $CustomType } from "./gleam.mjs";

export class IpV4 extends $CustomType {
  constructor($0, $1, $2, $3) {
    super();
    this[0] = $0;
    this[1] = $1;
    this[2] = $2;
    this[3] = $3;
  }
}
export const IpAddress$IpV4 = ($0, $1, $2, $3) => new IpV4($0, $1, $2, $3);
export const IpAddress$isIpV4 = (value) => value instanceof IpV4;
export const IpAddress$IpV4$0 = (value) => value[0];
export const IpAddress$IpV4$1 = (value) => value[1];
export const IpAddress$IpV4$2 = (value) => value[2];
export const IpAddress$IpV4$3 = (value) => value[3];

export class IpV6 extends $CustomType {
  constructor($0, $1, $2, $3, $4, $5, $6, $7) {
    super();
    this[0] = $0;
    this[1] = $1;
    this[2] = $2;
    this[3] = $3;
    this[4] = $4;
    this[5] = $5;
    this[6] = $6;
    this[7] = $7;
  }
}
export const IpAddress$IpV6 = ($0, $1, $2, $3, $4, $5, $6, $7) =>
  new IpV6($0, $1, $2, $3, $4, $5, $6, $7);
export const IpAddress$isIpV6 = (value) => value instanceof IpV6;
export const IpAddress$IpV6$0 = (value) => value[0];
export const IpAddress$IpV6$1 = (value) => value[1];
export const IpAddress$IpV6$2 = (value) => value[2];
export const IpAddress$IpV6$3 = (value) => value[3];
export const IpAddress$IpV6$4 = (value) => value[4];
export const IpAddress$IpV6$5 = (value) => value[5];
export const IpAddress$IpV6$6 = (value) => value[6];
export const IpAddress$IpV6$7 = (value) => value[7];

export class SocketAddress extends $CustomType {
  constructor(ip, port) {
    super();
    this.ip = ip;
    this.port = port;
  }
}
export const SocketAddress$SocketAddress = (ip, port) =>
  new SocketAddress(ip, port);
export const SocketAddress$isSocketAddress = (value) =>
  value instanceof SocketAddress;
export const SocketAddress$SocketAddress$ip = (value) => value.ip;
export const SocketAddress$SocketAddress$0 = (value) => value.ip;
export const SocketAddress$SocketAddress$port = (value) => value.port;
export const SocketAddress$SocketAddress$1 = (value) => value.port;

/**
 * Allows to set response body from a string.
 */
export class TextData extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const ResponseBody$TextData = ($0) => new TextData($0);
export const ResponseBody$isTextData = (value) => value instanceof TextData;
export const ResponseBody$TextData$0 = (value) => value[0];

/**
 * Allows to set response body from bytes.
 */
export class BytesData extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const ResponseBody$BytesData = ($0) => new BytesData($0);
export const ResponseBody$isBytesData = (value) => value instanceof BytesData;
export const ResponseBody$BytesData$0 = (value) => value[0];

/**
 * Allows to set response body from bits.
 */
export class BitsData extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const ResponseBody$BitsData = ($0) => new BitsData($0);
export const ResponseBody$isBitsData = (value) => value instanceof BitsData;
export const ResponseBody$BitsData$0 = (value) => value[0];

/**
 * Allows to set response body from a string tree.
 */
export class StringTreeData extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const ResponseBody$StringTreeData = ($0) => new StringTreeData($0);
export const ResponseBody$isStringTreeData = (value) =>
  value instanceof StringTreeData;
export const ResponseBody$StringTreeData$0 = (value) => value[0];

export class Empty extends $CustomType {}
export const ResponseBody$Empty = () => new Empty();
export const ResponseBody$isEmpty = (value) => value instanceof Empty;

/**
 * Allows to set response body from a file more efficiently rather than
 * sending contents in regular data types.
 */
export class File extends $CustomType {
  constructor(descriptor, offset, size) {
    super();
    this.descriptor = descriptor;
    this.offset = offset;
    this.size = size;
  }
}
export const ResponseBody$File = (descriptor, offset, size) =>
  new File(descriptor, offset, size);
export const ResponseBody$isFile = (value) => value instanceof File;
export const ResponseBody$File$descriptor = (value) => value.descriptor;
export const ResponseBody$File$0 = (value) => value.descriptor;
export const ResponseBody$File$offset = (value) => value.offset;
export const ResponseBody$File$1 = (value) => value.offset;
export const ResponseBody$File$size = (value) => value.size;
export const ResponseBody$File$2 = (value) => value.size;

export class Chunked extends $CustomType {}
export const ResponseBody$Chunked = () => new Chunked();
export const ResponseBody$isChunked = (value) => value instanceof Chunked;

export class Websocket extends $CustomType {}
export const ResponseBody$Websocket = () => new Websocket();
export const ResponseBody$isWebsocket = (value) => value instanceof Websocket;

export class SSE extends $CustomType {}
export const ResponseBody$SSE = () => new SSE();
export const ResponseBody$isSSE = (value) => value instanceof SSE;

export class NoEntry extends $CustomType {}
export const FileError$NoEntry = () => new NoEntry();
export const FileError$isNoEntry = (value) => value instanceof NoEntry;

export class NoAccess extends $CustomType {}
export const FileError$NoAccess = () => new NoAccess();
export const FileError$isNoAccess = (value) => value instanceof NoAccess;

export class IsDirectory extends $CustomType {}
export const FileError$IsDirectory = () => new IsDirectory();
export const FileError$isIsDirectory = (value) => value instanceof IsDirectory;

/**
 * Untypical file error.
 */
export class UnknownFileError extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const FileError$UnknownFileError = ($0) => new UnknownFileError($0);
export const FileError$isUnknownFileError = (value) =>
  value instanceof UnknownFileError;
export const FileError$UnknownFileError$0 = (value) => value[0];

class Builder extends $CustomType {
  constructor(handler, port, interface$, ipv6, tls, on_start, on_crash, listener_name, idle_timeout) {
    super();
    this.handler = handler;
    this.port = port;
    this.interface = interface$;
    this.ipv6 = ipv6;
    this.tls = tls;
    this.on_start = on_start;
    this.on_crash = on_crash;
    this.listener_name = listener_name;
    this.idle_timeout = idle_timeout;
  }
}

export class BodyTooLarge extends $CustomType {}
export const BodyError$BodyTooLarge = () => new BodyTooLarge();
export const BodyError$isBodyTooLarge = (value) =>
  value instanceof BodyTooLarge;

export class InvalidBody extends $CustomType {}
export const BodyError$InvalidBody = () => new InvalidBody();
export const BodyError$isInvalidBody = (value) => value instanceof InvalidBody;

/**
 * Chunk of data has been consumed.
 */
export class Consumed extends $CustomType {
  constructor(data, next) {
    super();
    this.data = data;
    this.next = next;
  }
}
export const Stream$Consumed = (data, next) => new Consumed(data, next);
export const Stream$isConsumed = (value) => value instanceof Consumed;
export const Stream$Consumed$data = (value) => value.data;
export const Stream$Consumed$0 = (value) => value.data;
export const Stream$Consumed$next = (value) => value.next;
export const Stream$Consumed$1 = (value) => value.next;

export class Done extends $CustomType {}
export const Stream$Done = () => new Done();
export const Stream$isDone = (value) => value instanceof Done;

class ChunkedContinue extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}

class ChunkedStop extends $CustomType {}

class ChunkedAbnormalStop extends $CustomType {
  constructor(reason) {
    super();
    this.reason = reason;
  }
}

class WebsocketContinue extends $CustomType {
  constructor($0, $1) {
    super();
    this[0] = $0;
    this[1] = $1;
  }
}

class WebsocketNormalStop extends $CustomType {}

class WebsocketAbnormalStop extends $CustomType {
  constructor(reason) {
    super();
    this.reason = reason;
  }
}

/**
 * Indicate that text frame has been received.
 */
export class Text extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const WebsocketMessage$Text = ($0) => new Text($0);
export const WebsocketMessage$isText = (value) => value instanceof Text;
export const WebsocketMessage$Text$0 = (value) => value[0];

/**
 * Indicate that binary frame has been received.
 */
export class Binary extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const WebsocketMessage$Binary = ($0) => new Binary($0);
export const WebsocketMessage$isBinary = (value) => value instanceof Binary;
export const WebsocketMessage$Binary$0 = (value) => value[0];

/**
 * Indicate that user message has been received from WebSocket selector.
 */
export class User extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const WebsocketMessage$User = ($0) => new User($0);
export const WebsocketMessage$isUser = (value) => value instanceof User;
export const WebsocketMessage$User$0 = (value) => value[0];

/**
 * Standard graceful shutdown (1000). Use when connection completed
 * successfully.
 */
export class NormalClosure extends $CustomType {
  constructor(data) {
    super();
    this.data = data;
  }
}
export const CloseCode$NormalClosure = (data) => new NormalClosure(data);
export const CloseCode$isNormalClosure = (value) =>
  value instanceof NormalClosure;
export const CloseCode$NormalClosure$data = (value) => value.data;
export const CloseCode$NormalClosure$0 = (value) => value.data;

/**
 * Invalid message format (1007). Received payload that doesn't match what
 * you expected.
 */
export class InvalidPayloadData extends $CustomType {
  constructor(data) {
    super();
    this.data = data;
  }
}
export const CloseCode$InvalidPayloadData = (data) =>
  new InvalidPayloadData(data);
export const CloseCode$isInvalidPayloadData = (value) =>
  value instanceof InvalidPayloadData;
export const CloseCode$InvalidPayloadData$data = (value) => value.data;
export const CloseCode$InvalidPayloadData$0 = (value) => value.data;

/**
 * Application policy violation (1008).Client broke your rules - failed
 * authentication, hit rate limits, or violated business logic.
 */
export class PolicyViolation extends $CustomType {
  constructor(data) {
    super();
    this.data = data;
  }
}
export const CloseCode$PolicyViolation = (data) => new PolicyViolation(data);
export const CloseCode$isPolicyViolation = (value) =>
  value instanceof PolicyViolation;
export const CloseCode$PolicyViolation$data = (value) => value.data;
export const CloseCode$PolicyViolation$0 = (value) => value.data;

/**
 * Message exceeds size limits (1009). Client sent something bigger than
 * your application allows.
 */
export class MessageTooBig extends $CustomType {
  constructor(data) {
    super();
    this.data = data;
  }
}
export const CloseCode$MessageTooBig = (data) => new MessageTooBig(data);
export const CloseCode$isMessageTooBig = (value) =>
  value instanceof MessageTooBig;
export const CloseCode$MessageTooBig$data = (value) => value.data;
export const CloseCode$MessageTooBig$0 = (value) => value.data;

/**
 * Server encountered unexpected error (1011). Something went wrong on your
 * side that prevents handling the connection.
 */
export class InternalError extends $CustomType {
  constructor(data) {
    super();
    this.data = data;
  }
}
export const CloseCode$InternalError = (data) => new InternalError(data);
export const CloseCode$isInternalError = (value) =>
  value instanceof InternalError;
export const CloseCode$InternalError$data = (value) => value.data;
export const CloseCode$InternalError$0 = (value) => value.data;

/**
 * Server is restarting (1012). Planned restart - clients can reconnect
 * after a bit.
 */
export class ServiceRestart extends $CustomType {
  constructor(data) {
    super();
    this.data = data;
  }
}
export const CloseCode$ServiceRestart = (data) => new ServiceRestart(data);
export const CloseCode$isServiceRestart = (value) =>
  value instanceof ServiceRestart;
export const CloseCode$ServiceRestart$data = (value) => value.data;
export const CloseCode$ServiceRestart$0 = (value) => value.data;

/**
 * Temporary server overload (1013). Use when server is temporarily
 * unavailable, client should retry.
 */
export class TryAgainLater extends $CustomType {
  constructor(data) {
    super();
    this.data = data;
  }
}
export const CloseCode$TryAgainLater = (data) => new TryAgainLater(data);
export const CloseCode$isTryAgainLater = (value) =>
  value instanceof TryAgainLater;
export const CloseCode$TryAgainLater$data = (value) => value.data;
export const CloseCode$TryAgainLater$0 = (value) => value.data;

/**
 * Gateway/proxy received invalid response (1014). You're acting as a proxy
 * and the upstream server gave you garbage.
 */
export class BadGateway extends $CustomType {
  constructor(data) {
    super();
    this.data = data;
  }
}
export const CloseCode$BadGateway = (data) => new BadGateway(data);
export const CloseCode$isBadGateway = (value) => value instanceof BadGateway;
export const CloseCode$BadGateway$data = (value) => value.data;
export const CloseCode$BadGateway$0 = (value) => value.data;

/**
 * Custom close codes 3000-4999 for application-specific use.
 */
export class CustomCloseCode extends $CustomType {
  constructor(code, data) {
    super();
    this.code = code;
    this.data = data;
  }
}
export const CloseCode$CustomCloseCode = (code, data) =>
  new CustomCloseCode(code, data);
export const CloseCode$isCustomCloseCode = (value) =>
  value instanceof CustomCloseCode;
export const CloseCode$CustomCloseCode$code = (value) => value.code;
export const CloseCode$CustomCloseCode$0 = (value) => value.code;
export const CloseCode$CustomCloseCode$data = (value) => value.data;
export const CloseCode$CustomCloseCode$1 = (value) => value.data;

export class NoCloseReason extends $CustomType {}
export const CloseCode$NoCloseReason = () => new NoCloseReason();
export const CloseCode$isNoCloseReason = (value) =>
  value instanceof NoCloseReason;

class SSEContinue extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}

class SSENormalStop extends $CustomType {}

class SSEAbnormalStop extends $CustomType {
  constructor(reason) {
    super();
    this.reason = reason;
  }
}

function glisten_to_ewe_ip(ip) {
  if (ip instanceof $glisten.IpV4) {
    let n1 = ip[0];
    let n2 = ip[1];
    let n3 = ip[2];
    let n4 = ip[3];
    return new IpV4(n1, n2, n3, n4);
  } else {
    let n1 = ip[0];
    let n2 = ip[1];
    let n3 = ip[2];
    let n4 = ip[3];
    let n5 = ip[4];
    let n6 = ip[5];
    let n7 = ip[6];
    let n8 = ip[7];
    return new IpV6(n1, n2, n3, n4, n5, n6, n7, n8);
  }
}

function glisten_options_to_ewe_ip(ip) {
  if (ip instanceof $glisten_options.IpV4) {
    let n1 = ip[0];
    let n2 = ip[1];
    let n3 = ip[2];
    let n4 = ip[3];
    return new IpV4(n1, n2, n3, n4);
  } else {
    let n1 = ip[0];
    let n2 = ip[1];
    let n3 = ip[2];
    let n4 = ip[3];
    let n5 = ip[4];
    let n6 = ip[5];
    let n7 = ip[6];
    let n8 = ip[7];
    return new IpV6(n1, n2, n3, n4, n5, n6, n7, n8);
  }
}

function ewe_to_glisten_ip(ip) {
  if (ip instanceof IpV4) {
    let n1 = ip[0];
    let n2 = ip[1];
    let n3 = ip[2];
    let n4 = ip[3];
    return new $glisten.IpV4(n1, n2, n3, n4);
  } else {
    let n1 = ip[0];
    let n2 = ip[1];
    let n3 = ip[2];
    let n4 = ip[3];
    let n5 = ip[4];
    let n6 = ip[5];
    let n7 = ip[6];
    let n8 = ip[7];
    return new $glisten.IpV6(n1, n2, n3, n4, n5, n6, n7, n8);
  }
}

/**
 * Converts an `IpAddress` to its string representation.
 */
export function ip_address_to_string(address) {
  let _pipe = ewe_to_glisten_ip(address);
  return $glisten.ip_address_to_string(_pipe);
}

function transform_response_body(resp) {
  return $response.set_body(
    resp,
    (() => {
      let $ = resp.body;
      if ($ instanceof TextData) {
        let text = $[0];
        return new $ewe_http.TextData(text);
      } else if ($ instanceof BytesData) {
        let bytes = $[0];
        return new $ewe_http.BytesData(bytes);
      } else if ($ instanceof BitsData) {
        let bits = $[0];
        return new $ewe_http.BitsData(bits);
      } else if ($ instanceof StringTreeData) {
        let string_tree = $[0];
        return new $ewe_http.StringTreeData(string_tree);
      } else if ($ instanceof Empty) {
        return new $ewe_http.Empty();
      } else if ($ instanceof File) {
        let descriptor = $.descriptor;
        let offset = $.offset;
        let size = $.size;
        return new $ewe_http.File(descriptor, offset, size);
      } else if ($ instanceof Chunked) {
        return new $ewe_http.Chunked();
      } else if ($ instanceof Websocket) {
        return new $ewe_http.Websocket();
      } else {
        return new $ewe_http.SSE();
      }
    })(),
  );
}

function internal_to_file_error(error) {
  if (error instanceof $file.Enoent) {
    return new NoEntry();
  } else if (error instanceof $file.Eacces) {
    return new NoAccess();
  } else if (error instanceof $file.Eisdir) {
    return new IsDirectory();
  } else {
    let error$1 = error[0];
    return new UnknownFileError(error$1);
  }
}

/**
 * Binds server to a specific network interface (e.g., "0.0.0.0" for all IPv4
 * interfaces or "127.0.0.1" for localhost). To bind to IPv6 addresses like
 * "::" or "::1", you must use `ewe.enable_ipv6`. Crashes the program if the
 * interface is invalid.
 */
export function bind(builder, interface$) {
  return new Builder(
    builder.handler,
    builder.port,
    interface$,
    builder.ipv6,
    builder.tls,
    builder.on_start,
    builder.on_crash,
    builder.listener_name,
    builder.idle_timeout,
  );
}

/**
 * Sets the listening port for server.
 */
export function listening(builder, port) {
  return new Builder(
    builder.handler,
    port,
    builder.interface,
    builder.ipv6,
    builder.tls,
    builder.on_start,
    builder.on_crash,
    builder.listener_name,
    builder.idle_timeout,
  );
}

/**
 * Sets the listening port to 0, which causes the OS to assign a random
 * available port.
 */
export function listening_random(builder) {
  return new Builder(
    builder.handler,
    0,
    builder.interface,
    builder.ipv6,
    builder.tls,
    builder.on_start,
    builder.on_crash,
    builder.listener_name,
    builder.idle_timeout,
  );
}

/**
 * Enables IPv6 support, allowing the server to accept connections over IPv6
 * addresses. Must be called for binding to IPv6 addresses via `ewe.bind`.
 */
export function enable_ipv6(builder) {
  return new Builder(
    builder.handler,
    builder.port,
    builder.interface,
    true,
    builder.tls,
    builder.on_start,
    builder.on_crash,
    builder.listener_name,
    builder.idle_timeout,
  );
}

/**
 * Enables TLS (HTTPS) support, with provided certificate and key files.
 * Crashes the program if the files don't exist or are invalid.
 */
export function enable_tls(builder, certificate_file, key_file) {
  return new Builder(
    builder.handler,
    builder.port,
    builder.interface,
    builder.ipv6,
    new Some([certificate_file, key_file]),
    builder.on_start,
    builder.on_crash,
    builder.listener_name,
    builder.idle_timeout,
  );
}

/**
 * Sets a custom listener process name. This name is required when calling
 * `ewe.get_server_info` to retrieve the server's bound address and port.
 */
export function with_name(builder, name) {
  return new Builder(
    builder.handler,
    builder.port,
    builder.interface,
    builder.ipv6,
    builder.tls,
    builder.on_start,
    builder.on_crash,
    name,
    builder.idle_timeout,
  );
}

/**
 * Sets a callback function called after the server starts. Receives the scheme
 * and server's socket address.
 */
export function on_start(builder, on_start) {
  return new Builder(
    builder.handler,
    builder.port,
    builder.interface,
    builder.ipv6,
    builder.tls,
    on_start,
    builder.on_crash,
    builder.listener_name,
    builder.idle_timeout,
  );
}

/**
 * Sets an empty `on_start` function.
 */
export function quiet(builder) {
  return new Builder(
    builder.handler,
    builder.port,
    builder.interface,
    builder.ipv6,
    builder.tls,
    (_, _1) => { return undefined; },
    builder.on_crash,
    builder.listener_name,
    builder.idle_timeout,
  );
}

/**
 * Sets a custom response that will be sent when server crashes.
 */
export function on_crash(builder, on_crash) {
  return new Builder(
    builder.handler,
    builder.port,
    builder.interface,
    builder.ipv6,
    builder.tls,
    builder.on_start,
    on_crash,
    builder.listener_name,
    builder.idle_timeout,
  );
}

/**
 * Sets the idle timeout in milliseconds. Connections are closed after this
 * period of inactivity. Defaults to 10_000ms if the value is negative.
 */
export function idle_timeout(builder, idle_timeout) {
  let idle_timeout$1 = idle_timeout;
  if (idle_timeout$1 >= 0) {
    return new Builder(
      builder.handler,
      builder.port,
      builder.interface,
      builder.ipv6,
      builder.tls,
      builder.on_start,
      builder.on_crash,
      builder.listener_name,
      idle_timeout$1,
    );
  } else {
    return new Builder(
      builder.handler,
      builder.port,
      builder.interface,
      builder.ipv6,
      builder.tls,
      builder.on_start,
      builder.on_crash,
      builder.listener_name,
      10_000,
    );
  }
}

function consumer_adapter(internal_consumer) {
  return (size) => {
    let $ = internal_consumer(size);
    if ($ instanceof Ok) {
      let $1 = $[0];
      if ($1 instanceof $ewe_http.Consumed) {
        let data = $1.data;
        let next = $1.next;
        return new Ok(new Consumed(data, consumer_adapter(next)));
      } else {
        return new Ok(new Done());
      }
    } else {
      return new Error(new InvalidBody());
    }
  };
}

/**
 * Instructs chunked response to continue processing.
 */
export function chunked_continue(user_state) {
  return new ChunkedContinue(user_state);
}

/**
 * Instructs chunked response to stop normally.
 */
export function chunked_stop() {
  return new ChunkedStop();
}

/**
 * Instructs chunked response to stop with abnormal reason.
 */
export function chunked_stop_abnormal(reason) {
  return new ChunkedAbnormalStop(reason);
}

function to_internal_chunked_next(next) {
  if (next instanceof ChunkedContinue) {
    let user_state = next[0];
    return new $chunked.Continue(user_state);
  } else if (next instanceof ChunkedStop) {
    return new $chunked.NormalStop();
  } else {
    let reason = next.reason;
    return new $chunked.AbnormalStop(reason);
  }
}

/**
 * Instructs WebSocket connection to continue processing.
 */
export function websocket_continue(user_state) {
  return new WebsocketContinue(user_state, new None());
}

/**
 * Instructs WebSocket connection to continue processing, including selector
 * for custom messages.
 */
export function websocket_continue_with_selector(user_state, selector) {
  return new WebsocketContinue(user_state, new Some(selector));
}

/**
 * Instructs WebSocket connection to stop.
 */
export function websocket_stop() {
  return new WebsocketNormalStop();
}

/**
 * Instructs WebSocket connection to stop with abnormal reason.
 */
export function websocket_stop_abnormal(reason) {
  return new WebsocketAbnormalStop(reason);
}

function to_websocket_next(next) {
  if (next instanceof $websocket.Continue) {
    let user_state = next.user_state;
    let selector = next.selector;
    return new WebsocketContinue(user_state, selector);
  } else if (next instanceof $websocket.NormalStop) {
    return new WebsocketNormalStop();
  } else {
    let reason = next.reason;
    return new WebsocketAbnormalStop(reason);
  }
}

function to_internal_websocket_next(next) {
  if (next instanceof WebsocketContinue) {
    let user_state = next[0];
    let selector = next[1];
    return new $websocket.Continue(user_state, selector);
  } else if (next instanceof WebsocketNormalStop) {
    return new $websocket.NormalStop();
  } else {
    let reason = next.reason;
    return new $websocket.AbnormalStop(reason);
  }
}

function to_internal_close_code(code) {
  if (code instanceof NormalClosure) {
    let data = code.data;
    return new $websocks.NormalClosure($bit_array.from_string(data));
  } else if (code instanceof InvalidPayloadData) {
    let data = code.data;
    return new $websocks.InvalidPayloadData($bit_array.from_string(data));
  } else if (code instanceof PolicyViolation) {
    let data = code.data;
    return new $websocks.PolicyViolation($bit_array.from_string(data));
  } else if (code instanceof MessageTooBig) {
    let data = code.data;
    return new $websocks.MessageTooBig($bit_array.from_string(data));
  } else if (code instanceof InternalError) {
    let data = code.data;
    return new $websocks.InternalError($bit_array.from_string(data));
  } else if (code instanceof ServiceRestart) {
    let data = code.data;
    return new $websocks.ServiceRestart($bit_array.from_string(data));
  } else if (code instanceof TryAgainLater) {
    let data = code.data;
    return new $websocks.TryAgainLater($bit_array.from_string(data));
  } else if (code instanceof BadGateway) {
    let data = code.data;
    return new $websocks.BadGateway($bit_array.from_string(data));
  } else if (code instanceof CustomCloseCode) {
    let code$1 = code.code;
    let data = code.data;
    return new $websocks.CustomCloseCode(code$1, $bit_array.from_string(data));
  } else {
    return new $websocks.NoCloseReason();
  }
}

/**
 * Instructs Server-Sent Events connection to continue processing.
 */
export function sse_continue(user_state) {
  return new SSEContinue(user_state);
}

/**
 * Instructs Server-Sent Events connection to stop.
 */
export function sse_stop() {
  return new SSENormalStop();
}

/**
 * Instructs Server-Sent Events connection to stop with abnormal reason.
 */
export function sse_stop_abnormal(reason) {
  return new SSEAbnormalStop(reason);
}

/**
 * Sets the name of the event.
 */
export function event_name(event, name) {
  return new $sse.SSEEvent(new Some(name), event.data, event.id, event.retry);
}

/**
 * Sets the ID of the event.
 */
export function event_id(event, id) {
  return new $sse.SSEEvent(event.event, event.data, new Some(id), event.retry);
}

/**
 * Sets the retry time of the event.
 */
export function event_retry(event, retry) {
  return new $sse.SSEEvent(event.event, event.data, event.id, new Some(retry));
}
