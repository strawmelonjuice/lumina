import * as $bool from "../gleam_stdlib/gleam/bool.mjs";
import * as $float from "../gleam_stdlib/gleam/float.mjs";
import * as $int from "../gleam_stdlib/gleam/int.mjs";
import * as $io from "../gleam_stdlib/gleam/io.mjs";
import * as $list from "../gleam_stdlib/gleam/list.mjs";
import * as $option from "../gleam_stdlib/gleam/option.mjs";
import { None, Some } from "../gleam_stdlib/gleam/option.mjs";
import * as $result from "../gleam_stdlib/gleam/result.mjs";
import * as $string from "../gleam_stdlib/gleam/string.mjs";
import { toList, Empty as $Empty, CustomType as $CustomType } from "./gleam.mjs";
import {
  get_state as ffi_get_state,
  set_state as ffi_set_state,
  get_context as ffi_get_context,
  set_context as ffi_set_context,
  now as ffi_now,
  monotonic_now as ffi_monotonic_now,
  is_tty as ffi_is_tty,
  get_env as ffi_get_env,
  beam_log as ffi_beam_log,
} from "./woof_ffi.mjs";

export class Debug extends $CustomType {}
export const Level$Debug = () => new Debug();
export const Level$isDebug = (value) => value instanceof Debug;

export class Info extends $CustomType {}
export const Level$Info = () => new Info();
export const Level$isInfo = (value) => value instanceof Info;

export class Warning extends $CustomType {}
export const Level$Warning = () => new Warning();
export const Level$isWarning = (value) => value instanceof Warning;

export class Error extends $CustomType {}
export const Level$Error = () => new Error();
export const Level$isError = (value) => value instanceof Error;

export class Text extends $CustomType {}
export const Format$Text = () => new Text();
export const Format$isText = (value) => value instanceof Text;

export class Json extends $CustomType {}
export const Format$Json = () => new Json();
export const Format$isJson = (value) => value instanceof Json;

export class Compact extends $CustomType {}
export const Format$Compact = () => new Compact();
export const Format$isCompact = (value) => value instanceof Compact;

export class Custom extends $CustomType {
  constructor(formatter) {
    super();
    this.formatter = formatter;
  }
}
export const Format$Custom = (formatter) => new Custom(formatter);
export const Format$isCustom = (value) => value instanceof Custom;
export const Format$Custom$formatter = (value) => value.formatter;
export const Format$Custom$0 = (value) => value.formatter;

export class Auto extends $CustomType {}
export const ColorMode$Auto = () => new Auto();
export const ColorMode$isAuto = (value) => value instanceof Auto;

export class Always extends $CustomType {}
export const ColorMode$Always = () => new Always();
export const ColorMode$isAlways = (value) => value instanceof Always;

export class Never extends $CustomType {}
export const ColorMode$Never = () => new Never();
export const ColorMode$isNever = (value) => value instanceof Never;

export class Config extends $CustomType {
  constructor(level, format, colors) {
    super();
    this.level = level;
    this.format = format;
    this.colors = colors;
  }
}
export const Config$Config = (level, format, colors) =>
  new Config(level, format, colors);
export const Config$isConfig = (value) => value instanceof Config;
export const Config$Config$level = (value) => value.level;
export const Config$Config$0 = (value) => value.level;
export const Config$Config$format = (value) => value.format;
export const Config$Config$1 = (value) => value.format;
export const Config$Config$colors = (value) => value.colors;
export const Config$Config$2 = (value) => value.colors;

export class Entry extends $CustomType {
  constructor(level, message, fields, namespace, timestamp) {
    super();
    this.level = level;
    this.message = message;
    this.fields = fields;
    this.namespace = namespace;
    this.timestamp = timestamp;
  }
}
export const Entry$Entry = (level, message, fields, namespace, timestamp) =>
  new Entry(level, message, fields, namespace, timestamp);
