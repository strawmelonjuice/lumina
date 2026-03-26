import * as $exception from "../../exception/exception.mjs";
import * as $atom from "../../gleam_erlang/gleam/erlang/atom.mjs";
import * as $option from "../../gleam_stdlib/gleam/option.mjs";
import { Some } from "../../gleam_stdlib/gleam/option.mjs";
import * as $result from "../../gleam_stdlib/gleam/result.mjs";
import * as $string from "../../gleam_stdlib/gleam/string.mjs";
import * as $logging from "../../logging/logging.mjs";
import { CustomType as $CustomType } from "../gleam.mjs";

export class Default extends $CustomType {}
export const CompressionStrategy$Default = () => new Default();
export const CompressionStrategy$isDefault = (value) =>
  value instanceof Default;

export class Filtered extends $CustomType {}
export const CompressionStrategy$Filtered = () => new Filtered();
export const CompressionStrategy$isFiltered = (value) =>
  value instanceof Filtered;

export class HuffmanOnly extends $CustomType {}
export const CompressionStrategy$HuffmanOnly = () => new HuffmanOnly();
export const CompressionStrategy$isHuffmanOnly = (value) =>
  value instanceof HuffmanOnly;

export class RLE extends $CustomType {}
export const CompressionStrategy$RLE = () => new RLE();
export const CompressionStrategy$isRLE = (value) => value instanceof RLE;

class Deflated extends $CustomType {}

export class None extends $CustomType {}
export const Flush$None = () => new None();
export const Flush$isNone = (value) => value instanceof None;

export class Sync extends $CustomType {}
export const Flush$Sync = () => new Sync();
export const Flush$isSync = (value) => value instanceof Sync;

export class Full extends $CustomType {}
export const Flush$Full = () => new Full();
export const Flush$isFull = (value) => value instanceof Full;

export class Finish extends $CustomType {}
export const Flush$Finish = () => new Finish();
export const Flush$isFinish = (value) => value instanceof Finish;

export const default_compression = 6;

export const no_compression = 0;

export const best_speed_compression = 1;

export const best_compression = 9;
