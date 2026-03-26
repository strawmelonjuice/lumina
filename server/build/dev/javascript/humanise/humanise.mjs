import * as $float from "../gleam_stdlib/gleam/float.mjs";
import * as $int from "../gleam_stdlib/gleam/int.mjs";
import * as $calendar from "../gleam_time/gleam/time/calendar.mjs";
import { Date, TimeOfDay } from "../gleam_time/gleam/time/calendar.mjs";
import * as $duration from "../gleam_time/gleam/time/duration.mjs";
import * as $timestamp from "../gleam_time/gleam/time/timestamp.mjs";
import * as $bytes from "./humanise/bytes.mjs";
import * as $bytes1024 from "./humanise/bytes1024.mjs";
import * as $time from "./humanise/time.mjs";

/**
 * Format a `Timestamp` relative to the provided current `Timestamp`.
 *
 * This function finds the difference between the current time and the given time, and returns a string describing the difference. (e.g. "in 2.0s", "3.5d ago")
 */
export function date_relative(date, current) {
  let _block;
  let _pipe = current;
  let _pipe$1 = $timestamp.difference(_pipe, date);
  _block = $time.from_duration(_pipe$1);
  let relative = _block;
  let decompose = (a) => {
    if (a instanceof $time.Nanoseconds) {
      let n = a[0];
      return [(var0) => { return new $time.Nanoseconds(var0); }, n];
    } else if (a instanceof $time.Microseconds) {
      let n = a[0];
      return [(var0) => { return new $time.Microseconds(var0); }, n];
    } else if (a instanceof $time.Milliseconds) {
      let n = a[0];
      return [(var0) => { return new $time.Milliseconds(var0); }, n];
    } else if (a instanceof $time.Seconds) {
      let n = a[0];
      return [(var0) => { return new $time.Seconds(var0); }, n];
    } else if (a instanceof $time.Minutes) {
      let n = a[0];
      return [(var0) => { return new $time.Minutes(var0); }, n];
    } else if (a instanceof $time.Hours) {
      let n = a[0];
      return [(var0) => { return new $time.Hours(var0); }, n];
    } else if (a instanceof $time.Days) {
      let n = a[0];
      return [(var0) => { return new $time.Days(var0); }, n];
    } else {
      let n = a[0];
      return [(var0) => { return new $time.Weeks(var0); }, n];
    }
  };
  let $ = decompose(relative);
  let constructor;
  let n;
  constructor = $[0];
  n = $[1];
  let $1 = n >= 0.0;
  if ($1) {
    return "in " + $time.to_string(relative);
  } else {
    return $time.to_string(constructor($float.absolute_value(n))) + " ago";
  }
}

/**
 * Format a `Date`, `TimeOfDay` pair, automatically omitting redundant information (omit year if it matches the current year, omit month and day if it also matches the current day)
 *
 * The given date will be compared against the provided "current" date to determine what information to omit.
 *
 * This function does not currently support internationalization, and simply returns a string in the following largest-to-smallest format:
 * ```
 * <maybe year> <maybe <month> <day>> <hours>:<minutes>:<seconds>
 * ```
 * Note that hours are in 24 hour format, not 12 hours with AM/PM.
 */
