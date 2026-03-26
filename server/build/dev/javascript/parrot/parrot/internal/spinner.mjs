import * as $io from "../../../gleam_stdlib/gleam/io.mjs";
import * as $glearray from "../../../glearray/glearray.mjs";
import * as $repeatedly from "../../../repeatedly/repeatedly.mjs";
import { Ok, toList, CustomType as $CustomType, makeError, remainderInt } from "../../gleam.mjs";
import * as $lib from "../../parrot/internal/lib.mjs";

const FILEPATH = "src/parrot/internal/spinner.gleam";

class Spinner extends $CustomType {
  constructor(repeater, frames, current_text) {
    super();
    this.repeater = repeater;
    this.frames = frames;
    this.current_text = current_text;
  }
}

class State extends $CustomType {
  constructor(text, colour) {
    super();
    this.text = text;
    this.colour = colour;
  }
}

class Builder extends $CustomType {
  constructor(frames, text, colour) {
    super();
    this.frames = frames;
    this.text = text;
    this.colour = colour;
  }
}

const clear_line_code = "\u{001b}[2K";

const go_to_start_code = "\r";

export const clock_frames = /* @__PURE__ */ toList([
  "🕛",
  "🕐",
  "🕑",
  "🕒",
  "🕓",
  "🕔",
  "🕕",
  "🕖",
  "🕗",
  "🕘",
  "🕙",
  "🕚",
]);

export const half_circle_frames = /* @__PURE__ */ toList(["◐", "◓", "◑", "◒"]);

export const moon_frames = /* @__PURE__ */ toList([
  "🌑",
  "🌒",
  "🌓",
  "🌔",
  "🌕",
  "🌖",
  "🌗",
  "🌘",
]);

export const negative_dots_frames = /* @__PURE__ */ toList([
  "⣾",
  "⣽",
  "⣻",
  "⢿",
  "⡿",
  "⣟",
  "⣯",
  "⣷",
]);

export const snake_frames = /* @__PURE__ */ toList([
  "⠋",
  "⠙",
  "⠹",
  "⠸",
  "⠼",
  "⠴",
  "⠦",
  "⠧",
  "⠇",
  "⠏",
]);

export const triangle_frames = /* @__PURE__ */ toList(["◢", "◣", "◤", "◥"]);

export const walking_frames = /* @__PURE__ */ toList([
  "⢄",
  "⢂",
  "⢁",
  "⡁",
  "⡈",
  "⡐",
  "⡠",
]);

function magenta(text) {
  return ("\u{001b}[35m" + text) + $lib.colorless;
}

function green(text) {
  return ("\u{001b}[32m" + text) + $lib.colorless;
}

export function with_frames(builder, frames) {
  return new Builder(frames, builder.text, builder.colour);
}

export function with_colour(builder, colour) {
  return new Builder(builder.frames, builder.text, colour);
}

export function set_text(spinner, text) {
  return $repeatedly.update_state(
    spinner.repeater,
    (state) => { return new State(text, state.colour); },
  );
}

export function set_colour(spinner, colour) {
  return $repeatedly.update_state(
    spinner.repeater,
    (state) => { return new State(state.text, colour); },
  );
}

export function green_checkmark() {
  let checkmark = "✓";
  return green(checkmark);
}

export function orange_warning() {
  let warning = "⚠️";
  return magenta(warning);
}

function frame(frames, index) {
  let $ = $glearray.get(frames, remainderInt(index, $glearray.length(frames)));
  let frame$1;
  if ($ instanceof Ok) {
    frame$1 = $[0];
  } else {
    throw makeError(
      "let_assert",
      FILEPATH,
      "parrot/internal/spinner",
      205,
      "frame",
      "Pattern match failed, no pattern matched the value.",
      {
        value: $,
        start: 5323,
        end: 5399,
        pattern_start: 5334,
        pattern_end: 5343
      }
    )
  }
  return frame$1;
}

/**
 * Stop the spinner with a checkmark and move to the next line.
 * This shows completion and prepares for the next task.
 */
export function complete_and_continue(spinner, completed_text) {
  $repeatedly.stop(spinner.repeater);
  let checkmark = "✓";
  $io.print(
    (((clear_line_code + go_to_start_code) + green(checkmark)) + " ") + completed_text,
  );
  return $io.print("\n");
}

export function complete_and_continue_current(spinner) {
  return complete_and_continue(spinner, spinner.current_text);
}

/**
 * Stop the spinner with a checkmark, showing the completed task.
 * This is useful when you want to show completion without starting a new spinner.
 */
export function complete(spinner, completed_text, prefix) {
  $repeatedly.stop(spinner.repeater);
  let show_cursor = "\u{001b}[?25h";
  $io.print(
    ((((clear_line_code + go_to_start_code) + prefix) + " ") + completed_text) + show_cursor,
  );
  return $io.print("\n");
}

export function complete_current(spinner, prefix) {
  complete(spinner, spinner.current_text, prefix);
  return $io.print("");
}

/**
 * Stop the spinner with an error mark, showing the failed task.
 * This is useful when you want to show failure.
 */
export function fail(spinner, failed_text) {
  $repeatedly.stop(spinner.repeater);
  let error_mark = "✗";
  let red = (text) => { return ("\u{001b}[31m" + text) + $lib.colorless; };
  let show_cursor = "\u{001b}[?25h";
  $io.print(
    ((((clear_line_code + go_to_start_code) + red(error_mark)) + " ") + failed_text) + show_cursor,
  );
  return $io.print("\n");
}

/**
 * Stop the spinner, clearing the terminal line and showing the cursor. You
 * may want to print a success message after this.
 *
 * This should be called before your program ends to re-enable the terminal
 * cursor.
 */
export function stop(spinner) {
  $repeatedly.stop(spinner.repeater);
  let show_cursor = "\u{001b}[?25h";
  return $io.print((clear_line_code + go_to_start_code) + show_cursor);
}

function print(frames, state, index) {
  let hide_cursor = "\u{001b}[?25l";
  return $io.print(
    ((((hide_cursor + clear_line_code) + go_to_start_code) + state.colour(
      frame(frames, index),
    )) + " ") + state.text,
  );
}

export function start(builder) {
  let frames = $glearray.from_list(builder.frames);
  let repeater = $repeatedly.call(
    80,
    new State(builder.text, builder.colour),
    (state, i) => {
      print(frames, state, i);
      return state;
    },
  );
  return new Spinner(repeater, frames, builder.text);
}

export function with_spinner(builder, context) {
  let spinner = start(builder);
  context(spinner);
  return stop(spinner);
}

/**
 * Start a spinner that runs concurrently in another Erlang process or
 * JavaScript task.
 */
export function new$(text) {
  return new Builder(snake_frames, text, magenta);
}