export const Entry$isEntry = (value) => value instanceof Entry;
export const Entry$Entry$level = (value) => value.level;
export const Entry$Entry$0 = (value) => value.level;
export const Entry$Entry$message = (value) => value.message;
export const Entry$Entry$1 = (value) => value.message;
export const Entry$Entry$fields = (value) => value.fields;
export const Entry$Entry$2 = (value) => value.fields;
export const Entry$Entry$namespace = (value) => value.namespace;
export const Entry$Entry$3 = (value) => value.namespace;
export const Entry$Entry$timestamp = (value) => value.timestamp;
export const Entry$Entry$4 = (value) => value.timestamp;

class Logger extends $CustomType {
  constructor(namespace) {
    super();
    this.namespace = namespace;
  }
}

class State extends $CustomType {
  constructor(level, format, colors, global_context, sink) {
    super();
    this.level = level;
    this.format = format;
    this.colors = colors;
    this.global_context = global_context;
    this.sink = sink;
  }
}

const ansi_reset = "\u{001b}[0m";

const ansi_dim = "\u{001b}[90m";

const ansi_yellow = "\u{001b}[33m";

const ansi_blue = "\u{001b}[34m";

const ansi_red_bold = "\u{001b}[1;31m";

/**
 * The default sink — prints the formatted log line to standard output.
 *
 * This is the out-of-the-box behaviour: zero configuration, beautiful
 * output on any terminal.  Useful when building a custom sink that still
 * wants to write to stdout.
 *
 * See `beam_logger_sink` for the OTP-integrated alternative.
 */
export function default_sink(_, formatted) {
  return $io.println(formatted);
}

/**
 * A sink that does nothing and discards all log events.
 *
 * Useful for muting logs entirely, for example during test runs:
 * `woof.set_sink(woof.silent_sink)`
 */
export function silent_sink(_, _1) {
  return undefined;
}

/**
 * Create a namespaced logger.
 *
 * The namespace is prepended to every message formatted with `Text` and
 * included as a `"ns"` field in `Json` output.
 */
export function new$(namespace) {
  return new Logger(namespace);
}

/**
 * Create a string field. Same as writing `#(key, value)` directly, but
 * reads nicely alongside the typed helpers.
 */
export function field(key, value) {
  return [key, value];
}

/**
 * Create a field from an `Int`.
 */
export function int_field(key, value) {
  return [key, $int.to_string(value)];
}

/**
 * Create a field from a `Float`.
 */
export function float_field(key, value) {
  return [key, $float.to_string(value)];
}

/**
 * Create a field from a `Bool`.
 */
export function bool_field(key, value) {
  return [key, $bool.to_string(value)];
}

/**
 * Return the lowercase name of a level.
 *
 * Useful inside `Custom` formatters.
 */
export function level_name(level) {
  if (level instanceof Debug) {
    return "debug";
  } else if (level instanceof Info) {
    return "info";
  } else if (level instanceof Warning) {
    return "warning";
  } else {
    return "error";
  }
}

function default_state() {
  return new State(
    new Debug(),
    new Text(),
    new Auto(),
    toList([]),
    default_sink,
  );
}

function level_to_int(level) {
  if (level instanceof Debug) {
    return 0;
  } else if (level instanceof Info) {
    return 1;
  } else if (level instanceof Warning) {
    return 2;
  } else {
    return 3;
  }
}

function should_log(msg_level, min_level) {
  return level_to_int(msg_level) >= level_to_int(min_level);
}

function json_escape(s) {
  let _pipe = s;
  let _pipe$1 = $string.replace(_pipe, "\\", "\\\\");
  let _pipe$2 = $string.replace(_pipe$1, "\"", "\\\"");
  let _pipe$3 = $string.replace(_pipe$2, "\n", "\\n");
  let _pipe$4 = $string.replace(_pipe$3, "\u{001B}", "\\u001b");
  let _pipe$5 = $string.replace(_pipe$4, "\r", "\\r");
  let _pipe$6 = $string.replace(_pipe$5, "\t", "\\t");
  let _pipe$7 = $string.replace(_pipe$6, "\u{0008}", "\\b");
  return $string.replace(_pipe$7, "\u{000C}", "\\f");
}

