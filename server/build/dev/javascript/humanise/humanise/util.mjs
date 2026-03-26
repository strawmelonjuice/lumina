import * as $float from "../../gleam_stdlib/gleam/float.mjs";
import * as $int from "../../gleam_stdlib/gleam/int.mjs";
import { Ok, makeError, divideFloat } from "../gleam.mjs";

const FILEPATH = "src/humanise/util.gleam";

export function round_to(n, places) {
  let _block;
  let _pipe = $int.to_float($int.max(1, places));
  _block = ((_capture) => { return $float.power(10.0, _capture); })(_pipe);
  let $ = _block;
  let places$1;
  if ($ instanceof Ok) {
    places$1 = $[0];
  } else {
    throw makeError(
      "let_assert",
      FILEPATH,
      "humanise/util",
      5,
      "round_to",
      "Pattern match failed, no pattern matched the value.",
      { value: $, start: 97, end: 181, pattern_start: 108, pattern_end: 118 }
    )
  }
  return divideFloat(
    (() => {
      let _pipe$1 = $float.round(n * places$1);
      return $int.to_float(_pipe$1);
    })(),
    places$1
  );
}

export function format(n, suffix) {
  return (() => {
    let _pipe = n;
    let _pipe$1 = round_to(_pipe, 2);
    return $float.to_string(_pipe$1);
  })() + suffix;
}
