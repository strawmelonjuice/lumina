import * as $crypto from "../../gleam_crypto/gleam/crypto.mjs";
import * as $bit_array from "../../gleam_stdlib/gleam/bit_array.mjs";
import * as $int from "../../gleam_stdlib/gleam/int.mjs";
import * as $list from "../../gleam_stdlib/gleam/list.mjs";
import * as $result from "../../gleam_stdlib/gleam/result.mjs";
import * as $string from "../../gleam_stdlib/gleam/string.mjs";
import * as $timestamp from "../../gleam_time/gleam/time/timestamp.mjs";
import {
  Ok,
  Error,
  toList,
  CustomType as $CustomType,
  makeError,
  divideInt,
  toBitArray,
  bitArraySlice,
  bitArraySliceToInt,
  sizedInt,
} from "../gleam.mjs";

const FILEPATH = "src/youid/uuid.gleam";

class Uuid extends $CustomType {
  constructor(value) {
    super();
    this.value = value;
  }
}

export class V1 extends $CustomType {}
export const Version$V1 = () => new V1();
export const Version$isV1 = (value) => value instanceof V1;

export class V2 extends $CustomType {}
export const Version$V2 = () => new V2();
export const Version$isV2 = (value) => value instanceof V2;

export class V3 extends $CustomType {}
export const Version$V3 = () => new V3();
export const Version$isV3 = (value) => value instanceof V3;

export class V4 extends $CustomType {}
export const Version$V4 = () => new V4();
export const Version$isV4 = (value) => value instanceof V4;

export class V5 extends $CustomType {}
export const Version$V5 = () => new V5();
export const Version$isV5 = (value) => value instanceof V5;

export class V7 extends $CustomType {}
export const Version$V7 = () => new V7();
export const Version$isV7 = (value) => value instanceof V7;

export class VUnknown extends $CustomType {}
export const Version$VUnknown = () => new VUnknown();
export const Version$isVUnknown = (value) => value instanceof VUnknown;

export class ReservedFuture extends $CustomType {}
export const Variant$ReservedFuture = () => new ReservedFuture();
export const Variant$isReservedFuture = (value) =>
  value instanceof ReservedFuture;

export class ReservedMicrosoft extends $CustomType {}
export const Variant$ReservedMicrosoft = () => new ReservedMicrosoft();
export const Variant$isReservedMicrosoft = (value) =>
  value instanceof ReservedMicrosoft;

export class ReservedNcs extends $CustomType {}
export const Variant$ReservedNcs = () => new ReservedNcs();
export const Variant$isReservedNcs = (value) => value instanceof ReservedNcs;

export class Rfc4122 extends $CustomType {}
export const Variant$Rfc4122 = () => new Rfc4122();
export const Variant$isRfc4122 = (value) => value instanceof Rfc4122;

export class String extends $CustomType {}
export const Format$String = () => new String();
export const Format$isString = (value) => value instanceof String;

export class Hex extends $CustomType {}
export const Format$Hex = () => new Hex();
export const Format$isHex = (value) => value instanceof Hex;

export class Urn extends $CustomType {}
export const Format$Urn = () => new Urn();
export const Format$isUrn = (value) => value instanceof Urn;

export class DefaultNode extends $CustomType {}
export const V1Node$DefaultNode = () => new DefaultNode();
export const V1Node$isDefaultNode = (value) => value instanceof DefaultNode;

export class RandomNode extends $CustomType {}
export const V1Node$RandomNode = () => new RandomNode();
export const V1Node$isRandomNode = (value) => value instanceof RandomNode;

/**
 * Will be the provided sting, must be 12 characters long and valid hex
 */
export class CustomNode extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const V1Node$CustomNode = ($0) => new CustomNode($0);
export const V1Node$isCustomNode = (value) => value instanceof CustomNode;
export const V1Node$CustomNode$0 = (value) => value[0];

export class RandomClockSeq extends $CustomType {}
export const V1ClockSeq$RandomClockSeq = () => new RandomClockSeq();
export const V1ClockSeq$isRandomClockSeq = (value) =>
  value instanceof RandomClockSeq;

/**
 * Will be the provided bit string, must be exactly 14 bits.
 */
export class CustomClockSeq extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const V1ClockSeq$CustomClockSeq = ($0) => new CustomClockSeq($0);
export const V1ClockSeq$isCustomClockSeq = (value) =>
  value instanceof CustomClockSeq;
export const V1ClockSeq$CustomClockSeq$0 = (value) => value[0];

const ms_intervals_offset = 122_192_928_000_000;

const nanosec_intervals_factor = 10;

