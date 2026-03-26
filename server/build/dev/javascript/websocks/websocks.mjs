import * as $crypto from "../gleam_crypto/gleam/crypto.mjs";
import * as $atom from "../gleam_erlang/gleam/erlang/atom.mjs";
import * as $bit_array from "../gleam_stdlib/gleam/bit_array.mjs";
import * as $bool from "../gleam_stdlib/gleam/bool.mjs";
import * as $bytes_tree from "../gleam_stdlib/gleam/bytes_tree.mjs";
import * as $int from "../gleam_stdlib/gleam/int.mjs";
import * as $list from "../gleam_stdlib/gleam/list.mjs";
import * as $option from "../gleam_stdlib/gleam/option.mjs";
import { None, Some } from "../gleam_stdlib/gleam/option.mjs";
import * as $result from "../gleam_stdlib/gleam/result.mjs";
import * as $string from "../gleam_stdlib/gleam/string.mjs";
import { Ok, Error, CustomType as $CustomType } from "./gleam.mjs";

export class Client extends $CustomType {}
export const Role$Client = () => new Client();
export const Role$isClient = (value) => value instanceof Client;

export class Server extends $CustomType {}
export const Role$Server = () => new Server();
export const Role$isServer = (value) => value instanceof Server;

export class CompressionExtensions extends $CustomType {
  constructor(client_no_context_takeover, client_max_window_bits, server_no_context_takeover, server_max_window_bits) {
    super();
    this.client_no_context_takeover = client_no_context_takeover;
    this.client_max_window_bits = client_max_window_bits;
    this.server_no_context_takeover = server_no_context_takeover;
    this.server_max_window_bits = server_max_window_bits;
  }
}
export const CompressionExtensions$CompressionExtensions = (client_no_context_takeover, client_max_window_bits, server_no_context_takeover, server_max_window_bits) =>
  new CompressionExtensions(client_no_context_takeover,
  client_max_window_bits,
  server_no_context_takeover,
  server_max_window_bits);
export const CompressionExtensions$isCompressionExtensions = (value) =>
  value instanceof CompressionExtensions;
export const CompressionExtensions$CompressionExtensions$client_no_context_takeover = (value) =>
  value.client_no_context_takeover;
export const CompressionExtensions$CompressionExtensions$0 = (value) =>
  value.client_no_context_takeover;
export const CompressionExtensions$CompressionExtensions$client_max_window_bits = (value) =>
  value.client_max_window_bits;
export const CompressionExtensions$CompressionExtensions$1 = (value) =>
  value.client_max_window_bits;
export const CompressionExtensions$CompressionExtensions$server_no_context_takeover = (value) =>
  value.server_no_context_takeover;
export const CompressionExtensions$CompressionExtensions$2 = (value) =>
  value.server_no_context_takeover;
export const CompressionExtensions$CompressionExtensions$server_max_window_bits = (value) =>
  value.server_max_window_bits;
export const CompressionExtensions$CompressionExtensions$3 = (value) =>
  value.server_max_window_bits;

class Disabled extends $CustomType {}

class Enabled extends $CustomType {
  constructor(inflate_context, inflate_window_bits, deflate_context, deflate_window_bits, reset_on_compress, reset_on_decompress) {
    super();
    this.inflate_context = inflate_context;
    this.inflate_window_bits = inflate_window_bits;
    this.deflate_context = deflate_context;
    this.deflate_window_bits = deflate_window_bits;
    this.reset_on_compress = reset_on_compress;
    this.reset_on_decompress = reset_on_decompress;
  }
}

class Sync extends $CustomType {}

class Deflated extends $CustomType {}

class Default extends $CustomType {}

class Empty extends $CustomType {
  constructor(compression, buffer) {
    super();
    this.compression = compression;
    this.buffer = buffer;
  }
}

class Accumulating extends $CustomType {
  constructor(compression, buffer, frame_builder, accumulated_payload, compressed) {
    super();
    this.compression = compression;
    this.buffer = buffer;
    this.frame_builder = frame_builder;
    this.accumulated_payload = accumulated_payload;
    this.compressed = compressed;
  }
}

/**
 * A continuation frame, used for fragmented messages.
 */
