import * as $bool from "../../gleam_stdlib/gleam/bool.mjs";
import * as $float from "../../gleam_stdlib/gleam/float.mjs";
import * as $duration from "../../gleam_time/gleam/time/duration.mjs";
import { CustomType as $CustomType, divideFloat } from "../gleam.mjs";
import * as $util from "../humanise/util.mjs";

export class Nanoseconds extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Time$Nanoseconds = ($0) => new Nanoseconds($0);
export const Time$isNanoseconds = (value) => value instanceof Nanoseconds;
export const Time$Nanoseconds$0 = (value) => value[0];

export class Microseconds extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Time$Microseconds = ($0) => new Microseconds($0);
export const Time$isMicroseconds = (value) => value instanceof Microseconds;
export const Time$Microseconds$0 = (value) => value[0];

export class Milliseconds extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Time$Milliseconds = ($0) => new Milliseconds($0);
export const Time$isMilliseconds = (value) => value instanceof Milliseconds;
export const Time$Milliseconds$0 = (value) => value[0];

export class Seconds extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Time$Seconds = ($0) => new Seconds($0);
export const Time$isSeconds = (value) => value instanceof Seconds;
export const Time$Seconds$0 = (value) => value[0];

export class Minutes extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Time$Minutes = ($0) => new Minutes($0);
export const Time$isMinutes = (value) => value instanceof Minutes;
export const Time$Minutes$0 = (value) => value[0];

export class Hours extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Time$Hours = ($0) => new Hours($0);
export const Time$isHours = (value) => value instanceof Hours;
export const Time$Hours$0 = (value) => value[0];

export class Days extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Time$Days = ($0) => new Days($0);
export const Time$isDays = (value) => value instanceof Days;
export const Time$Days$0 = (value) => value[0];

export class Weeks extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Time$Weeks = ($0) => new Weeks($0);
export const Time$isWeeks = (value) => value instanceof Weeks;
export const Time$Weeks$0 = (value) => value[0];

const microsecond = 1000.0;

const millisecond = 1_000_000.0;

const second = 1_000_000_000.0;

const minute = 60_000_000_000.0;

const hour = 3_600_000_000_000.0;

const day = 86_400_000_000_000.0;

const week = 604_800_000_000_000.0;

/**
 * Format a value as a `String`, rounded to at most 2 decimal places, followed by a unit suffix.
 *
 * Example:
 * ```
 * time.Seconds(30.125) |> time.to_string // "30.13s"
 * ```
 */
export function to_string(time) {
  let _block;
  if (time instanceof Nanoseconds) {
    let ns = time[0];
    _block = [ns, "ns"];
  } else if (time instanceof Microseconds) {
    let us = time[0];
    _block = [us, "us"];
  } else if (time instanceof Milliseconds) {
    let ms = time[0];
    _block = [ms, "ms"];
  } else if (time instanceof Seconds) {
    let s = time[0];
    _block = [s, "s"];
  } else if (time instanceof Minutes) {
    let m = time[0];
    _block = [m, "m"];
  } else if (time instanceof Hours) {
    let h = time[0];
    _block = [h, "h"];
  } else if (time instanceof Days) {
    let d = time[0];
    _block = [d, "d"];
  } else {
    let w = time[0];
    _block = [w, "w"];
  }
  let $ = _block;
  let n;
  let suffix;
  n = $[0];
  suffix = $[1];
  return $util.format(n, suffix);
}

/**
 * Convert a value to nanoseconds.
 *
 * Example:
 * ```
 * time.Microseconds(1.0) |> time.as_nanoseconds // 1000.0
 * ```
 */