const rfc_variant = 2;

const urn_id = "urn:uuid:";

const v1_version = 1;

const v3_version = 3;

const v4_version = 4;

const v5_version = 5;

const v7_version = 7;

/**
 * The Nil UUID is special form of UUID that is specified to have all 128 bits
 * set to zero.
 * 
 * ```
 * 00000000-0000-0000-0000-000000000000
 * ```
 * 
 * A Nil UUID value can be useful to communicate the absence of any other UUID
 * value in situations that otherwise require or use a 128-bit UUID. A Nil UUID
 * can express the concept "no such value here". Thus, it is reserved for such
 * use as needed for implementation-specific situations.
 */
export const nil = /* @__PURE__ */ new Uuid(
  /* @__PURE__ */ toBitArray([sizedInt(0, 128, true)]),
);

/**
 * Convenience for quickly creating a Nil UUID String.
 */
export const nil_string = "00000000-0000-0000-0000-000000000000";

function random_uuid1_clockseq() {
  let $ = $crypto.strong_random_bytes(2);
  let clock_seq;
  if ($.bitSize >= 14 && $.bitSize === 16) {
    clock_seq = bitArraySliceToInt($, 0, 14, true, false);
  } else {
    throw makeError(
      "let_assert",
      FILEPATH,
      "youid/uuid",
      181,
      "random_uuid1_clockseq",
      "Pattern match failed, no pattern matched the value.",
      {
        value: $,
        start: 4541,
        end: 4617,
        pattern_start: 4552,
        pattern_end: 4585
      }
    )
  }
  return toBitArray([sizedInt(clock_seq, 14, true)]);
}

function validate_clock_seq(clock_seq) {
  if (clock_seq instanceof RandomClockSeq) {
    return new Ok(random_uuid1_clockseq());
  } else {
    let bs = clock_seq[0];
    let $ = $bit_array.bit_size(bs) === 14;
    if ($) {
      return new Ok(bs);
    } else {
      return new Error(undefined);
    }
  }
}

function random_uuid1_node() {
  let $ = $crypto.strong_random_bytes(6);
  let rnd_hi;
  let rnd_low;
  if ($.bitSize >= 7 && $.bitSize >= 8 && $.bitSize === 48) {
    rnd_hi = bitArraySliceToInt($, 0, 7, true, false);
    rnd_low = bitArraySliceToInt($, 8, 48, true, false);
  } else {
    throw makeError(
      "let_assert",
      FILEPATH,
      "youid/uuid",
      197,
      "random_uuid1_node",
      "Pattern match failed, no pattern matched the value.",
      {
        value: $,
        start: 5032,
        end: 5126,
        pattern_start: 5043,
        pattern_end: 5090
      }
    )
  }
  return toBitArray([
    sizedInt(rnd_hi, 7, true),
    sizedInt(1, 1, true),
    sizedInt(rnd_low, 40, true),
  ]);
}

function md5(data) {
  return $crypto.hash(new $crypto.Md5(), data);
}

function sha1(data) {
  let $ = $crypto.hash(new $crypto.Sha1(), data);
  let data$1;
  if ($.bitSize >= 128 && $.bitSize === 160) {
    data$1 = bitArraySlice($, 0, 128);
  } else {
    throw makeError(
      "let_assert",
      FILEPATH,
      "youid/uuid",
      280,
      "sha1",
      "Pattern match failed, no pattern matched the value.",
      {
        value: $,
        start: 6838,
        end: 6911,
        pattern_start: 6849,
        pattern_end: 6878
      }
    )
  }
  return data$1;
}

/**
 * Determine the time a UUID was created with Gregorian Epoch.
 *
 * This is only relevant to a V1 UUID.
 *
 * UUID's use 15 Oct 1582 as Epoch and time is measured in 100ns intervals.
 * This value is useful for comparing V1 UUIDs but not so much for
 * telling what time a UUID was created. See time_posix_microsec and clock_sequence.
 */