export class Continuation extends $CustomType {
  constructor(payload) {
    super();
    this.payload = payload;
  }
}
export const Frame$Continuation = (payload) => new Continuation(payload);
export const Frame$isContinuation = (value) => value instanceof Continuation;
export const Frame$Continuation$payload = (value) => value.payload;
export const Frame$Continuation$0 = (value) => value.payload;

/**
 * A text frame, containing UTF-8 encoded payload.
 */
export class Text extends $CustomType {
  constructor(payload) {
    super();
    this.payload = payload;
  }
}
export const Frame$Text = (payload) => new Text(payload);
export const Frame$isText = (value) => value instanceof Text;
export const Frame$Text$payload = (value) => value.payload;
export const Frame$Text$0 = (value) => value.payload;

/**
 * A binary frame, containing arbitrary binary data.
 */
export class Binary extends $CustomType {
  constructor(payload) {
    super();
    this.payload = payload;
  }
}
export const Frame$Binary = (payload) => new Binary(payload);
export const Frame$isBinary = (value) => value instanceof Binary;
export const Frame$Binary$payload = (value) => value.payload;
export const Frame$Binary$0 = (value) => value.payload;

/**
 * A control frame, controlling WebSocket connection.
 */
export class Control extends $CustomType {
  constructor(control) {
    super();
    this.control = control;
  }
}
export const Frame$Control = (control) => new Control(control);
export const Frame$isControl = (value) => value instanceof Control;
export const Frame$Control$control = (value) => value.control;
export const Frame$Control$0 = (value) => value.control;

/**
 * A ping control frame. Used for keepalive.
 */
export class Ping extends $CustomType {
  constructor(payload) {
    super();
    this.payload = payload;
  }
}
export const Control$Ping = (payload) => new Ping(payload);
export const Control$isPing = (value) => value instanceof Ping;
export const Control$Ping$payload = (value) => value.payload;
export const Control$Ping$0 = (value) => value.payload;

/**
 * A pong control frame. Response to ping.
 */
export class Pong extends $CustomType {
  constructor(payload) {
    super();
    this.payload = payload;
  }
}
export const Control$Pong = (payload) => new Pong(payload);
export const Control$isPong = (value) => value instanceof Pong;
export const Control$Pong$payload = (value) => value.payload;
export const Control$Pong$0 = (value) => value.payload;

/**
 * A close control frame. Contains the reason for closing if present.
 */
export class Close extends $CustomType {
  constructor(reason) {
    super();
    this.reason = reason;
  }
}
export const Control$Close = (reason) => new Close(reason);
export const Control$isClose = (value) => value instanceof Close;
export const Control$Close$reason = (value) => value.reason;
export const Control$Close$0 = (value) => value.reason;

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
 * The server encountered unexpected error.
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

class DecodedContinuation extends $CustomType {
  constructor(payload, compressed) {
    super();
    this.payload = payload;
    this.compressed = compressed;
  }
}

class DecodedText extends $CustomType {
  constructor(payload, compressed) {
    super();
    this.payload = payload;
    this.compressed = compressed;
  }
}

class DecodedBinary extends $CustomType {
  constructor(payload, compressed) {
    super();
    this.payload = payload;
    this.compressed = compressed;
  }
}

class DecodedControl extends $CustomType {
  constructor(control) {
    super();
    this.control = control;
  }
}

class Complete extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}

class Incomplete extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}

class Resolved extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}

export class InvalidFrame extends $CustomType {}
export const DecodeError$InvalidFrame = () => new InvalidFrame();
export const DecodeError$isInvalidFrame = (value) =>
  value instanceof InvalidFrame;

/**
 * The data is not enough to decode the frame.
 */
export class NotEnoughData extends $CustomType {
  constructor(data) {
    super();
    this.data = data;
  }
}
export const DecodeError$NotEnoughData = (data) => new NotEnoughData(data);
export const DecodeError$isNotEnoughData = (value) =>
  value instanceof NotEnoughData;
export const DecodeError$NotEnoughData$data = (value) => value.data;
export const DecodeError$NotEnoughData$0 = (value) => value.data;

export class NotUtf8 extends $CustomType {}
export const ResolveError$NotUtf8 = () => new NotUtf8();
export const ResolveError$isNotUtf8 = (value) => value instanceof NotUtf8;

export class OrphanedContinuation extends $CustomType {}
export const ResolveError$OrphanedContinuation = () =>
  new OrphanedContinuation();
