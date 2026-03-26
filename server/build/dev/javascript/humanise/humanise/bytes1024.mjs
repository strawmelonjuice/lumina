import * as $bool from "../../gleam_stdlib/gleam/bool.mjs";
import * as $float from "../../gleam_stdlib/gleam/float.mjs";
import { CustomType as $CustomType, divideFloat } from "../gleam.mjs";
import * as $util from "../humanise/util.mjs";

export class Bytes extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Bytes$Bytes = ($0) => new Bytes($0);
export const Bytes$isBytes = (value) => value instanceof Bytes;
export const Bytes$Bytes$0 = (value) => value[0];

export class Kibibytes extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Bytes$Kibibytes = ($0) => new Kibibytes($0);
export const Bytes$isKibibytes = (value) => value instanceof Kibibytes;
export const Bytes$Kibibytes$0 = (value) => value[0];

export class Mebibytes extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Bytes$Mebibytes = ($0) => new Mebibytes($0);
export const Bytes$isMebibytes = (value) => value instanceof Mebibytes;
export const Bytes$Mebibytes$0 = (value) => value[0];

export class Gibibytes extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Bytes$Gibibytes = ($0) => new Gibibytes($0);
export const Bytes$isGibibytes = (value) => value instanceof Gibibytes;
export const Bytes$Gibibytes$0 = (value) => value[0];

export class Tebibytes extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Bytes$Tebibytes = ($0) => new Tebibytes($0);
export const Bytes$isTebibytes = (value) => value instanceof Tebibytes;
export const Bytes$Tebibytes$0 = (value) => value[0];

const kibibyte = 1024.0;

const mebibyte = 1_048_576.0;

const gibibyte = 1_073_741_824.0;

const tebibyte = 1_099_511_627_776.0;

/**
 * Format a value as a `String`, rounded to at most 2 decimal places, followed by a unit suffix.
 *
 * Example:
 * ```
 * bytes1024.Gibibytes(30.125) |> bytes1024.to_string // "30.13GiB"
 * ```
 */
export function to_string(bytes) {
  let _block;
  if (bytes instanceof Bytes) {
    let n = bytes[0];
    _block = [n, "B"];
  } else if (bytes instanceof Kibibytes) {
    let n = bytes[0];
    _block = [n, "KiB"];
  } else if (bytes instanceof Mebibytes) {
    let n = bytes[0];
    _block = [n, "MiB"];
  } else if (bytes instanceof Gibibytes) {
    let n = bytes[0];
    _block = [n, "GiB"];
  } else {
    let n = bytes[0];
    _block = [n, "TiB"];
  }
  let $ = _block;
  let n;
  let suffix;
  n = $[0];
  suffix = $[1];
  return $util.format(n, suffix);
}

/**
 * Convert a value to bytes.
 *
 * Example:
 * ```
 * bytes1024.Kibibytes(1.0) |> bytes1024.as_bytes // 1024.0
 * ```
 */
export function as_bytes(bytes) {
  if (bytes instanceof Bytes) {
    let n = bytes[0];
    return n;
  } else if (bytes instanceof Kibibytes) {
    let n = bytes[0];
    return n * kibibyte;
  } else if (bytes instanceof Mebibytes) {
    let n = bytes[0];
    return n * mebibyte;
  } else if (bytes instanceof Gibibytes) {
    let n = bytes[0];
    return n * gibibyte;
  } else {
    let n = bytes[0];
    return n * tebibyte;
  }
}

/**
 * Convert a value to kibibytes.
 *
 * Example:
 * ```
 * bytes1024.Bytes(1024.0) |> bytes1024.as_kibibytes // 1.0
 * ```
 */
export function as_kibibytes(bytes) {
  return divideFloat(as_bytes(bytes), kibibyte);
}

/**
 * Convert a value to mebibytes.
 *
 * Example:
 * ```
 * bytes1024.Kibibytes(1024.0) |> bytes1024.as_mebibytes // 1.0
 * ```
 */
export function as_mebibytes(bytes) {
  return divideFloat(as_bytes(bytes), mebibyte);
}

/**
 * Convert a value to gibibytes.
 *
 * Example:
 * ```
 * bytes1024.Mebibytes(1024.0) |> bytes1024.as_gibibytes // 1.0
 * ```
 */
export function as_gibibytes(bytes) {
  return divideFloat(as_bytes(bytes), gibibyte);
}

/**
 * Convert a value to tebibytes.
 *
 * Example:
 * ```
 * bytes1024.Gibibytes(1024.0) |> bytes1024.as_tebibytes // 1.0
 * ```
 */
export function as_tebibytes(bytes) {
  return divideFloat(as_bytes(bytes), tebibyte);
}

/**
 * Convert a value to a more optimal unit, if possible.
 *
 * Example:
 * ```
 * bytes1024.Mebibytes(0.5) |> bytes1024.humanise // bytes1024.Kibibytes(512.0)
 * ```
 */
export function humanise(bytes) {
  let abs = $float.absolute_value;
  let b = as_bytes(bytes);
  return $bool.guard(
    abs(b) < kibibyte,
    new Bytes(b),
    () => {
      return $bool.guard(
        abs(b) < mebibyte,
        new Kibibytes(divideFloat(b, kibibyte)),
        () => {
          return $bool.guard(
            abs(b) < gibibyte,
            new Mebibytes(divideFloat(b, mebibyte)),
            () => {
              return $bool.guard(
                abs(b) < tebibyte,
                new Gibibytes(divideFloat(b, gibibyte)),
                () => { return new Tebibytes(divideFloat(b, tebibyte)); },
              );
            },
          );
        },
      );
    },
  );
}