function json_pair(key, value) {
  return ((("\"" + json_escape(key)) + "\":\"") + json_escape(value)) + "\"";
}

/**
 * JSON format — one object per line (NDJSON / JSON Lines).
 *
 * Example:
 *   {"level":"info","time":"2026-…","msg":"Server started","port":"3000"}
 * 
 * @ignore
 */
function format_json(entry) {
  let _block;
  let $ = entry.namespace;
  if ($ instanceof Some) {
    let ns = $[0];
    _block = toList([
      json_pair("level", level_name(entry.level)),
      json_pair("time", entry.timestamp),
      json_pair("ns", ns),
      json_pair("msg", entry.message),
    ]);
  } else {
    _block = toList([
      json_pair("level", level_name(entry.level)),
      json_pair("time", entry.timestamp),
      json_pair("msg", entry.message),
    ]);
  }
  let core = _block;
  let user_fields = $list.map(
    entry.fields,
    (f) => {
      let k;
      let v;
      k = f[0];
      v = f[1];
      let _block$1;
      if (k === "level") {
        _block$1 = "_" + k;
      } else if (k === "time") {
        _block$1 = "_" + k;
      } else if (k === "ns") {
        _block$1 = "_" + k;
      } else if (k === "msg") {
        _block$1 = "_" + k;
      } else {
        _block$1 = k;
      }
      let safe_k = _block$1;
      return json_pair(safe_k, v);
    },
  );
  return ("{" + $string.join($list.append(core, user_fields), ",")) + "}";
}

function level_tag(level) {
  if (level instanceof Debug) {
    return "DEBUG";
  } else if (level instanceof Info) {
    return "INFO";
  } else if (level instanceof Warning) {
    return "WARN";
  } else {
    return "ERROR";
  }
}

/**
 * Compact format: single-line, key=value style.
 *
 *   INFO 2026-02-11T10:30:45Z Server started port=3000 workers=4
 * 
 * @ignore
 */
function format_compact(entry) {
  let tag = level_tag(entry.level);
  let _block;
  let $ = entry.namespace;
  if ($ instanceof Some) {
    let n = $[0];
    _block = " ns=" + n;
  } else {
    _block = "";
  }
  let ns = _block;
  let _block$1;
  let _pipe = entry.message;
  let _pipe$1 = $string.replace(_pipe, "\\", "\\\\");
  let _pipe$2 = $string.replace(_pipe$1, "\n", "\\n");
  _block$1 = $string.replace(_pipe$2, "\r", "\\r");
  let msg = _block$1;
  let base = ((((tag + " ") + entry.timestamp) + ns) + " ") + msg;
  let $1 = entry.fields;
  if ($1 instanceof $Empty) {
    return base;
  } else {
    let fields = $1;
    let _block$2;
    let _pipe$3 = $list.map(
      fields,
      (f) => {
        let k;
        let v;
        k = f[0];
        v = f[1];
        let needs_quotes = ((($string.contains(v, " ") || $string.contains(
          v,
          "=",
        )) || $string.contains(v, "\n")) || $string.contains(v, "\r")) || $string.is_empty(
          v,
        );
        let _block$3;
        if (needs_quotes) {
          _block$3 = ("\"" + (() => {
            let _pipe$3 = v;
            let _pipe$4 = $string.replace(_pipe$3, "\\", "\\\\");
            let _pipe$5 = $string.replace(_pipe$4, "\"", "\\\"");
            let _pipe$6 = $string.replace(_pipe$5, "\n", "\\n");
            return $string.replace(_pipe$6, "\r", "\\r");
          })()) + "\"";
        } else {
          _block$3 = v;
        }
        let val = _block$3;
        return (k + "=") + val;
      },
    );
    _block$2 = $string.join(_pipe$3, " ");
    let pairs = _block$2;
    return (base + " ") + pairs;
  }
}

