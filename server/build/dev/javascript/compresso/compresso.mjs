import * as $bit_array from "../gleam_stdlib/gleam/bit_array.mjs";
import * as $option from "../gleam_stdlib/gleam/option.mjs";
import { None, Some } from "../gleam_stdlib/gleam/option.mjs";
import * as $yielder from "../gleam_yielder/gleam/yielder.mjs";
import * as $compression from "./compresso/compression.mjs";
import { CustomType as $CustomType } from "./gleam.mjs";

class YielderAcc extends $CustomType {
  constructor(stream, uncompressed, done) {
    super();
    this.stream = stream;
    this.uncompressed = uncompressed;
    this.done = done;
  }
}
