import * as $filepath from "../../../filepath/filepath.mjs";
import * as $simplifile from "../../../simplifile/simplifile.mjs";
import * as $tom from "../../../tom/tom.mjs";
import { Ok, toList, makeError } from "../../gleam.mjs";

const FILEPATH = "src/parrot/internal/project.gleam";

function find_root(loop$path) {
  while (true) {
    let path = loop$path;
    let toml = $filepath.join(path, "gleam.toml");
    let $ = $simplifile.is_file(toml);
    if ($ instanceof Ok) {
      let $1 = $[0];
      if ($1) {
        return path;
      } else {
        loop$path = $filepath.join("..", path);
      }
    } else {
      loop$path = $filepath.join("..", path);
    }
  }
}

export function root() {
  return find_root(".");
}

export function src() {
  return $filepath.join(root(), "src");
}

export function project_name() {
  let root$1 = find_root(".");
  let toml_path = $filepath.join(root$1, "gleam.toml");
  let $ = $simplifile.read(toml_path);
  let toml;
  if ($ instanceof Ok) {
    toml = $[0];
  } else {
    throw makeError(
      "let_assert",
      FILEPATH,
      "parrot/internal/project",
      20,
      "project_name",
      "Pattern match failed, no pattern matched the value.",
      { value: $, start: 441, end: 489, pattern_start: 452, pattern_end: 460 }
    )
  }
  let $1 = $tom.parse(toml);
  let parsed;
  if ($1 instanceof Ok) {
    parsed = $1[0];
  } else {
    throw makeError(
      "let_assert",
      FILEPATH,
      "parrot/internal/project",
      22,
      "project_name",
      "Pattern match failed, no pattern matched the value.",
      { value: $1, start: 493, end: 532, pattern_start: 504, pattern_end: 514 }
    )
  }
  let $2 = $tom.get_string(parsed, toList(["name"]));
  let name;
  if ($2 instanceof Ok) {
    name = $2[0];
  } else {
    throw makeError(
      "let_assert",
      FILEPATH,
      "parrot/internal/project",
      23,
      "project_name",
      "Pattern match failed, no pattern matched the value.",
      { value: $2, start: 535, end: 589, pattern_start: 546, pattern_end: 554 }
    )
  }
  return name;
}
