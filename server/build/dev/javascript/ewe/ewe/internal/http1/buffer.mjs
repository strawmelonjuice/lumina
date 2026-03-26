import * as $bit_array from "../../../../gleam_stdlib/gleam/bit_array.mjs";
import * as $int from "../../../../gleam_stdlib/gleam/int.mjs";
import { CustomType as $CustomType, toBitArray, bitArraySlice } from "../../../gleam.mjs";

export class Buffer extends $CustomType {
  constructor(data, pending) {
    super();
    this.data = data;
    this.pending = pending;
  }
}
export const Buffer$Buffer = (data, pending) => new Buffer(data, pending);
export const Buffer$isBuffer = (value) => value instanceof Buffer;
export const Buffer$Buffer$data = (value) => value.data;
export const Buffer$Buffer$0 = (value) => value.data;
export const Buffer$Buffer$pending = (value) => value.pending;
export const Buffer$Buffer$1 = (value) => value.pending;

/**
 * Appends data to the buffer and decrements pending bytes accordingly.
 */
export function append(buffer, data) {
  let pending = $int.max(0, buffer.pending - $bit_array.byte_size(data));
  return new Buffer(toBitArray([buffer.data, data]), pending);
}

/**
 * Splits the buffer data at the given byte boundary. Returns the first part
 * and the rest.
 */
export function split(buffer, bytes) {
  let $ = buffer.data;
  if (bytes * 8 >= 0 && $.bitSize >= bytes * 8) {
    let partition = bitArraySlice($, 0, bytes * 8);
    let rest = bitArraySlice($, bytes * 8);
    return [partition, rest];
  } else {
    return [buffer.data, toBitArray([])];
  }
}
