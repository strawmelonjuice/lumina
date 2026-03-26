import gleam/erlang/atom
import gleam/erlang/process
import gleam/int
import gleam/otp/actor
import gleam/result
import gleam/string
import gleam/string_tree
import logging

/// Message that can be sent to the clock actor.
/// 
type Message {
  Tick
}

/// Starts the clock application.
/// 
pub fn start(_type, _args) -> Result(process.Pid, actor.StartError) {
  actor.new_with_initialiser(1000, fn(subject) {
    init_clock_storage()
    set_http_date(calculate_http_date())
    process.send_after(subject, 1000, Tick)

    actor.initialised(subject)
    |> actor.returning(subject)
    |> Ok
  })
  |> actor.on_message(fn(subject, _msg) {
    process.send_after(subject, 1000, Tick)

    set_http_date(calculate_http_date())

    actor.continue(subject)
  })
  |> actor.start()
  |> result.map(fn(started) {
    let assert Ok(pid) = process.subject_owner(started.data)
    pid
  })
}

/// Stops the clock application.
/// 
pub fn stop(_state) {
  atom.create("ok")
}

/// Looks up the HTTP date from the clock storage or calculates a new one if 
/// it's not found.
/// 
pub fn get_http_date() -> String {
  case lookup_http_date() {
    Ok(date) -> date
    Error(Nil) -> {
      logging.log(
        logging.Warning,
        "Failed to lookup HTTP date, calculating new one",
      )
      calculate_http_date()
    }
  }
}

/// Calculates the HTTP date based on the current time.
/// 
fn calculate_http_date() -> String {
  let #(weekday, #(year, month, day), #(hour, minute, second)) = now()
  string_tree.new()
  |> string_tree.append(weekday_to_string(weekday))
  |> string_tree.append(", ")
  |> string_tree.append(int.to_string(day) |> string.pad_start(2, "0"))
  |> string_tree.append(" ")
  |> string_tree.append(month_to_string(month))
  |> string_tree.append(" ")
  |> string_tree.append(int.to_string(year) |> string.pad_start(4, "0"))
  |> string_tree.append(" ")
  |> string_tree.append(int.to_string(hour) |> string.pad_start(2, "0"))
  |> string_tree.append(":")
  |> string_tree.append(int.to_string(minute) |> string.pad_start(2, "0"))
  |> string_tree.append(":")
  |> string_tree.append(int.to_string(second) |> string.pad_start(2, "0"))
  |> string_tree.append(" GMT")
  |> string_tree.to_string()
}

/// Converts a weekday number to a string.
/// 
fn weekday_to_string(weekday: Int) -> String {
  case weekday {
    1 -> "Mon"
    2 -> "Tue"
    3 -> "Wed"
    4 -> "Thu"
    5 -> "Fri"
    6 -> "Sat"
    7 -> "Sun"
    _ ->
      panic as "erlang is breaking the fourth wall: erlang weekday outside of 1-7 range"
  }
}

/// Converts a month number to a string.
/// 
fn month_to_string(month: Int) -> String {
  case month {
    1 -> "Jan"
    2 -> "Feb"
    3 -> "Mar"
    4 -> "Apr"
    5 -> "May"
    6 -> "Jun"
    7 -> "Jul"
    8 -> "Aug"
    9 -> "Sep"
    10 -> "Oct"
    11 -> "Nov"
    12 -> "Dec"
    _ ->
      panic as "erlang is breaking the fourth wall: erlang month outside of 1-12 range"
  }
}

@external(erlang, "ewe_ffi", "now")
fn now() -> #(Int, #(Int, Int, Int), #(Int, Int, Int))

@external(erlang, "ewe_ffi", "init_clock_storage")
fn init_clock_storage() -> Nil

@external(erlang, "ewe_ffi", "set_http_date")
fn set_http_date(date: String) -> Nil

@external(erlang, "ewe_ffi", "lookup_http_date")
fn lookup_http_date() -> Result(String, Nil)