/**
 * Extract HH:MM:SS from an ISO 8601 timestamp.
 * "2026-02-11T10:30:45.123Z" → "10:30:45"
 * 
 * @ignore
 */
function short_time(iso) {
  return $string.slice(iso, 11, 8);
}

function read_state() {
  return ffi_get_state(default_state());
}

/**
 * Check if a specific log level is currently enabled.
 *
 * Useful if you need to perform expensive work before emitting several
 * log messages, and want to skip that work if the level is silenced.
 */
export function is_enabled(level) {
  let state = read_state();
  return should_log(level, state.level);
}

/**
 * Get the current global context fields.
 */
export function get_global_context() {
  let state = read_state();
  return state.global_context;
}

function write_state(state) {
  return ffi_set_state(state);
}

/**
 * Replace the current configuration.
 *
 * This sets level, format, and color mode at once.  Global context is
 * left untouched — use `set_global_context` if you need to change it.
 */
export function configure(config) {
  let state = read_state();
  return write_state(
    new State(
      config.level,
      config.format,
      config.colors,
      state.global_context,
      state.sink,
    ),
  );
}

/**
 * Change whether text logs use ANSI colors.
 * (Json/Compact formats ignore this setting.)
 */
export function set_colors(mode) {
  let state = read_state();
  return write_state(
    new State(state.level, state.format, mode, state.global_context, state.sink),
  );
}

/**
 * Set the minimum log level.
 *
 * Messages below this level are silently dropped with near-zero overhead.
 */
export function set_level(level) {
  let state = read_state();
  return write_state(
    new State(
      level,
      state.format,
      state.colors,
      state.global_context,
      state.sink,
    ),
  );
}

/**
 * Set the output format.
 */
export function set_format(format) {
  let state = read_state();
  return write_state(
    new State(
      state.level,
      format,
      state.colors,
      state.global_context,
      state.sink,
    ),
  );
}

/**
 * Set the sink function used to emit formatted logs.
 *
 * The default sink uses `io.println` to write to standard output.
 */
export function set_sink(sink) {
  let state = read_state();
  return write_state(
    new State(
      state.level,
      state.format,
      state.colors,
      state.global_context,
      sink,
    ),
  );
}

/**
 * Set fields that appear on **every** log message globally.
 *
 * Typically called once at application start.
 */
export function set_global_context(fields) {
  let state = read_state();
  return write_state(
    new State(state.level, state.format, state.colors, fields, state.sink),
  );
}

/**
 * Append fields to the global context without replacing the existing ones.
 */
export function append_global_context(fields) {
  let current = get_global_context();
  return set_global_context($list.append(current, fields));
}

/**
 * Run `body` with extra fields attached to every log call inside it.
 *
 * Fields from the context are merged with inline fields.  If a key appears
 * in both, the inline value wins (it comes last in the list).
 *
 * Contexts can be nested — inner fields accumulate on top of outer ones.
 *
 * On the BEAM each process gets its own context (process dictionary), so
 * concurrent request handlers never interfere with each other.
 *
 * **Notice for JavaScript async users**: On the JavaScript target, because
 * JS uses cooperative concurrency and is single-threaded, `with_context` 
 * modifies a global state. If your callback enters an async sleep/promise,
 * the context might be overwritten by other concurrent tasks. Use with 
 * caution in highly concurrent async Node/Deno servers.
 */
export function with_context(fields, body) {
  let previous = ffi_get_context(toList([]));
  ffi_set_context($list.append(previous, fields));
  let result = body();
  ffi_set_context(previous);
  return result;
}

function no_color_set() {
  return $result.is_ok(ffi_get_env("NO_COLOR"));
}