export function time(uuid) {
  let $ = uuid.value;
  let t_low;
  let t_mid;
  let t_hi;
  if (
    $.bitSize >= 32 &&
    $.bitSize >= 48 &&
    $.bitSize >= 52 &&
    $.bitSize >= 64 &&
    $.bitSize === 128
  ) {
    t_low = bitArraySliceToInt($, 0, 32, true, false);
    t_mid = bitArraySliceToInt($, 32, 48, true, false);
    t_hi = bitArraySliceToInt($, 52, 64, true, false);
  } else {
    throw makeError(
      "let_assert",
      FILEPATH,
      "youid/uuid",
      356,
      "time",
      "Pattern match failed, no pattern matched the value.",
      {
        value: $,
        start: 9014,
        end: 9080,
        pattern_start: 9025,
        pattern_end: 9067
      }
    )
  }
  let $1 = toBitArray([
    sizedInt(t_hi, 12, true),
    sizedInt(t_mid, 16, true),
    sizedInt(t_low, 32, true),
  ]);
  let t;
  if ($1.bitSize === 60) {
    t = bitArraySliceToInt($1, 0, 60, true, false);
  } else {
    throw makeError(
      "let_assert",
      FILEPATH,
      "youid/uuid",
      357,
      "time",
      "Pattern match failed, no pattern matched the value.",
      {
        value: $1,
        start: 9083,
        end: 9136,
        pattern_start: 9094,
        pattern_end: 9102
      }
    )
  }
  return t;
}

/**
 * Determine the clock sequence of a UUID
 * This is only relevant to a V1 UUID
 */
export function clock_sequence(uuid) {
  let $ = uuid.value;
  let clock_seq;
  if ($.bitSize >= 66 && $.bitSize >= 80 && $.bitSize === 128) {
    clock_seq = bitArraySliceToInt($, 66, 80, true, false);
  } else {
    throw makeError(
      "let_assert",
      FILEPATH,
      "youid/uuid",
      379,
      "clock_sequence",
      "Pattern match failed, no pattern matched the value.",
      {
        value: $,
        start: 9668,
        end: 9720,
        pattern_start: 9679,
        pattern_end: 9707
      }
    )
  }
  return clock_seq;
}

/**
 * Determine the node of a UUID
 * This is only relevant to a V1 UUID
 */
export function node(uuid) {
  let $ = uuid.value;
  let a;
  let b;
  let c;
  let d;
  let e;
  let f;
  let g;
  let h;
  let i;
  let j;
  let k;
  let l;
  if (
    $.bitSize >= 80 &&
    $.bitSize >= 84 &&
    $.bitSize >= 88 &&
    $.bitSize >= 92 &&
    $.bitSize >= 96 &&
    $.bitSize >= 100 &&
    $.bitSize >= 104 &&
    $.bitSize >= 108 &&
    $.bitSize >= 112 &&
    $.bitSize >= 116 &&
    $.bitSize >= 120 &&
    $.bitSize >= 124 &&
    $.bitSize === 128
  ) {
    a = bitArraySliceToInt($, 80, 84, true, false);
    b = bitArraySliceToInt($, 84, 88, true, false);
    c = bitArraySliceToInt($, 88, 92, true, false);
    d = bitArraySliceToInt($, 92, 96, true, false);
    e = bitArraySliceToInt($, 96, 100, true, false);
    f = bitArraySliceToInt($, 100, 104, true, false);
    g = bitArraySliceToInt($, 104, 108, true, false);
    h = bitArraySliceToInt($, 108, 112, true, false);
    i = bitArraySliceToInt($, 112, 116, true, false);
    j = bitArraySliceToInt($, 116, 120, true, false);
    k = bitArraySliceToInt($, 120, 124, true, false);
    l = bitArraySliceToInt($, 124, 128, true, false);
  } else {
    throw makeError(
      "let_assert",
      FILEPATH,
      "youid/uuid",
      386,
      "node",
      "Pattern match failed, no pattern matched the value.",
      {
        value: $,
        start: 9846,
        end: 9995,
        pattern_start: 9857,
        pattern_end: 9982
      }
    )
  }
  let _pipe = toList([a, b, c, d, e, f, g, h, i, j, k, l]);
  let _pipe$1 = $list.map(_pipe, $int.to_base16);
  return $string.concat(_pipe$1);
}

function to_string_help(loop$ints, loop$position, loop$acc, loop$separator) {
  while (true) {
    let ints = loop$ints;
    let position = loop$position;
    let acc = loop$acc;
    let separator = loop$separator;
    if (position === 8) {
      loop$ints = ints;
      loop$position = position + 1;
      loop$acc = acc + separator;
      loop$separator = separator;
    } else if (position === 13) {
      loop$ints = ints;
      loop$position = position + 1;
      loop$acc = acc + separator;
      loop$separator = separator;
    } else if (position === 18) {
      loop$ints = ints;
      loop$position = position + 1;
      loop$acc = acc + separator;
      loop$separator = separator;
    } else if (position === 23) {
      loop$ints = ints;
      loop$position = position + 1;
      loop$acc = acc + separator;
      loop$separator = separator;
    } else {
      if (ints.bitSize >= 4) {
        let i = bitArraySliceToInt(ints, 0, 4, true, false);
        let rest = bitArraySlice(ints, 4);
        let _block;
        let _pipe = $int.to_base16(i);
        _block = $string.lowercase(_pipe);
        let string = _block;
        loop$ints = rest;
        loop$position = position + 1;
        loop$acc = acc + string;
        loop$separator = separator;
      } else {
        return acc;
      }
    }
  }
}

