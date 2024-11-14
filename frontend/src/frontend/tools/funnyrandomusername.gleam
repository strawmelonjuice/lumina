// Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
// Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
const both = [
  "strawberry", "hat", "burger", "flat", "orange", "toothpaste", "nerd", "koala",
  "sample",
]

const first = [
  "straw", "hacker", "hat", "strawberry", "apple", "rotten", "shrimp", "feared-",
  "smelly",
]

const last = [
  "-bubble", "-hat", "-man", "-bro", "-woman", "grapes", "dancer", "salad",
  "hair",
]

import gleam/list
import gleam/string

/// Generate a random username
pub fn funnyrandomusername() {
  let assert Ok(start) =
    first
    |> list.append(both)
    |> list.shuffle()
    |> list.first()
  let assert Ok(end) =
    last
    |> list.append(both)
    |> list.shuffle()
    |> list.first()
  start
  <> end
  |> string.replace("--", "-")
}
