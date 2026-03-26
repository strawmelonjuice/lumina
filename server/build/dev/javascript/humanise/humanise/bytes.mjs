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

export class Kilobytes extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Bytes$Kilobytes = ($0) => new Kilobytes($0);
export const Bytes$isKilobytes = (value) => value instanceof Kilobytes;
export const Bytes$Kilobytes$0 = (value) => value[0];

export class Megabytes extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Bytes$Megabytes = ($0) => new Megabytes($0);
export const Bytes$isMegabytes = (value) => value instanceof Megabytes;
export const Bytes$Megabytes$0 = (value) => value[0];

export class Gigabytes extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Bytes$Gigabytes = ($0) => new Gigabytes($0);
export const Bytes$isGigabytes = (value) => value instanceof Gigabytes;
export const Bytes$Gigabytes$0 = (value) => value[0];

export class Terabytes extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Bytes$Terabytes = ($0) => new Terabytes($0);
export const Bytes$isTerabytes = (value) => value instanceof Terabytes;
export const Bytes$Terabytes$0 = (value) => value[0];

const kilobyte = 1000.0;

const megabyte = 1_000_000.0;

const gigabyte = 1_000_000_000.0;

const terabyte = 1_000_000_000_000.0;

/**
 * Format a value as a `String`, rounded to at most 2 decimal places, followed by a unit suffix.
 *
 * Example:
 * ```
 * bytes.Gigabytes(30.125) |> bytes.to_string // "30.13GB"
 * ```
 */
export function to_string(bytes) {
  let _block;
  if (bytes instanceof Bytes) {
    let n = bytes[0];
    _block = [n, "B"];
  } else if (bytes instanceof Kilobytes) {
    let n = bytes[0];
    _block = [n, "KB"];
  } else if (bytes instanceof Megabytes) {
    let n = bytes[0];
    _block = [n, "MB"];
  } else if (bytes instanceof Gigabytes) {
    let n = bytes[0];
    _block = [n, "GB"];
  } else {
    let n = bytes[0];
    _block = [n, "TB"];
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
 * bytes.Kilobytes(1.0) |> bytes.as_bytes // 1000.0
 * ```
 */
export function as_bytes(bytes) {
  if (bytes instanceof Bytes) {
    let n = bytes[0];
    return n;
  } else if (bytes instanceof Kilobytes) {
    let n = bytes[0];
    return n * kilobyte;
  } else if (bytes instanceof Megabytes) {
    let n = bytes[0];
    return n * megabyte;
  } else if (bytes instanceof Gigabytes) {
    let n = bytes[0];
    return n * gigabyte;
  } else {
    let n = bytes[0];
    return n * terabyte;
  }
}

/**
 * Convert a value to kilobytes.
 *
 * Example:
 * ```
 * bytes.Bytes(1000.0) |> bytes.as_kilobytes // 1.0
 * ```
 */
export function as_kilobytes(bytes) {
  return divideFloat(as_bytes(bytes), kilobyte);
}

/**
 * Convert a value to megabytes.
 *
 * Example:
 * ```
 * bytes.Kilobytes(1000.0) |> bytes.as_megabytes // 1.0
 * ```
 */
export function as_megabytes(bytes) {
  return divideFloat(as_bytes(bytes), megabyte);
}

/**
 * Convert a value to gigabytes.
 *
 * Example:
 * ```
 * bytes.Megabytes(1000.0) |> bytes.as_gigabytes // 1.0
 * ```
 */
export function as_gigabytes(bytes) {
  return divideFloat(as_bytes(bytes), gigabyte);
}

/**
 * Convert a value to terabytes.
 *
 * Example:
 * ```
 * bytes.Gigabytes(1000.0) |> bytes.as_terabytes // 1.0
 * ```
 */
export function as_terabytes(bytes) {
  return divideFloat(as_bytes(bytes), terabyte);
}

/**
 * Convert a value to a more optimal unit, if possible.
 *
 * Example:
 * ```
 * bytes.Megabytes(0.5) |> bytes.humanise // bytes.Kilobytes(500.0)
 * ```
 */
export function humanise(bytes) {
  let abs = $float.absolute_value;
  let b = as_bytes(bytes);
  return $bool.guard(
    abs(b) < kilobyte,
    new Bytes(b),
    () => {
      return $bool.guard(
        abs(b) < megabyte,
        new Kilobytes(divideFloat(b, kilobyte)),
        () => {
          return $bool.guard(
            abs(b) < gigabyte,
            new Megabytes(divideFloat(b, megabyte)),
            () => {
              return $bool.guard(
                abs(b) < terabyte,
                new Gigabytes(divideFloat(b, gigabyte)),
                () => { return new Terabytes(divideFloat(b, terabyte)); },
              );
            },
          );
        },
      );
    },
  );
}