/**
 * dns namespace UUID provided by the spec, only useful for v3 and v5
 */
export function dns_uuid() {
  return new Uuid(
    toBitArray([
      107,
      167,
      184,
      16,
      157,
      173,
      17,
      209,
      128,
      180,
      0,
      192,
      79,
      212,
      48,
      200,
    ]),
  );
}

/**
 * url namespace UUID provided by the spec, only useful for v3 and v5
 */
export function url_uuid() {
  return new Uuid(
    toBitArray([
      107,
      167,
      184,
      17,
      157,
      173,
      17,
      209,
      128,
      180,
      0,
      192,
      79,
      212,
      48,
      200,
    ]),
  );
}

/**
 * oid namespace UUID provided by the spec, only useful for v3 and v5
 */
export function oid_uuid() {
  return new Uuid(
    toBitArray([
      107,
      167,
      184,
      18,
      157,
      173,
      17,
      209,
      128,
      180,
      0,
      192,
      79,
      212,
      48,
      200,
    ]),
  );
}

/**
 * x500 namespace UUID provided by the spec, only useful for v3 and v5
 */
export function x500_uuid() {
  return new Uuid(
    toBitArray([
      107,
      167,
      184,
      19,
      157,
      173,
      17,
      209,
      128,
      180,
      0,
      192,
      79,
      212,
      48,
      200,
    ]),
  );
}

/**
 * Convert a UUID to a bit array
 */
export function to_bit_array(uuid) {
  return uuid.value;
}

/**
 * Convert a UUID to a URL-safe base-64 string.
 *
 * The output is 22 characters long and URL-safe, making it an ideal format
 * for ids in paths and APIs.
 */
export function to_base64(uuid) {
  return $bit_array.base64_url_encode(uuid.value, false);
}

/**
 * Attempt to decode a UUID from a URL-safe base-64 string.
 *
 * Supports unpadded 22 character uuids and padded 24 character uuids.
 */
export function from_base64(in$) {
  return $result.try$(
    (() => {
      let $ = $string.byte_size(in$);
      if ($ === 22) {
        return new Ok(in$ + "==");
      } else if ($ === 24) {
        return new Ok(in$);
      } else {
        return new Error(undefined);
      }
    })(),
    (padded) => {
      return $result.try$(
        $bit_array.base64_url_decode(padded),
        (bits) => {
          let $ = $bit_array.byte_size(bits);
          if ($ === 16) {
            return new Ok(new Uuid(bits));
          } else {
            return new Error(undefined);
          }
        },
      );
    },
  );
}

function decode_version(int) {
  if (int === 1) {
    return new V1();
  } else if (int === 2) {
    return new V2();
  } else if (int === 3) {
    return new V3();
  } else if (int === 4) {
    return new V4();
  } else if (int === 5) {
    return new V5();
  } else if (int === 7) {
    return new V7();
  } else {
    return new VUnknown();
  }
}

/**
 * Determine the Version of a UUID
 */
export function version(uuid) {
  let $ = uuid.value;
  let ver;
  if ($.bitSize >= 48 && $.bitSize >= 52 && $.bitSize === 128) {
    ver = bitArraySliceToInt($, 48, 52, true, false);
  } else {
    throw makeError(
      "let_assert",
      FILEPATH,
      "youid/uuid",
      338,
      "version",
      "Pattern match failed, no pattern matched the value.",
      {
        value: $,
        start: 8410,
        end: 8455,
        pattern_start: 8421,
        pattern_end: 8442
      }
    )
  }
  return decode_version(ver);
}

/**
 * Attemts to convert a bit array to a UUID.
 * Will fail if the bit array is not 16 bytes long or has an invalid version.
 */
export function from_bit_array(bit_array) {
  let uuid = new Uuid(bit_array);
  let $ = $bit_array.byte_size(bit_array);
  if ($ === 16) {
    let $1 = version(uuid);
    if ($1 instanceof VUnknown) {
      return new Error(undefined);
    } else {
      return new Ok(uuid);
    }
  } else {
    return new Error(undefined);
  }
}