export function as_nanoseconds(time) {
  if (time instanceof Nanoseconds) {
    let n = time[0];
    return n;
  } else if (time instanceof Microseconds) {
    let n = time[0];
    return n * microsecond;
  } else if (time instanceof Milliseconds) {
    let n = time[0];
    return n * millisecond;
  } else if (time instanceof Seconds) {
    let n = time[0];
    return n * second;
  } else if (time instanceof Minutes) {
    let n = time[0];
    return n * minute;
  } else if (time instanceof Hours) {
    let n = time[0];
    return n * hour;
  } else if (time instanceof Days) {
    let n = time[0];
    return n * day;
  } else {
    let n = time[0];
    return n * week;
  }
}

/**
 * Convert a value to microseconds.
 *
 * Example:
 * ```
 * time.Nanoseconds(1000.0) |> time.as_microseconds // 1.0
 * ```
 */
export function as_microseconds(time) {
  return divideFloat(as_nanoseconds(time), microsecond);
}

/**
 * Convert a value to milliseconds.
 *
 * Example:
 * ```
 * time.Microseconds(1000.0) |> time.as_milliseconds // 1.0
 * ```
 */
export function as_milliseconds(time) {
  return divideFloat(as_nanoseconds(time), millisecond);
}

/**
 * Convert a value to seconds.
 *
 * Example:
 * ```
 * time.Milliseconds(1000.0) |> time.as_seconds // 1.0
 * ```
 */
export function as_seconds(time) {
  return divideFloat(as_nanoseconds(time), second);
}

/**
 * Convert a value to minutes.
 *
 * Example:
 * ```
 * time.Seconds(60.0) |> time.as_minutes // 1.0
 * ```
 */
export function as_minutes(time) {
  return divideFloat(as_nanoseconds(time), minute);
}

/**
 * Convert a value to hours.
 *
 * Example:
 * ```
 * time.Minutes(60.0) |> time.as_hours // 1.0
 * ```
 */
export function as_hours(time) {
  return divideFloat(as_nanoseconds(time), hour);
}

/**
 * Convert a value to days.
 *
 * Example:
 * ```
 * time.Hours(24.0) |> time.as_days // 1.0
 * ```
 */
export function as_days(time) {
  return divideFloat(as_nanoseconds(time), day);
}

/**
 * Convert a value to weeks.
 *
 * Example:
 * ```
 * time.Days(7.0) |> time.as_weeks // 1.0
 * ```
 */
export function as_weeks(time) {
  return divideFloat(as_nanoseconds(time), week);
}

/**
 * Convert a value to a more optimal unit, if possible.
 *
 * Example:
 * ```
 * time.Seconds(120.0) |> time.humanise // time.Minutes(2.0)
 * ```
 */
export function humanise(time) {
  let abs = $float.absolute_value;
  let ns = as_nanoseconds(time);
  return $bool.guard(
    abs(ns) < microsecond,
    new Nanoseconds(ns),
    () => {
      return $bool.guard(
        abs(ns) < millisecond,
        new Microseconds(divideFloat(ns, microsecond)),
        () => {
          return $bool.guard(
            abs(ns) < second,
            new Milliseconds(divideFloat(ns, millisecond)),
            () => {
              return $bool.guard(
                abs(ns) < minute,
                new Seconds(divideFloat(ns, second)),
                () => {
                  return $bool.guard(
                    abs(ns) < hour,
                    new Minutes(divideFloat(ns, minute)),
                    () => {
                      return $bool.guard(
                        abs(ns) < day,
                        new Hours(divideFloat(ns, hour)),
                        () => {
                          return $bool.guard(
                            abs(ns) < week,
                            new Days(divideFloat(ns, day)),
                            () => { return new Weeks(divideFloat(ns, week)); },
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      );
    },
  );
}

/**
 * Convert a Duration from `gleam/time`.
 *
 * Example:
 * ```
 * duration.seconds(120) |> time.from_duration // time.Minutes(2.0)
 * ```
 */
export function from_duration(duration) {
  let _pipe = new Seconds(
    (() => {
      let _pipe = duration;
      return $duration.to_seconds(_pipe);
    })(),
  );
  return humanise(_pipe);
}
