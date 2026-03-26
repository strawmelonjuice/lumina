import { toList as to_list, Ok, Error } from "./gleam.mjs";
import {
  newArray as new$,
  fromList as from_list,
  arrayLength as length,
  get as do_get,
  set as do_set,
  push as copy_push,
  insert as do_insert,
} from "./glearray_ffi.mjs";

export { copy_push, from_list, length, new$, to_list };

function is_valid_index(array, index) {
  return (index >= 0) && (index < length(array));
}

/**
 * Returns the element at the specified index, starting from 0.
 *
 * `Error(Nil)` is returned if `index` is less than 0 or greater than
 * or equal to `length(array)`.
 *
 * ## Performance
 *
 * This function is very efficient and runs in constant time.
 *
 * ## Examples
 *
 * ```gleam
 * > from_list([5, 6, 7]) |> get(1)
 * Ok(6)
 * ```
 *
 * ```gleam
 * > from_list([5, 6, 7]) |> get(3)
 * Error(Nil)
 * ```
 */
export function get(array, index) {
  let $ = is_valid_index(array, index);
  if ($) {
    return new Ok(do_get(array, index));
  } else {
    return new Error(undefined);
  }
}

/**
 * Returns the element at the specified index, starting from 0.
 *
 * The specified default is returned if `index` is less than 0 or
 * greater than / or equal to `length(array)`.
 *
 * ## Performance
 *
 * This function is very efficient and runs in constant time.
 *
 * ## Examples
 *
 * ```gleam
 * > from_list([5, 6, 7]) |> get_or_default(1, -1)
 * 6
 * ```
 *
 * ```gleam
 * > from_list([5, 6, 7]) |> get_or_default(3, -1)
 * -1
 * ```
 */
export function get_or_default(array, index, default$) {
  let $ = is_valid_index(array, index);
  if ($) {
    return do_get(array, index);
  } else {
    return default$;
  }
}

/**
 * Replaces the element at the given index with `value`.
 *
 * This function cannot extend an array and returns `Error(Nil)` if `index` is
 * not valid.
 * See also [`copy_insert`](#copy_insert) and [`copy_push`](#copy_push).
 *
 * ## Performance
 *
 * This function has to copy the entire array, making it very inefficient
 * especially for larger arrays.
 *
 * ## Examples
 *
 * ```gleam
 * > from_list(["a", "b", "c"]) |> copy_set(1, "x")
 * Ok(from_list(["a", "x", "c"]))
 * ```
 *
 * ```gleam
 * > from_list(["a", "b", "c"]) |> copy_set(3, "x")
 * Error(Nil)
 * ```
 */
export function copy_set(array, index, value) {
  let $ = is_valid_index(array, index);
  if ($) {
    return new Ok(do_set(array, index, value));
  } else {
    return new Error(undefined);
  }
}

/**
 * Inserts an element into the array at the given index.
 *
 * All following elements are shifted to the right, having their index
 * incremented by one.
 *
 * `Error(Nil)` is returned if the index is less than 0 or greater than
 * `length(array)`.
 * If the index is equal to `length(array)`, this function behaves like
 * [`copy_push`](#copy_push).
 *
 * ## Performance
 *
 * This function has to copy the entire array, making it very inefficient
 * especially for larger arrays.
 *
 * ## Examples
 *
 * ```gleam
 * > from_list(["a", "b"]) |> copy_insert(0, "c")
 * Ok(from_list(["c", "a", "b"]))
 * ```
 *
 * ```gleam
 * > from_list(["a", "b"]) |> copy_insert(1, "c")
 * Ok(from_list(["a", "c", "b"]))
 * ```
 *
 * ```gleam
 * > from_list(["a", "b"]) |> copy_insert(2, "c")
 * Ok(from_list(["a", "b", "c"]))
 * ```
 *
 * ```gleam
 * > from_list(["a", "b"]) |> copy_insert(3, "c")
 * Error(Nil)
 * ```
 */
export function copy_insert(array, index, value) {
  let $ = (index >= 0) && (index <= length(array));
  if ($) {
    return new Ok(do_insert(array, index, value));
  } else {
    return new Error(undefined);
  }
}
