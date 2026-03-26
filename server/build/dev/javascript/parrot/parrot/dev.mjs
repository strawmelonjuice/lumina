import * as $decode from "../../gleam_stdlib/gleam/dynamic/decode.mjs";
import * as $float from "../../gleam_stdlib/gleam/float.mjs";
import * as $option from "../../gleam_stdlib/gleam/option.mjs";
import * as $calendar from "../../gleam_time/gleam/time/calendar.mjs";
import { Date } from "../../gleam_time/gleam/time/calendar.mjs";
import * as $timestamp from "../../gleam_time/gleam/time/timestamp.mjs";
import { Ok, toList, CustomType as $CustomType } from "../gleam.mjs";

export class ParamInt extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Param$ParamInt = ($0) => new ParamInt($0);
export const Param$isParamInt = (value) => value instanceof ParamInt;
export const Param$ParamInt$0 = (value) => value[0];

export class ParamString extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Param$ParamString = ($0) => new ParamString($0);
export const Param$isParamString = (value) => value instanceof ParamString;
export const Param$ParamString$0 = (value) => value[0];

export class ParamFloat extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Param$ParamFloat = ($0) => new ParamFloat($0);
export const Param$isParamFloat = (value) => value instanceof ParamFloat;
export const Param$ParamFloat$0 = (value) => value[0];

export class ParamBool extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Param$ParamBool = ($0) => new ParamBool($0);
export const Param$isParamBool = (value) => value instanceof ParamBool;
export const Param$ParamBool$0 = (value) => value[0];

export class ParamBitArray extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Param$ParamBitArray = ($0) => new ParamBitArray($0);
export const Param$isParamBitArray = (value) => value instanceof ParamBitArray;
export const Param$ParamBitArray$0 = (value) => value[0];

export class ParamTimestamp extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Param$ParamTimestamp = ($0) => new ParamTimestamp($0);
export const Param$isParamTimestamp = (value) =>
  value instanceof ParamTimestamp;
export const Param$ParamTimestamp$0 = (value) => value[0];

export class ParamDate extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Param$ParamDate = ($0) => new ParamDate($0);
export const Param$isParamDate = (value) => value instanceof ParamDate;
export const Param$ParamDate$0 = (value) => value[0];

export class ParamList extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Param$ParamList = ($0) => new ParamList($0);
export const Param$isParamList = (value) => value instanceof ParamList;
export const Param$ParamList$0 = (value) => value[0];

export class ParamDynamic extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Param$ParamDynamic = ($0) => new ParamDynamic($0);
export const Param$isParamDynamic = (value) => value instanceof ParamDynamic;
export const Param$ParamDynamic$0 = (value) => value[0];

export class ParamNullable extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Param$ParamNullable = ($0) => new ParamNullable($0);
export const Param$isParamNullable = (value) => value instanceof ParamNullable;
export const Param$ParamNullable$0 = (value) => value[0];

export function bool_decoder() {
  let _block;
  let _pipe = $decode.int;
  _block = $decode.then$(
    _pipe,
    (v) => {
      if (v === 0) {
        return $decode.success(false);
      } else if (v === 1) {
        return $decode.success(true);
      } else {
        return $decode.failure(false, "could not decode int to boolean");
      }
    },
  );
  let int_to_bool = _block;
  return $decode.one_of($decode.bool, toList([int_to_bool]));
}

/**
 * https://github.com/lpil/pog/blob/v4.1.0/src/pog.gleam#L394
 * 
 * @ignore
 */
function timestamp_decoder() {
  return $decode.map(
    $decode.int,
    (microseconds) => {
      let seconds = globalThis.Math.trunc(microseconds / 1_000_000);
      let nanoseconds = (microseconds % 1_000_000) * 1000;
      return $timestamp.from_unix_seconds_and_nanoseconds(seconds, nanoseconds);
    },
  );
}

/**
 * https://github.com/lpil/pog/blob/v4.1.0/src/pog.gleam#L873
 */
export function calendar_date_decoder() {
  return $decode.field(
    0,
    $decode.int,
    (year) => {
      return $decode.field(
        1,
        $decode.int,
        (month) => {
          return $decode.field(
            2,
            $decode.int,
            (day) => {
              let $ = $calendar.month_from_int(month);
              if ($ instanceof Ok) {
                let month$1 = $[0];
                return $decode.success(new $calendar.Date(year, month$1, day));
              } else {
                return $decode.failure(
                  new $calendar.Date(0, new $calendar.January(), 1),
                  "Calendar date",
                );
              }
            },
          );
        },
      );
    },
  );
}

function datetime_string_decoder() {
  let _pipe = $decode.string;
  return $decode.then$(
    _pipe,
    (datetime_str) => {
      let $ = $timestamp.parse_rfc3339(datetime_str);
      if ($ instanceof Ok) {
        let ts = $[0];
        return $decode.success(ts);
      } else {
        return $decode.failure(
          $timestamp.from_unix_seconds(0),
          "Invalid datetime format",
        );
      }
    },
  );
}

function date_decoder() {
  return $decode.field(
    0,
    $decode.int,
    (year) => {
      return $decode.field(
        1,
        (() => {
          let _pipe = $decode.int;
          return $decode.then$(
            _pipe,
            (month) => {
              let $ = $calendar.month_from_int(month);
              if ($ instanceof Ok) {
                let month$1 = $[0];
                return $decode.success(month$1);
              } else {
                return $decode.failure(new $calendar.January(), "Month");
              }
            },
          );
        })(),
        (month) => {
          return $decode.field(
            2,
            $decode.int,
            (day) => { return $decode.success(new Date(year, month, day)); },
          );
        },
      );
    },
  );
}

function seconds_decoder() {
  let _block;
  let _pipe = $decode.int;
  _block = $decode.map(_pipe, (i) => { return [i, 0]; });
  let int = _block;
  let _block$1;
  let _pipe$1 = $decode.float;
  _block$1 = $decode.map(
    _pipe$1,
    (f) => {
      let floored = $float.floor(f);
      let seconds = $float.round(floored);
      let nanoseconds = $float.round((f - floored) * 1000000000.0);
      return [seconds, nanoseconds];
    },
  );
  let float = _block$1;
  return $decode.one_of(int, toList([float]));
}

function time_decoder() {
  return $decode.field(
    0,
    $decode.int,
    (hours) => {
      return $decode.field(
        1,
        $decode.int,
        (minutes) => {
          return $decode.field(
            2,
            seconds_decoder(),
            (_use0) => {
              let seconds;
              let nanoseconds;
              seconds = _use0[0];
              nanoseconds = _use0[1];
              let _pipe = new $calendar.TimeOfDay(
                hours,
                minutes,
                seconds,
                nanoseconds,
              );
              return $decode.success(_pipe);
            },
          );
        },
      );
    },
  );
}

function datetime_tuple_decoder() {
  return $decode.field(
    0,
    date_decoder(),
    (date) => {
      return $decode.field(
        1,
        time_decoder(),
        (time) => {
          let _pipe = $timestamp.from_calendar(date, time, $calendar.utc_offset);
          return $decode.success(_pipe);
        },
      );
    },
  );
}

export function datetime_decoder() {
  return $decode.one_of(
    datetime_string_decoder(),
    toList([datetime_tuple_decoder(), timestamp_decoder()]),
  );
}