export const ResolveError$isOrphanedContinuation = (value) =>
  value instanceof OrphanedContinuation;

export class ControlFrameFragmented extends $CustomType {}
export const ResolveError$ControlFrameFragmented = () =>
  new ControlFrameFragmented();
export const ResolveError$isControlFrameFragmented = (value) =>
  value instanceof ControlFrameFragmented;

export class FragmentationInterrupted extends $CustomType {}
export const ResolveError$FragmentationInterrupted = () =>
  new FragmentationInterrupted();
export const ResolveError$isFragmentationInterrupted = (value) =>
  value instanceof FragmentationInterrupted;

export class ConcurrentFragmentation extends $CustomType {}
export const ResolveError$ConcurrentFragmentation = () =>
  new ConcurrentFragmentation();
export const ResolveError$isConcurrentFragmentation = (value) =>
  value instanceof ConcurrentFragmentation;

export class CompressedContinuation extends $CustomType {}
export const ResolveError$CompressedContinuation = () =>
  new CompressedContinuation();
export const ResolveError$isCompressedContinuation = (value) =>
  value instanceof CompressedContinuation;

/**
 * Continue processing more frames with the updated state.
 */
export class Continue extends $CustomType {
  constructor(state) {
    super();
    this.state = state;
  }
}
export const ResolveNext$Continue = (state) => new Continue(state);
export const ResolveNext$isContinue = (value) => value instanceof Continue;
export const ResolveNext$Continue$state = (value) => value.state;
export const ResolveNext$Continue$0 = (value) => value.state;

/**
 * Stop processing frames and return the updated state. Remaining data will
 * be stored in the context buffer for the next processing call.
 */
export class Stop extends $CustomType {
  constructor(state) {
    super();
    this.state = state;
  }
}
export const ResolveNext$Stop = (state) => new Stop(state);
export const ResolveNext$isStop = (value) => value instanceof Stop;
export const ResolveNext$Stop$state = (value) => value.state;
export const ResolveNext$Stop$0 = (value) => value.state;

export const ResolveNext$state = (value) => value.state;

/**
 * Frame decoding failed with the given decode error.
 */
export class DecodeFailed extends $CustomType {
  constructor(reason) {
    super();
    this.reason = reason;
  }
}
export const ProcessError$DecodeFailed = (reason) => new DecodeFailed(reason);
export const ProcessError$isDecodeFailed = (value) =>
  value instanceof DecodeFailed;
export const ProcessError$DecodeFailed$reason = (value) => value.reason;
export const ProcessError$DecodeFailed$0 = (value) => value.reason;

/**
 * Frame resolution failed with the given resolve error.
 */
export class ResolveFailed extends $CustomType {
  constructor(reason) {
    super();
    this.reason = reason;
  }
}
export const ProcessError$ResolveFailed = (reason) => new ResolveFailed(reason);
export const ProcessError$isResolveFailed = (value) =>
  value instanceof ResolveFailed;
export const ProcessError$ResolveFailed$reason = (value) => value.reason;
export const ProcessError$ResolveFailed$0 = (value) => value.reason;

/**
 * Sequence of characters that is used to compute the `Sec-WebSocket-Accept`
 * header during the handshake.
 */
export const magic_string = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";

const default_extensions = /* @__PURE__ */ new CompressionExtensions(
  false,
  /* @__PURE__ */ new None(),
  false,
  /* @__PURE__ */ new None(),
);

/**
 * Generates a random WebSocket key for the `Sec-WebSocket-Key` header.
 * Used by clients during the handshake.
 *
 * ### Example
 *
 * ```gleam
 * websocks.websocket_key()
 * // => "dGhlIHNhbXBsZSBub25jZQ=="
 * ```
 */
export function websocket_key() {
  let _pipe = $crypto.strong_random_bytes(16);
  return $bit_array.base64_encode(_pipe, true);
}

/**
 * Checks if the `permessage-deflate` extension is present in the list of
 * extensions.
 *
 * ### Example
 *
 * ```gleam
 * let extensions =
 *    request.get_header(req, "sec-websocket-extensions")
 *    |> result.map(string.split(_, ";"))
 *    |> result.unwrap([])
 * // => ["permessage-deflate", "client_no_context_takeover"]
 *
 * websocks.has_deflate(extensions)
 * // => True
 * ```
 */