/**
 * Decide whether to actually use colors given the mode.
 * 
 * @ignore
 */
function resolve_colors(mode) {
  if (mode instanceof Auto) {
    let $ = ffi_is_tty();
    if ($) {
      let $1 = no_color_set();
      if ($1) {
        return false;
      } else {
        return true;
      }
    } else {
      return $;
    }
  } else if (mode instanceof Always) {
    return true;
  } else {
    return false;
  }
}

/**
 * A sink that routes log events through the official logging pipeline.
 *
 * On the **BEAM target** each event is delivered to OTP's `logger` module
 * (available since OTP 21), so the entire BEAM ecosystem can observe,
 * filter, and re-route woof messages:
 *
 * - Applications that use woof no longer need a second logging system.
 * - Libraries that depend on woof can be silenced by the host application.
 * - BEAM logger handlers (Loki, Datadog, etc.) receive woof events.
 * - OTP performance features apply: async dispatch, load-shedding, etc.
 *
 * Each event is tagged with `domain => [woof]` so handlers and filters
 * can target woof output specifically:
 *
 * ```erlang
 * %% Silence all woof output in a specific environment:
 * logger:add_primary_filter(no_woof,
 *     {fun logger_filters:domain/2, {stop, sub, [woof]}}).
 * ```
 *
 * On the **JavaScript target** the event is passed to the level-appropriate
 * `console` method (`console.debug`, `console.info`, `console.warn`, or
 * `console.error`) — the JS equivalent of routing by severity.
 *
 * ## Usage
 *
 * Call once at application startup, before any logging:
 *
 * ```gleam
 * pub fn main() {
 *   woof.set_sink(woof.beam_logger_sink)
 *   // ... rest of startup
 * }
 * ```
 */
export function beam_logger_sink(entry, formatted) {
  return ffi_beam_log(
    entry.level,
    entry.message,
    entry.fields,
    entry.namespace,
    formatted,
  );
}

function level_color(level) {
  if (level instanceof Debug) {
    return ansi_dim;
  } else if (level instanceof Info) {
    return ansi_blue;
  } else if (level instanceof Warning) {
    return ansi_yellow;
  } else {
    return ansi_red_bold;
  }
}

/**
 * Text format example:
 *   [INFO] 10:30:45 Server started
 *     port: 3000
 *
 * With namespace:
 *   [INFO] 10:30:45 database: Connecting
 * 
 * @ignore
 */
function format_text(entry, use_colors) {
  let tag = level_tag(entry.level);
  let time$1 = short_time(entry.timestamp);
  let _block;
  let $ = entry.namespace;
  if ($ instanceof Some) {
    let n = $[0];
    _block = n + ": ";
  } else {
    _block = "";
  }
  let ns = _block;
  let _block$1;
  if (use_colors) {
    let color = level_color(entry.level);
    _block$1 = ((((((((((color + "[") + tag) + "]") + ansi_reset) + " ") + ansi_dim) + time$1) + ansi_reset) + " ") + ns) + entry.message;
  } else {
    _block$1 = ((((("[" + tag) + "] ") + time$1) + " ") + ns) + entry.message;
  }
  let header = _block$1;
  let $1 = entry.fields;
  if ($1 instanceof $Empty) {
    return header;
  } else {
    let fields = $1;
    let _block$2;
    let _pipe = $list.map(
      fields,
      (pair) => {
        let k;
        let v;
        k = pair[0];
        v = pair[1];
        return (("  " + k) + ": ") + v;
      },
    );
    _block$2 = $string.join(_pipe, "\n");
    let field_lines = _block$2;
    return (header + "\n") + field_lines;
  }
}

function format_entry(entry, output_format, colors) {
  if (output_format instanceof Text) {
    return format_text(entry, resolve_colors(colors));
  } else if (output_format instanceof Json) {
    return format_json(entry);
  } else if (output_format instanceof Compact) {
    return format_compact(entry);
  } else {
    let f = output_format.formatter;
    return f(entry);
  }
}

