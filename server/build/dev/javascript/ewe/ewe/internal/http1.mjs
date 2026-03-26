import * as $atom from "../../../gleam_erlang/gleam/erlang/atom.mjs";
import * as $process from "../../../gleam_erlang/gleam/erlang/process.mjs";
import * as $http from "../../../gleam_http/gleam/http.mjs";
import * as $request from "../../../gleam_http/gleam/http/request.mjs";
import { Request } from "../../../gleam_http/gleam/http/request.mjs";
import * as $response from "../../../gleam_http/gleam/http/response.mjs";
import * as $actor from "../../../gleam_otp/gleam/otp/actor.mjs";
import * as $factory from "../../../gleam_otp/gleam/otp/factory_supervisor.mjs";
import * as $bit_array from "../../../gleam_stdlib/gleam/bit_array.mjs";
import * as $bool from "../../../gleam_stdlib/gleam/bool.mjs";
import * as $bytes_tree from "../../../gleam_stdlib/gleam/bytes_tree.mjs";
import * as $dict from "../../../gleam_stdlib/gleam/dict.mjs";
import * as $int from "../../../gleam_stdlib/gleam/int.mjs";
import * as $list from "../../../gleam_stdlib/gleam/list.mjs";
import * as $option from "../../../gleam_stdlib/gleam/option.mjs";
import { None, Some } from "../../../gleam_stdlib/gleam/option.mjs";
import * as $result from "../../../gleam_stdlib/gleam/result.mjs";
import { replace_error, try$ } from "../../../gleam_stdlib/gleam/result.mjs";
import * as $set from "../../../gleam_stdlib/gleam/set.mjs";
import * as $string from "../../../gleam_stdlib/gleam/string.mjs";
import * as $string_tree from "../../../gleam_stdlib/gleam/string_tree.mjs";
import * as $glisten from "../../../glisten/glisten.mjs";
import * as $socket from "../../../glisten/glisten/socket.mjs";
import * as $transport from "../../../glisten/glisten/transport.mjs";
import * as $websocks from "../../../websocks/websocks.mjs";
import * as $clock from "../../ewe/internal/clock.mjs";
import * as $decoder from "../../ewe/internal/decoder.mjs";
import {
  AbsPath,
  HttpBin,
  HttpEoh,
  HttpHeader,
  HttpRequest,
  HttphBin,
  More,
  Packet,
} from "../../ewe/internal/decoder.mjs";
import * as $encoder from "../../ewe/internal/encoder.mjs";
import * as $file from "../../ewe/internal/file.mjs";
import * as $buffer from "../../ewe/internal/http1/buffer.mjs";
import { Buffer } from "../../ewe/internal/http1/buffer.mjs";
import { Ok, CustomType as $CustomType, toBitArray } from "../../gleam.mjs";

export class Connection extends $CustomType {
  constructor(transport, socket, buffer, factory_name) {
    super();
    this.transport = transport;
    this.socket = socket;
    this.buffer = buffer;
    this.factory_name = factory_name;
  }
}
export const Connection$Connection = (transport, socket, buffer, factory_name) =>
  new Connection(transport, socket, buffer, factory_name);
export const Connection$isConnection = (value) => value instanceof Connection;
export const Connection$Connection$transport = (value) => value.transport;
export const Connection$Connection$0 = (value) => value.transport;
export const Connection$Connection$socket = (value) => value.socket;
export const Connection$Connection$1 = (value) => value.socket;
export const Connection$Connection$buffer = (value) => value.buffer;
export const Connection$Connection$2 = (value) => value.buffer;
export const Connection$Connection$factory_name = (value) => value.factory_name;
export const Connection$Connection$3 = (value) => value.factory_name;

export class InvalidMethod extends $CustomType {}
export const ParseError$InvalidMethod = () => new InvalidMethod();
export const ParseError$isInvalidMethod = (value) =>
  value instanceof InvalidMethod;

export class InvalidPath extends $CustomType {}
export const ParseError$InvalidPath = () => new InvalidPath();
export const ParseError$isInvalidPath = (value) => value instanceof InvalidPath;

export class InvalidVersion extends $CustomType {}
export const ParseError$InvalidVersion = () => new InvalidVersion();
export const ParseError$isInvalidVersion = (value) =>
  value instanceof InvalidVersion;

export class InvalidHeaders extends $CustomType {}
export const ParseError$InvalidHeaders = () => new InvalidHeaders();
export const ParseError$isInvalidHeaders = (value) =>
  value instanceof InvalidHeaders;

export class MissingHost extends $CustomType {}
export const ParseError$MissingHost = () => new MissingHost();
export const ParseError$isMissingHost = (value) => value instanceof MissingHost;

