import * as $http from "../../../gleam_http/gleam/http.mjs";
import * as $dynamic from "../../../gleam_stdlib/gleam/dynamic.mjs";
import * as $option from "../../../gleam_stdlib/gleam/option.mjs";
import * as $buffer from "../../ewe/internal/http1/buffer.mjs";
import { Ok, Error, CustomType as $CustomType } from "../../gleam.mjs";

export class HttpBin extends $CustomType {}
export const PacketType$HttpBin = () => new HttpBin();
export const PacketType$isHttpBin = (value) => value instanceof HttpBin;

export class HttphBin extends $CustomType {}
export const PacketType$HttphBin = () => new HttphBin();
export const PacketType$isHttphBin = (value) => value instanceof HttphBin;

export class AbsPath extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const AbsPath$AbsPath = ($0) => new AbsPath($0);
export const AbsPath$isAbsPath = (value) => value instanceof AbsPath;
export const AbsPath$AbsPath$0 = (value) => value[0];

export class HttpRequest extends $CustomType {
  constructor(method, path, version) {
    super();
    this.method = method;
    this.path = path;
    this.version = version;
  }
}
export const HttpPacket$HttpRequest = (method, path, version) =>
  new HttpRequest(method, path, version);
export const HttpPacket$isHttpRequest = (value) => value instanceof HttpRequest;
export const HttpPacket$HttpRequest$method = (value) => value.method;
export const HttpPacket$HttpRequest$0 = (value) => value.method;
export const HttpPacket$HttpRequest$path = (value) => value.path;
export const HttpPacket$HttpRequest$1 = (value) => value.path;
export const HttpPacket$HttpRequest$version = (value) => value.version;
export const HttpPacket$HttpRequest$2 = (value) => value.version;

export class HttpHeader extends $CustomType {
  constructor(idx, field, value) {
    super();
    this.idx = idx;
    this.field = field;
    this.value = value;
  }
}
export const HttpPacket$HttpHeader = (idx, field, value) =>
  new HttpHeader(idx, field, value);
export const HttpPacket$isHttpHeader = (value) => value instanceof HttpHeader;
export const HttpPacket$HttpHeader$idx = (value) => value.idx;
export const HttpPacket$HttpHeader$0 = (value) => value.idx;
export const HttpPacket$HttpHeader$field = (value) => value.field;
export const HttpPacket$HttpHeader$1 = (value) => value.field;
export const HttpPacket$HttpHeader$value = (value) => value.value;
export const HttpPacket$HttpHeader$2 = (value) => value.value;

export class HttpEoh extends $CustomType {}
export const HttpPacket$HttpEoh = () => new HttpEoh();
export const HttpPacket$isHttpEoh = (value) => value instanceof HttpEoh;

export class Http2Upgrade extends $CustomType {}
export const HttpPacket$Http2Upgrade = () => new Http2Upgrade();
export const HttpPacket$isHttp2Upgrade = (value) =>
  value instanceof Http2Upgrade;

export class Packet extends $CustomType {
  constructor($0, rest) {
    super();
    this[0] = $0;
    this.rest = rest;
  }
}
export const Packet$Packet = ($0, rest) => new Packet($0, rest);
export const Packet$isPacket = (value) => value instanceof Packet;
export const Packet$Packet$0 = (value) => value[0];
export const Packet$Packet$rest = (value) => value.rest;
export const Packet$Packet$1 = (value) => value.rest;

export class More extends $CustomType {
  constructor(length) {
    super();
    this.length = length;
  }
}
export const Packet$More = (length) => new More(length);
export const Packet$isMore = (value) => value instanceof More;
export const Packet$More$length = (value) => value.length;
export const Packet$More$0 = (value) => value.length;

/**
 * Decodes HTTP method from binary data.
 */
export function decode_method(method) {
  if (method.bitSize === 24) {
    if (
      method.byteAt(0) === 71 &&
        method.byteAt(1) === 69 &&
        method.byteAt(2) === 84
    ) {
      return new Ok(new $http.Get());
    } else if (
      method.byteAt(0) === 80 &&
        method.byteAt(1) === 85 &&
        method.byteAt(2) === 84
    ) {
      return new Ok(new $http.Put());
    } else {
      return new Error(undefined);
    }
  } else if (method.bitSize === 32) {
    if (
      method.byteAt(0) === 80 &&
        method.byteAt(1) === 79 &&
        method.byteAt(2) === 83 &&
        method.byteAt(3) === 84
    ) {
      return new Ok(new $http.Post());
    } else if (
      method.byteAt(0) === 72 &&
        method.byteAt(1) === 69 &&
        method.byteAt(2) === 65 &&
        method.byteAt(3) === 68
    ) {
      return new Ok(new $http.Head());
    } else {
      return new Error(undefined);
    }
  } else if (method.bitSize === 48) {
    if (
      method.byteAt(0) === 68 &&
        method.byteAt(1) === 69 &&
        method.byteAt(2) === 76 &&
        method.byteAt(3) === 69 &&
        method.byteAt(4) === 84 &&
        method.byteAt(5) === 69
    ) {
      return new Ok(new $http.Delete());
    } else {
      return new Error(undefined);
    }
  } else if (method.bitSize === 40) {
    if (
      method.byteAt(0) === 84 &&
        method.byteAt(1) === 82 &&
        method.byteAt(2) === 65 &&
        method.byteAt(3) === 67 &&
        method.byteAt(4) === 69
    ) {
      return new Ok(new $http.Trace());
    } else if (
      method.byteAt(0) === 80 &&
        method.byteAt(1) === 65 &&
        method.byteAt(2) === 84 &&
        method.byteAt(3) === 67 &&
        method.byteAt(4) === 72
    ) {
      return new Ok(new $http.Patch());
    } else {
      return new Error(undefined);
    }
  } else if (method.bitSize === 56) {
    if (
      method.byteAt(0) === 67 &&
        method.byteAt(1) === 79 &&
        method.byteAt(2) === 78 &&
        method.byteAt(3) === 78 &&
        method.byteAt(4) === 69 &&
        method.byteAt(5) === 67 &&
        method.byteAt(6) === 84
    ) {
      return new Ok(new $http.Connect());
    } else if (
      method.byteAt(0) === 79 &&
        method.byteAt(1) === 80 &&
        method.byteAt(2) === 84 &&
        method.byteAt(3) === 73 &&
        method.byteAt(4) === 79 &&
        method.byteAt(5) === 78 &&
        method.byteAt(6) === 83
    ) {
      return new Ok(new $http.Options());
    } else {
      return new Error(undefined);
    }
  } else {
    return new Error(undefined);
  }
}

/**
 * Maps header field indices to their string names.
 */
export function formatted_field_by_idx(idx) {
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
