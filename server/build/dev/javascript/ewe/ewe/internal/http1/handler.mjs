import * as $compresso from "../../../../compresso/compresso.mjs";
import * as $exception from "../../../../exception/exception.mjs";
import * as $process from "../../../../gleam_erlang/gleam/erlang/process.mjs";
import * as $request from "../../../../gleam_http/gleam/http/request.mjs";
import * as $response from "../../../../gleam_http/gleam/http/response.mjs";
import * as $bit_array from "../../../../gleam_stdlib/gleam/bit_array.mjs";
import * as $bytes_tree from "../../../../gleam_stdlib/gleam/bytes_tree.mjs";
import * as $int from "../../../../gleam_stdlib/gleam/int.mjs";
import * as $option from "../../../../gleam_stdlib/gleam/option.mjs";
import { None, Some } from "../../../../gleam_stdlib/gleam/option.mjs";
import * as $result from "../../../../gleam_stdlib/gleam/result.mjs";
import * as $string from "../../../../gleam_stdlib/gleam/string.mjs";
import * as $string_tree from "../../../../gleam_stdlib/gleam/string_tree.mjs";
import * as $glisten from "../../../../glisten/glisten.mjs";
import * as $glisten_handler from "../../../../glisten/glisten/internal/handler.mjs";
import { Close, Internal } from "../../../../glisten/glisten/internal/handler.mjs";
import * as $socket from "../../../../glisten/glisten/socket.mjs";
import * as $transport from "../../../../glisten/glisten/transport.mjs";
import * as $logging from "../../../../logging/logging.mjs";
import * as $encoder from "../../../ewe/internal/encoder.mjs";
import * as $file from "../../../ewe/internal/file.mjs";
import * as $ewe_http from "../../../ewe/internal/http1.mjs";
import {
  BitsData,
  BytesData,
  Chunked,
  Empty,
  File,
  SSE,
  StringTreeData,
  TextData,
  Websocket,
} from "../../../ewe/internal/http1.mjs";
import * as $buffer from "../../../ewe/internal/http1/buffer.mjs";
import { Buffer } from "../../../ewe/internal/http1/buffer.mjs";
import { Ok, Error, CustomType as $CustomType } from "../../../gleam.mjs";

export class Http1Handler extends $CustomType {
  constructor(idle_timer) {
    super();
    this.idle_timer = idle_timer;
  }
}
export const Http1Handler$Http1Handler = (idle_timer) =>
  new Http1Handler(idle_timer);
export const Http1Handler$isHttp1Handler = (value) =>
  value instanceof Http1Handler;
export const Http1Handler$Http1Handler$idle_timer = (value) => value.idle_timer;
export const Http1Handler$Http1Handler$0 = (value) => value.idle_timer;

export class Continue extends $CustomType {
  constructor(state) {
    super();
    this.state = state;
  }
}
export const Next$Continue = (state) => new Continue(state);
export const Next$isContinue = (value) => value instanceof Continue;
export const Next$Continue$state = (value) => value.state;
export const Next$Continue$0 = (value) => value.state;

export class Stop extends $CustomType {}
export const Next$Stop = () => new Stop();
export const Next$isStop = (value) => value instanceof Stop;

export class Http2Upgrade extends $CustomType {
  constructor(upgrade) {
    super();
    this.upgrade = upgrade;
  }
}
export const Next$Http2Upgrade = (upgrade) => new Http2Upgrade(upgrade);
export const Next$isHttp2Upgrade = (value) => value instanceof Http2Upgrade;
export const Next$Http2Upgrade$upgrade = (value) => value.upgrade;
export const Next$Http2Upgrade$0 = (value) => value.upgrade;

export class Upgrade extends $CustomType {
  constructor(request, settings) {
    super();
    this.request = request;
    this.settings = settings;
  }
}
export const Http2Upgrade$Upgrade = (request, settings) =>
  new Upgrade(request, settings);
export const Http2Upgrade$isUpgrade = (value) => value instanceof Upgrade;
export const Http2Upgrade$Upgrade$request = (value) => value.request;
export const Http2Upgrade$Upgrade$0 = (value) => value.request;
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

/**
 * Initializes the HTTP/1.1 handler state.
 */
export function init() {
  return new Http1Handler(new None());
}

/**
 * Can the body be encoded to gzip?
 * 
 * @ignore
 */
function can_encode_gzip(request, response) {
  let _block;
  let _pipe = $request.get_header(request, "accept-encoding");
  _block = $result.map(
    _pipe,
    (_capture) => { return $string.contains(_capture, "gzip"); },
  );
  let accept_encoding = _block;
  let content_encoding = $response.get_header(response, "content-encoding");
  if (accept_encoding instanceof Ok && content_encoding instanceof Error) {
    let $ = accept_encoding[0];
    if ($) {
      return true;
    } else {
      return false;
    }
  } else {
    return false;
  }
}

/**
 * Removes the charset from the content-type header.
 * 
 * @ignore
 */
function remove_charset(response) {
  let _pipe = $response.get_header(response, "content-type");
  let _pipe$1 = $result.try$(
    _pipe,
    (_capture) => { return $string.split_once(_capture, ";"); },
  );
  let _pipe$2 = $result.map(
    _pipe$1,
    (parts) => {
      return $response.set_header(response, "content-type", parts[0]);
    },
  );
  return $result.unwrap(_pipe$2, response);
}

/**
 * Is the connection set to close?
 * 
 * @ignore
 */
function is_connection_close(response) {
  let $ = $response.get_header(response, "connection");
  if ($ instanceof Ok) {
    let $1 = $[0];
    if ($1 === "close") {
      return true;
    } else {
      return false;
    }
  } else {
    return false;
  }
}