export class DuplicateHost extends $CustomType {}
export const ParseError$DuplicateHost = () => new DuplicateHost();
export const ParseError$isDuplicateHost = (value) =>
  value instanceof DuplicateHost;

export class InvalidContentLength extends $CustomType {}
export const ParseError$InvalidContentLength = () => new InvalidContentLength();
export const ParseError$isInvalidContentLength = (value) =>
  value instanceof InvalidContentLength;

export class InvalidBody extends $CustomType {}
export const ParseError$InvalidBody = () => new InvalidBody();
export const ParseError$isInvalidBody = (value) => value instanceof InvalidBody;

export class BodyTooLarge extends $CustomType {}
export const ParseError$BodyTooLarge = () => new BodyTooLarge();
export const ParseError$isBodyTooLarge = (value) =>
  value instanceof BodyTooLarge;

export class MalformedRequest extends $CustomType {}
export const ParseError$MalformedRequest = () => new MalformedRequest();
export const ParseError$isMalformedRequest = (value) =>
  value instanceof MalformedRequest;

export class PacketDiscard extends $CustomType {}
export const ParseError$PacketDiscard = () => new PacketDiscard();
export const ParseError$isPacketDiscard = (value) =>
  value instanceof PacketDiscard;

export class Http10 extends $CustomType {}
export const HttpVersion$Http10 = () => new Http10();
export const HttpVersion$isHttp10 = (value) => value instanceof Http10;

export class Http11 extends $CustomType {}
export const HttpVersion$Http11 = () => new Http11();
export const HttpVersion$isHttp11 = (value) => value instanceof Http11;

export class Http1Request extends $CustomType {
  constructor(req, version) {
    super();
    this.req = req;
    this.version = version;
  }
}
export const ParsedRequest$Http1Request = (req, version) =>
  new Http1Request(req, version);
export const ParsedRequest$isHttp1Request = (value) =>
  value instanceof Http1Request;
export const ParsedRequest$Http1Request$req = (value) => value.req;
export const ParsedRequest$Http1Request$0 = (value) => value.req;
export const ParsedRequest$Http1Request$version = (value) => value.version;
export const ParsedRequest$Http1Request$1 = (value) => value.version;

export class Http2Upgrade extends $CustomType {
  constructor(upgrade) {
    super();
    this.upgrade = upgrade;
  }
}
export const ParsedRequest$Http2Upgrade = (upgrade) =>
  new Http2Upgrade(upgrade);
export const ParsedRequest$isHttp2Upgrade = (value) =>
  value instanceof Http2Upgrade;
export const ParsedRequest$Http2Upgrade$upgrade = (value) => value.upgrade;
export const ParsedRequest$Http2Upgrade$0 = (value) => value.upgrade;

export class Upgrade extends $CustomType {
  constructor(req, settings) {
    super();
    this.req = req;
    this.settings = settings;
  }
}
export const Http2Upgrade$Upgrade = (req, settings) =>
  new Upgrade(req, settings);
export const Http2Upgrade$isUpgrade = (value) => value instanceof Upgrade;
export const Http2Upgrade$Upgrade$req = (value) => value.req;
export const Http2Upgrade$Upgrade$0 = (value) => value.req;
export const Http2Upgrade$Upgrade$settings = (value) => value.settings;
export const Http2Upgrade$Upgrade$1 = (value) => value.settings;

export class Direct extends $CustomType {
  constructor(data) {
    super();
    this.data = data;
  }
}
export const Http2Upgrade$Direct = (data) => new Direct(data);
export const Http2Upgrade$isDirect = (value) => value instanceof Direct;
export const Http2Upgrade$Direct$data = (value) => value.data;
export const Http2Upgrade$Direct$0 = (value) => value.data;

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

class Incomplete extends $CustomType {}

class Chunk extends $CustomType {
  constructor($0, size, rest) {
    super();
    this[0] = $0;
    this.size = size;
    this.rest = rest;
  }
}

class FinalChunk extends $CustomType {
  constructor(rest) {
    super();
    this.rest = rest;
  }
}

class ChunkedStreamState extends $CustomType {
  constructor(data, chunk, done) {
    super();
    this.data = data;
    this.chunk = chunk;
    this.done = done;
  }
}

export class MethodNotGet extends $CustomType {}
export const UpgradeWebsocketError$MethodNotGet = () => new MethodNotGet();
export const UpgradeWebsocketError$isMethodNotGet = (value) =>
  value instanceof MethodNotGet;

export class MissingConnectionHeader extends $CustomType {}
export const UpgradeWebsocketError$MissingConnectionHeader = () =>
  new MissingConnectionHeader();