export function date(date, current) {
  let _block;
  let $ = date[0];
  let current$1 = current.year;
  let given = $.year;
  if (current$1 === given) {
    _block = true;
  } else {
    _block = false;
  }
  let year_matches = _block;
  let _block$1;
  let $1 = date[0];
  let current$1 = current.day;
  let given = $1.day;
  if (current$1 === given) {
    _block$1 = true;
  } else {
    _block$1 = false;
  }
  let day_matches = _block$1;
  let $2 = date[0];
  let year;
  let month;
  let day;
  year = $2.year;
  month = $2.month;
  day = $2.day;
  let $3 = date[1];
  let hours;
  let minutes;
  let seconds;
  hours = $3.hours;
  minutes = $3.minutes;
  seconds = $3.seconds;
  let _block$2;
  if (year_matches) {
    _block$2 = "";
  } else {
    _block$2 = $int.to_string(year) + " ";
  }
  let maybe_year = _block$2;
  let _block$3;
  let $4 = year_matches && day_matches;
  if ($4) {
    _block$3 = "";
  } else if (month instanceof $calendar.January) {
    _block$3 = "January ";
  } else if (month instanceof $calendar.February) {
    _block$3 = "February ";
  } else if (month instanceof $calendar.March) {
    _block$3 = "March ";
  } else if (month instanceof $calendar.April) {
    _block$3 = "April ";
  } else if (month instanceof $calendar.May) {
    _block$3 = "May ";
  } else if (month instanceof $calendar.June) {
    _block$3 = "June ";
  } else if (month instanceof $calendar.July) {
    _block$3 = "July ";
  } else if (month instanceof $calendar.August) {
    _block$3 = "August ";
  } else if (month instanceof $calendar.September) {
    _block$3 = "September ";
  } else if (month instanceof $calendar.October) {
    _block$3 = "October ";
  } else if (month instanceof $calendar.November) {
    _block$3 = "November ";
  } else {
    _block$3 = "December ";
  }
  let maybe_month = _block$3;
  let _block$4;
  let $5 = year_matches && day_matches;
  if ($5) {
    _block$4 = "";
  } else {
    _block$4 = $int.to_string(day) + " ";
  }
  let maybe_day = _block$4;
  let _block$5;
  let $6 = hours < 10;
  if ($6) {
    _block$5 = "0" + $int.to_string(hours);
  } else {
    _block$5 = $int.to_string(hours);
  }
  let hours$1 = _block$5;
  let _block$6;
  let $7 = minutes < 10;
  if ($7) {
    _block$6 = "0" + $int.to_string(minutes);
  } else {
    _block$6 = $int.to_string(minutes);
  }
  let minutes$1 = _block$6;
  let _block$7;
  let $8 = seconds < 10;
  if ($8) {
    _block$7 = "0" + $int.to_string(seconds);
  } else {
    _block$7 = $int.to_string(seconds);
  }
  let seconds$1 = _block$7;
  return ((((((maybe_year + maybe_month) + maybe_day) + hours$1) + ":") + minutes$1) + ":") + seconds$1;
}

/**
 * Format a `Duration`, using the most optimal unit.
 */
export function duration(duration) {
  let _pipe = $time.from_duration(duration);
  return $time.to_string(_pipe);
}

/**
 * Format *n* nanoseconds as a `Float`, converting to a more optimal unit if possible.
 */
export function nanoseconds_float(n) {
  let _pipe = new $time.Nanoseconds(n);
  let _pipe$1 = $time.humanise(_pipe);
  return $time.to_string(_pipe$1);
}

/**
 * Format *n* nanoseconds as a `Float`, converting to a more optimal unit if possible.
 */
export function nanoseconds_int(n) {
  let _pipe = new $time.Nanoseconds($int.to_float(n));
  let _pipe$1 = $time.humanise(_pipe);
  return $time.to_string(_pipe$1);
}

/**
 * Format *n* microseconds as a `Float`, converting to a more optimal unit if possible.
 */
export function microseconds_float(n) {
  let _pipe = new $time.Microseconds(n);
  let _pipe$1 = $time.humanise(_pipe);
  return $time.to_string(_pipe$1);
}

/**
 * Format *n* microseconds as an `Int`, converting to a more optimal unit if possible.
 */
export function microseconds_int(n) {
  let _pipe = new $time.Microseconds($int.to_float(n));
  let _pipe$1 = $time.humanise(_pipe);
  return $time.to_string(_pipe$1);
}

/**
 * Format *n* milliseconds as a `Float`, converting to a more optimal unit if possible.
 */
export function milliseconds_float(n) {
  let _pipe = new $time.Milliseconds(n);
  let _pipe$1 = $time.humanise(_pipe);
  return $time.to_string(_pipe$1);
}

/**
 * Format *n* milliseconds as an `Int`, converting to a more optimal unit if possible.
 */