function decode_variant(variant_bits) {
  if (variant_bits.bitSize >= 1) {
    if (bitArraySliceToInt(variant_bits, 0, 1, true, false) === 1) {
      if (variant_bits.bitSize >= 2) {
        if (bitArraySliceToInt(variant_bits, 1, 2, true, false) === 1) {
          if (variant_bits.bitSize === 3) {
            if (bitArraySliceToInt(variant_bits, 2, 3, true, false) === 1) {
              return new ReservedFuture();
            } else if (bitArraySliceToInt(variant_bits, 2, 3, true, false) === 0) {
              return new ReservedMicrosoft();
            } else {
              return new ReservedNcs();
            }
          } else {
            return new ReservedNcs();
          }
        } else if (
          bitArraySliceToInt(variant_bits, 1, 2, true, false) === 0 &&
          variant_bits.bitSize === 3
        ) {
          return new Rfc4122();
        } else {
          return new ReservedNcs();
        }
      } else {
        return new ReservedNcs();
      }
    } else if (
      bitArraySliceToInt(variant_bits, 0, 1, true, false) === 0 &&
      variant_bits.bitSize >= 2 &&
      variant_bits.bitSize === 3
    ) {
      return new ReservedNcs();
    } else {
      return new ReservedNcs();
    }
  } else {
    return new ReservedNcs();
  }
}

/**
 * Determine the Variant of a UUID
 */
export function variant(uuid) {
  let $ = uuid.value;
  let var$;
  if ($.bitSize >= 64 && $.bitSize >= 67 && $.bitSize === 128) {
    var$ = bitArraySliceToInt($, 64, 67, true, false);
  } else {
    throw makeError(
      "let_assert",
      FILEPATH,
      "youid/uuid",
      344,
      "variant",
      "Pattern match failed, no pattern matched the value.",
      {
        value: $,
        start: 8559,
        end: 8604,
        pattern_start: 8570,
        pattern_end: 8591
      }
    )
  }
  return decode_variant(toBitArray([sizedInt(var$, 3, true)]));
}

function hex_to_int(c) {
  let _block;
  if (c === "0") {
    _block = 0;
  } else if (c === "1") {
    _block = 1;
  } else if (c === "2") {
    _block = 2;
  } else if (c === "3") {
    _block = 3;
  } else if (c === "4") {
    _block = 4;
  } else if (c === "5") {
    _block = 5;
  } else if (c === "6") {
    _block = 6;
  } else if (c === "7") {
    _block = 7;
  } else if (c === "8") {
    _block = 8;
  } else if (c === "9") {
    _block = 9;
  } else if (c === "a") {
    _block = 10;
  } else if (c === "A") {
    _block = 10;
  } else if (c === "b") {
    _block = 11;
  } else if (c === "B") {
    _block = 11;
  } else if (c === "c") {
    _block = 12;
  } else if (c === "C") {
    _block = 12;
  } else if (c === "d") {
    _block = 13;
  } else if (c === "D") {
    _block = 13;
  } else if (c === "e") {
    _block = 14;
  } else if (c === "E") {
    _block = 14;
  } else if (c === "f") {
    _block = 15;
  } else if (c === "F") {
    _block = 15;
  } else {
    _block = 16;
  }
  let i = _block;
  if (i === 16) {
    return new Error(undefined);
  } else {
    let x = i;
    return new Ok(x);
  }
}

function validate_custom_node(loop$str, loop$index, loop$acc) {
  while (true) {
    let str = loop$str;
    let index = loop$index;
    let acc = loop$acc;
    let $ = $string.pop_grapheme(str);
    if ($ instanceof Ok) {
      let $1 = $[0][0];
      if ($1 === ":") {
        let rest = $[0][1];
        loop$str = rest;
        loop$index = index;
        loop$acc = acc;
      } else {
        let c = $1;
        let rest = $[0][1];
        let $2 = hex_to_int(c);
        if ($2 instanceof Ok && index < 12) {
          let i = $2[0];
          loop$str = rest;
          loop$index = index + 1;
          loop$acc = toBitArray([acc, sizedInt(i, 4, true)]);
        } else {
          return new Error(undefined);
        }
      }
    } else if (index === 12) {
      return new Ok(acc);
    } else {
      return new Error(undefined);
    }
  }
}