export const UpgradeWebsocketError$isMissingConnectionHeader = (value) =>
  value instanceof MissingConnectionHeader;

export class InvalidConnectionHeader extends $CustomType {}
export const UpgradeWebsocketError$InvalidConnectionHeader = () =>
  new InvalidConnectionHeader();
export const UpgradeWebsocketError$isInvalidConnectionHeader = (value) =>
  value instanceof InvalidConnectionHeader;

export class MissingUpgradeHeader extends $CustomType {}
export const UpgradeWebsocketError$MissingUpgradeHeader = () =>
  new MissingUpgradeHeader();
export const UpgradeWebsocketError$isMissingUpgradeHeader = (value) =>
  value instanceof MissingUpgradeHeader;

export class InvalidUpgradeHeader extends $CustomType {}
export const UpgradeWebsocketError$InvalidUpgradeHeader = () =>
  new InvalidUpgradeHeader();
export const UpgradeWebsocketError$isInvalidUpgradeHeader = (value) =>
  value instanceof InvalidUpgradeHeader;

export class MissingWebsocketVersion extends $CustomType {}
export const UpgradeWebsocketError$MissingWebsocketVersion = () =>
  new MissingWebsocketVersion();
export const UpgradeWebsocketError$isMissingWebsocketVersion = (value) =>
  value instanceof MissingWebsocketVersion;

export class MissingWebsocketKey extends $CustomType {}
export const UpgradeWebsocketError$MissingWebsocketKey = () =>
  new MissingWebsocketKey();
export const UpgradeWebsocketError$isMissingWebsocketKey = (value) =>
  value instanceof MissingWebsocketKey;

export class TextData extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const ResponseBody$TextData = ($0) => new TextData($0);
export const ResponseBody$isTextData = (value) => value instanceof TextData;
export const ResponseBody$TextData$0 = (value) => value[0];

export class BytesData extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const ResponseBody$BytesData = ($0) => new BytesData($0);
export const ResponseBody$isBytesData = (value) => value instanceof BytesData;
export const ResponseBody$BytesData$0 = (value) => value[0];

export class BitsData extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const ResponseBody$BitsData = ($0) => new BitsData($0);
export const ResponseBody$isBitsData = (value) => value instanceof BitsData;
export const ResponseBody$BitsData$0 = (value) => value[0];

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

export class Empty extends $CustomType {}
export const ResponseBody$Empty = () => new Empty();
export const ResponseBody$isEmpty = (value) => value instanceof Empty;

/**
 * 2MB (2 million bytes).
 * 
 * @ignore
 */
const max_reading_size = 2_000_000;

/**
 * Transforms a glisten connection.
 */
export function transform_connection(conn, factory_name) {
  return new Connection(
    conn.transport,
    conn.socket,
    new Buffer(toBitArray([]), 0),
    factory_name,
  );
}

/**
 * Finds an available key for set-cookie headers.
 * 
 * @ignore
 */
function available_cookie_key(loop$headers, loop$idx) {
  while (true) {
    let headers = loop$headers;
    let idx = loop$idx;
    let _block;
    if (idx === 0) {
      _block = "set-cookie";
    } else {
      let n = idx;
      _block = "set-cookie-" + $int.to_string(n);
    }
    let key = _block;
    let $ = $dict.has_key(headers, key);
    if ($) {
      loop$headers = headers;
      loop$idx = idx + 1;
    } else {
      return key;
    }
  }
}

/**
 * Inserts a header into the headers dictionary.
 * 
 * @ignore
 */
function insert_header(headers, field, value) {
  let $ = field !== "set-cookie";
  if ($) {
    return $dict.upsert(
      headers,
      field,
      (target) => {
        if (target instanceof $option.Some) {
          let existing = target[0];
          return (existing + ", ") + value;
        } else {
          return value;
        }
      },
    );
  } else {
    return $dict.insert(headers, available_cookie_key(headers, 0), value);
  }
}

/**
 * Checks if a trailer field is allowed.
 * 
 * @ignore
 */
function is_allowed_trailer(field) {
  if (field === "server-timing") {
    return true;
  } else if (field === "content-digest") {
    return true;
  } else if (field === "repr-digest") {
    return true;
  } else {
    return false;
  }
}

/**
 * Sets the content length header if it is not already set.
 */
export function set_content_length(resp) {
  let $ = $response.get_header(resp, "content-length");
  if ($ instanceof Ok) {
    return resp;
  } else {
    let _block;
    let _pipe = $bit_array.byte_size(resp.body);
    _block = $int.to_string(_pipe);
    let body_size = _block;
    return $response.set_header(resp, "content-length", body_size);
  }
}