export function milliseconds_int(n) {
  let _pipe = new $time.Milliseconds($int.to_float(n));
  let _pipe$1 = $time.humanise(_pipe);
  return $time.to_string(_pipe$1);
}

/**
 * Format *n* seconds as a `Float`, converting to a more optimal unit if possible.
 */
export function seconds_float(n) {
  let _pipe = new $time.Seconds(n);
  let _pipe$1 = $time.humanise(_pipe);
  return $time.to_string(_pipe$1);
}

/**
 * Format *n* seconds as an `Int`, converting to a more optimal unit if possible.
 */
export function seconds_int(n) {
  let _pipe = new $time.Seconds($int.to_float(n));
  let _pipe$1 = $time.humanise(_pipe);
  return $time.to_string(_pipe$1);
}

/**
 * Format *n* hours as a `Float`, converting to a more optimal unit if possible.
 */
export function hours_float(n) {
  let _pipe = new $time.Hours(n);
  let _pipe$1 = $time.humanise(_pipe);
  return $time.to_string(_pipe$1);
}

/**
 * Format *n* hours as an `Int`, converting to a more optimal unit if possible.
 */
export function hours_int(n) {
  let _pipe = new $time.Hours($int.to_float(n));
  let _pipe$1 = $time.humanise(_pipe);
  return $time.to_string(_pipe$1);
}

/**
 * Format *n* days as a `Float`, converting to a more optimal unit if possible.
 */
export function days_float(n) {
  let _pipe = new $time.Days(n);
  let _pipe$1 = $time.humanise(_pipe);
  return $time.to_string(_pipe$1);
}

/**
 * Format *n* days as an `Int`, converting to a more optimal unit if possible.
 */
export function days_int(n) {
  let _pipe = new $time.Days($int.to_float(n));
  let _pipe$1 = $time.humanise(_pipe);
  return $time.to_string(_pipe$1);
}

/**
 * Format *n* weeks as a `Float`, converting to a more optimal unit if possible.
 */
export function weeks_float(n) {
  let _pipe = new $time.Weeks(n);
  let _pipe$1 = $time.humanise(_pipe);
  return $time.to_string(_pipe$1);
}

/**
 * Format *n* weeks as an `Int`, converting to a more optimal unit if possible.
 */
export function weeks_int(n) {
  let _pipe = new $time.Weeks($int.to_float(n));
  let _pipe$1 = $time.humanise(_pipe);
  return $time.to_string(_pipe$1);
}

/**
 * Format *n* bytes as a `Float`, converting to a more optimal unit if possible.
 */
export function bytes_float(n) {
  let _pipe = new $bytes.Bytes(n);
  let _pipe$1 = $bytes.humanise(_pipe);
  return $bytes.to_string(_pipe$1);
}

/**
 * Format *n* bytes as an `Int`, converting to a more optimal unit if possible.
 */
export function bytes_int(n) {
  let _pipe = new $bytes.Bytes($int.to_float(n));
  let _pipe$1 = $bytes.humanise(_pipe);
  return $bytes.to_string(_pipe$1);
}

/**
 * Format *n* kilobytes as a `Float`, converting to a more optimal unit if possible.
 */
export function kilobytes_float(n) {
  let _pipe = new $bytes.Kilobytes(n);
  let _pipe$1 = $bytes.humanise(_pipe);
  return $bytes.to_string(_pipe$1);
}

/**
 * Format *n* kilobytes as an `Int`, converting to a more optimal unit if possible.
 */
export function kilobytes_int(n) {
  let _pipe = new $bytes.Kilobytes($int.to_float(n));
  let _pipe$1 = $bytes.humanise(_pipe);
  return $bytes.to_string(_pipe$1);
}

/**
 * Format *n* megabytes as a `Float`, converting to a more optimal unit if possible.
 */
export function megabytes_float(n) {
  let _pipe = new $bytes.Megabytes(n);
  let _pipe$1 = $bytes.humanise(_pipe);
  return $bytes.to_string(_pipe$1);
}

/**
 * Format *n* megabytes as an `Int`, converting to a more optimal unit if possible.
 */
