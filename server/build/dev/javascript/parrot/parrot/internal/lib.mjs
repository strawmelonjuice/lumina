import * as $filepath from "../../../filepath/filepath.mjs";
import * as $bool from "../../../gleam_stdlib/gleam/bool.mjs";
import * as $dict from "../../../gleam_stdlib/gleam/dict.mjs";
import * as $list from "../../../gleam_stdlib/gleam/list.mjs";
import * as $result from "../../../gleam_stdlib/gleam/result.mjs";
import * as $simplifile from "../../../simplifile/simplifile.mjs";
import { Ok, Error, toList, makeError } from "../../gleam.mjs";

const FILEPATH = "src/parrot/internal/lib.gleam";

export const colorless = "\u{001b}[0m";

export function try_nil(result, do$) {
  return $result.try$($result.replace_error(result, undefined), do$);
}

/**
 * Finds all `from/**\/sql` directories and lists the full paths of the `*.sql`
 * files inside each one.
 * https://github.com/giacomocavalieri/squirrel/blob/main/src/squirrel.gleam
 */
export function walk(from) {
  let $ = $filepath.base_name(from);
  if ($ === "sql") {
    let $1 = $simplifile.read_directory(from);
    let files;
    if ($1 instanceof Ok) {
      files = $1[0];
    } else {
      throw makeError(
        "let_assert",
        FILEPATH,
        "parrot/internal/lib",
        27,
        "walk",
        "Pattern match failed, no pattern matched the value.",
        { value: $1, start: 653, end: 707, pattern_start: 664, pattern_end: 673 }
      )
    }
    let files$1 = $list.filter_map(
      files,
      (file) => {
        return $result.try$(
          $filepath.extension(file),
          (extension) => {
            return $bool.guard(
              extension !== "sql",
              new Error(undefined),
              () => {
                let file_name = $filepath.join(from, file);
                let $2 = $simplifile.is_file(file_name);
                if ($2 instanceof Ok) {
                  let $3 = $2[0];
                  if ($3) {
                    return new Ok(file_name);
                  } else {
                    return new Error(undefined);
                  }
                } else {
                  return new Error(undefined);
                }
              },
            );
          },
        );
      },
    );
    return $dict.from_list(toList([[from, files$1]]));
  } else {
    let $1 = $simplifile.read_directory(from);
    let files;
    if ($1 instanceof Ok) {
      files = $1[0];
    } else {
      throw makeError(
        "let_assert",
        FILEPATH,
        "parrot/internal/lib",
        42,
        "walk",
        "Pattern match failed, no pattern matched the value.",
        {
          value: $1,
          start: 1162,
          end: 1216,
          pattern_start: 1173,
          pattern_end: 1182
        }
      )
    }
    let directories = $list.filter_map(
      files,
      (file) => {
        let file_name = $filepath.join(from, file);
        let $2 = $simplifile.is_directory(file_name);
        if ($2 instanceof Ok) {
          let $3 = $2[0];
          if ($3) {
            return new Ok(file_name);
          } else {
            return new Error(undefined);
          }
        } else {
          return new Error(undefined);
        }
      },
    );
    let _pipe = $list.map(directories, walk);
    return $list.fold(_pipe, $dict.new$(), $dict.merge);
  }
}

export function green(text) {
  return ("\u{001b}[32m" + text) + colorless;
}

export function red(text) {
  return ("\u{001b}[31m" + text) + colorless;
}

export function yellow(text) {
  return ("\u{001b}[33m" + text) + colorless;
}