export function has_deflate(extensions) {
  return $list.any(
    extensions,
    (str) => { return str === "permessage-deflate"; },
  );
}

function update_buffer(context, data) {
  if (context instanceof Empty) {
    return new Empty(context.compression, data);
  } else {
    return new Accumulating(
      context.compression,
      data,
      context.frame_builder,
      context.accumulated_payload,
      context.compressed,
    );
  }
}

export function extract_accumulating_frame(context) {
  if (context instanceof Empty) {
    return new Error(undefined);
  } else {
    let frame_builder = context.frame_builder;
    let accumulated_payload = context.accumulated_payload;
    return new Ok(frame_builder(accumulated_payload));
  }
}

export function extract_buffer(context) {
  return context.buffer;
}

export function is_empty_context(context) {
  if (context instanceof Empty) {
    return true;
  } else {
    return false;
  }
}

function wrap_decoded_frame(internal, final) {
  if (final) {
    return new Complete(internal);
  } else {
    return new Incomplete(internal);
  }
}

export function to_decoded_frame(frame, final, compressed) {
  if (frame instanceof Continuation) {
    let payload = frame.payload;
    let _pipe = new DecodedContinuation(payload, compressed);
    return wrap_decoded_frame(_pipe, final);
  } else if (frame instanceof Text) {
    let payload = frame.payload;
    let _pipe = new DecodedText(payload, compressed);
    return wrap_decoded_frame(_pipe, final);
  } else if (frame instanceof Binary) {
    let payload = frame.payload;
    let _pipe = new DecodedBinary(payload, compressed);
    return wrap_decoded_frame(_pipe, final);
  } else {
    let control = frame.control;
    return new Resolved(new Control(control));
  }
}

/**
 * Computes the value of the `Sec-WebSocket-Accept` header during the handshake.
 * Requires `Sec-WebSocket-Key` header value to be present.
 *
 * ### Example
 *
 * ```gleam
 * websocks.compute_accept("dGhlIHNhbXBsZSBub25jZQ==")
 * // => "s3pPLMBiTxaQ9kYGzzhZRbK+xOo="
 * ```
 */
export function compute_accept(key) {
  let _pipe = $string.append(key, magic_string);
  let _pipe$1 = $bit_array.from_string(_pipe);
  let _pipe$2 = ((_capture) => {
    return $crypto.hash(new $crypto.Sha1(), _capture);
  })(_pipe$1);
  return $bit_array.base64_encode(_pipe$2, true);
}

/**
 * Parses compression extension parameters from the handshake extension list.
 * Extracts context takeover settings as well as window bits.
 *
 * ### Example
 *
 * ```gleam
 * let extensions = [
 *   "permessage-deflate",
 *   "client_no_context_takeover",
 *   "client_max_window_bits=15",
 * ]
 *
 * websocks.get_compression_extensions(extensions)
 * // => CompressionExtensions(
 * //      client_no_context_takeover: True,
 * //      client_max_window_bits: Some(15),
 * //      server_no_context_takeover: False,
 * //      server_max_window_bits: None,
 * //    )
 * ```
 */
export function get_compression_extensions(extensions) {
  return $list.fold(
    extensions,
    default_extensions,
    (acc, extension) => {
      if (extension === "client_no_context_takeover") {
        return new CompressionExtensions(
          true,
          acc.client_max_window_bits,
          acc.server_no_context_takeover,
          acc.server_max_window_bits,
        );
      } else if (extension.startsWith("client_max_window_bits=")) {
        let bits = extension.slice(23);
        let client_max_window_bits = $option.from_result($int.parse(bits));
        return new CompressionExtensions(
          acc.client_no_context_takeover,
          client_max_window_bits,
          acc.server_no_context_takeover,
          acc.server_max_window_bits,
        );
      } else if (extension === "server_no_context_takeover") {
        return new CompressionExtensions(
          acc.client_no_context_takeover,
          acc.client_max_window_bits,
          true,
          acc.server_max_window_bits,
        );
      } else if (extension.startsWith("server_max_window_bits=")) {
        let bits = extension.slice(23);
        let server_max_window_bits = $option.from_result($int.parse(bits));
        return new CompressionExtensions(
          acc.client_no_context_takeover,
          acc.client_max_window_bits,
          acc.server_no_context_takeover,
          server_max_window_bits,
        );
      } else {
        return acc;
      }
    },
  );
}