function to_bitstring_help(loop$str, loop$index, loop$acc) {
  while (true) {
    let str = loop$str;
    let index = loop$index;
    let acc = loop$acc;
    let $ = $string.pop_grapheme(str);
    if ($ instanceof Ok) {
      let $1 = $[0][0];
      if ($1 === "-" && index < 32) {
        let rest = $[0][1];
        loop$str = rest;
        loop$index = index;
        loop$acc = acc;
      } else if (index < 32) {
        let c = $1;
        let rest = $[0][1];
        let $2 = hex_to_int(c);
        if ($2 instanceof Ok) {
          let i = $2[0];
          loop$str = rest;
          loop$index = index + 1;
          loop$acc = toBitArray([acc, sizedInt(i, 4, true)]);
        } else {
          return new Error(undefined);
        }
      } else {
        return new Error(undefined);
      }
    } else if (index === 32) {
      return new Ok(acc);
    } else {
      return new Error(undefined);
    }
  }
}

function to_bit_array_helper(str) {
  return to_bitstring_help(str, 0, toBitArray([]));
}

/**
 * Attempt to decode a UUID from a string. Supports strings formatted in the same
 * ways this library will output them. Hex with dashes, hex without dashes and
 * hex with or without dashes prepended with "urn:uuid:"
 */
export function from_string(in$) {
  let _block;
  if (in$.startsWith("urn:uuid:")) {
    let in$1 = in$.slice(9);
    _block = in$1;
  } else {
    _block = in$;
  }
  let hex = _block;
  let $ = to_bit_array_helper(hex);
  if ($ instanceof Ok) {
    let bits = $[0];
    return new Ok(new Uuid(bits));
  } else {
    return new Error(undefined);
  }
}

function mac_address() {
  return new Error(undefined);
}

function default_uuid1_node() {
  let $ = mac_address();
  if ($ instanceof Ok) {
    let node$1 = $[0];
    return node$1;
  } else {
    return random_uuid1_node();
  }
}

function validate_node(node) {
  if (node instanceof DefaultNode) {
    return new Ok(default_uuid1_node());
  } else if (node instanceof RandomNode) {
    return new Ok(random_uuid1_node());
  } else {
    let str = node[0];
    return validate_custom_node(str, 0, toBitArray([]));
  }
}

function uuid1_time() {
  let _block;
  let _pipe = $timestamp.system_time();
  _block = $timestamp.to_unix_seconds_and_nanoseconds(_pipe);
  let $ = _block;
  let sec;
  let ns;
  sec = $[0];
  ns = $[1];
  let time$1 = (sec * 10_000_000 + (globalThis.Math.trunc(ns / 100))) + ms_intervals_offset * 1000;
  return toBitArray([sizedInt(time$1, 60, true)]);
}

/**
 * Determine the time a UUID was created with.
 *
 * This is only relevant to V1 and V7 UUIDs.
 *
 * Value is the number of micro seconds since Unix Epoch.
 */
export function time_posix_microsec(uuid) {
  let $ = version(uuid);
  if ($ instanceof V7) {
    let $1 = uuid.value;
    let t;
    if ($1.bitSize >= 48 && $1.bitSize === 128) {
      t = bitArraySliceToInt($1, 0, 48, true, false);
    } else {
      throw makeError(
        "let_assert",
        FILEPATH,
        "youid/uuid",
        369,
        "time_posix_microsec",
        "Pattern match failed, no pattern matched the value.",
        {
          value: $1,
          start: 9394,
          end: 9432,
          pattern_start: 9405,
          pattern_end: 9419
        }
      )
    }
    return t * 1000;
  } else {
    return divideInt(
      (time(uuid) - ms_intervals_offset * 1000),
      nanosec_intervals_factor
    );
  }
}

/**
 * Determine the time a UUID was created with Unix Epoch
 * This is only relevant to V1 and V7 UUIDs
 * Value is the number of milli seconds since Unix Epoch
 */
export function time_posix_millisec(uuid) {
  let $ = version(uuid);
  if ($ instanceof V1) {
    return globalThis.Math.trunc(
      (divideInt(
        (time(uuid) - ms_intervals_offset * 1000),
        nanosec_intervals_factor
      )) / 1000
    );
  } else {
    let $1 = uuid.value;
    let t;
    if ($1.bitSize >= 48 && $1.bitSize === 128) {
      t = bitArraySliceToInt($1, 0, 48, true, false);
    } else {
      throw makeError(
        "let_assert",
        FILEPATH,
        "youid/uuid",
        415,
        "time_posix_millisec",
        "Pattern match failed, no pattern matched the value.",
        {
          value: $1,
          start: 10441,
          end: 10479,
          pattern_start: 10452,
          pattern_end: 10466
        }
      )
    }
    return t;
  }
}

