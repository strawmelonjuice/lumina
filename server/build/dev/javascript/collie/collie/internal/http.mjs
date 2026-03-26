import * as $request from "../../../gleam_http/gleam/http/request.mjs";
import * as $response from "../../../gleam_http/gleam/http/response.mjs";
import * as $bit_array from "../../../gleam_stdlib/gleam/bit_array.mjs";
import * as $bytes_tree from "../../../gleam_stdlib/gleam/bytes_tree.mjs";
import * as $int from "../../../gleam_stdlib/gleam/int.mjs";
import * as $list from "../../../gleam_stdlib/gleam/list.mjs";
import * as $option from "../../../gleam_stdlib/gleam/option.mjs";
import * as $result from "../../../gleam_stdlib/gleam/result.mjs";
import * as $string from "../../../gleam_stdlib/gleam/string.mjs";
import * as $websocks from "../../../websocks/websocks.mjs";
import * as $socket from "../../collie/internal/socket.mjs";
import { Ok, Error, CustomType as $CustomType } from "../../gleam.mjs";

export class SocketFailed extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const DecodeError$SocketFailed = ($0) => new SocketFailed($0);
export const DecodeError$isSocketFailed = (value) =>
  value instanceof SocketFailed;
export const DecodeError$SocketFailed$0 = (value) => value[0];

export class MalformedRequest extends $CustomType {}
export const DecodeError$MalformedRequest = () => new MalformedRequest();
export const DecodeError$isMalformedRequest = (value) =>
  value instanceof MalformedRequest;

export class More extends $CustomType {
  constructor(length) {
    super();
    this.length = length;
  }
}
export const DecoderError$More = (length) => new More(length);
export const DecoderError$isMore = (value) => value instanceof More;
export const DecoderError$More$length = (value) => value.length;
export const DecoderError$More$0 = (value) => value.length;

export class HttpError extends $CustomType {
  constructor(reason) {
    super();
    this.reason = reason;
  }
}
export const DecoderError$HttpError = (reason) => new HttpError(reason);
export const DecoderError$isHttpError = (value) => value instanceof HttpError;
export const DecoderError$HttpError$reason = (value) => value.reason;
export const DecoderError$HttpError$0 = (value) => value.reason;

export class HttphBin extends $CustomType {}
export const PacketType$HttphBin = () => new HttphBin();
export const PacketType$isHttphBin = (value) => value instanceof HttphBin;

export class HttpBin extends $CustomType {}
export const PacketType$HttpBin = () => new HttpBin();
export const PacketType$isHttpBin = (value) => value instanceof HttpBin;

export class HttpResponse extends $CustomType {
  constructor(version, status, text) {
    super();
    this.version = version;
    this.status = status;
    this.text = text;
  }
}
export const Packet$HttpResponse = (version, status, text) =>
  new HttpResponse(version, status, text);
export const Packet$isHttpResponse = (value) => value instanceof HttpResponse;
export const Packet$HttpResponse$version = (value) => value.version;
export const Packet$HttpResponse$0 = (value) => value.version;
export const Packet$HttpResponse$status = (value) => value.status;
export const Packet$HttpResponse$1 = (value) => value.status;
export const Packet$HttpResponse$text = (value) => value.text;
export const Packet$HttpResponse$2 = (value) => value.text;

export class HttpHeader extends $CustomType {
  constructor(idx, field, value) {
    super();
    this.idx = idx;
    this.field = field;
    this.value = value;
  }
}
export const Packet$HttpHeader = (idx, field, value) =>
  new HttpHeader(idx, field, value);
export const Packet$isHttpHeader = (value) => value instanceof HttpHeader;
export const Packet$HttpHeader$idx = (value) => value.idx;
export const Packet$HttpHeader$0 = (value) => value.idx;
export const Packet$HttpHeader$field = (value) => value.field;
export const Packet$HttpHeader$1 = (value) => value.field;
export const Packet$HttpHeader$value = (value) => value.value;
export const Packet$HttpHeader$2 = (value) => value.value;

export class HttpEoh extends $CustomType {}
export const Packet$HttpEoh = () => new HttpEoh();
export const Packet$isHttpEoh = (value) => value instanceof HttpEoh;

function formatted_field_by_idx(idx) {
  if (idx === 0) {
    return new Error(undefined);
  } else if (idx === 1) {
    return new Ok("cache-control");
  } else if (idx === 2) {
    return new Ok("connection");
  } else if (idx === 3) {
    return new Ok("date");
  } else if (idx === 4) {
    return new Ok("pragma");
  } else if (idx === 5) {
    return new Ok("transfer-encoding");
  } else if (idx === 6) {
    return new Ok("upgrade");
  } else if (idx === 7) {
    return new Ok("via");
  } else if (idx === 8) {
    return new Ok("accept");
  } else if (idx === 9) {
    return new Ok("accept-charset");
  } else if (idx === 10) {
    return new Ok("accept-encoding");
  } else if (idx === 11) {
    return new Ok("accept-language");
  } else if (idx === 12) {
    return new Ok("authorization");
  } else if (idx === 13) {
    return new Ok("from");
  } else if (idx === 14) {
    return new Ok("host");
  } else if (idx === 15) {
    return new Ok("if-modified-since");
  } else if (idx === 16) {
    return new Ok("if-match");
  } else if (idx === 17) {
    return new Ok("if-none-match");
  } else if (idx === 18) {
    return new Ok("if-range");
  } else if (idx === 19) {
    return new Ok("if-unmodified-since");
  } else if (idx === 20) {
    return new Ok("max-forwards");
  } else if (idx === 21) {
    return new Ok("proxy-authorization");
  } else if (idx === 22) {
    return new Ok("range");
  } else if (idx === 23) {
    return new Ok("referer");
  } else if (idx === 24) {
    return new Ok("user-agent");
  } else if (idx === 25) {
    return new Ok("age");
  } else if (idx === 26) {
    return new Ok("location");
  } else if (idx === 27) {
    return new Ok("proxy-authenticate");
  } else if (idx === 28) {
    return new Ok("public");
  } else if (idx === 29) {
    return new Ok("retry-after");
  } else if (idx === 30) {
    return new Ok("server");
  } else if (idx === 31) {
    return new Ok("vary");
  } else if (idx === 32) {
    return new Ok("warning");
  } else if (idx === 33) {
    return new Ok("www-authenticate");
  } else if (idx === 34) {
    return new Ok("allow");
  } else if (idx === 35) {
    return new Ok("content-base");
  } else if (idx === 36) {
    return new Ok("content-encoding");
  } else if (idx === 37) {
    return new Ok("content-language");
  } else if (idx === 38) {
    return new Ok("content-length");
  } else if (idx === 39) {
    return new Ok("content-location");
  } else if (idx === 40) {
    return new Ok("content-md5");
  } else if (idx === 41) {
    return new Ok("content-range");
  } else if (idx === 42) {
    return new Ok("content-type");
  } else if (idx === 43) {
    return new Ok("etag");
  } else if (idx === 44) {
    return new Ok("expires");
  } else if (idx === 45) {
    return new Ok("last-modified");
  } else if (idx === 46) {
    return new Ok("accept-ranges");
  } else if (idx === 47) {
    return new Ok("set-cookie");
  } else if (idx === 48) {
    return new Ok("set-cookie2");
  } else if (idx === 49) {
    return new Ok("x-forwarded-for");
  } else if (idx === 50) {
    return new Ok("cookie");
  } else if (idx === 51) {
    return new Ok("keep-alive");
  } else if (idx === 52) {
    return new Ok("proxy-connection");
  } else {
    return new Error(undefined);
  }
}