/**
 * Format an entry without emitting it.
 *
 * Handy for testing, previews, or sending formatted output to a custom
 * sink (file, HTTP, etc.).
 */
export function format(entry, output_format) {
  return format_entry(entry, output_format, new Never());
}

function do_emit(state, level, message, fields, namespace) {
  let ctx = ffi_get_context(toList([]));
  let all_fields = $list.flatten(toList([state.global_context, ctx, fields]));
  let entry = new Entry(level, message, all_fields, namespace, ffi_now());
  let formatted = format_entry(entry, state.format, state.colors);
  return state.sink(entry, formatted);
}

function emit(level, message, fields, namespace) {
  let state = read_state();
  let $ = should_log(level, state.level);
  if ($) {
    return do_emit(state, level, message, fields, namespace);
  } else {
    return undefined;
  }
}

/**
 * Log at Debug level.
 */
export function debug(message, fields) {
  return emit(new Debug(), message, fields, new None());
}

/**
 * Log at Info level.
 */
export function info(message, fields) {
  return emit(new Info(), message, fields, new None());
}

/**
 * Log at Warning level.
 */
export function warning(message, fields) {
  return emit(new Warning(), message, fields, new None());
}

/**
 * Log at Error level.
 */
export function error(message, fields) {
  return emit(new Error(), message, fields, new None());
}

/**
 * Log a message through a namespaced logger.
 */
export function log(logger, level, message, fields) {
  return emit(level, message, fields, new Some(logger.namespace));
}

/**
 * Log the value at Info level and pass it through.  Fits naturally in
 * pipelines.
 */
export function tap_info(value, message, fields) {
  info(message, fields);
  return value;
}

/**
 * Log the value at Debug level and pass it through.
 */
export function tap_debug(value, message, fields) {
  debug(message, fields);
  return value;
}

/**
 * Log the value at Warning level and pass it through.
 */
export function tap_warning(value, message, fields) {
  warning(message, fields);
  return value;
}

/**
 * Log the value at Error level and pass it through.
 */
export function tap_error(value, message, fields) {
  error(message, fields);
  return value;
}

/**
 * If the `Result` is `Error`, log the message at Error level and pass
 * the original value through — useful in result pipelines.
 */
export function log_error(res, message, fields) {
  let $ = $result.is_ok(res);
  if ($) {
    return res;
  } else {
    error(message, fields);
    return res;
  }
}

/**
 * Measure how long `body` takes and log it at Info level.
 *
 * Returns whatever `body` returns — the timing log is a side effect.
 */
export function time(label, body) {
  let start = ffi_monotonic_now();
  let result = body();
  let elapsed = ffi_monotonic_now() - start;
  info(label + " completed", toList([["duration_ms", $int.to_string(elapsed)]]));
  return result;
}

function emit_lazy(level, build, fields, namespace) {
  let state = read_state();
  let $ = should_log(level, state.level);
  if ($) {
    return do_emit(state, level, build(), fields, namespace);
  } else {
    return undefined;
  }
}

/**
 * Log at Debug level, evaluating the message only if Debug is enabled.
 *
 * Use this when building the message string is expensive.
 */
export function debug_lazy(build, fields) {
  return emit_lazy(new Debug(), build, fields, new None());
}

/**
 * Log at Info level, evaluating the message only if Info is enabled.
 */
export function info_lazy(build, fields) {
  return emit_lazy(new Info(), build, fields, new None());
}

/**
 * Log at Warning level, evaluating the message only if Warning is enabled.
 */
export function warning_lazy(build, fields) {
  return emit_lazy(new Warning(), build, fields, new None());
}

/**
 * Log at Error level, evaluating the message only if Error is enabled.
 */
export function error_lazy(build, fields) {
  return emit_lazy(new Error(), build, fields, new None());
}