function hash_to_uuid_value(hash, ver) {
  let time_low;
  let time_mid;
  let time_hi;
  let clock_seq_hi;
  let clock_seq_low;
  let node$1;
  if (
    hash.bitSize >= 32 &&
    hash.bitSize >= 48 &&
    hash.bitSize >= 52 &&
    hash.bitSize >= 64 &&
    hash.bitSize >= 66 &&
    hash.bitSize >= 72 &&
    hash.bitSize >= 80 &&
    hash.bitSize === 128
  ) {
    time_low = bitArraySliceToInt(hash, 0, 32, true, false);
    time_mid = bitArraySliceToInt(hash, 32, 48, true, false);
    time_hi = bitArraySliceToInt(hash, 52, 64, true, false);
    clock_seq_hi = bitArraySliceToInt(hash, 66, 72, true, false);
    clock_seq_low = hash.byteAt(9);
    node$1 = bitArraySliceToInt(hash, 80, 128, true, false);
  } else {
    throw makeError(
      "let_assert",
      FILEPATH,
      "youid/uuid",
      224,
      "hash_to_uuid_value",
      "Pattern match failed, no pattern matched the value.",
      {
        value: hash,
        start: 5703,
        end: 5850,
        pattern_start: 5714,
        pattern_end: 5843
      }
    )
  }
  return toBitArray([
    sizedInt(time_low, 32, true),
    sizedInt(time_mid, 16, true),
    sizedInt(ver, 4, true),
    sizedInt(time_hi, 12, true),
    sizedInt(rfc_variant, 2, true),
    sizedInt(clock_seq_hi, 6, true),
    clock_seq_low,
    sizedInt(node$1, 48, true),
  ]);
}

/**
 * Convert a UUID to one of the supported string formats
 */
export function format(uuid, format) {
  let _block;
  if (format instanceof String) {
    _block = "-";
  } else {
    _block = "";
  }
  let separator = _block;
  let _block$1;
  if (format instanceof Urn) {
    _block$1 = urn_id;
  } else {
    _block$1 = "";
  }
  let start = _block$1;
  return to_string_help(uuid.value, 0, start, separator);
}

/**
 * Convert a UUID to a standard string
 */
export function to_string(uuid) {
  return format(uuid, new String());
}

function do_v1(node, clock_seq) {
  let node$1;
  if (node.bitSize === 48) {
    node$1 = bitArraySliceToInt(node, 0, 48, true, false);
  } else {
    throw makeError(
      "let_assert",
      FILEPATH,
      "youid/uuid",
      119,
      "do_v1",
      "Pattern match failed, no pattern matched the value.",
      {
        value: node,
        start: 2902,
        end: 2931,
        pattern_start: 2913,
        pattern_end: 2924
      }
    )
  }
  let $ = uuid1_time();
  let time_hi;
  let time_mid;
  let time_low;
  if ($.bitSize >= 12 && $.bitSize >= 28 && $.bitSize === 60) {
    time_hi = bitArraySliceToInt($, 0, 12, true, false);
    time_mid = bitArraySliceToInt($, 12, 28, true, false);
    time_low = bitArraySliceToInt($, 28, 60, true, false);
  } else {
    throw makeError(
      "let_assert",
      FILEPATH,
      "youid/uuid",
      120,
      "do_v1",
      "Pattern match failed, no pattern matched the value.",
      {
        value: $,
        start: 2934,
        end: 3000,
        pattern_start: 2945,
        pattern_end: 2985
      }
    )
  }
  let clock_seq$1;
  if (clock_seq.bitSize === 14) {
    clock_seq$1 = bitArraySliceToInt(clock_seq, 0, 14, true, false);
  } else {
    throw makeError(
      "let_assert",
      FILEPATH,
      "youid/uuid",
      121,
      "do_v1",
      "Pattern match failed, no pattern matched the value.",
      {
        value: clock_seq,
        start: 3003,
        end: 3042,
        pattern_start: 3014,
        pattern_end: 3030
      }
    )
  }
  let value = toBitArray([
    sizedInt(time_low, 32, true),
    sizedInt(time_mid, 16, true),
    sizedInt(v1_version, 4, true),
    sizedInt(time_hi, 12, true),
    sizedInt(rfc_variant, 2, true),
    sizedInt(clock_seq$1, 14, true),
    sizedInt(node$1, 48, true),
  ]);
  return new Uuid(value);
}

/**
 * Create a V1 (time-based) UUID with default node and random clock sequence.
 */
export function v1() {
  return do_v1(default_uuid1_node(), random_uuid1_clockseq());
}

/**
 * Convenience for quickly creating a time-based UUID String with default settings.
 */
export function v1_string() {
  let _pipe = v1();
  return to_string(_pipe);
}

/**
 * Create a V1 (time-based) UUID with custom node and clock sequence.
 */