export function megabytes_int(n) {
  let _pipe = new $bytes.Megabytes($int.to_float(n));
  let _pipe$1 = $bytes.humanise(_pipe);
  return $bytes.to_string(_pipe$1);
}

/**
 * Format *n* gigabytes as a `Float`, converting to a more optimal unit if possible.
 */
export function gigabytes_float(n) {
  let _pipe = new $bytes.Gigabytes(n);
  let _pipe$1 = $bytes.humanise(_pipe);
  return $bytes.to_string(_pipe$1);
}

/**
 * Format *n* gigabytes as an `Int`, converting to a more optimal unit if possible.
 */
export function gigabytes_int(n) {
  let _pipe = new $bytes.Gigabytes($int.to_float(n));
  let _pipe$1 = $bytes.humanise(_pipe);
  return $bytes.to_string(_pipe$1);
}

/**
 * Format *n* terabytes as a `Float`, converting to a more optimal unit if possible.
 */
export function terabytes_float(n) {
  let _pipe = new $bytes.Terabytes(n);
  let _pipe$1 = $bytes.humanise(_pipe);
  return $bytes.to_string(_pipe$1);
}

/**
 * Format *n* terabytes as an `Int`, converting to a more optimal unit if possible.
 */
export function terabytes_int(n) {
  let _pipe = new $bytes.Terabytes($int.to_float(n));
  let _pipe$1 = $bytes.humanise(_pipe);
  return $bytes.to_string(_pipe$1);
}

/**
 * Format *n* kibibytes as a `Float`, converting to a more optimal unit if possible.
 */
export function kibibytes_float(n) {
  let _pipe = new $bytes1024.Kibibytes(n);
  let _pipe$1 = $bytes1024.humanise(_pipe);
  return $bytes1024.to_string(_pipe$1);
}

/**
 * Format *n* kibibytes as an `Int`, converting to a more optimal unit if possible.
 */
export function kibibytes_int(n) {
  let _pipe = new $bytes1024.Kibibytes($int.to_float(n));
  let _pipe$1 = $bytes1024.humanise(_pipe);
  return $bytes1024.to_string(_pipe$1);
}

/**
 * Format *n* mebibytes as a `Float`, converting to a more optimal unit if possible.
 */
export function mebibytes_float(n) {
  let _pipe = new $bytes1024.Mebibytes(n);
  let _pipe$1 = $bytes1024.humanise(_pipe);
  return $bytes1024.to_string(_pipe$1);
}

/**
 * Format *n* mebibytes as an `Int`, converting to a more optimal unit if possible.
 */
export function mebibytes_int(n) {
  let _pipe = new $bytes1024.Mebibytes($int.to_float(n));
  let _pipe$1 = $bytes1024.humanise(_pipe);
  return $bytes1024.to_string(_pipe$1);
}

/**
 * Format *n* gibibytes as a `Float`, converting to a more optimal unit if possible.
 */
export function gibibytes_float(n) {
  let _pipe = new $bytes1024.Gibibytes(n);
  let _pipe$1 = $bytes1024.humanise(_pipe);
  return $bytes1024.to_string(_pipe$1);
}

/**
 * Format *n* gibibytes as an `Int`, converting to a more optimal unit if possible.
 */
export function gibibytes_int(n) {
  let _pipe = new $bytes1024.Gibibytes($int.to_float(n));
  let _pipe$1 = $bytes1024.humanise(_pipe);
  return $bytes1024.to_string(_pipe$1);
}

/**
 * Format *n* tebibytes as a `Float`, converting to a more optimal unit if possible.
 */
export function tebibytes_float(n) {
  let _pipe = new $bytes1024.Tebibytes(n);
  let _pipe$1 = $bytes1024.humanise(_pipe);
  return $bytes1024.to_string(_pipe$1);
}

/**
 * Format *n* tebibytes as an `Int`, converting to a more optimal unit if possible.
 */
export function tebibytes_int(n) {
  let _pipe = new $bytes1024.Tebibytes($int.to_float(n));
  let _pipe$1 = $bytes1024.humanise(_pipe);
  return $bytes1024.to_string(_pipe$1);
}