export function v1_custom(node, clock_seq) {
  let $ = validate_node(node);
  let $1 = validate_clock_seq(clock_seq);
  if ($ instanceof Ok && $1 instanceof Ok) {
    let n = $[0];
    let cs = $1[0];
    return new Ok(do_v1(n, cs));
  } else {
    return new Error(undefined);
  }
}

/**
 * Generates a version 3 (name-based, md5 hashed) UUID.
 * Name must be a valid sequence of bytes
 */
export function v3(namespace, name) {
  let $ = ($bit_array.bit_size(name) % 8) === 0;
  if ($) {
    let _pipe = toBitArray([namespace.value, name]);
    let _pipe$1 = md5(_pipe);
    let _pipe$2 = hash_to_uuid_value(_pipe$1, v3_version);
    let _pipe$3 = new Uuid(_pipe$2);
    return new Ok(_pipe$3);
  } else {
    return new Error(undefined);
  }
}

/**
 * Generates a version 4 (random) UUID.
 */
export function v4() {
  let $ = $crypto.strong_random_bytes(16);
  let a;
  let b;
  let c;
  if (
    $.bitSize >= 48 &&
    $.bitSize >= 52 &&
    $.bitSize >= 64 &&
    $.bitSize >= 66 &&
    $.bitSize === 128
  ) {
    a = bitArraySliceToInt($, 0, 48, true, false);
    b = bitArraySliceToInt($, 52, 64, true, false);
    c = bitArraySliceToInt($, 66, 128, true, false);
  } else {
    throw makeError(
      "let_assert",
      FILEPATH,
      "youid/uuid",
      246,
      "v4",
      "Pattern match failed, no pattern matched the value.",
      {
        value: $,
        start: 6052,
        end: 6160,
        pattern_start: 6063,
        pattern_end: 6123
      }
    )
  }
  let value = toBitArray([
    sizedInt(a, 48, true),
    sizedInt(v4_version, 4, true),
    sizedInt(b, 12, true),
    sizedInt(rfc_variant, 2, true),
    sizedInt(c, 62, true),
  ]);
  return new Uuid(value);
}

/**
 * Convenience for quickly creating a random UUID String
 */
export function v4_string() {
  let _pipe = v4();
  return format(_pipe, new String());
}

/**
 * Generates a version 5 (name-based, sha1 hashed) UUID.
 * name must be a valid sequence of bytes
 */
export function v5(namespace, name) {
  let $ = ($bit_array.bit_size(name) % 8) === 0;
  if ($) {
    let _pipe = toBitArray([namespace.value, name]);
    let _pipe$1 = sha1(_pipe);
    let _pipe$2 = hash_to_uuid_value(_pipe$1, v5_version);
    let _pipe$3 = new Uuid(_pipe$2);
    return new Ok(_pipe$3);
  } else {
    return new Error(undefined);
  }
}

/**
 * Creates a version 7 UUID from a specific UNIX timestamp.
 * Integer should be milliseconds from UNIX epoch.
 */
export function v7_from_millisec(timestamp) {
  let $ = $crypto.strong_random_bytes(10);
  let a;
  let b;
  if ($.bitSize >= 12 && $.bitSize >= 74 && $.bitSize === 80) {
    a = bitArraySliceToInt($, 0, 12, true, false);
    b = bitArraySliceToInt($, 12, 74, true, false);
  } else {
    throw makeError(
      "let_assert",
      FILEPATH,
      "youid/uuid",
      299,
      "v7_from_millisec",
      "Pattern match failed, no pattern matched the value.",
      {
        value: $,
        start: 7321,
        end: 7406,
        pattern_start: 7332,
        pattern_end: 7369
      }
    )
  }
  let value = toBitArray([
    sizedInt(timestamp, 48, true),
    sizedInt(v7_version, 4, true),
    sizedInt(a, 12, true),
    sizedInt(rfc_variant, 2, true),
    sizedInt(b, 62, true),
  ]);
  return new Uuid(value);
}

/**
 * Generates a version 7 (timestamp-based) UUID.
 */
export function v7() {
  let _block;
  let _pipe = $timestamp.system_time();
  _block = $timestamp.to_unix_seconds_and_nanoseconds(_pipe);
  let $ = _block;
  let sec;
  let ns;
  sec = $[0];
  ns = $[1];
  return v7_from_millisec(sec * 1000 + (globalThis.Math.trunc(ns / 1_000_000)));
}

/**
 * Convenience function for quickly creating a timestamp-based
 * version 7 UUID
 */
export function v7_string() {
  let _pipe = v7();
  return format(_pipe, new String());
}
