// build/dev/javascript/prelude.mjs
class CustomType {
  withFields(fields) {
    let properties = Object.keys(this).map((label) => (label in fields) ? fields[label] : this[label]);
    return new this.constructor(...properties);
  }
}

class List {
  static fromArray(array, tail) {
    let t = tail || new Empty;
    for (let i = array.length - 1;i >= 0; --i) {
      t = new NonEmpty(array[i], t);
    }
    return t;
  }
  [Symbol.iterator]() {
    return new ListIterator(this);
  }
  toArray() {
    return [...this];
  }
  atLeastLength(desired) {
    let current = this;
    while (desired-- > 0 && current)
      current = current.tail;
    return current !== undefined;
  }
  hasLength(desired) {
    let current = this;
    while (desired-- > 0 && current)
      current = current.tail;
    return desired === -1 && current instanceof Empty;
  }
  countLength() {
    let current = this;
    let length = 0;
    while (current) {
      current = current.tail;
      length++;
    }
    return length - 1;
  }
}
function prepend(element, tail) {
  return new NonEmpty(element, tail);
}
function toList(elements, tail) {
  return List.fromArray(elements, tail);
}

class ListIterator {
  #current;
  constructor(current) {
    this.#current = current;
  }
  next() {
    if (this.#current instanceof Empty) {
      return { done: true };
    } else {
      let { head, tail } = this.#current;
      this.#current = tail;
      return { value: head, done: false };
    }
  }
}

class Empty extends List {
}
class NonEmpty extends List {
  constructor(head, tail) {
    super();
    this.head = head;
    this.tail = tail;
  }
}
class BitArray {
  bitSize;
  byteSize;
  bitOffset;
  rawBuffer;
  constructor(buffer, bitSize, bitOffset) {
    if (!(buffer instanceof Uint8Array)) {
      throw globalThis.Error("BitArray can only be constructed from a Uint8Array");
    }
    this.bitSize = bitSize ?? buffer.length * 8;
    this.byteSize = Math.trunc((this.bitSize + 7) / 8);
    this.bitOffset = bitOffset ?? 0;
    if (this.bitSize < 0) {
      throw globalThis.Error(`BitArray bit size is invalid: ${this.bitSize}`);
    }
    if (this.bitOffset < 0 || this.bitOffset > 7) {
      throw globalThis.Error(`BitArray bit offset is invalid: ${this.bitOffset}`);
    }
    if (buffer.length !== Math.trunc((this.bitOffset + this.bitSize + 7) / 8)) {
      throw globalThis.Error("BitArray buffer length is invalid");
    }
    this.rawBuffer = buffer;
  }
  byteAt(index) {
    if (index < 0 || index >= this.byteSize) {
      return;
    }
    return bitArrayByteAt(this.rawBuffer, this.bitOffset, index);
  }
  equals(other) {
    if (this.bitSize !== other.bitSize) {
      return false;
    }
    const wholeByteCount = Math.trunc(this.bitSize / 8);
    if (this.bitOffset === 0 && other.bitOffset === 0) {
      for (let i = 0;i < wholeByteCount; i++) {
        if (this.rawBuffer[i] !== other.rawBuffer[i]) {
          return false;
        }
      }
      const trailingBitsCount = this.bitSize % 8;
      if (trailingBitsCount) {
        const unusedLowBitCount = 8 - trailingBitsCount;
        if (this.rawBuffer[wholeByteCount] >> unusedLowBitCount !== other.rawBuffer[wholeByteCount] >> unusedLowBitCount) {
          return false;
        }
      }
    } else {
      for (let i = 0;i < wholeByteCount; i++) {
        const a = bitArrayByteAt(this.rawBuffer, this.bitOffset, i);
        const b = bitArrayByteAt(other.rawBuffer, other.bitOffset, i);
        if (a !== b) {
          return false;
        }
      }
      const trailingBitsCount = this.bitSize % 8;
      if (trailingBitsCount) {
        const a = bitArrayByteAt(this.rawBuffer, this.bitOffset, wholeByteCount);
        const b = bitArrayByteAt(other.rawBuffer, other.bitOffset, wholeByteCount);
        const unusedLowBitCount = 8 - trailingBitsCount;
        if (a >> unusedLowBitCount !== b >> unusedLowBitCount) {
          return false;
        }
      }
    }
    return true;
  }
  get buffer() {
    if (this.bitOffset !== 0 || this.bitSize % 8 !== 0) {
      throw new globalThis.Error("BitArray.buffer does not support unaligned bit arrays");
    }
    return this.rawBuffer;
  }
  get length() {
    if (this.bitOffset !== 0 || this.bitSize % 8 !== 0) {
      throw new globalThis.Error("BitArray.length does not support unaligned bit arrays");
    }
    return this.rawBuffer.length;
  }
}
function bitArrayByteAt(buffer, bitOffset, index) {
  if (bitOffset === 0) {
    return buffer[index] ?? 0;
  } else {
    const a = buffer[index] << bitOffset & 255;
    const b = buffer[index + 1] >> 8 - bitOffset;
    return a | b;
  }
}

class UtfCodepoint {
  constructor(value) {
    this.value = value;
  }
}
class Result extends CustomType {
  static isResult(data) {
    return data instanceof Result;
  }
}

class Ok extends Result {
  constructor(value) {
    super();
    this[0] = value;
  }
  isOk() {
    return true;
  }
}
class Error extends Result {
  constructor(detail) {
    super();
    this[0] = detail;
  }
  isOk() {
    return false;
  }
}
function isEqual(x, y) {
  let values = [x, y];
  while (values.length) {
    let a = values.pop();
    let b = values.pop();
    if (a === b)
      continue;
    if (!isObject(a) || !isObject(b))
      return false;
    let unequal = !structurallyCompatibleObjects(a, b) || unequalDates(a, b) || unequalBuffers(a, b) || unequalArrays(a, b) || unequalMaps(a, b) || unequalSets(a, b) || unequalRegExps(a, b);
    if (unequal)
      return false;
    const proto = Object.getPrototypeOf(a);
    if (proto !== null && typeof proto.equals === "function") {
      try {
        if (a.equals(b))
          continue;
        else
          return false;
      } catch {}
    }
    let [keys, get] = getters(a);
    const ka = keys(a);
    const kb = keys(b);
    if (ka.length !== kb.length)
      return false;
    for (let k of ka) {
      values.push(get(a, k), get(b, k));
    }
  }
  return true;
}
function getters(object) {
  if (object instanceof Map) {
    return [(x) => x.keys(), (x, y) => x.get(y)];
  } else {
    let extra = object instanceof globalThis.Error ? ["message"] : [];
    return [(x) => [...extra, ...Object.keys(x)], (x, y) => x[y]];
  }
}
function unequalDates(a, b) {
  return a instanceof Date && (a > b || a < b);
}
function unequalBuffers(a, b) {
  return !(a instanceof BitArray) && a.buffer instanceof ArrayBuffer && a.BYTES_PER_ELEMENT && !(a.byteLength === b.byteLength && a.every((n, i) => n === b[i]));
}
function unequalArrays(a, b) {
  return Array.isArray(a) && a.length !== b.length;
}
function unequalMaps(a, b) {
  return a instanceof Map && a.size !== b.size;
}
function unequalSets(a, b) {
  return a instanceof Set && (a.size != b.size || [...a].some((e) => !b.has(e)));
}
function unequalRegExps(a, b) {
  return a instanceof RegExp && (a.source !== b.source || a.flags !== b.flags);
}
function isObject(a) {
  return typeof a === "object" && a !== null;
}
function structurallyCompatibleObjects(a, b) {
  if (typeof a !== "object" && typeof b !== "object" && (!a || !b))
    return false;
  let nonstructural = [Promise, WeakSet, WeakMap, Function];
  if (nonstructural.some((c) => a instanceof c))
    return false;
  return a.constructor === b.constructor;
}
function remainderInt(a, b) {
  if (b === 0) {
    return 0;
  } else {
    return a % b;
  }
}
function divideInt(a, b) {
  return Math.trunc(divideFloat(a, b));
}
function divideFloat(a, b) {
  if (b === 0) {
    return 0;
  } else {
    return a / b;
  }
}
function makeError(variant, file, module, line, fn, message, extra) {
  let error = new globalThis.Error(message);
  error.gleam_error = variant;
  error.file = file;
  error.module = module;
  error.line = line;
  error.function = fn;
  error.fn = fn;
  for (let k in extra)
    error[k] = extra[k];
  return error;
}
// build/dev/javascript/gleam_stdlib/gleam/order.mjs
class Lt extends CustomType {
}
class Eq extends CustomType {
}
class Gt extends CustomType {
}

// build/dev/javascript/gleam_stdlib/gleam/option.mjs
class Some extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class None extends CustomType {
}
function is_some(option) {
  return !(option instanceof None);
}
function to_result(option, e) {
  if (option instanceof Some) {
    let a = option[0];
    return new Ok(a);
  } else {
    return new Error(e);
  }
}
function unwrap(option, default$) {
  if (option instanceof Some) {
    let x = option[0];
    return x;
  } else {
    return default$;
  }
}
function map(option, fun) {
  if (option instanceof Some) {
    let x = option[0];
    return new Some(fun(x));
  } else {
    return option;
  }
}
function or(first, second) {
  if (first instanceof Some) {
    return first;
  } else {
    return second;
  }
}

// build/dev/javascript/gleam_stdlib/gleam/dict.mjs
function insert(dict, key, value) {
  return map_insert(key, value, dict);
}
function reverse_and_concat(loop$remaining, loop$accumulator) {
  while (true) {
    let remaining = loop$remaining;
    let accumulator = loop$accumulator;
    if (remaining instanceof Empty) {
      return accumulator;
    } else {
      let first = remaining.head;
      let rest = remaining.tail;
      loop$remaining = rest;
      loop$accumulator = prepend(first, accumulator);
    }
  }
}
function do_keys_loop(loop$list, loop$acc) {
  while (true) {
    let list = loop$list;
    let acc = loop$acc;
    if (list instanceof Empty) {
      return reverse_and_concat(acc, toList([]));
    } else {
      let rest = list.tail;
      let key = list.head[0];
      loop$list = rest;
      loop$acc = prepend(key, acc);
    }
  }
}
function keys(dict) {
  return do_keys_loop(map_to_list(dict), toList([]));
}
function do_values_loop(loop$list, loop$acc) {
  while (true) {
    let list = loop$list;
    let acc = loop$acc;
    if (list instanceof Empty) {
      return reverse_and_concat(acc, toList([]));
    } else {
      let rest = list.tail;
      let value = list.head[1];
      loop$list = rest;
      loop$acc = prepend(value, acc);
    }
  }
}
function values(dict) {
  let list_of_pairs = map_to_list(dict);
  return do_values_loop(list_of_pairs, toList([]));
}
function fold_loop(loop$list, loop$initial, loop$fun) {
  while (true) {
    let list = loop$list;
    let initial = loop$initial;
    let fun = loop$fun;
    if (list instanceof Empty) {
      return initial;
    } else {
      let rest = list.tail;
      let k = list.head[0];
      let v = list.head[1];
      loop$list = rest;
      loop$initial = fun(initial, k, v);
      loop$fun = fun;
    }
  }
}
function fold(dict, initial, fun) {
  return fold_loop(map_to_list(dict), initial, fun);
}

// build/dev/javascript/gleam_stdlib/gleam/pair.mjs
function new$(first, second) {
  return [first, second];
}

// build/dev/javascript/gleam_stdlib/gleam/list.mjs
class Ascending extends CustomType {
}

class Descending extends CustomType {
}
function length_loop(loop$list, loop$count) {
  while (true) {
    let list = loop$list;
    let count = loop$count;
    if (list instanceof Empty) {
      return count;
    } else {
      let list$1 = list.tail;
      loop$list = list$1;
      loop$count = count + 1;
    }
  }
}
function length(list) {
  return length_loop(list, 0);
}
function reverse_and_prepend(loop$prefix, loop$suffix) {
  while (true) {
    let prefix = loop$prefix;
    let suffix = loop$suffix;
    if (prefix instanceof Empty) {
      return suffix;
    } else {
      let first$1 = prefix.head;
      let rest$1 = prefix.tail;
      loop$prefix = rest$1;
      loop$suffix = prepend(first$1, suffix);
    }
  }
}
function reverse(list) {
  return reverse_and_prepend(list, toList([]));
}
function filter_map_loop(loop$list, loop$fun, loop$acc) {
  while (true) {
    let list = loop$list;
    let fun = loop$fun;
    let acc = loop$acc;
    if (list instanceof Empty) {
      return reverse(acc);
    } else {
      let first$1 = list.head;
      let rest$1 = list.tail;
      let _block;
      let $ = fun(first$1);
      if ($ instanceof Ok) {
        let first$2 = $[0];
        _block = prepend(first$2, acc);
      } else {
        _block = acc;
      }
      let new_acc = _block;
      loop$list = rest$1;
      loop$fun = fun;
      loop$acc = new_acc;
    }
  }
}
function filter_map(list, fun) {
  return filter_map_loop(list, fun, toList([]));
}
function map_loop(loop$list, loop$fun, loop$acc) {
  while (true) {
    let list = loop$list;
    let fun = loop$fun;
    let acc = loop$acc;
    if (list instanceof Empty) {
      return reverse(acc);
    } else {
      let first$1 = list.head;
      let rest$1 = list.tail;
      loop$list = rest$1;
      loop$fun = fun;
      loop$acc = prepend(fun(first$1), acc);
    }
  }
}
function map2(list, fun) {
  return map_loop(list, fun, toList([]));
}
function take_loop(loop$list, loop$n, loop$acc) {
  while (true) {
    let list = loop$list;
    let n = loop$n;
    let acc = loop$acc;
    let $ = n <= 0;
    if ($) {
      return reverse(acc);
    } else {
      if (list instanceof Empty) {
        return reverse(acc);
      } else {
        let first$1 = list.head;
        let rest$1 = list.tail;
        loop$list = rest$1;
        loop$n = n - 1;
        loop$acc = prepend(first$1, acc);
      }
    }
  }
}
function take(list, n) {
  return take_loop(list, n, toList([]));
}
function append_loop(loop$first, loop$second) {
  while (true) {
    let first = loop$first;
    let second = loop$second;
    if (first instanceof Empty) {
      return second;
    } else {
      let first$1 = first.head;
      let rest$1 = first.tail;
      loop$first = rest$1;
      loop$second = prepend(first$1, second);
    }
  }
}
function append(first, second) {
  return append_loop(reverse(first), second);
}
function prepend2(list, item) {
  return prepend(item, list);
}
function flatten_loop(loop$lists, loop$acc) {
  while (true) {
    let lists = loop$lists;
    let acc = loop$acc;
    if (lists instanceof Empty) {
      return reverse(acc);
    } else {
      let list = lists.head;
      let further_lists = lists.tail;
      loop$lists = further_lists;
      loop$acc = reverse_and_prepend(list, acc);
    }
  }
}
function flatten(lists) {
  return flatten_loop(lists, toList([]));
}
function fold2(loop$list, loop$initial, loop$fun) {
  while (true) {
    let list = loop$list;
    let initial = loop$initial;
    let fun = loop$fun;
    if (list instanceof Empty) {
      return initial;
    } else {
      let first$1 = list.head;
      let rest$1 = list.tail;
      loop$list = rest$1;
      loop$initial = fun(initial, first$1);
      loop$fun = fun;
    }
  }
}
function all(loop$list, loop$predicate) {
  while (true) {
    let list = loop$list;
    let predicate = loop$predicate;
    if (list instanceof Empty) {
      return true;
    } else {
      let first$1 = list.head;
      let rest$1 = list.tail;
      let $ = predicate(first$1);
      if ($) {
        loop$list = rest$1;
        loop$predicate = predicate;
      } else {
        return $;
      }
    }
  }
}
function sequences(loop$list, loop$compare, loop$growing, loop$direction, loop$prev, loop$acc) {
  while (true) {
    let list = loop$list;
    let compare3 = loop$compare;
    let growing = loop$growing;
    let direction = loop$direction;
    let prev = loop$prev;
    let acc = loop$acc;
    let growing$1 = prepend(prev, growing);
    if (list instanceof Empty) {
      if (direction instanceof Ascending) {
        return prepend(reverse(growing$1), acc);
      } else {
        return prepend(growing$1, acc);
      }
    } else {
      let new$1 = list.head;
      let rest$1 = list.tail;
      let $ = compare3(prev, new$1);
      if (direction instanceof Ascending) {
        if ($ instanceof Lt) {
          loop$list = rest$1;
          loop$compare = compare3;
          loop$growing = growing$1;
          loop$direction = direction;
          loop$prev = new$1;
          loop$acc = acc;
        } else if ($ instanceof Eq) {
          loop$list = rest$1;
          loop$compare = compare3;
          loop$growing = growing$1;
          loop$direction = direction;
          loop$prev = new$1;
          loop$acc = acc;
        } else {
          let _block;
          if (direction instanceof Ascending) {
            _block = prepend(reverse(growing$1), acc);
          } else {
            _block = prepend(growing$1, acc);
          }
          let acc$1 = _block;
          if (rest$1 instanceof Empty) {
            return prepend(toList([new$1]), acc$1);
          } else {
            let next = rest$1.head;
            let rest$2 = rest$1.tail;
            let _block$1;
            let $1 = compare3(new$1, next);
            if ($1 instanceof Lt) {
              _block$1 = new Ascending;
            } else if ($1 instanceof Eq) {
              _block$1 = new Ascending;
            } else {
              _block$1 = new Descending;
            }
            let direction$1 = _block$1;
            loop$list = rest$2;
            loop$compare = compare3;
            loop$growing = toList([new$1]);
            loop$direction = direction$1;
            loop$prev = next;
            loop$acc = acc$1;
          }
        }
      } else if ($ instanceof Lt) {
        let _block;
        if (direction instanceof Ascending) {
          _block = prepend(reverse(growing$1), acc);
        } else {
          _block = prepend(growing$1, acc);
        }
        let acc$1 = _block;
        if (rest$1 instanceof Empty) {
          return prepend(toList([new$1]), acc$1);
        } else {
          let next = rest$1.head;
          let rest$2 = rest$1.tail;
          let _block$1;
          let $1 = compare3(new$1, next);
          if ($1 instanceof Lt) {
            _block$1 = new Ascending;
          } else if ($1 instanceof Eq) {
            _block$1 = new Ascending;
          } else {
            _block$1 = new Descending;
          }
          let direction$1 = _block$1;
          loop$list = rest$2;
          loop$compare = compare3;
          loop$growing = toList([new$1]);
          loop$direction = direction$1;
          loop$prev = next;
          loop$acc = acc$1;
        }
      } else if ($ instanceof Eq) {
        let _block;
        if (direction instanceof Ascending) {
          _block = prepend(reverse(growing$1), acc);
        } else {
          _block = prepend(growing$1, acc);
        }
        let acc$1 = _block;
        if (rest$1 instanceof Empty) {
          return prepend(toList([new$1]), acc$1);
        } else {
          let next = rest$1.head;
          let rest$2 = rest$1.tail;
          let _block$1;
          let $1 = compare3(new$1, next);
          if ($1 instanceof Lt) {
            _block$1 = new Ascending;
          } else if ($1 instanceof Eq) {
            _block$1 = new Ascending;
          } else {
            _block$1 = new Descending;
          }
          let direction$1 = _block$1;
          loop$list = rest$2;
          loop$compare = compare3;
          loop$growing = toList([new$1]);
          loop$direction = direction$1;
          loop$prev = next;
          loop$acc = acc$1;
        }
      } else {
        loop$list = rest$1;
        loop$compare = compare3;
        loop$growing = growing$1;
        loop$direction = direction;
        loop$prev = new$1;
        loop$acc = acc;
      }
    }
  }
}
function merge_ascendings(loop$list1, loop$list2, loop$compare, loop$acc) {
  while (true) {
    let list1 = loop$list1;
    let list2 = loop$list2;
    let compare3 = loop$compare;
    let acc = loop$acc;
    if (list1 instanceof Empty) {
      let list = list2;
      return reverse_and_prepend(list, acc);
    } else if (list2 instanceof Empty) {
      let list = list1;
      return reverse_and_prepend(list, acc);
    } else {
      let first1 = list1.head;
      let rest1 = list1.tail;
      let first2 = list2.head;
      let rest2 = list2.tail;
      let $ = compare3(first1, first2);
      if ($ instanceof Lt) {
        loop$list1 = rest1;
        loop$list2 = list2;
        loop$compare = compare3;
        loop$acc = prepend(first1, acc);
      } else if ($ instanceof Eq) {
        loop$list1 = list1;
        loop$list2 = rest2;
        loop$compare = compare3;
        loop$acc = prepend(first2, acc);
      } else {
        loop$list1 = list1;
        loop$list2 = rest2;
        loop$compare = compare3;
        loop$acc = prepend(first2, acc);
      }
    }
  }
}
function merge_ascending_pairs(loop$sequences, loop$compare, loop$acc) {
  while (true) {
    let sequences2 = loop$sequences;
    let compare3 = loop$compare;
    let acc = loop$acc;
    if (sequences2 instanceof Empty) {
      return reverse(acc);
    } else {
      let $ = sequences2.tail;
      if ($ instanceof Empty) {
        let sequence = sequences2.head;
        return reverse(prepend(reverse(sequence), acc));
      } else {
        let ascending1 = sequences2.head;
        let ascending2 = $.head;
        let rest$1 = $.tail;
        let descending = merge_ascendings(ascending1, ascending2, compare3, toList([]));
        loop$sequences = rest$1;
        loop$compare = compare3;
        loop$acc = prepend(descending, acc);
      }
    }
  }
}
function merge_descendings(loop$list1, loop$list2, loop$compare, loop$acc) {
  while (true) {
    let list1 = loop$list1;
    let list2 = loop$list2;
    let compare3 = loop$compare;
    let acc = loop$acc;
    if (list1 instanceof Empty) {
      let list = list2;
      return reverse_and_prepend(list, acc);
    } else if (list2 instanceof Empty) {
      let list = list1;
      return reverse_and_prepend(list, acc);
    } else {
      let first1 = list1.head;
      let rest1 = list1.tail;
      let first2 = list2.head;
      let rest2 = list2.tail;
      let $ = compare3(first1, first2);
      if ($ instanceof Lt) {
        loop$list1 = list1;
        loop$list2 = rest2;
        loop$compare = compare3;
        loop$acc = prepend(first2, acc);
      } else if ($ instanceof Eq) {
        loop$list1 = rest1;
        loop$list2 = list2;
        loop$compare = compare3;
        loop$acc = prepend(first1, acc);
      } else {
        loop$list1 = rest1;
        loop$list2 = list2;
        loop$compare = compare3;
        loop$acc = prepend(first1, acc);
      }
    }
  }
}
function merge_descending_pairs(loop$sequences, loop$compare, loop$acc) {
  while (true) {
    let sequences2 = loop$sequences;
    let compare3 = loop$compare;
    let acc = loop$acc;
    if (sequences2 instanceof Empty) {
      return reverse(acc);
    } else {
      let $ = sequences2.tail;
      if ($ instanceof Empty) {
        let sequence = sequences2.head;
        return reverse(prepend(reverse(sequence), acc));
      } else {
        let descending1 = sequences2.head;
        let descending2 = $.head;
        let rest$1 = $.tail;
        let ascending = merge_descendings(descending1, descending2, compare3, toList([]));
        loop$sequences = rest$1;
        loop$compare = compare3;
        loop$acc = prepend(ascending, acc);
      }
    }
  }
}
function merge_all(loop$sequences, loop$direction, loop$compare) {
  while (true) {
    let sequences2 = loop$sequences;
    let direction = loop$direction;
    let compare3 = loop$compare;
    if (sequences2 instanceof Empty) {
      return sequences2;
    } else if (direction instanceof Ascending) {
      let $ = sequences2.tail;
      if ($ instanceof Empty) {
        let sequence = sequences2.head;
        return sequence;
      } else {
        let sequences$1 = merge_ascending_pairs(sequences2, compare3, toList([]));
        loop$sequences = sequences$1;
        loop$direction = new Descending;
        loop$compare = compare3;
      }
    } else {
      let $ = sequences2.tail;
      if ($ instanceof Empty) {
        let sequence = sequences2.head;
        return reverse(sequence);
      } else {
        let sequences$1 = merge_descending_pairs(sequences2, compare3, toList([]));
        loop$sequences = sequences$1;
        loop$direction = new Ascending;
        loop$compare = compare3;
      }
    }
  }
}
function sort(list, compare3) {
  if (list instanceof Empty) {
    return list;
  } else {
    let $ = list.tail;
    if ($ instanceof Empty) {
      return list;
    } else {
      let x = list.head;
      let y = $.head;
      let rest$1 = $.tail;
      let _block;
      let $1 = compare3(x, y);
      if ($1 instanceof Lt) {
        _block = new Ascending;
      } else if ($1 instanceof Eq) {
        _block = new Ascending;
      } else {
        _block = new Descending;
      }
      let direction = _block;
      let sequences$1 = sequences(rest$1, compare3, toList([x]), direction, y, toList([]));
      return merge_all(sequences$1, new Ascending, compare3);
    }
  }
}
function shuffle_pair_unwrap_loop(loop$list, loop$acc) {
  while (true) {
    let list = loop$list;
    let acc = loop$acc;
    if (list instanceof Empty) {
      return acc;
    } else {
      let elem_pair = list.head;
      let enumerable = list.tail;
      loop$list = enumerable;
      loop$acc = prepend(elem_pair[1], acc);
    }
  }
}
function do_shuffle_by_pair_indexes(list_of_pairs) {
  return sort(list_of_pairs, (a_pair, b_pair) => {
    return compare(a_pair[0], b_pair[0]);
  });
}
function shuffle(list) {
  let _pipe = list;
  let _pipe$1 = fold2(_pipe, toList([]), (acc, a) => {
    return prepend([random_uniform(), a], acc);
  });
  let _pipe$2 = do_shuffle_by_pair_indexes(_pipe$1);
  return shuffle_pair_unwrap_loop(_pipe$2, toList([]));
}

// build/dev/javascript/gleam_stdlib/gleam/result.mjs
function is_ok(result) {
  if (result instanceof Ok) {
    return true;
  } else {
    return false;
  }
}
function map3(result, fun) {
  if (result instanceof Ok) {
    let x = result[0];
    return new Ok(fun(x));
  } else {
    return result;
  }
}
function map_error(result, fun) {
  if (result instanceof Ok) {
    return result;
  } else {
    let error = result[0];
    return new Error(fun(error));
  }
}
function try$(result, fun) {
  if (result instanceof Ok) {
    let x = result[0];
    return fun(x);
  } else {
    return result;
  }
}
function then$(result, fun) {
  return try$(result, fun);
}
function unwrap2(result, default$) {
  if (result instanceof Ok) {
    let v = result[0];
    return v;
  } else {
    return default$;
  }
}
function values2(results) {
  return filter_map(results, (r) => {
    return r;
  });
}

// build/dev/javascript/gleam_stdlib/dict.mjs
var referenceMap = /* @__PURE__ */ new WeakMap;
var tempDataView = /* @__PURE__ */ new DataView(/* @__PURE__ */ new ArrayBuffer(8));
var referenceUID = 0;
function hashByReference(o) {
  const known = referenceMap.get(o);
  if (known !== undefined) {
    return known;
  }
  const hash = referenceUID++;
  if (referenceUID === 2147483647) {
    referenceUID = 0;
  }
  referenceMap.set(o, hash);
  return hash;
}
function hashMerge(a, b) {
  return a ^ b + 2654435769 + (a << 6) + (a >> 2) | 0;
}
function hashString(s) {
  let hash = 0;
  const len = s.length;
  for (let i = 0;i < len; i++) {
    hash = Math.imul(31, hash) + s.charCodeAt(i) | 0;
  }
  return hash;
}
function hashNumber(n) {
  tempDataView.setFloat64(0, n);
  const i = tempDataView.getInt32(0);
  const j = tempDataView.getInt32(4);
  return Math.imul(73244475, i >> 16 ^ i) ^ j;
}
function hashBigInt(n) {
  return hashString(n.toString());
}
function hashObject(o) {
  const proto = Object.getPrototypeOf(o);
  if (proto !== null && typeof proto.hashCode === "function") {
    try {
      const code = o.hashCode(o);
      if (typeof code === "number") {
        return code;
      }
    } catch {}
  }
  if (o instanceof Promise || o instanceof WeakSet || o instanceof WeakMap) {
    return hashByReference(o);
  }
  if (o instanceof Date) {
    return hashNumber(o.getTime());
  }
  let h = 0;
  if (o instanceof ArrayBuffer) {
    o = new Uint8Array(o);
  }
  if (Array.isArray(o) || o instanceof Uint8Array) {
    for (let i = 0;i < o.length; i++) {
      h = Math.imul(31, h) + getHash(o[i]) | 0;
    }
  } else if (o instanceof Set) {
    o.forEach((v) => {
      h = h + getHash(v) | 0;
    });
  } else if (o instanceof Map) {
    o.forEach((v, k) => {
      h = h + hashMerge(getHash(v), getHash(k)) | 0;
    });
  } else {
    const keys2 = Object.keys(o);
    for (let i = 0;i < keys2.length; i++) {
      const k = keys2[i];
      const v = o[k];
      h = h + hashMerge(getHash(v), hashString(k)) | 0;
    }
  }
  return h;
}
function getHash(u) {
  if (u === null)
    return 1108378658;
  if (u === undefined)
    return 1108378659;
  if (u === true)
    return 1108378657;
  if (u === false)
    return 1108378656;
  switch (typeof u) {
    case "number":
      return hashNumber(u);
    case "string":
      return hashString(u);
    case "bigint":
      return hashBigInt(u);
    case "object":
      return hashObject(u);
    case "symbol":
      return hashByReference(u);
    case "function":
      return hashByReference(u);
    default:
      return 0;
  }
}
var SHIFT = 5;
var BUCKET_SIZE = Math.pow(2, SHIFT);
var MASK = BUCKET_SIZE - 1;
var MAX_INDEX_NODE = BUCKET_SIZE / 2;
var MIN_ARRAY_NODE = BUCKET_SIZE / 4;
var ENTRY = 0;
var ARRAY_NODE = 1;
var INDEX_NODE = 2;
var COLLISION_NODE = 3;
var EMPTY = {
  type: INDEX_NODE,
  bitmap: 0,
  array: []
};
function mask(hash, shift) {
  return hash >>> shift & MASK;
}
function bitpos(hash, shift) {
  return 1 << mask(hash, shift);
}
function bitcount(x) {
  x -= x >> 1 & 1431655765;
  x = (x & 858993459) + (x >> 2 & 858993459);
  x = x + (x >> 4) & 252645135;
  x += x >> 8;
  x += x >> 16;
  return x & 127;
}
function index(bitmap, bit) {
  return bitcount(bitmap & bit - 1);
}
function cloneAndSet(arr, at, val) {
  const len = arr.length;
  const out = new Array(len);
  for (let i = 0;i < len; ++i) {
    out[i] = arr[i];
  }
  out[at] = val;
  return out;
}
function spliceIn(arr, at, val) {
  const len = arr.length;
  const out = new Array(len + 1);
  let i = 0;
  let g = 0;
  while (i < at) {
    out[g++] = arr[i++];
  }
  out[g++] = val;
  while (i < len) {
    out[g++] = arr[i++];
  }
  return out;
}
function spliceOut(arr, at) {
  const len = arr.length;
  const out = new Array(len - 1);
  let i = 0;
  let g = 0;
  while (i < at) {
    out[g++] = arr[i++];
  }
  ++i;
  while (i < len) {
    out[g++] = arr[i++];
  }
  return out;
}
function createNode(shift, key1, val1, key2hash, key2, val2) {
  const key1hash = getHash(key1);
  if (key1hash === key2hash) {
    return {
      type: COLLISION_NODE,
      hash: key1hash,
      array: [
        { type: ENTRY, k: key1, v: val1 },
        { type: ENTRY, k: key2, v: val2 }
      ]
    };
  }
  const addedLeaf = { val: false };
  return assoc(assocIndex(EMPTY, shift, key1hash, key1, val1, addedLeaf), shift, key2hash, key2, val2, addedLeaf);
}
function assoc(root2, shift, hash, key, val, addedLeaf) {
  switch (root2.type) {
    case ARRAY_NODE:
      return assocArray(root2, shift, hash, key, val, addedLeaf);
    case INDEX_NODE:
      return assocIndex(root2, shift, hash, key, val, addedLeaf);
    case COLLISION_NODE:
      return assocCollision(root2, shift, hash, key, val, addedLeaf);
  }
}
function assocArray(root2, shift, hash, key, val, addedLeaf) {
  const idx = mask(hash, shift);
  const node = root2.array[idx];
  if (node === undefined) {
    addedLeaf.val = true;
    return {
      type: ARRAY_NODE,
      size: root2.size + 1,
      array: cloneAndSet(root2.array, idx, { type: ENTRY, k: key, v: val })
    };
  }
  if (node.type === ENTRY) {
    if (isEqual(key, node.k)) {
      if (val === node.v) {
        return root2;
      }
      return {
        type: ARRAY_NODE,
        size: root2.size,
        array: cloneAndSet(root2.array, idx, {
          type: ENTRY,
          k: key,
          v: val
        })
      };
    }
    addedLeaf.val = true;
    return {
      type: ARRAY_NODE,
      size: root2.size,
      array: cloneAndSet(root2.array, idx, createNode(shift + SHIFT, node.k, node.v, hash, key, val))
    };
  }
  const n = assoc(node, shift + SHIFT, hash, key, val, addedLeaf);
  if (n === node) {
    return root2;
  }
  return {
    type: ARRAY_NODE,
    size: root2.size,
    array: cloneAndSet(root2.array, idx, n)
  };
}
function assocIndex(root2, shift, hash, key, val, addedLeaf) {
  const bit = bitpos(hash, shift);
  const idx = index(root2.bitmap, bit);
  if ((root2.bitmap & bit) !== 0) {
    const node = root2.array[idx];
    if (node.type !== ENTRY) {
      const n = assoc(node, shift + SHIFT, hash, key, val, addedLeaf);
      if (n === node) {
        return root2;
      }
      return {
        type: INDEX_NODE,
        bitmap: root2.bitmap,
        array: cloneAndSet(root2.array, idx, n)
      };
    }
    const nodeKey = node.k;
    if (isEqual(key, nodeKey)) {
      if (val === node.v) {
        return root2;
      }
      return {
        type: INDEX_NODE,
        bitmap: root2.bitmap,
        array: cloneAndSet(root2.array, idx, {
          type: ENTRY,
          k: key,
          v: val
        })
      };
    }
    addedLeaf.val = true;
    return {
      type: INDEX_NODE,
      bitmap: root2.bitmap,
      array: cloneAndSet(root2.array, idx, createNode(shift + SHIFT, nodeKey, node.v, hash, key, val))
    };
  } else {
    const n = root2.array.length;
    if (n >= MAX_INDEX_NODE) {
      const nodes = new Array(32);
      const jdx = mask(hash, shift);
      nodes[jdx] = assocIndex(EMPTY, shift + SHIFT, hash, key, val, addedLeaf);
      let j = 0;
      let bitmap = root2.bitmap;
      for (let i = 0;i < 32; i++) {
        if ((bitmap & 1) !== 0) {
          const node = root2.array[j++];
          nodes[i] = node;
        }
        bitmap = bitmap >>> 1;
      }
      return {
        type: ARRAY_NODE,
        size: n + 1,
        array: nodes
      };
    } else {
      const newArray = spliceIn(root2.array, idx, {
        type: ENTRY,
        k: key,
        v: val
      });
      addedLeaf.val = true;
      return {
        type: INDEX_NODE,
        bitmap: root2.bitmap | bit,
        array: newArray
      };
    }
  }
}
function assocCollision(root2, shift, hash, key, val, addedLeaf) {
  if (hash === root2.hash) {
    const idx = collisionIndexOf(root2, key);
    if (idx !== -1) {
      const entry = root2.array[idx];
      if (entry.v === val) {
        return root2;
      }
      return {
        type: COLLISION_NODE,
        hash,
        array: cloneAndSet(root2.array, idx, { type: ENTRY, k: key, v: val })
      };
    }
    const size = root2.array.length;
    addedLeaf.val = true;
    return {
      type: COLLISION_NODE,
      hash,
      array: cloneAndSet(root2.array, size, { type: ENTRY, k: key, v: val })
    };
  }
  return assoc({
    type: INDEX_NODE,
    bitmap: bitpos(root2.hash, shift),
    array: [root2]
  }, shift, hash, key, val, addedLeaf);
}
function collisionIndexOf(root2, key) {
  const size = root2.array.length;
  for (let i = 0;i < size; i++) {
    if (isEqual(key, root2.array[i].k)) {
      return i;
    }
  }
  return -1;
}
function find(root2, shift, hash, key) {
  switch (root2.type) {
    case ARRAY_NODE:
      return findArray(root2, shift, hash, key);
    case INDEX_NODE:
      return findIndex(root2, shift, hash, key);
    case COLLISION_NODE:
      return findCollision(root2, key);
  }
}
function findArray(root2, shift, hash, key) {
  const idx = mask(hash, shift);
  const node = root2.array[idx];
  if (node === undefined) {
    return;
  }
  if (node.type !== ENTRY) {
    return find(node, shift + SHIFT, hash, key);
  }
  if (isEqual(key, node.k)) {
    return node;
  }
  return;
}
function findIndex(root2, shift, hash, key) {
  const bit = bitpos(hash, shift);
  if ((root2.bitmap & bit) === 0) {
    return;
  }
  const idx = index(root2.bitmap, bit);
  const node = root2.array[idx];
  if (node.type !== ENTRY) {
    return find(node, shift + SHIFT, hash, key);
  }
  if (isEqual(key, node.k)) {
    return node;
  }
  return;
}
function findCollision(root2, key) {
  const idx = collisionIndexOf(root2, key);
  if (idx < 0) {
    return;
  }
  return root2.array[idx];
}
function without(root2, shift, hash, key) {
  switch (root2.type) {
    case ARRAY_NODE:
      return withoutArray(root2, shift, hash, key);
    case INDEX_NODE:
      return withoutIndex(root2, shift, hash, key);
    case COLLISION_NODE:
      return withoutCollision(root2, key);
  }
}
function withoutArray(root2, shift, hash, key) {
  const idx = mask(hash, shift);
  const node = root2.array[idx];
  if (node === undefined) {
    return root2;
  }
  let n = undefined;
  if (node.type === ENTRY) {
    if (!isEqual(node.k, key)) {
      return root2;
    }
  } else {
    n = without(node, shift + SHIFT, hash, key);
    if (n === node) {
      return root2;
    }
  }
  if (n === undefined) {
    if (root2.size <= MIN_ARRAY_NODE) {
      const arr = root2.array;
      const out = new Array(root2.size - 1);
      let i = 0;
      let j = 0;
      let bitmap = 0;
      while (i < idx) {
        const nv = arr[i];
        if (nv !== undefined) {
          out[j] = nv;
          bitmap |= 1 << i;
          ++j;
        }
        ++i;
      }
      ++i;
      while (i < arr.length) {
        const nv = arr[i];
        if (nv !== undefined) {
          out[j] = nv;
          bitmap |= 1 << i;
          ++j;
        }
        ++i;
      }
      return {
        type: INDEX_NODE,
        bitmap,
        array: out
      };
    }
    return {
      type: ARRAY_NODE,
      size: root2.size - 1,
      array: cloneAndSet(root2.array, idx, n)
    };
  }
  return {
    type: ARRAY_NODE,
    size: root2.size,
    array: cloneAndSet(root2.array, idx, n)
  };
}
function withoutIndex(root2, shift, hash, key) {
  const bit = bitpos(hash, shift);
  if ((root2.bitmap & bit) === 0) {
    return root2;
  }
  const idx = index(root2.bitmap, bit);
  const node = root2.array[idx];
  if (node.type !== ENTRY) {
    const n = without(node, shift + SHIFT, hash, key);
    if (n === node) {
      return root2;
    }
    if (n !== undefined) {
      return {
        type: INDEX_NODE,
        bitmap: root2.bitmap,
        array: cloneAndSet(root2.array, idx, n)
      };
    }
    if (root2.bitmap === bit) {
      return;
    }
    return {
      type: INDEX_NODE,
      bitmap: root2.bitmap ^ bit,
      array: spliceOut(root2.array, idx)
    };
  }
  if (isEqual(key, node.k)) {
    if (root2.bitmap === bit) {
      return;
    }
    return {
      type: INDEX_NODE,
      bitmap: root2.bitmap ^ bit,
      array: spliceOut(root2.array, idx)
    };
  }
  return root2;
}
function withoutCollision(root2, key) {
  const idx = collisionIndexOf(root2, key);
  if (idx < 0) {
    return root2;
  }
  if (root2.array.length === 1) {
    return;
  }
  return {
    type: COLLISION_NODE,
    hash: root2.hash,
    array: spliceOut(root2.array, idx)
  };
}
function forEach(root2, fn) {
  if (root2 === undefined) {
    return;
  }
  const items = root2.array;
  const size = items.length;
  for (let i = 0;i < size; i++) {
    const item = items[i];
    if (item === undefined) {
      continue;
    }
    if (item.type === ENTRY) {
      fn(item.v, item.k);
      continue;
    }
    forEach(item, fn);
  }
}

class Dict {
  static fromObject(o) {
    const keys2 = Object.keys(o);
    let m = Dict.new();
    for (let i = 0;i < keys2.length; i++) {
      const k = keys2[i];
      m = m.set(k, o[k]);
    }
    return m;
  }
  static fromMap(o) {
    let m = Dict.new();
    o.forEach((v, k) => {
      m = m.set(k, v);
    });
    return m;
  }
  static new() {
    return new Dict(undefined, 0);
  }
  constructor(root2, size) {
    this.root = root2;
    this.size = size;
  }
  get(key, notFound) {
    if (this.root === undefined) {
      return notFound;
    }
    const found = find(this.root, 0, getHash(key), key);
    if (found === undefined) {
      return notFound;
    }
    return found.v;
  }
  set(key, val) {
    const addedLeaf = { val: false };
    const root2 = this.root === undefined ? EMPTY : this.root;
    const newRoot = assoc(root2, 0, getHash(key), key, val, addedLeaf);
    if (newRoot === this.root) {
      return this;
    }
    return new Dict(newRoot, addedLeaf.val ? this.size + 1 : this.size);
  }
  delete(key) {
    if (this.root === undefined) {
      return this;
    }
    const newRoot = without(this.root, 0, getHash(key), key);
    if (newRoot === this.root) {
      return this;
    }
    if (newRoot === undefined) {
      return Dict.new();
    }
    return new Dict(newRoot, this.size - 1);
  }
  has(key) {
    if (this.root === undefined) {
      return false;
    }
    return find(this.root, 0, getHash(key), key) !== undefined;
  }
  entries() {
    if (this.root === undefined) {
      return [];
    }
    const result = [];
    this.forEach((v, k) => result.push([k, v]));
    return result;
  }
  forEach(fn) {
    forEach(this.root, fn);
  }
  hashCode() {
    let h = 0;
    this.forEach((v, k) => {
      h = h + hashMerge(getHash(v), getHash(k)) | 0;
    });
    return h;
  }
  equals(o) {
    if (!(o instanceof Dict) || this.size !== o.size) {
      return false;
    }
    try {
      this.forEach((v, k) => {
        if (!isEqual(o.get(k, !v), v)) {
          throw unequalDictSymbol;
        }
      });
      return true;
    } catch (e) {
      if (e === unequalDictSymbol) {
        return false;
      }
      throw e;
    }
  }
}
var unequalDictSymbol = /* @__PURE__ */ Symbol();

// build/dev/javascript/gleam_stdlib/gleam_stdlib.mjs
var Nil = undefined;
var NOT_FOUND = {};
function identity(x) {
  return x;
}
function parse_float(value) {
  if (/^[-+]?(\d+)\.(\d+)([eE][-+]?\d+)?$/.test(value)) {
    return new Ok(parseFloat(value));
  } else {
    return new Error(Nil);
  }
}
function to_string(term) {
  return term.toString();
}
function float_to_string(float) {
  const string = float.toString().replace("+", "");
  if (string.indexOf(".") >= 0) {
    return string;
  } else {
    const index2 = string.indexOf("e");
    if (index2 >= 0) {
      return string.slice(0, index2) + ".0" + string.slice(index2);
    } else {
      return string + ".0";
    }
  }
}
function string_replace(string, target, substitute) {
  if (typeof string.replaceAll !== "undefined") {
    return string.replaceAll(target, substitute);
  }
  return string.replace(new RegExp(target.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "g"), substitute);
}
function graphemes(string) {
  const iterator = graphemes_iterator(string);
  if (iterator) {
    return List.fromArray(Array.from(iterator).map((item) => item.segment));
  } else {
    return List.fromArray(string.match(/./gsu));
  }
}
var segmenter = undefined;
function graphemes_iterator(string) {
  if (globalThis.Intl && Intl.Segmenter) {
    segmenter ||= new Intl.Segmenter;
    return segmenter.segment(string)[Symbol.iterator]();
  }
}
function pop_grapheme(string) {
  let first;
  const iterator = graphemes_iterator(string);
  if (iterator) {
    first = iterator.next().value?.segment;
  } else {
    first = string.match(/./su)?.[0];
  }
  if (first) {
    return new Ok([first, string.slice(first.length)]);
  } else {
    return new Error(Nil);
  }
}
function pop_codeunit(str) {
  return [str.charCodeAt(0) | 0, str.slice(1)];
}
function lowercase(string) {
  return string.toLowerCase();
}
function split(xs, pattern) {
  return List.fromArray(xs.split(pattern));
}
function string_codeunit_slice(str, from, length3) {
  return str.slice(from, from + length3);
}
function contains_string(haystack, needle) {
  return haystack.indexOf(needle) >= 0;
}
function starts_with(haystack, needle) {
  return haystack.startsWith(needle);
}
var unicode_whitespaces = [
  " ",
  "\t",
  `
`,
  "\v",
  "\f",
  "\r",
  "",
  "\u2028",
  "\u2029"
].join("");
var trim_start_regex = /* @__PURE__ */ new RegExp(`^[${unicode_whitespaces}]*`);
var trim_end_regex = /* @__PURE__ */ new RegExp(`[${unicode_whitespaces}]*$`);
function trim_start(string) {
  return string.replace(trim_start_regex, "");
}
function trim_end(string) {
  return string.replace(trim_end_regex, "");
}
function floor(float) {
  return Math.floor(float);
}
function round2(float) {
  return Math.round(float);
}
function truncate(float) {
  return Math.trunc(float);
}
function random_uniform() {
  const random_uniform_result = Math.random();
  if (random_uniform_result === 1) {
    return random_uniform();
  }
  return random_uniform_result;
}
function new_map() {
  return Dict.new();
}
function map_to_list(map4) {
  return List.fromArray(map4.entries());
}
function map_get(map4, key) {
  const value = map4.get(key, NOT_FOUND);
  if (value === NOT_FOUND) {
    return new Error(Nil);
  }
  return new Ok(value);
}
function map_insert(key, value, map4) {
  return map4.set(key, value);
}
function classify_dynamic(data) {
  if (typeof data === "string") {
    return "String";
  } else if (typeof data === "boolean") {
    return "Bool";
  } else if (data instanceof Result) {
    return "Result";
  } else if (data instanceof List) {
    return "List";
  } else if (data instanceof BitArray) {
    return "BitArray";
  } else if (data instanceof Dict) {
    return "Dict";
  } else if (Number.isInteger(data)) {
    return "Int";
  } else if (Array.isArray(data)) {
    return `Tuple of ${data.length} elements`;
  } else if (typeof data === "number") {
    return "Float";
  } else if (data === null) {
    return "Null";
  } else if (data === undefined) {
    return "Nil";
  } else {
    const type = typeof data;
    return type.charAt(0).toUpperCase() + type.slice(1);
  }
}
function inspect(v) {
  const t = typeof v;
  if (v === true)
    return "True";
  if (v === false)
    return "False";
  if (v === null)
    return "//js(null)";
  if (v === undefined)
    return "Nil";
  if (t === "string")
    return inspectString(v);
  if (t === "bigint" || Number.isInteger(v))
    return v.toString();
  if (t === "number")
    return float_to_string(v);
  if (Array.isArray(v))
    return `#(${v.map(inspect).join(", ")})`;
  if (v instanceof List)
    return inspectList(v);
  if (v instanceof UtfCodepoint)
    return inspectUtfCodepoint(v);
  if (v instanceof BitArray)
    return `<<${bit_array_inspect(v, "")}>>`;
  if (v instanceof CustomType)
    return inspectCustomType(v);
  if (v instanceof Dict)
    return inspectDict(v);
  if (v instanceof Set)
    return `//js(Set(${[...v].map(inspect).join(", ")}))`;
  if (v instanceof RegExp)
    return `//js(${v})`;
  if (v instanceof Date)
    return `//js(Date("${v.toISOString()}"))`;
  if (v instanceof Function) {
    const args = [];
    for (const i of Array(v.length).keys())
      args.push(String.fromCharCode(i + 97));
    return `//fn(${args.join(", ")}) { ... }`;
  }
  return inspectObject(v);
}
function inspectString(str) {
  let new_str = '"';
  for (let i = 0;i < str.length; i++) {
    const char = str[i];
    switch (char) {
      case `
`:
        new_str += "\\n";
        break;
      case "\r":
        new_str += "\\r";
        break;
      case "\t":
        new_str += "\\t";
        break;
      case "\f":
        new_str += "\\f";
        break;
      case "\\":
        new_str += "\\\\";
        break;
      case '"':
        new_str += "\\\"";
        break;
      default:
        if (char < " " || char > "~" && char < " ") {
          new_str += "\\u{" + char.charCodeAt(0).toString(16).toUpperCase().padStart(4, "0") + "}";
        } else {
          new_str += char;
        }
    }
  }
  new_str += '"';
  return new_str;
}
function inspectDict(map4) {
  let body = "dict.from_list([";
  let first = true;
  map4.forEach((value, key) => {
    if (!first)
      body = body + ", ";
    body = body + "#(" + inspect(key) + ", " + inspect(value) + ")";
    first = false;
  });
  return body + "])";
}
function inspectObject(v) {
  const name = Object.getPrototypeOf(v)?.constructor?.name || "Object";
  const props = [];
  for (const k of Object.keys(v)) {
    props.push(`${inspect(k)}: ${inspect(v[k])}`);
  }
  const body = props.length ? " " + props.join(", ") + " " : "";
  const head = name === "Object" ? "" : name + " ";
  return `//js(${head}{${body}})`;
}
function inspectCustomType(record) {
  const props = Object.keys(record).map((label) => {
    const value = inspect(record[label]);
    return isNaN(parseInt(label)) ? `${label}: ${value}` : value;
  }).join(", ");
  return props ? `${record.constructor.name}(${props})` : record.constructor.name;
}
function inspectList(list) {
  return `[${list.toArray().map(inspect).join(", ")}]`;
}
function inspectUtfCodepoint(codepoint) {
  return `//utfcodepoint(${String.fromCodePoint(codepoint.value)})`;
}
function bit_array_inspect(bits, acc) {
  if (bits.bitSize === 0) {
    return acc;
  }
  for (let i = 0;i < bits.byteSize - 1; i++) {
    acc += bits.byteAt(i).toString();
    acc += ", ";
  }
  if (bits.byteSize * 8 === bits.bitSize) {
    acc += bits.byteAt(bits.byteSize - 1).toString();
  } else {
    const trailingBitsCount = bits.bitSize % 8;
    acc += bits.byteAt(bits.byteSize - 1) >> 8 - trailingBitsCount;
    acc += `:size(${trailingBitsCount})`;
  }
  return acc;
}

// build/dev/javascript/gleam_stdlib/gleam/float.mjs
function compare(a, b) {
  let $ = a === b;
  if ($) {
    return new Eq;
  } else {
    let $1 = a < b;
    if ($1) {
      return new Lt;
    } else {
      return new Gt;
    }
  }
}
function negate(x) {
  return -1 * x;
}
function round(x) {
  let $ = x >= 0;
  if ($) {
    return round2(x);
  } else {
    return 0 - round2(negate(x));
  }
}

// build/dev/javascript/gleam_stdlib/gleam/int.mjs
function modulo(dividend, divisor) {
  if (divisor === 0) {
    return new Error(undefined);
  } else {
    let remainder$1 = remainderInt(dividend, divisor);
    let $ = remainder$1 * divisor < 0;
    if ($) {
      return new Ok(remainder$1 + divisor);
    } else {
      return new Ok(remainder$1);
    }
  }
}

// build/dev/javascript/gleam_stdlib/gleam/string.mjs
function replace(string, pattern, substitute) {
  let _pipe = string;
  let _pipe$1 = identity(_pipe);
  let _pipe$2 = string_replace(_pipe$1, pattern, substitute);
  return identity(_pipe$2);
}
function concat_loop(loop$strings, loop$accumulator) {
  while (true) {
    let strings = loop$strings;
    let accumulator = loop$accumulator;
    if (strings instanceof Empty) {
      return accumulator;
    } else {
      let string = strings.head;
      let strings$1 = strings.tail;
      loop$strings = strings$1;
      loop$accumulator = accumulator + string;
    }
  }
}
function concat2(strings) {
  return concat_loop(strings, "");
}
function join_loop(loop$strings, loop$separator, loop$accumulator) {
  while (true) {
    let strings = loop$strings;
    let separator = loop$separator;
    let accumulator = loop$accumulator;
    if (strings instanceof Empty) {
      return accumulator;
    } else {
      let string = strings.head;
      let strings$1 = strings.tail;
      loop$strings = strings$1;
      loop$separator = separator;
      loop$accumulator = accumulator + separator + string;
    }
  }
}
function join(strings, separator) {
  if (strings instanceof Empty) {
    return "";
  } else {
    let first$1 = strings.head;
    let rest = strings.tail;
    return join_loop(rest, separator, first$1);
  }
}
function trim(string) {
  let _pipe = string;
  let _pipe$1 = trim_start(_pipe);
  return trim_end(_pipe$1);
}
function drop_start(loop$string, loop$num_graphemes) {
  while (true) {
    let string = loop$string;
    let num_graphemes = loop$num_graphemes;
    let $ = num_graphemes > 0;
    if ($) {
      let $1 = pop_grapheme(string);
      if ($1 instanceof Ok) {
        let string$1 = $1[0][1];
        loop$string = string$1;
        loop$num_graphemes = num_graphemes - 1;
      } else {
        return string;
      }
    } else {
      return string;
    }
  }
}
function split2(x, substring) {
  if (substring === "") {
    return graphemes(x);
  } else {
    let _pipe = x;
    let _pipe$1 = identity(_pipe);
    let _pipe$2 = split(_pipe$1, substring);
    return map2(_pipe$2, identity);
  }
}
function inspect2(term) {
  let _pipe = inspect(term);
  return identity(_pipe);
}

// build/dev/javascript/gleam_stdlib/gleam_stdlib_decode_ffi.mjs
function index2(data, key) {
  if (data instanceof Dict || data instanceof WeakMap || data instanceof Map) {
    const token = {};
    const entry = data.get(key, token);
    if (entry === token)
      return new Ok(new None);
    return new Ok(new Some(entry));
  }
  const key_is_int = Number.isInteger(key);
  if (key_is_int && key >= 0 && key < 8 && data instanceof List) {
    let i = 0;
    for (const value of data) {
      if (i === key)
        return new Ok(new Some(value));
      i++;
    }
    return new Error("Indexable");
  }
  if (key_is_int && Array.isArray(data) || data && typeof data === "object" || data && Object.getPrototypeOf(data) === Object.prototype) {
    if (key in data)
      return new Ok(new Some(data[key]));
    return new Ok(new None);
  }
  return new Error(key_is_int ? "Indexable" : "Dict");
}
function list(data, decode, pushPath, index3, emptyList) {
  if (!(data instanceof List || Array.isArray(data))) {
    const error = new DecodeError2("List", classify_dynamic(data), emptyList);
    return [emptyList, List.fromArray([error])];
  }
  const decoded = [];
  for (const element of data) {
    const layer = decode(element);
    const [out, errors] = layer;
    if (errors instanceof NonEmpty) {
      const [_, errors2] = pushPath(layer, index3.toString());
      return [emptyList, errors2];
    }
    decoded.push(out);
    index3++;
  }
  return [List.fromArray(decoded), emptyList];
}
function int(data) {
  if (Number.isInteger(data))
    return new Ok(data);
  return new Error(0);
}
function string(data) {
  if (typeof data === "string")
    return new Ok(data);
  return new Error("");
}
function is_null(data) {
  return data === null || data === undefined;
}

// build/dev/javascript/gleam_stdlib/gleam/dynamic/decode.mjs
class DecodeError2 extends CustomType {
  constructor(expected, found, path) {
    super();
    this.expected = expected;
    this.found = found;
    this.path = path;
  }
}
class Decoder extends CustomType {
  constructor(function$) {
    super();
    this.function = function$;
  }
}
var dynamic = /* @__PURE__ */ new Decoder(decode_dynamic);
var bool = /* @__PURE__ */ new Decoder(decode_bool2);
var int2 = /* @__PURE__ */ new Decoder(decode_int2);
var string2 = /* @__PURE__ */ new Decoder(decode_string2);
function run(data, decoder) {
  let $ = decoder.function(data);
  let maybe_invalid_data;
  let errors;
  maybe_invalid_data = $[0];
  errors = $[1];
  if (errors instanceof Empty) {
    return new Ok(maybe_invalid_data);
  } else {
    return new Error(errors);
  }
}
function success(data) {
  return new Decoder((_) => {
    return [data, toList([])];
  });
}
function decode_dynamic(data) {
  return [data, toList([])];
}
function map4(decoder, transformer) {
  return new Decoder((d) => {
    let $ = decoder.function(d);
    let data;
    let errors;
    data = $[0];
    errors = $[1];
    return [transformer(data), errors];
  });
}
function run_decoders(loop$data, loop$failure, loop$decoders) {
  while (true) {
    let data = loop$data;
    let failure = loop$failure;
    let decoders = loop$decoders;
    if (decoders instanceof Empty) {
      return failure;
    } else {
      let decoder = decoders.head;
      let decoders$1 = decoders.tail;
      let $ = decoder.function(data);
      let layer;
      let errors;
      layer = $;
      errors = $[1];
      if (errors instanceof Empty) {
        return layer;
      } else {
        loop$data = data;
        loop$failure = failure;
        loop$decoders = decoders$1;
      }
    }
  }
}
function one_of(first, alternatives) {
  return new Decoder((dynamic_data) => {
    let $ = first.function(dynamic_data);
    let layer;
    let errors;
    layer = $;
    errors = $[1];
    if (errors instanceof Empty) {
      return layer;
    } else {
      return run_decoders(dynamic_data, layer, alternatives);
    }
  });
}
function optional(inner) {
  return new Decoder((data) => {
    let $ = is_null(data);
    if ($) {
      return [new None, toList([])];
    } else {
      let $1 = inner.function(data);
      let data$1;
      let errors;
      data$1 = $1[0];
      errors = $1[1];
      return [new Some(data$1), errors];
    }
  });
}
function decode_error(expected, found) {
  return toList([
    new DecodeError2(expected, classify_dynamic(found), toList([]))
  ]);
}
function run_dynamic_function(data, name, f) {
  let $ = f(data);
  if ($ instanceof Ok) {
    let data$1 = $[0];
    return [data$1, toList([])];
  } else {
    let zero = $[0];
    return [
      zero,
      toList([new DecodeError2(name, classify_dynamic(data), toList([]))])
    ];
  }
}
function decode_bool2(data) {
  let $ = isEqual(identity(true), data);
  if ($) {
    return [true, toList([])];
  } else {
    let $1 = isEqual(identity(false), data);
    if ($1) {
      return [false, toList([])];
    } else {
      return [false, decode_error("Bool", data)];
    }
  }
}
function decode_int2(data) {
  return run_dynamic_function(data, "Int", int);
}
function failure(zero, expected) {
  return new Decoder((d) => {
    return [zero, decode_error(expected, d)];
  });
}
function decode_string2(data) {
  return run_dynamic_function(data, "String", string);
}
function list2(inner) {
  return new Decoder((data) => {
    return list(data, inner.function, (p, k) => {
      return push_path(p, toList([k]));
    }, 0, toList([]));
  });
}
function push_path(layer, path) {
  let decoder = one_of(string2, toList([
    (() => {
      let _pipe = int2;
      return map4(_pipe, to_string);
    })()
  ]));
  let path$1 = map2(path, (key) => {
    let key$1 = identity(key);
    let $ = run(key$1, decoder);
    if ($ instanceof Ok) {
      let key$2 = $[0];
      return key$2;
    } else {
      return "<" + classify_dynamic(key$1) + ">";
    }
  });
  let errors = map2(layer[1], (error) => {
    return new DecodeError2(error.expected, error.found, append(path$1, error.path));
  });
  return [layer[0], errors];
}
function index3(loop$path, loop$position, loop$inner, loop$data, loop$handle_miss) {
  while (true) {
    let path = loop$path;
    let position = loop$position;
    let inner = loop$inner;
    let data = loop$data;
    let handle_miss = loop$handle_miss;
    if (path instanceof Empty) {
      let _pipe = inner(data);
      return push_path(_pipe, reverse(position));
    } else {
      let key = path.head;
      let path$1 = path.tail;
      let $ = index2(data, key);
      if ($ instanceof Ok) {
        let $1 = $[0];
        if ($1 instanceof Some) {
          let data$1 = $1[0];
          loop$path = path$1;
          loop$position = prepend(key, position);
          loop$inner = inner;
          loop$data = data$1;
          loop$handle_miss = handle_miss;
        } else {
          return handle_miss(data, prepend(key, position));
        }
      } else {
        let kind = $[0];
        let $1 = inner(data);
        let default$;
        default$ = $1[0];
        let _pipe = [
          default$,
          toList([new DecodeError2(kind, classify_dynamic(data), toList([]))])
        ];
        return push_path(_pipe, reverse(position));
      }
    }
  }
}
function subfield(field_path, field_decoder, next) {
  return new Decoder((data) => {
    let $ = index3(field_path, toList([]), field_decoder.function, data, (data2, position) => {
      let $12 = field_decoder.function(data2);
      let default$;
      default$ = $12[0];
      let _pipe = [
        default$,
        toList([new DecodeError2("Field", "Nothing", toList([]))])
      ];
      return push_path(_pipe, reverse(position));
    });
    let out;
    let errors1;
    out = $[0];
    errors1 = $[1];
    let $1 = next(out).function(data);
    let out$1;
    let errors2;
    out$1 = $1[0];
    errors2 = $1[1];
    return [out$1, append(errors1, errors2)];
  });
}
function field(field_name, field_decoder, next) {
  return subfield(toList([field_name]), field_decoder, next);
}
function optional_field(key, default$, field_decoder, next) {
  return new Decoder((data) => {
    let _block;
    let _block$1;
    let $1 = index2(data, key);
    if ($1 instanceof Ok) {
      let $22 = $1[0];
      if ($22 instanceof Some) {
        let data$1 = $22[0];
        _block$1 = field_decoder.function(data$1);
      } else {
        _block$1 = [default$, toList([])];
      }
    } else {
      let kind = $1[0];
      _block$1 = [
        default$,
        toList([new DecodeError2(kind, classify_dynamic(data), toList([]))])
      ];
    }
    let _pipe = _block$1;
    _block = push_path(_pipe, toList([key]));
    let $ = _block;
    let out;
    let errors1;
    out = $[0];
    errors1 = $[1];
    let $2 = next(out).function(data);
    let out$1;
    let errors2;
    out$1 = $2[0];
    errors2 = $2[1];
    return [out$1, append(errors1, errors2)];
  });
}
// build/dev/javascript/gleam_json/gleam_json_ffi.mjs
function json_to_string(json) {
  return JSON.stringify(json);
}
function object(entries) {
  return Object.fromEntries(entries);
}
function identity2(x) {
  return x;
}
function do_null() {
  return null;
}
function decode(string3) {
  try {
    const result = JSON.parse(string3);
    return new Ok(result);
  } catch (err) {
    return new Error(getJsonDecodeError(err, string3));
  }
}
function getJsonDecodeError(stdErr, json) {
  if (isUnexpectedEndOfInput(stdErr))
    return new UnexpectedEndOfInput;
  return toUnexpectedByteError(stdErr, json);
}
function isUnexpectedEndOfInput(err) {
  const unexpectedEndOfInputRegex = /((unexpected (end|eof))|(end of data)|(unterminated string)|(json( parse error|\.parse)\: expected '(\:|\}|\])'))/i;
  return unexpectedEndOfInputRegex.test(err.message);
}
function toUnexpectedByteError(err, json) {
  let converters = [
    v8UnexpectedByteError,
    oldV8UnexpectedByteError,
    jsCoreUnexpectedByteError,
    spidermonkeyUnexpectedByteError
  ];
  for (let converter of converters) {
    let result = converter(err, json);
    if (result)
      return result;
  }
  return new UnexpectedByte("", 0);
}
function v8UnexpectedByteError(err) {
  const regex = /unexpected token '(.)', ".+" is not valid JSON/i;
  const match = regex.exec(err.message);
  if (!match)
    return null;
  const byte = toHex(match[1]);
  return new UnexpectedByte(byte, -1);
}
function oldV8UnexpectedByteError(err) {
  const regex = /unexpected token (.) in JSON at position (\d+)/i;
  const match = regex.exec(err.message);
  if (!match)
    return null;
  const byte = toHex(match[1]);
  const position = Number(match[2]);
  return new UnexpectedByte(byte, position);
}
function spidermonkeyUnexpectedByteError(err, json) {
  const regex = /(unexpected character|expected .*) at line (\d+) column (\d+)/i;
  const match = regex.exec(err.message);
  if (!match)
    return null;
  const line = Number(match[2]);
  const column = Number(match[3]);
  const position = getPositionFromMultiline(line, column, json);
  const byte = toHex(json[position]);
  return new UnexpectedByte(byte, position);
}
function jsCoreUnexpectedByteError(err) {
  const regex = /unexpected (identifier|token) "(.)"/i;
  const match = regex.exec(err.message);
  if (!match)
    return null;
  const byte = toHex(match[2]);
  return new UnexpectedByte(byte, 0);
}
function toHex(char) {
  return "0x" + char.charCodeAt(0).toString(16).toUpperCase();
}
function getPositionFromMultiline(line, column, string3) {
  if (line === 1)
    return column - 1;
  let currentLn = 1;
  let position = 0;
  string3.split("").find((char, idx) => {
    if (char === `
`)
      currentLn += 1;
    if (currentLn === line) {
      position = idx + column;
      return true;
    }
    return false;
  });
  return position;
}

// build/dev/javascript/gleam_json/gleam/json.mjs
class UnexpectedEndOfInput extends CustomType {
}
class UnexpectedByte extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class UnableToDecode extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
function do_parse(json, decoder) {
  return then$(decode(json), (dynamic_value) => {
    let _pipe = run(dynamic_value, decoder);
    return map_error(_pipe, (var0) => {
      return new UnableToDecode(var0);
    });
  });
}
function parse(json, decoder) {
  return do_parse(json, decoder);
}
function to_string2(json) {
  return json_to_string(json);
}
function string3(input) {
  return identity2(input);
}
function bool2(input) {
  return identity2(input);
}
function int3(input) {
  return identity2(input);
}
function null$() {
  return do_null();
}
function object2(entries) {
  return object(entries);
}

// build/dev/javascript/gleam_stdlib/gleam/bool.mjs
function negate2(bool3) {
  return !bool3;
}
function to_string3(bool3) {
  if (bool3) {
    return "True";
  } else {
    return "False";
  }
}
function guard(requirement, consequence, alternative) {
  if (requirement) {
    return consequence;
  } else {
    return alternative();
  }
}
function lazy_guard(requirement, consequence, alternative) {
  if (requirement) {
    return consequence();
  } else {
    return alternative();
  }
}
// build/dev/javascript/gleam_time/gleam/time/duration.mjs
class Duration extends CustomType {
  constructor(seconds, nanoseconds) {
    super();
    this.seconds = seconds;
    this.nanoseconds = nanoseconds;
  }
}
function seconds(amount) {
  return new Duration(amount, 0);
}
function to_seconds(duration) {
  let seconds$1 = identity(duration.seconds);
  let nanoseconds$1 = identity(duration.nanoseconds);
  return seconds$1 + nanoseconds$1 / 1e9;
}

// build/dev/javascript/gleam_time/gleam_time_ffi.mjs
function system_time() {
  const now = Date.now();
  const milliseconds = now % 1000;
  const nanoseconds = milliseconds * 1e6;
  const seconds2 = (now - milliseconds) / 1000;
  return [seconds2, nanoseconds];
}
function local_time_offset_seconds() {
  return new Date().getTimezoneOffset() * -60;
}

// build/dev/javascript/gleam_time/gleam/time/calendar.mjs
class Date2 extends CustomType {
  constructor(year, month, day) {
    super();
    this.year = year;
    this.month = month;
    this.day = day;
  }
}
class TimeOfDay extends CustomType {
  constructor(hours, minutes, seconds2, nanoseconds) {
    super();
    this.hours = hours;
    this.minutes = minutes;
    this.seconds = seconds2;
    this.nanoseconds = nanoseconds;
  }
}
class January extends CustomType {
}
class February extends CustomType {
}
class March extends CustomType {
}
class April extends CustomType {
}
class May extends CustomType {
}
class June extends CustomType {
}
class July extends CustomType {
}
class August extends CustomType {
}
class September extends CustomType {
}
class October extends CustomType {
}
class November extends CustomType {
}
class December extends CustomType {
}
function local_offset() {
  return seconds(local_time_offset_seconds());
}

// build/dev/javascript/gleam_time/gleam/time/timestamp.mjs
class Timestamp extends CustomType {
  constructor(seconds2, nanoseconds2) {
    super();
    this.seconds = seconds2;
    this.nanoseconds = nanoseconds2;
  }
}
function normalise(timestamp) {
  let multiplier = 1e9;
  let nanoseconds2 = remainderInt(timestamp.nanoseconds, multiplier);
  let overflow = timestamp.nanoseconds - nanoseconds2;
  let seconds2 = timestamp.seconds + divideInt(overflow, multiplier);
  let $ = nanoseconds2 >= 0;
  if ($) {
    return new Timestamp(seconds2, nanoseconds2);
  } else {
    return new Timestamp(seconds2 - 1, multiplier + nanoseconds2);
  }
}
function system_time2() {
  let $ = system_time();
  let seconds2;
  let nanoseconds2;
  seconds2 = $[0];
  nanoseconds2 = $[1];
  return normalise(new Timestamp(seconds2, nanoseconds2));
}
function duration_to_minutes(duration) {
  return round(to_seconds(duration) / 60);
}
function modulo2(n, m) {
  let $ = modulo(n, m);
  if ($ instanceof Ok) {
    let n$1 = $[0];
    return n$1;
  } else {
    return 0;
  }
}
function floored_div(numerator, denominator) {
  let n = divideFloat(identity(numerator), denominator);
  return round(floor(n));
}
function to_civil(minutes) {
  let raw_day = floored_div(minutes, 60 * 24) + 719468;
  let _block;
  let $ = raw_day >= 0;
  if ($) {
    _block = globalThis.Math.trunc(raw_day / 146097);
  } else {
    _block = globalThis.Math.trunc((raw_day - 146096) / 146097);
  }
  let era = _block;
  let day_of_era = raw_day - era * 146097;
  let year_of_era = globalThis.Math.trunc((day_of_era - globalThis.Math.trunc(day_of_era / 1460) + globalThis.Math.trunc(day_of_era / 36524) - globalThis.Math.trunc(day_of_era / 146096)) / 365);
  let year = year_of_era + era * 400;
  let day_of_year = day_of_era - (365 * year_of_era + globalThis.Math.trunc(year_of_era / 4) - globalThis.Math.trunc(year_of_era / 100));
  let mp = globalThis.Math.trunc((5 * day_of_year + 2) / 153);
  let _block$1;
  let $1 = mp < 10;
  if ($1) {
    _block$1 = mp + 3;
  } else {
    _block$1 = mp - 9;
  }
  let month = _block$1;
  let day = day_of_year - globalThis.Math.trunc((153 * mp + 2) / 5) + 1;
  let _block$2;
  let $2 = month <= 2;
  if ($2) {
    _block$2 = year + 1;
  } else {
    _block$2 = year;
  }
  let year$1 = _block$2;
  return [year$1, month, day];
}
function to_calendar_from_offset(timestamp, offset) {
  let total = timestamp.seconds + offset * 60;
  let seconds2 = modulo2(total, 60);
  let total_minutes = floored_div(total, 60);
  let minutes = globalThis.Math.trunc(modulo2(total, 60 * 60) / 60);
  let hours = divideInt(modulo2(total, 24 * 60 * 60), 60 * 60);
  let $ = to_civil(total_minutes);
  let year;
  let month;
  let day;
  year = $[0];
  month = $[1];
  day = $[2];
  return [year, month, day, hours, minutes, seconds2];
}
function to_calendar(timestamp, offset) {
  let offset$1 = duration_to_minutes(offset);
  let $ = to_calendar_from_offset(timestamp, offset$1);
  let year;
  let month;
  let day;
  let hours;
  let minutes;
  let seconds2;
  year = $[0];
  month = $[1];
  day = $[2];
  hours = $[3];
  minutes = $[4];
  seconds2 = $[5];
  let _block;
  if (month === 1) {
    _block = new January;
  } else if (month === 2) {
    _block = new February;
  } else if (month === 3) {
    _block = new March;
  } else if (month === 4) {
    _block = new April;
  } else if (month === 5) {
    _block = new May;
  } else if (month === 6) {
    _block = new June;
  } else if (month === 7) {
    _block = new July;
  } else if (month === 8) {
    _block = new August;
  } else if (month === 9) {
    _block = new September;
  } else if (month === 10) {
    _block = new October;
  } else if (month === 11) {
    _block = new November;
  } else {
    _block = new December;
  }
  let month$1 = _block;
  let nanoseconds2 = timestamp.nanoseconds;
  let date = new Date2(year, month$1, day);
  let time = new TimeOfDay(hours, minutes, seconds2, nanoseconds2);
  return [date, time];
}
function to_unix_seconds(timestamp) {
  let seconds2 = identity(timestamp.seconds);
  let nanoseconds2 = identity(timestamp.nanoseconds);
  return seconds2 + nanoseconds2 / 1e9;
}

// build/dev/javascript/gleamy_lights/ffi.mjs
function log2(str) {
  console.log(...cstdoutln(str));
}
function info(str) {
  console.info(...cstdoutln(str));
}
function error(str) {
  console.error(...cstdoutln(str));
}
function warn(str) {
  console.warn(...cstdoutln(str));
}
function cstdoutln(str) {
  if (typeof process === "undefined") {
    let parts = [];
    str.split("\x1B[0m").map((part) => {
      if (part.includes("\x1B") && !part.startsWith("\x1B")) {
        part.replaceAll("\x1B", "\r.\r\x1B").split("\r.\r").map((part2) => {
          parts.push(process_part(part2));
        });
      } else {
        parts.push(process_part(part));
      }
    });
    let msg = "";
    let styles = '"‎'.repeat(24).split('"');
    for (let partindex in parts) {
      let part = parts[partindex];
      msg = `${msg}%c${part.text}`;
      styles[partindex] = part.style;
    }
    return [msg, ...styles];
  } else {
    return [str];
  }
}
function process_part(part) {
  if (part.match(/\x1b\[38;2;(\d+);(\d+);(\d+)m(.+)/)) {
    const match = part.match(/\x1b\[38;2;(\d+);(\d+);(\d+)m(.+)/);
    const r = parseInt(match[1]);
    const g = parseInt(match[2]);
    const b = parseInt(match[3]);
    const text = match[4];
    return { text, style: `color: rgb(${r}, ${g}, ${b})` };
  } else if (part.match(/\x1b\[48;2;(\d+);(\d+);(\d+)m(.+)/)) {
    const match = part.match(/\x1b\[48;2;(\d+);(\d+);(\d+)m(.+)/);
    const r = parseInt(match[1]);
    const g = parseInt(match[2]);
    const b = parseInt(match[3]);
    const text = match[4];
    return { text, style: `background-color: rgb(${r}, ${g}, ${b})` };
  } else {
    return { text: part, style: "color: inherit; background-color: inherit;" };
  }
}
// build/dev/javascript/envoy/envoy_ffi.mjs
function get(key) {
  let value;
  if (globalThis.Deno) {
    value = Deno.env.get(key);
  } else if (globalThis.process) {
    value = process.env[key];
  }
  if (value === undefined) {
    return new Error(undefined);
  } else {
    return new Ok(value);
  }
}
// build/dev/javascript/gleamy_lights/gleamy_lights.mjs
function by_rgb(msg, r, g, b) {
  let f = () => {
    return "\x1B[38;2;" + to_string(r) + ";" + to_string(g) + ";" + to_string(b) + "m" + msg + "\x1B[0m";
  };
  let $ = get("NO_COLOR");
  if ($ instanceof Ok) {
    let $1 = $[0];
    if ($1 === "") {
      return f();
    } else {
      return msg;
    }
  } else {
    return f();
  }
}

// build/dev/javascript/gleamy_lights/gleamy_lights/premixed.mjs
function text_error_red(msg) {
  let _pipe = msg;
  return by_rgb(_pipe, 184, 28, 74);
}
function text_cyan(msg) {
  let _pipe = msg;
  return by_rgb(_pipe, 16, 227, 227);
}
// build/dev/javascript/gleam_stdlib/gleam/function.mjs
function identity3(x) {
  return x;
}
// build/dev/javascript/gleam_stdlib/gleam/set.mjs
class Set2 extends CustomType {
  constructor(dict2) {
    super();
    this.dict = dict2;
  }
}
var token = undefined;
function new$2() {
  return new Set2(new_map());
}
function contains(set2, member) {
  let _pipe = set2.dict;
  let _pipe$1 = map_get(_pipe, member);
  return is_ok(_pipe$1);
}
function insert2(set2, member) {
  return new Set2(insert(set2.dict, member, token));
}

// build/dev/javascript/lustre/lustre/internals/constants.ffi.mjs
var EMPTY_DICT = /* @__PURE__ */ Dict.new();
function empty_dict() {
  return EMPTY_DICT;
}
var EMPTY_SET = /* @__PURE__ */ new$2();
function empty_set() {
  return EMPTY_SET;
}
var document2 = globalThis?.document;
var NAMESPACE_HTML = "http://www.w3.org/1999/xhtml";
var ELEMENT_NODE = 1;
var TEXT_NODE = 3;
var DOCUMENT_FRAGMENT_NODE = 11;
var SUPPORTS_MOVE_BEFORE = !!globalThis.HTMLElement?.prototype?.moveBefore;

// build/dev/javascript/lustre/lustre/internals/constants.mjs
var empty_list = /* @__PURE__ */ toList([]);
var option_none = /* @__PURE__ */ new None;

// build/dev/javascript/lustre/lustre/vdom/vattr.ffi.mjs
var GT = /* @__PURE__ */ new Gt;
var LT = /* @__PURE__ */ new Lt;
var EQ = /* @__PURE__ */ new Eq;
function compare3(a, b) {
  if (a.name === b.name) {
    return EQ;
  } else if (a.name < b.name) {
    return LT;
  } else {
    return GT;
  }
}

// build/dev/javascript/lustre/lustre/vdom/vattr.mjs
class Attribute extends CustomType {
  constructor(kind, name, value) {
    super();
    this.kind = kind;
    this.name = name;
    this.value = value;
  }
}
class Property extends CustomType {
  constructor(kind, name, value) {
    super();
    this.kind = kind;
    this.name = name;
    this.value = value;
  }
}
class Event2 extends CustomType {
  constructor(kind, name, handler, include, prevent_default, stop_propagation, immediate2, limit) {
    super();
    this.kind = kind;
    this.name = name;
    this.handler = handler;
    this.include = include;
    this.prevent_default = prevent_default;
    this.stop_propagation = stop_propagation;
    this.immediate = immediate2;
    this.limit = limit;
  }
}
class NoLimit extends CustomType {
  constructor(kind) {
    super();
    this.kind = kind;
  }
}
class Debounce extends CustomType {
  constructor(kind, delay) {
    super();
    this.kind = kind;
    this.delay = delay;
  }
}
class Throttle extends CustomType {
  constructor(kind, delay) {
    super();
    this.kind = kind;
    this.delay = delay;
  }
}
var attribute_kind = 0;
var property_kind = 1;
var event_kind = 2;
var debounce_kind = 1;
var throttle_kind = 2;
function limit_equals(a, b) {
  if (a instanceof NoLimit) {
    if (b instanceof NoLimit) {
      return true;
    } else {
      return false;
    }
  } else if (a instanceof Debounce) {
    if (b instanceof Debounce) {
      let d1 = a.delay;
      let d2 = b.delay;
      if (d1 === d2) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  } else if (b instanceof Throttle) {
    let d1 = a.delay;
    let d2 = b.delay;
    if (d1 === d2) {
      return true;
    } else {
      return false;
    }
  } else {
    return false;
  }
}
function merge(loop$attributes, loop$merged) {
  while (true) {
    let attributes = loop$attributes;
    let merged = loop$merged;
    if (attributes instanceof Empty) {
      return merged;
    } else {
      let $ = attributes.tail;
      if ($ instanceof Empty) {
        let attribute$1 = attributes.head;
        let rest2 = $;
        loop$attributes = rest2;
        loop$merged = prepend(attribute$1, merged);
      } else {
        let $1 = attributes.head;
        if ($1 instanceof Attribute) {
          let $2 = $.head;
          if ($2 instanceof Attribute) {
            let $3 = $1.name;
            if ($3 === "class") {
              let $4 = $2.name;
              if ($4 === "class") {
                let rest2 = $.tail;
                let kind = $1.kind;
                let class1 = $1.value;
                let class2 = $2.value;
                let value = class1 + " " + class2;
                let attribute$1 = new Attribute(kind, "class", value);
                loop$attributes = prepend(attribute$1, rest2);
                loop$merged = merged;
              } else {
                let attribute$1 = $1;
                let rest2 = $;
                loop$attributes = rest2;
                loop$merged = prepend(attribute$1, merged);
              }
            } else if ($3 === "style") {
              let $4 = $2.name;
              if ($4 === "style") {
                let rest2 = $.tail;
                let kind = $1.kind;
                let style1 = $1.value;
                let style2 = $2.value;
                let value = style1 + ";" + style2;
                let attribute$1 = new Attribute(kind, "style", value);
                loop$attributes = prepend(attribute$1, rest2);
                loop$merged = merged;
              } else {
                let attribute$1 = $1;
                let rest2 = $;
                loop$attributes = rest2;
                loop$merged = prepend(attribute$1, merged);
              }
            } else {
              let attribute$1 = $1;
              let rest2 = $;
              loop$attributes = rest2;
              loop$merged = prepend(attribute$1, merged);
            }
          } else {
            let attribute$1 = $1;
            let rest2 = $;
            loop$attributes = rest2;
            loop$merged = prepend(attribute$1, merged);
          }
        } else {
          let attribute$1 = $1;
          let rest2 = $;
          loop$attributes = rest2;
          loop$merged = prepend(attribute$1, merged);
        }
      }
    }
  }
}
function prepare(attributes) {
  if (attributes instanceof Empty) {
    return attributes;
  } else {
    let $ = attributes.tail;
    if ($ instanceof Empty) {
      return attributes;
    } else {
      let _pipe = attributes;
      let _pipe$1 = sort(_pipe, (a, b) => {
        return compare3(b, a);
      });
      return merge(_pipe$1, empty_list);
    }
  }
}
function attribute(name, value) {
  return new Attribute(attribute_kind, name, value);
}
function property(name, value) {
  return new Property(property_kind, name, value);
}
function event(name, handler, include, prevent_default, stop_propagation, immediate2, limit) {
  return new Event2(event_kind, name, handler, include, prevent_default, stop_propagation, immediate2, limit);
}

// build/dev/javascript/lustre/lustre/attribute.mjs
function attribute2(name, value) {
  return attribute(name, value);
}
function property2(name, value) {
  return property(name, value);
}
function boolean_attribute(name, value) {
  if (value) {
    return attribute2(name, "");
  } else {
    return property2(name, bool2(false));
  }
}
function class$(name) {
  return attribute2("class", name);
}
function none() {
  return class$("");
}
function id(value) {
  return attribute2("id", value);
}
function style(property3, value) {
  if (property3 === "") {
    return class$("");
  } else if (value === "") {
    return class$("");
  } else {
    return attribute2("style", property3 + ":" + value + ";");
  }
}
function href(url) {
  return attribute2("href", url);
}
function target(value) {
  return attribute2("target", value);
}
function alt(text) {
  return attribute2("alt", text);
}
function src(url) {
  return attribute2("src", url);
}
function checked(is_checked) {
  return boolean_attribute("checked", is_checked);
}
function disabled(is_disabled) {
  return boolean_attribute("disabled", is_disabled);
}
function for$(id2) {
  return attribute2("for", id2);
}
function name(element_name) {
  return attribute2("name", element_name);
}
function placeholder(text) {
  return attribute2("placeholder", text);
}
function type_(control_type) {
  return attribute2("type", control_type);
}
function value(control_value) {
  return attribute2("value", control_value);
}
function role(name2) {
  return attribute2("role", name2);
}

// build/dev/javascript/lustre/lustre/effect.mjs
class Effect extends CustomType {
  constructor(synchronous, before_paint, after_paint) {
    super();
    this.synchronous = synchronous;
    this.before_paint = before_paint;
    this.after_paint = after_paint;
  }
}
var empty2 = /* @__PURE__ */ new Effect(/* @__PURE__ */ toList([]), /* @__PURE__ */ toList([]), /* @__PURE__ */ toList([]));
function none2() {
  return empty2;
}
function from(effect) {
  let task = (actions) => {
    let dispatch = actions.dispatch;
    return effect(dispatch);
  };
  return new Effect(toList([task]), empty2.before_paint, empty2.after_paint);
}
function batch(effects) {
  return fold2(effects, empty2, (acc, eff) => {
    return new Effect(fold2(eff.synchronous, acc.synchronous, prepend2), fold2(eff.before_paint, acc.before_paint, prepend2), fold2(eff.after_paint, acc.after_paint, prepend2));
  });
}

// build/dev/javascript/lustre/lustre/internals/mutable_map.ffi.mjs
function empty3() {
  return null;
}
function get2(map5, key) {
  const value2 = map5?.get(key);
  if (value2 != null) {
    return new Ok(value2);
  } else {
    return new Error(undefined);
  }
}
function insert3(map5, key, value2) {
  map5 ??= new Map;
  map5.set(key, value2);
  return map5;
}
function remove(map5, key) {
  map5?.delete(key);
  return map5;
}

// build/dev/javascript/lustre/lustre/vdom/path.mjs
class Root extends CustomType {
}

class Key extends CustomType {
  constructor(key, parent) {
    super();
    this.key = key;
    this.parent = parent;
  }
}

class Index extends CustomType {
  constructor(index4, parent) {
    super();
    this.index = index4;
    this.parent = parent;
  }
}
var root2 = /* @__PURE__ */ new Root;
var separator_index = `
`;
var separator_key = "\t";
var separator_event = "\f";
function do_matches(loop$path, loop$candidates) {
  while (true) {
    let path = loop$path;
    let candidates = loop$candidates;
    if (candidates instanceof Empty) {
      return false;
    } else {
      let candidate = candidates.head;
      let rest2 = candidates.tail;
      let $ = starts_with(path, candidate);
      if ($) {
        return $;
      } else {
        loop$path = path;
        loop$candidates = rest2;
      }
    }
  }
}
function add3(parent, index4, key) {
  if (key === "") {
    return new Index(index4, parent);
  } else {
    return new Key(key, parent);
  }
}
function do_to_string(loop$path, loop$acc) {
  while (true) {
    let path = loop$path;
    let acc = loop$acc;
    if (path instanceof Root) {
      if (acc instanceof Empty) {
        return "";
      } else {
        let segments = acc.tail;
        return concat2(segments);
      }
    } else if (path instanceof Key) {
      let key = path.key;
      let parent = path.parent;
      loop$path = parent;
      loop$acc = prepend(separator_key, prepend(key, acc));
    } else {
      let index4 = path.index;
      let parent = path.parent;
      loop$path = parent;
      loop$acc = prepend(separator_index, prepend(to_string(index4), acc));
    }
  }
}
function to_string4(path) {
  return do_to_string(path, toList([]));
}
function matches(path, candidates) {
  if (candidates instanceof Empty) {
    return false;
  } else {
    return do_matches(to_string4(path), candidates);
  }
}
function event2(path, event3) {
  return do_to_string(path, toList([separator_event, event3]));
}

// build/dev/javascript/lustre/lustre/vdom/vnode.mjs
class Fragment extends CustomType {
  constructor(kind, key, mapper, children, keyed_children, children_count) {
    super();
    this.kind = kind;
    this.key = key;
    this.mapper = mapper;
    this.children = children;
    this.keyed_children = keyed_children;
    this.children_count = children_count;
  }
}
class Element extends CustomType {
  constructor(kind, key, mapper, namespace, tag, attributes, children, keyed_children, self_closing, void$) {
    super();
    this.kind = kind;
    this.key = key;
    this.mapper = mapper;
    this.namespace = namespace;
    this.tag = tag;
    this.attributes = attributes;
    this.children = children;
    this.keyed_children = keyed_children;
    this.self_closing = self_closing;
    this.void = void$;
  }
}
class Text extends CustomType {
  constructor(kind, key, mapper, content) {
    super();
    this.kind = kind;
    this.key = key;
    this.mapper = mapper;
    this.content = content;
  }
}
class UnsafeInnerHtml extends CustomType {
  constructor(kind, key, mapper, namespace, tag, attributes, inner_html) {
    super();
    this.kind = kind;
    this.key = key;
    this.mapper = mapper;
    this.namespace = namespace;
    this.tag = tag;
    this.attributes = attributes;
    this.inner_html = inner_html;
  }
}
var fragment_kind = 0;
var element_kind = 1;
var text_kind = 2;
var unsafe_inner_html_kind = 3;
function is_void_element(tag, namespace) {
  if (namespace === "") {
    if (tag === "area") {
      return true;
    } else if (tag === "base") {
      return true;
    } else if (tag === "br") {
      return true;
    } else if (tag === "col") {
      return true;
    } else if (tag === "embed") {
      return true;
    } else if (tag === "hr") {
      return true;
    } else if (tag === "img") {
      return true;
    } else if (tag === "input") {
      return true;
    } else if (tag === "link") {
      return true;
    } else if (tag === "meta") {
      return true;
    } else if (tag === "param") {
      return true;
    } else if (tag === "source") {
      return true;
    } else if (tag === "track") {
      return true;
    } else if (tag === "wbr") {
      return true;
    } else {
      return false;
    }
  } else {
    return false;
  }
}
function advance(node) {
  if (node instanceof Fragment) {
    let children_count = node.children_count;
    return 1 + children_count;
  } else {
    return 1;
  }
}
function fragment(key, mapper, children, keyed_children, children_count) {
  return new Fragment(fragment_kind, key, mapper, children, keyed_children, children_count);
}
function element(key, mapper, namespace, tag, attributes, children, keyed_children, self_closing, void$) {
  return new Element(element_kind, key, mapper, namespace, tag, prepare(attributes), children, keyed_children, self_closing, void$ || is_void_element(tag, namespace));
}
function text(key, mapper, content) {
  return new Text(text_kind, key, mapper, content);
}
function set_fragment_key(loop$key, loop$children, loop$index, loop$new_children, loop$keyed_children) {
  while (true) {
    let key = loop$key;
    let children = loop$children;
    let index4 = loop$index;
    let new_children = loop$new_children;
    let keyed_children = loop$keyed_children;
    if (children instanceof Empty) {
      return [reverse(new_children), keyed_children];
    } else {
      let $ = children.head;
      if ($ instanceof Fragment) {
        let node = $;
        if (node.key === "") {
          let children$1 = children.tail;
          let child_key = key + "::" + to_string(index4);
          let $1 = set_fragment_key(child_key, node.children, 0, empty_list, empty3());
          let node_children;
          let node_keyed_children;
          node_children = $1[0];
          node_keyed_children = $1[1];
          let new_node = new Fragment(node.kind, node.key, node.mapper, node_children, node_keyed_children, node.children_count);
          let new_children$1 = prepend(new_node, new_children);
          let index$1 = index4 + 1;
          loop$key = key;
          loop$children = children$1;
          loop$index = index$1;
          loop$new_children = new_children$1;
          loop$keyed_children = keyed_children;
        } else {
          let node2 = $;
          if (node2.key !== "") {
            let children$1 = children.tail;
            let child_key = key + "::" + node2.key;
            let keyed_node = to_keyed(child_key, node2);
            let new_children$1 = prepend(keyed_node, new_children);
            let keyed_children$1 = insert3(keyed_children, child_key, keyed_node);
            let index$1 = index4 + 1;
            loop$key = key;
            loop$children = children$1;
            loop$index = index$1;
            loop$new_children = new_children$1;
            loop$keyed_children = keyed_children$1;
          } else {
            let node3 = $;
            let children$1 = children.tail;
            let new_children$1 = prepend(node3, new_children);
            let index$1 = index4 + 1;
            loop$key = key;
            loop$children = children$1;
            loop$index = index$1;
            loop$new_children = new_children$1;
            loop$keyed_children = keyed_children;
          }
        }
      } else {
        let node = $;
        if (node.key !== "") {
          let children$1 = children.tail;
          let child_key = key + "::" + node.key;
          let keyed_node = to_keyed(child_key, node);
          let new_children$1 = prepend(keyed_node, new_children);
          let keyed_children$1 = insert3(keyed_children, child_key, keyed_node);
          let index$1 = index4 + 1;
          loop$key = key;
          loop$children = children$1;
          loop$index = index$1;
          loop$new_children = new_children$1;
          loop$keyed_children = keyed_children$1;
        } else {
          let node2 = $;
          let children$1 = children.tail;
          let new_children$1 = prepend(node2, new_children);
          let index$1 = index4 + 1;
          loop$key = key;
          loop$children = children$1;
          loop$index = index$1;
          loop$new_children = new_children$1;
          loop$keyed_children = keyed_children;
        }
      }
    }
  }
}
function to_keyed(key, node) {
  if (node instanceof Fragment) {
    let children = node.children;
    let $ = set_fragment_key(key, children, 0, empty_list, empty3());
    let children$1;
    let keyed_children;
    children$1 = $[0];
    keyed_children = $[1];
    return new Fragment(node.kind, key, node.mapper, children$1, keyed_children, node.children_count);
  } else if (node instanceof Element) {
    return new Element(node.kind, key, node.mapper, node.namespace, node.tag, node.attributes, node.children, node.keyed_children, node.self_closing, node.void);
  } else if (node instanceof Text) {
    return new Text(node.kind, key, node.mapper, node.content);
  } else {
    return new UnsafeInnerHtml(node.kind, key, node.mapper, node.namespace, node.tag, node.attributes, node.inner_html);
  }
}

// build/dev/javascript/lustre/lustre/vdom/patch.mjs
class Patch extends CustomType {
  constructor(index4, removed, changes, children) {
    super();
    this.index = index4;
    this.removed = removed;
    this.changes = changes;
    this.children = children;
  }
}
class ReplaceText extends CustomType {
  constructor(kind, content) {
    super();
    this.kind = kind;
    this.content = content;
  }
}
class ReplaceInnerHtml extends CustomType {
  constructor(kind, inner_html) {
    super();
    this.kind = kind;
    this.inner_html = inner_html;
  }
}
class Update extends CustomType {
  constructor(kind, added, removed) {
    super();
    this.kind = kind;
    this.added = added;
    this.removed = removed;
  }
}
class Move extends CustomType {
  constructor(kind, key, before, count) {
    super();
    this.kind = kind;
    this.key = key;
    this.before = before;
    this.count = count;
  }
}
class RemoveKey extends CustomType {
  constructor(kind, key, count) {
    super();
    this.kind = kind;
    this.key = key;
    this.count = count;
  }
}
class Replace extends CustomType {
  constructor(kind, from2, count, with$) {
    super();
    this.kind = kind;
    this.from = from2;
    this.count = count;
    this.with = with$;
  }
}
class Insert extends CustomType {
  constructor(kind, children, before) {
    super();
    this.kind = kind;
    this.children = children;
    this.before = before;
  }
}
class Remove extends CustomType {
  constructor(kind, from2, count) {
    super();
    this.kind = kind;
    this.from = from2;
    this.count = count;
  }
}
var replace_text_kind = 0;
var replace_inner_html_kind = 1;
var update_kind = 2;
var move_kind = 3;
var remove_key_kind = 4;
var replace_kind = 5;
var insert_kind = 6;
var remove_kind = 7;
function new$5(index4, removed, changes, children) {
  return new Patch(index4, removed, changes, children);
}
function replace_text(content) {
  return new ReplaceText(replace_text_kind, content);
}
function replace_inner_html(inner_html) {
  return new ReplaceInnerHtml(replace_inner_html_kind, inner_html);
}
function update(added, removed) {
  return new Update(update_kind, added, removed);
}
function move(key, before, count) {
  return new Move(move_kind, key, before, count);
}
function remove_key(key, count) {
  return new RemoveKey(remove_key_kind, key, count);
}
function replace2(from2, count, with$) {
  return new Replace(replace_kind, from2, count, with$);
}
function insert4(children, before) {
  return new Insert(insert_kind, children, before);
}
function remove2(from2, count) {
  return new Remove(remove_kind, from2, count);
}

// build/dev/javascript/lustre/lustre/vdom/diff.mjs
class Diff extends CustomType {
  constructor(patch, events) {
    super();
    this.patch = patch;
    this.events = events;
  }
}
class AttributeChange extends CustomType {
  constructor(added, removed, events) {
    super();
    this.added = added;
    this.removed = removed;
    this.events = events;
  }
}
function is_controlled(events, namespace, tag, path) {
  if (tag === "input" && namespace === "") {
    return has_dispatched_events(events, path);
  } else if (tag === "select" && namespace === "") {
    return has_dispatched_events(events, path);
  } else if (tag === "textarea" && namespace === "") {
    return has_dispatched_events(events, path);
  } else {
    return false;
  }
}
function diff_attributes(loop$controlled, loop$path, loop$mapper, loop$events, loop$old, loop$new, loop$added, loop$removed) {
  while (true) {
    let controlled = loop$controlled;
    let path = loop$path;
    let mapper = loop$mapper;
    let events = loop$events;
    let old = loop$old;
    let new$6 = loop$new;
    let added = loop$added;
    let removed = loop$removed;
    if (old instanceof Empty) {
      if (new$6 instanceof Empty) {
        return new AttributeChange(added, removed, events);
      } else {
        let $ = new$6.head;
        if ($ instanceof Event2) {
          let next = $;
          let new$1 = new$6.tail;
          let name2 = $.name;
          let handler = $.handler;
          let added$1 = prepend(next, added);
          let events$1 = add_event(events, mapper, path, name2, handler);
          loop$controlled = controlled;
          loop$path = path;
          loop$mapper = mapper;
          loop$events = events$1;
          loop$old = old;
          loop$new = new$1;
          loop$added = added$1;
          loop$removed = removed;
        } else {
          let next = $;
          let new$1 = new$6.tail;
          let added$1 = prepend(next, added);
          loop$controlled = controlled;
          loop$path = path;
          loop$mapper = mapper;
          loop$events = events;
          loop$old = old;
          loop$new = new$1;
          loop$added = added$1;
          loop$removed = removed;
        }
      }
    } else if (new$6 instanceof Empty) {
      let $ = old.head;
      if ($ instanceof Event2) {
        let prev = $;
        let old$1 = old.tail;
        let name2 = $.name;
        let removed$1 = prepend(prev, removed);
        let events$1 = remove_event(events, path, name2);
        loop$controlled = controlled;
        loop$path = path;
        loop$mapper = mapper;
        loop$events = events$1;
        loop$old = old$1;
        loop$new = new$6;
        loop$added = added;
        loop$removed = removed$1;
      } else {
        let prev = $;
        let old$1 = old.tail;
        let removed$1 = prepend(prev, removed);
        loop$controlled = controlled;
        loop$path = path;
        loop$mapper = mapper;
        loop$events = events;
        loop$old = old$1;
        loop$new = new$6;
        loop$added = added;
        loop$removed = removed$1;
      }
    } else {
      let prev = old.head;
      let remaining_old = old.tail;
      let next = new$6.head;
      let remaining_new = new$6.tail;
      let $ = compare3(prev, next);
      if ($ instanceof Lt) {
        if (prev instanceof Event2) {
          let name2 = prev.name;
          let removed$1 = prepend(prev, removed);
          let events$1 = remove_event(events, path, name2);
          loop$controlled = controlled;
          loop$path = path;
          loop$mapper = mapper;
          loop$events = events$1;
          loop$old = remaining_old;
          loop$new = new$6;
          loop$added = added;
          loop$removed = removed$1;
        } else {
          let removed$1 = prepend(prev, removed);
          loop$controlled = controlled;
          loop$path = path;
          loop$mapper = mapper;
          loop$events = events;
          loop$old = remaining_old;
          loop$new = new$6;
          loop$added = added;
          loop$removed = removed$1;
        }
      } else if ($ instanceof Eq) {
        if (prev instanceof Attribute) {
          if (next instanceof Attribute) {
            let _block;
            let $1 = next.name;
            if ($1 === "value") {
              _block = controlled || prev.value !== next.value;
            } else if ($1 === "checked") {
              _block = controlled || prev.value !== next.value;
            } else if ($1 === "selected") {
              _block = controlled || prev.value !== next.value;
            } else {
              _block = prev.value !== next.value;
            }
            let has_changes = _block;
            let _block$1;
            if (has_changes) {
              _block$1 = prepend(next, added);
            } else {
              _block$1 = added;
            }
            let added$1 = _block$1;
            loop$controlled = controlled;
            loop$path = path;
            loop$mapper = mapper;
            loop$events = events;
            loop$old = remaining_old;
            loop$new = remaining_new;
            loop$added = added$1;
            loop$removed = removed;
          } else if (next instanceof Event2) {
            let name2 = next.name;
            let handler = next.handler;
            let added$1 = prepend(next, added);
            let removed$1 = prepend(prev, removed);
            let events$1 = add_event(events, mapper, path, name2, handler);
            loop$controlled = controlled;
            loop$path = path;
            loop$mapper = mapper;
            loop$events = events$1;
            loop$old = remaining_old;
            loop$new = remaining_new;
            loop$added = added$1;
            loop$removed = removed$1;
          } else {
            let added$1 = prepend(next, added);
            let removed$1 = prepend(prev, removed);
            loop$controlled = controlled;
            loop$path = path;
            loop$mapper = mapper;
            loop$events = events;
            loop$old = remaining_old;
            loop$new = remaining_new;
            loop$added = added$1;
            loop$removed = removed$1;
          }
        } else if (prev instanceof Property) {
          if (next instanceof Property) {
            let _block;
            let $1 = next.name;
            if ($1 === "scrollLeft") {
              _block = true;
            } else if ($1 === "scrollRight") {
              _block = true;
            } else if ($1 === "value") {
              _block = controlled || !isEqual(prev.value, next.value);
            } else if ($1 === "checked") {
              _block = controlled || !isEqual(prev.value, next.value);
            } else if ($1 === "selected") {
              _block = controlled || !isEqual(prev.value, next.value);
            } else {
              _block = !isEqual(prev.value, next.value);
            }
            let has_changes = _block;
            let _block$1;
            if (has_changes) {
              _block$1 = prepend(next, added);
            } else {
              _block$1 = added;
            }
            let added$1 = _block$1;
            loop$controlled = controlled;
            loop$path = path;
            loop$mapper = mapper;
            loop$events = events;
            loop$old = remaining_old;
            loop$new = remaining_new;
            loop$added = added$1;
            loop$removed = removed;
          } else if (next instanceof Event2) {
            let name2 = next.name;
            let handler = next.handler;
            let added$1 = prepend(next, added);
            let removed$1 = prepend(prev, removed);
            let events$1 = add_event(events, mapper, path, name2, handler);
            loop$controlled = controlled;
            loop$path = path;
            loop$mapper = mapper;
            loop$events = events$1;
            loop$old = remaining_old;
            loop$new = remaining_new;
            loop$added = added$1;
            loop$removed = removed$1;
          } else {
            let added$1 = prepend(next, added);
            let removed$1 = prepend(prev, removed);
            loop$controlled = controlled;
            loop$path = path;
            loop$mapper = mapper;
            loop$events = events;
            loop$old = remaining_old;
            loop$new = remaining_new;
            loop$added = added$1;
            loop$removed = removed$1;
          }
        } else if (next instanceof Event2) {
          let name2 = next.name;
          let handler = next.handler;
          let has_changes = prev.prevent_default !== next.prevent_default || prev.stop_propagation !== next.stop_propagation || prev.immediate !== next.immediate || !limit_equals(prev.limit, next.limit);
          let _block;
          if (has_changes) {
            _block = prepend(next, added);
          } else {
            _block = added;
          }
          let added$1 = _block;
          let events$1 = add_event(events, mapper, path, name2, handler);
          loop$controlled = controlled;
          loop$path = path;
          loop$mapper = mapper;
          loop$events = events$1;
          loop$old = remaining_old;
          loop$new = remaining_new;
          loop$added = added$1;
          loop$removed = removed;
        } else {
          let name2 = prev.name;
          let added$1 = prepend(next, added);
          let removed$1 = prepend(prev, removed);
          let events$1 = remove_event(events, path, name2);
          loop$controlled = controlled;
          loop$path = path;
          loop$mapper = mapper;
          loop$events = events$1;
          loop$old = remaining_old;
          loop$new = remaining_new;
          loop$added = added$1;
          loop$removed = removed$1;
        }
      } else if (next instanceof Event2) {
        let name2 = next.name;
        let handler = next.handler;
        let added$1 = prepend(next, added);
        let events$1 = add_event(events, mapper, path, name2, handler);
        loop$controlled = controlled;
        loop$path = path;
        loop$mapper = mapper;
        loop$events = events$1;
        loop$old = old;
        loop$new = remaining_new;
        loop$added = added$1;
        loop$removed = removed;
      } else {
        let added$1 = prepend(next, added);
        loop$controlled = controlled;
        loop$path = path;
        loop$mapper = mapper;
        loop$events = events;
        loop$old = old;
        loop$new = remaining_new;
        loop$added = added$1;
        loop$removed = removed;
      }
    }
  }
}
function do_diff(loop$old, loop$old_keyed, loop$new, loop$new_keyed, loop$moved, loop$moved_offset, loop$removed, loop$node_index, loop$patch_index, loop$path, loop$changes, loop$children, loop$mapper, loop$events) {
  while (true) {
    let old = loop$old;
    let old_keyed = loop$old_keyed;
    let new$6 = loop$new;
    let new_keyed = loop$new_keyed;
    let moved = loop$moved;
    let moved_offset = loop$moved_offset;
    let removed = loop$removed;
    let node_index = loop$node_index;
    let patch_index = loop$patch_index;
    let path = loop$path;
    let changes = loop$changes;
    let children = loop$children;
    let mapper = loop$mapper;
    let events = loop$events;
    if (old instanceof Empty) {
      if (new$6 instanceof Empty) {
        return new Diff(new Patch(patch_index, removed, changes, children), events);
      } else {
        let events$1 = add_children(events, mapper, path, node_index, new$6);
        let insert5 = insert4(new$6, node_index - moved_offset);
        let changes$1 = prepend(insert5, changes);
        return new Diff(new Patch(patch_index, removed, changes$1, children), events$1);
      }
    } else if (new$6 instanceof Empty) {
      let prev = old.head;
      let old$1 = old.tail;
      let _block;
      let $ = prev.key === "" || !contains(moved, prev.key);
      if ($) {
        _block = removed + advance(prev);
      } else {
        _block = removed;
      }
      let removed$1 = _block;
      let events$1 = remove_child(events, path, node_index, prev);
      loop$old = old$1;
      loop$old_keyed = old_keyed;
      loop$new = new$6;
      loop$new_keyed = new_keyed;
      loop$moved = moved;
      loop$moved_offset = moved_offset;
      loop$removed = removed$1;
      loop$node_index = node_index;
      loop$patch_index = patch_index;
      loop$path = path;
      loop$changes = changes;
      loop$children = children;
      loop$mapper = mapper;
      loop$events = events$1;
    } else {
      let prev = old.head;
      let next = new$6.head;
      if (prev.key !== next.key) {
        let old_remaining = old.tail;
        let new_remaining = new$6.tail;
        let next_did_exist = get2(old_keyed, next.key);
        let prev_does_exist = get2(new_keyed, prev.key);
        let prev_has_moved = contains(moved, prev.key);
        if (prev_does_exist instanceof Ok) {
          if (next_did_exist instanceof Ok) {
            if (prev_has_moved) {
              loop$old = old_remaining;
              loop$old_keyed = old_keyed;
              loop$new = new$6;
              loop$new_keyed = new_keyed;
              loop$moved = moved;
              loop$moved_offset = moved_offset - advance(prev);
              loop$removed = removed;
              loop$node_index = node_index;
              loop$patch_index = patch_index;
              loop$path = path;
              loop$changes = changes;
              loop$children = children;
              loop$mapper = mapper;
              loop$events = events;
            } else {
              let match = next_did_exist[0];
              let count = advance(next);
              let before = node_index - moved_offset;
              let move2 = move(next.key, before, count);
              let changes$1 = prepend(move2, changes);
              let moved$1 = insert2(moved, next.key);
              let moved_offset$1 = moved_offset + count;
              loop$old = prepend(match, old);
              loop$old_keyed = old_keyed;
              loop$new = new$6;
              loop$new_keyed = new_keyed;
              loop$moved = moved$1;
              loop$moved_offset = moved_offset$1;
              loop$removed = removed;
              loop$node_index = node_index;
              loop$patch_index = patch_index;
              loop$path = path;
              loop$changes = changes$1;
              loop$children = children;
              loop$mapper = mapper;
              loop$events = events;
            }
          } else {
            let before = node_index - moved_offset;
            let count = advance(next);
            let events$1 = add_child(events, mapper, path, node_index, next);
            let insert5 = insert4(toList([next]), before);
            let changes$1 = prepend(insert5, changes);
            loop$old = old;
            loop$old_keyed = old_keyed;
            loop$new = new_remaining;
            loop$new_keyed = new_keyed;
            loop$moved = moved;
            loop$moved_offset = moved_offset + count;
            loop$removed = removed;
            loop$node_index = node_index + count;
            loop$patch_index = patch_index;
            loop$path = path;
            loop$changes = changes$1;
            loop$children = children;
            loop$mapper = mapper;
            loop$events = events$1;
          }
        } else if (next_did_exist instanceof Ok) {
          let count = advance(prev);
          let moved_offset$1 = moved_offset - count;
          let events$1 = remove_child(events, path, node_index, prev);
          let remove3 = remove_key(prev.key, count);
          let changes$1 = prepend(remove3, changes);
          loop$old = old_remaining;
          loop$old_keyed = old_keyed;
          loop$new = new$6;
          loop$new_keyed = new_keyed;
          loop$moved = moved;
          loop$moved_offset = moved_offset$1;
          loop$removed = removed;
          loop$node_index = node_index;
          loop$patch_index = patch_index;
          loop$path = path;
          loop$changes = changes$1;
          loop$children = children;
          loop$mapper = mapper;
          loop$events = events$1;
        } else {
          let prev_count = advance(prev);
          let next_count = advance(next);
          let change = replace2(node_index - moved_offset, prev_count, next);
          let _block;
          let _pipe = events;
          let _pipe$1 = remove_child(_pipe, path, node_index, prev);
          _block = add_child(_pipe$1, mapper, path, node_index, next);
          let events$1 = _block;
          loop$old = old_remaining;
          loop$old_keyed = old_keyed;
          loop$new = new_remaining;
          loop$new_keyed = new_keyed;
          loop$moved = moved;
          loop$moved_offset = moved_offset - prev_count + next_count;
          loop$removed = removed;
          loop$node_index = node_index + next_count;
          loop$patch_index = patch_index;
          loop$path = path;
          loop$changes = prepend(change, changes);
          loop$children = children;
          loop$mapper = mapper;
          loop$events = events$1;
        }
      } else {
        let $ = old.head;
        if ($ instanceof Fragment) {
          let $1 = new$6.head;
          if ($1 instanceof Fragment) {
            let prev2 = $;
            let old$1 = old.tail;
            let next2 = $1;
            let new$1 = new$6.tail;
            let node_index$1 = node_index + 1;
            let prev_count = prev2.children_count;
            let next_count = next2.children_count;
            let composed_mapper = compose_mapper(mapper, next2.mapper);
            let child = do_diff(prev2.children, prev2.keyed_children, next2.children, next2.keyed_children, empty_set(), moved_offset, 0, node_index$1, -1, path, empty_list, children, composed_mapper, events);
            let _block;
            let $2 = child.patch.removed > 0;
            if ($2) {
              let remove_from = node_index$1 + next_count - moved_offset;
              let patch = remove2(remove_from, child.patch.removed);
              _block = append(child.patch.changes, prepend(patch, changes));
            } else {
              _block = append(child.patch.changes, changes);
            }
            let changes$1 = _block;
            loop$old = old$1;
            loop$old_keyed = old_keyed;
            loop$new = new$1;
            loop$new_keyed = new_keyed;
            loop$moved = moved;
            loop$moved_offset = moved_offset + next_count - prev_count;
            loop$removed = removed;
            loop$node_index = node_index$1 + next_count;
            loop$patch_index = patch_index;
            loop$path = path;
            loop$changes = changes$1;
            loop$children = child.patch.children;
            loop$mapper = mapper;
            loop$events = child.events;
          } else {
            let prev2 = $;
            let old_remaining = old.tail;
            let next2 = $1;
            let new_remaining = new$6.tail;
            let prev_count = advance(prev2);
            let next_count = advance(next2);
            let change = replace2(node_index - moved_offset, prev_count, next2);
            let _block;
            let _pipe = events;
            let _pipe$1 = remove_child(_pipe, path, node_index, prev2);
            _block = add_child(_pipe$1, mapper, path, node_index, next2);
            let events$1 = _block;
            loop$old = old_remaining;
            loop$old_keyed = old_keyed;
            loop$new = new_remaining;
            loop$new_keyed = new_keyed;
            loop$moved = moved;
            loop$moved_offset = moved_offset - prev_count + next_count;
            loop$removed = removed;
            loop$node_index = node_index + next_count;
            loop$patch_index = patch_index;
            loop$path = path;
            loop$changes = prepend(change, changes);
            loop$children = children;
            loop$mapper = mapper;
            loop$events = events$1;
          }
        } else if ($ instanceof Element) {
          let $1 = new$6.head;
          if ($1 instanceof Element) {
            let prev2 = $;
            let next2 = $1;
            if (prev2.namespace === next2.namespace && prev2.tag === next2.tag) {
              let old$1 = old.tail;
              let new$1 = new$6.tail;
              let composed_mapper = compose_mapper(mapper, next2.mapper);
              let child_path = add3(path, node_index, next2.key);
              let controlled = is_controlled(events, next2.namespace, next2.tag, child_path);
              let $2 = diff_attributes(controlled, child_path, composed_mapper, events, prev2.attributes, next2.attributes, empty_list, empty_list);
              let added_attrs;
              let removed_attrs;
              let events$1;
              added_attrs = $2.added;
              removed_attrs = $2.removed;
              events$1 = $2.events;
              let _block;
              if (added_attrs instanceof Empty && removed_attrs instanceof Empty) {
                _block = empty_list;
              } else {
                _block = toList([update(added_attrs, removed_attrs)]);
              }
              let initial_child_changes = _block;
              let child = do_diff(prev2.children, prev2.keyed_children, next2.children, next2.keyed_children, empty_set(), 0, 0, 0, node_index, child_path, initial_child_changes, empty_list, composed_mapper, events$1);
              let _block$1;
              let $3 = child.patch;
              let $4 = $3.changes;
              if ($4 instanceof Empty) {
                let $5 = $3.children;
                if ($5 instanceof Empty) {
                  let $6 = $3.removed;
                  if ($6 === 0) {
                    _block$1 = children;
                  } else {
                    _block$1 = prepend(child.patch, children);
                  }
                } else {
                  _block$1 = prepend(child.patch, children);
                }
              } else {
                _block$1 = prepend(child.patch, children);
              }
              let children$1 = _block$1;
              loop$old = old$1;
              loop$old_keyed = old_keyed;
              loop$new = new$1;
              loop$new_keyed = new_keyed;
              loop$moved = moved;
              loop$moved_offset = moved_offset;
              loop$removed = removed;
              loop$node_index = node_index + 1;
              loop$patch_index = patch_index;
              loop$path = path;
              loop$changes = changes;
              loop$children = children$1;
              loop$mapper = mapper;
              loop$events = child.events;
            } else {
              let prev3 = $;
              let old_remaining = old.tail;
              let next3 = $1;
              let new_remaining = new$6.tail;
              let prev_count = advance(prev3);
              let next_count = advance(next3);
              let change = replace2(node_index - moved_offset, prev_count, next3);
              let _block;
              let _pipe = events;
              let _pipe$1 = remove_child(_pipe, path, node_index, prev3);
              _block = add_child(_pipe$1, mapper, path, node_index, next3);
              let events$1 = _block;
              loop$old = old_remaining;
              loop$old_keyed = old_keyed;
              loop$new = new_remaining;
              loop$new_keyed = new_keyed;
              loop$moved = moved;
              loop$moved_offset = moved_offset - prev_count + next_count;
              loop$removed = removed;
              loop$node_index = node_index + next_count;
              loop$patch_index = patch_index;
              loop$path = path;
              loop$changes = prepend(change, changes);
              loop$children = children;
              loop$mapper = mapper;
              loop$events = events$1;
            }
          } else {
            let prev2 = $;
            let old_remaining = old.tail;
            let next2 = $1;
            let new_remaining = new$6.tail;
            let prev_count = advance(prev2);
            let next_count = advance(next2);
            let change = replace2(node_index - moved_offset, prev_count, next2);
            let _block;
            let _pipe = events;
            let _pipe$1 = remove_child(_pipe, path, node_index, prev2);
            _block = add_child(_pipe$1, mapper, path, node_index, next2);
            let events$1 = _block;
            loop$old = old_remaining;
            loop$old_keyed = old_keyed;
            loop$new = new_remaining;
            loop$new_keyed = new_keyed;
            loop$moved = moved;
            loop$moved_offset = moved_offset - prev_count + next_count;
            loop$removed = removed;
            loop$node_index = node_index + next_count;
            loop$patch_index = patch_index;
            loop$path = path;
            loop$changes = prepend(change, changes);
            loop$children = children;
            loop$mapper = mapper;
            loop$events = events$1;
          }
        } else if ($ instanceof Text) {
          let $1 = new$6.head;
          if ($1 instanceof Text) {
            let prev2 = $;
            let next2 = $1;
            if (prev2.content === next2.content) {
              let old$1 = old.tail;
              let new$1 = new$6.tail;
              loop$old = old$1;
              loop$old_keyed = old_keyed;
              loop$new = new$1;
              loop$new_keyed = new_keyed;
              loop$moved = moved;
              loop$moved_offset = moved_offset;
              loop$removed = removed;
              loop$node_index = node_index + 1;
              loop$patch_index = patch_index;
              loop$path = path;
              loop$changes = changes;
              loop$children = children;
              loop$mapper = mapper;
              loop$events = events;
            } else {
              let old$1 = old.tail;
              let next3 = $1;
              let new$1 = new$6.tail;
              let child = new$5(node_index, 0, toList([replace_text(next3.content)]), empty_list);
              loop$old = old$1;
              loop$old_keyed = old_keyed;
              loop$new = new$1;
              loop$new_keyed = new_keyed;
              loop$moved = moved;
              loop$moved_offset = moved_offset;
              loop$removed = removed;
              loop$node_index = node_index + 1;
              loop$patch_index = patch_index;
              loop$path = path;
              loop$changes = changes;
              loop$children = prepend(child, children);
              loop$mapper = mapper;
              loop$events = events;
            }
          } else {
            let prev2 = $;
            let old_remaining = old.tail;
            let next2 = $1;
            let new_remaining = new$6.tail;
            let prev_count = advance(prev2);
            let next_count = advance(next2);
            let change = replace2(node_index - moved_offset, prev_count, next2);
            let _block;
            let _pipe = events;
            let _pipe$1 = remove_child(_pipe, path, node_index, prev2);
            _block = add_child(_pipe$1, mapper, path, node_index, next2);
            let events$1 = _block;
            loop$old = old_remaining;
            loop$old_keyed = old_keyed;
            loop$new = new_remaining;
            loop$new_keyed = new_keyed;
            loop$moved = moved;
            loop$moved_offset = moved_offset - prev_count + next_count;
            loop$removed = removed;
            loop$node_index = node_index + next_count;
            loop$patch_index = patch_index;
            loop$path = path;
            loop$changes = prepend(change, changes);
            loop$children = children;
            loop$mapper = mapper;
            loop$events = events$1;
          }
        } else {
          let $1 = new$6.head;
          if ($1 instanceof UnsafeInnerHtml) {
            let prev2 = $;
            let old$1 = old.tail;
            let next2 = $1;
            let new$1 = new$6.tail;
            let composed_mapper = compose_mapper(mapper, next2.mapper);
            let child_path = add3(path, node_index, next2.key);
            let $2 = diff_attributes(false, child_path, composed_mapper, events, prev2.attributes, next2.attributes, empty_list, empty_list);
            let added_attrs;
            let removed_attrs;
            let events$1;
            added_attrs = $2.added;
            removed_attrs = $2.removed;
            events$1 = $2.events;
            let _block;
            if (added_attrs instanceof Empty && removed_attrs instanceof Empty) {
              _block = empty_list;
            } else {
              _block = toList([update(added_attrs, removed_attrs)]);
            }
            let child_changes = _block;
            let _block$1;
            let $3 = prev2.inner_html === next2.inner_html;
            if ($3) {
              _block$1 = child_changes;
            } else {
              _block$1 = prepend(replace_inner_html(next2.inner_html), child_changes);
            }
            let child_changes$1 = _block$1;
            let _block$2;
            if (child_changes$1 instanceof Empty) {
              _block$2 = children;
            } else {
              _block$2 = prepend(new$5(node_index, 0, child_changes$1, toList([])), children);
            }
            let children$1 = _block$2;
            loop$old = old$1;
            loop$old_keyed = old_keyed;
            loop$new = new$1;
            loop$new_keyed = new_keyed;
            loop$moved = moved;
            loop$moved_offset = moved_offset;
            loop$removed = removed;
            loop$node_index = node_index + 1;
            loop$patch_index = patch_index;
            loop$path = path;
            loop$changes = changes;
            loop$children = children$1;
            loop$mapper = mapper;
            loop$events = events$1;
          } else {
            let prev2 = $;
            let old_remaining = old.tail;
            let next2 = $1;
            let new_remaining = new$6.tail;
            let prev_count = advance(prev2);
            let next_count = advance(next2);
            let change = replace2(node_index - moved_offset, prev_count, next2);
            let _block;
            let _pipe = events;
            let _pipe$1 = remove_child(_pipe, path, node_index, prev2);
            _block = add_child(_pipe$1, mapper, path, node_index, next2);
            let events$1 = _block;
            loop$old = old_remaining;
            loop$old_keyed = old_keyed;
            loop$new = new_remaining;
            loop$new_keyed = new_keyed;
            loop$moved = moved;
            loop$moved_offset = moved_offset - prev_count + next_count;
            loop$removed = removed;
            loop$node_index = node_index + next_count;
            loop$patch_index = patch_index;
            loop$path = path;
            loop$changes = prepend(change, changes);
            loop$children = children;
            loop$mapper = mapper;
            loop$events = events$1;
          }
        }
      }
    }
  }
}
function diff(events, old, new$6) {
  return do_diff(toList([old]), empty3(), toList([new$6]), empty3(), empty_set(), 0, 0, 0, 0, root2, empty_list, empty_list, identity3, tick(events));
}

// build/dev/javascript/lustre/lustre/vdom/reconciler.ffi.mjs
class Reconciler {
  offset = 0;
  #root = null;
  #dispatch = () => {};
  #useServerEvents = false;
  constructor(root3, dispatch, { useServerEvents = false } = {}) {
    this.#root = root3;
    this.#dispatch = dispatch;
    this.#useServerEvents = useServerEvents;
  }
  mount(vdom) {
    appendChild(this.#root, this.#createElement(vdom));
  }
  #stack = [];
  push(patch) {
    const offset = this.offset;
    if (offset) {
      iterate(patch.changes, (change) => {
        switch (change.kind) {
          case insert_kind:
          case move_kind:
            change.before = (change.before | 0) + offset;
            break;
          case remove_kind:
          case replace_kind:
            change.from = (change.from | 0) + offset;
            break;
        }
      });
      iterate(patch.children, (child) => {
        child.index = (child.index | 0) + offset;
      });
    }
    this.#stack.push({ node: this.#root, patch });
    this.#reconcile();
  }
  #reconcile() {
    const self = this;
    while (self.#stack.length) {
      const { node, patch } = self.#stack.pop();
      iterate(patch.changes, (change) => {
        switch (change.kind) {
          case insert_kind:
            self.#insert(node, change.children, change.before);
            break;
          case move_kind:
            self.#move(node, change.key, change.before, change.count);
            break;
          case remove_key_kind:
            self.#removeKey(node, change.key, change.count);
            break;
          case remove_kind:
            self.#remove(node, change.from, change.count);
            break;
          case replace_kind:
            self.#replace(node, change.from, change.count, change.with);
            break;
          case replace_text_kind:
            self.#replaceText(node, change.content);
            break;
          case replace_inner_html_kind:
            self.#replaceInnerHtml(node, change.inner_html);
            break;
          case update_kind:
            self.#update(node, change.added, change.removed);
            break;
        }
      });
      if (patch.removed) {
        self.#remove(node, node.childNodes.length - patch.removed, patch.removed);
      }
      iterate(patch.children, (child) => {
        self.#stack.push({ node: childAt(node, child.index), patch: child });
      });
    }
  }
  #insert(node, children, before) {
    const fragment2 = createDocumentFragment();
    iterate(children, (child) => {
      const el = this.#createElement(child);
      addKeyedChild(node, el);
      appendChild(fragment2, el);
    });
    insertBefore(node, fragment2, childAt(node, before));
  }
  #move(node, key, before, count) {
    let el = getKeyedChild(node, key);
    const beforeEl = childAt(node, before);
    for (let i = 0;i < count && el !== null; ++i) {
      const next = el.nextSibling;
      if (SUPPORTS_MOVE_BEFORE) {
        node.moveBefore(el, beforeEl);
      } else {
        insertBefore(node, el, beforeEl);
      }
      el = next;
    }
  }
  #removeKey(node, key, count) {
    this.#removeFromChild(node, getKeyedChild(node, key), count);
  }
  #remove(node, from2, count) {
    this.#removeFromChild(node, childAt(node, from2), count);
  }
  #removeFromChild(parent, child, count) {
    while (count-- > 0 && child !== null) {
      const next = child.nextSibling;
      const key = child[meta].key;
      if (key) {
        parent[meta].keyedChildren.delete(key);
      }
      for (const [_, { timeout }] of child[meta].debouncers) {
        clearTimeout(timeout);
      }
      parent.removeChild(child);
      child = next;
    }
  }
  #replace(parent, from2, count, child) {
    this.#remove(parent, from2, count);
    const el = this.#createElement(child);
    addKeyedChild(parent, el);
    insertBefore(parent, el, childAt(parent, from2));
  }
  #replaceText(node, content) {
    node.data = content ?? "";
  }
  #replaceInnerHtml(node, inner_html) {
    node.innerHTML = inner_html ?? "";
  }
  #update(node, added, removed) {
    iterate(removed, (attribute3) => {
      const name2 = attribute3.name;
      if (node[meta].handlers.has(name2)) {
        node.removeEventListener(name2, handleEvent);
        node[meta].handlers.delete(name2);
        if (node[meta].throttles.has(name2)) {
          node[meta].throttles.delete(name2);
        }
        if (node[meta].debouncers.has(name2)) {
          clearTimeout(node[meta].debouncers.get(name2).timeout);
          node[meta].debouncers.delete(name2);
        }
      } else {
        node.removeAttribute(name2);
        ATTRIBUTE_HOOKS[name2]?.removed?.(node, name2);
      }
    });
    iterate(added, (attribute3) => {
      this.#createAttribute(node, attribute3);
    });
  }
  #createElement(vnode) {
    switch (vnode.kind) {
      case element_kind: {
        const node = createElement(vnode);
        this.#createAttributes(node, vnode);
        this.#insert(node, vnode.children, 0);
        return node;
      }
      case text_kind: {
        const node = createTextNode(vnode.content);
        initialiseMetadata(node, vnode.key);
        return node;
      }
      case fragment_kind: {
        const node = createDocumentFragment();
        const head = createTextNode();
        initialiseMetadata(head, vnode.key);
        appendChild(node, head);
        iterate(vnode.children, (child) => {
          appendChild(node, this.#createElement(child));
        });
        return node;
      }
      case unsafe_inner_html_kind: {
        const node = createElement(vnode);
        this.#createAttributes(node, vnode);
        this.#replaceInnerHtml(node, vnode.inner_html);
        return node;
      }
    }
  }
  #createAttributes(node, { attributes }) {
    iterate(attributes, (attribute3) => this.#createAttribute(node, attribute3));
  }
  #createAttribute(node, attribute3) {
    const nodeMeta = node[meta];
    switch (attribute3.kind) {
      case attribute_kind: {
        const name2 = attribute3.name;
        const value2 = attribute3.value ?? "";
        if (value2 !== node.getAttribute(name2)) {
          node.setAttribute(name2, value2);
        }
        ATTRIBUTE_HOOKS[name2]?.added?.(node, value2);
        break;
      }
      case property_kind:
        node[attribute3.name] = attribute3.value;
        break;
      case event_kind: {
        if (!nodeMeta.handlers.has(attribute3.name)) {
          node.addEventListener(attribute3.name, handleEvent, {
            passive: !attribute3.prevent_default
          });
        }
        const prevent = attribute3.prevent_default;
        const stop = attribute3.stop_propagation;
        const immediate2 = attribute3.immediate;
        const include = Array.isArray(attribute3.include) ? attribute3.include : [];
        if (attribute3.limit?.kind === throttle_kind) {
          const throttle = nodeMeta.throttles.get(attribute3.name) ?? {
            last: 0,
            delay: attribute3.limit.delay
          };
          nodeMeta.throttles.set(attribute3.name, throttle);
        }
        if (attribute3.limit?.kind === debounce_kind) {
          const debounce = nodeMeta.debouncers.get(attribute3.name) ?? {
            timeout: null,
            delay: attribute3.limit.delay
          };
          nodeMeta.debouncers.set(attribute3.name, debounce);
        }
        nodeMeta.handlers.set(attribute3.name, (event3) => {
          if (prevent)
            event3.preventDefault();
          if (stop)
            event3.stopPropagation();
          const type = event3.type;
          let path = "";
          let pathNode = event3.currentTarget;
          while (pathNode !== this.#root) {
            const key = pathNode[meta].key;
            const parent = pathNode.parentNode;
            if (key) {
              path = `${separator_key}${key}${path}`;
            } else {
              const siblings = parent.childNodes;
              let index4 = [].indexOf.call(siblings, pathNode);
              if (parent === this.#root) {
                index4 -= this.offset;
              }
              path = `${separator_index}${index4}${path}`;
            }
            pathNode = parent;
          }
          path = path.slice(1);
          const data = this.#useServerEvents ? createServerEvent(event3, include) : event3;
          if (nodeMeta.throttles.has(type)) {
            const throttle = nodeMeta.throttles.get(type);
            const now = Date.now();
            const last = throttle.last || 0;
            if (now > last + throttle.delay) {
              throttle.last = now;
              this.#dispatch(data, path, type, immediate2);
            } else {
              event3.preventDefault();
            }
          } else if (nodeMeta.debouncers.has(type)) {
            const debounce = nodeMeta.debouncers.get(type);
            clearTimeout(debounce.timeout);
            debounce.timeout = setTimeout(() => {
              this.#dispatch(data, path, type, immediate2);
            }, debounce.delay);
          } else {
            this.#dispatch(data, path, type, immediate2);
          }
        });
        break;
      }
    }
  }
}
var iterate = (list4, callback) => {
  if (Array.isArray(list4)) {
    for (let i = 0;i < list4.length; i++) {
      callback(list4[i]);
    }
  } else if (list4) {
    for (list4;list4.tail; list4 = list4.tail) {
      callback(list4.head);
    }
  }
};
var appendChild = (node, child) => node.appendChild(child);
var insertBefore = (parent, node, referenceNode) => parent.insertBefore(node, referenceNode ?? null);
var createElement = ({ key, tag, namespace }) => {
  const node = document2.createElementNS(namespace || NAMESPACE_HTML, tag);
  initialiseMetadata(node, key);
  return node;
};
var createTextNode = (text2) => document2.createTextNode(text2 ?? "");
var createDocumentFragment = () => document2.createDocumentFragment();
var childAt = (node, at) => node.childNodes[at | 0];
var meta = Symbol("lustre");
var initialiseMetadata = (node, key = "") => {
  switch (node.nodeType) {
    case ELEMENT_NODE:
    case DOCUMENT_FRAGMENT_NODE:
      node[meta] = {
        key,
        keyedChildren: new Map,
        handlers: new Map,
        throttles: new Map,
        debouncers: new Map
      };
      break;
    case TEXT_NODE:
      node[meta] = { key, debouncers: new Map };
      break;
  }
};
var addKeyedChild = (node, child) => {
  if (child.nodeType === DOCUMENT_FRAGMENT_NODE) {
    for (child = child.firstChild;child; child = child.nextSibling) {
      addKeyedChild(node, child);
    }
    return;
  }
  const key = child[meta].key;
  if (key) {
    node[meta].keyedChildren.set(key, new WeakRef(child));
  }
};
var getKeyedChild = (node, key) => node[meta].keyedChildren.get(key).deref();
var handleEvent = (event3) => {
  const target2 = event3.currentTarget;
  const handler = target2[meta].handlers.get(event3.type);
  if (event3.type === "submit") {
    event3.detail ??= {};
    event3.detail.formData = [...new FormData(event3.target).entries()];
  }
  handler(event3);
};
var createServerEvent = (event3, include = []) => {
  const data = {};
  if (event3.type === "input" || event3.type === "change") {
    include.push("target.value");
  }
  if (event3.type === "submit") {
    include.push("detail.formData");
  }
  for (const property3 of include) {
    const path = property3.split(".");
    for (let i = 0, input = event3, output = data;i < path.length; i++) {
      if (i === path.length - 1) {
        output[path[i]] = input[path[i]];
        break;
      }
      output = output[path[i]] ??= {};
      input = input[path[i]];
    }
  }
  return data;
};
var syncedBooleanAttribute = (name2) => {
  return {
    added(node) {
      node[name2] = true;
    },
    removed(node) {
      node[name2] = false;
    }
  };
};
var syncedAttribute = (name2) => {
  return {
    added(node, value2) {
      node[name2] = value2;
    }
  };
};
var ATTRIBUTE_HOOKS = {
  checked: syncedBooleanAttribute("checked"),
  selected: syncedBooleanAttribute("selected"),
  value: syncedAttribute("value"),
  autofocus: {
    added(node) {
      queueMicrotask(() => node.focus?.());
    }
  },
  autoplay: {
    added(node) {
      try {
        node.play?.();
      } catch (e) {
        console.error(e);
      }
    }
  }
};

// build/dev/javascript/lustre/lustre/vdom/virtualise.ffi.mjs
var virtualise = (root3) => {
  const vdom = virtualise_node(root3);
  if (vdom === null || vdom.children instanceof Empty) {
    const empty4 = empty_text_node();
    initialiseMetadata(empty4);
    root3.appendChild(empty4);
    return none3();
  } else if (vdom.children instanceof NonEmpty && vdom.children.tail instanceof Empty) {
    return vdom.children.head;
  } else {
    const head = empty_text_node();
    initialiseMetadata(head);
    root3.insertBefore(head, root3.firstChild);
    return fragment2(vdom.children);
  }
};
var empty_text_node = () => {
  return document2.createTextNode("");
};
var virtualise_node = (node) => {
  switch (node.nodeType) {
    case ELEMENT_NODE: {
      const key = node.getAttribute("data-lustre-key");
      initialiseMetadata(node, key);
      if (key) {
        node.removeAttribute("data-lustre-key");
      }
      const tag = node.localName;
      const namespace = node.namespaceURI;
      const isHtmlElement = !namespace || namespace === NAMESPACE_HTML;
      if (isHtmlElement && input_elements.includes(tag)) {
        virtualise_input_events(tag, node);
      }
      const attributes = virtualise_attributes(node);
      const children = virtualise_child_nodes(node);
      const vnode = isHtmlElement ? element2(tag, attributes, children) : namespaced(namespace, tag, attributes, children);
      return key ? to_keyed(key, vnode) : vnode;
    }
    case TEXT_NODE:
      initialiseMetadata(node);
      return text2(node.data);
    case DOCUMENT_FRAGMENT_NODE:
      initialiseMetadata(node);
      return node.childNodes.length > 0 ? fragment2(virtualise_child_nodes(node)) : null;
    default:
      return null;
  }
};
var input_elements = ["input", "select", "textarea"];
var virtualise_input_events = (tag, node) => {
  const value2 = node.value;
  const checked2 = node.checked;
  if (tag === "input" && node.type === "checkbox" && !checked2)
    return;
  if (tag === "input" && node.type === "radio" && !checked2)
    return;
  if (node.type !== "checkbox" && node.type !== "radio" && !value2)
    return;
  queueMicrotask(() => {
    node.value = value2;
    node.checked = checked2;
    node.dispatchEvent(new Event("input", { bubbles: true }));
    node.dispatchEvent(new Event("change", { bubbles: true }));
    if (document2.activeElement !== node) {
      node.dispatchEvent(new Event("blur", { bubbles: true }));
    }
  });
};
var virtualise_child_nodes = (node) => {
  let children = empty_list;
  let child = node.lastChild;
  while (child) {
    const vnode = virtualise_node(child);
    const next = child.previousSibling;
    if (vnode) {
      children = new NonEmpty(vnode, children);
    } else {
      node.removeChild(child);
    }
    child = next;
  }
  return children;
};
var virtualise_attributes = (node) => {
  let index4 = node.attributes.length;
  let attributes = empty_list;
  while (index4-- > 0) {
    attributes = new NonEmpty(virtualise_attribute(node.attributes[index4]), attributes);
  }
  return attributes;
};
var virtualise_attribute = (attr) => {
  const name2 = attr.localName;
  const value2 = attr.value;
  return attribute2(name2, value2);
};

// build/dev/javascript/lustre/lustre/runtime/client/runtime.ffi.mjs
var is_browser = () => !!document2;
var is_reference_equal = (a, b) => a === b;
class Runtime {
  constructor(root3, [model, effects], view, update2) {
    this.root = root3;
    this.#model = model;
    this.#view = view;
    this.#update = update2;
    this.#reconciler = new Reconciler(this.root, (event3, path, name2) => {
      const [events, msg] = handle(this.#events, path, name2, event3);
      this.#events = events;
      if (msg.isOk()) {
        this.dispatch(msg[0], false);
      }
    });
    this.#vdom = virtualise(this.root);
    this.#events = new$6();
    this.#shouldFlush = true;
    this.#tick(effects);
  }
  root = null;
  set offset(offset) {
    this.#reconciler.offset = offset;
  }
  dispatch(msg, immediate2 = false) {
    this.#shouldFlush ||= immediate2;
    if (this.#shouldQueue) {
      this.#queue.push(msg);
    } else {
      const [model, effects] = this.#update(this.#model, msg);
      this.#model = model;
      this.#tick(effects);
    }
  }
  emit(event3, data) {
    const target2 = this.root.host ?? this.root;
    target2.dispatchEvent(new CustomEvent(event3, {
      detail: data,
      bubbles: true,
      composed: true
    }));
  }
  #model;
  #view;
  #update;
  #vdom;
  #events;
  #reconciler;
  #shouldQueue = false;
  #queue = [];
  #beforePaint = empty_list;
  #afterPaint = empty_list;
  #renderTimer = null;
  #shouldFlush = false;
  #actions = {
    dispatch: (msg, immediate2) => this.dispatch(msg, immediate2),
    emit: (event3, data) => this.emit(event3, data),
    select: () => {},
    root: () => this.root
  };
  #tick(effects) {
    this.#shouldQueue = true;
    while (true) {
      for (let list4 = effects.synchronous;list4.tail; list4 = list4.tail) {
        list4.head(this.#actions);
      }
      this.#beforePaint = listAppend(this.#beforePaint, effects.before_paint);
      this.#afterPaint = listAppend(this.#afterPaint, effects.after_paint);
      if (!this.#queue.length)
        break;
      [this.#model, effects] = this.#update(this.#model, this.#queue.shift());
    }
    this.#shouldQueue = false;
    if (this.#shouldFlush) {
      cancelAnimationFrame(this.#renderTimer);
      this.#render();
    } else if (!this.#renderTimer) {
      this.#renderTimer = requestAnimationFrame(() => {
        this.#render();
      });
    }
  }
  #render() {
    this.#shouldFlush = false;
    this.#renderTimer = null;
    const next = this.#view(this.#model);
    const { patch, events } = diff(this.#events, this.#vdom, next);
    this.#events = events;
    this.#vdom = next;
    this.#reconciler.push(patch);
    if (this.#beforePaint instanceof NonEmpty) {
      const effects = makeEffect(this.#beforePaint);
      this.#beforePaint = empty_list;
      queueMicrotask(() => {
        this.#shouldFlush = true;
        this.#tick(effects);
      });
    }
    if (this.#afterPaint instanceof NonEmpty) {
      const effects = makeEffect(this.#afterPaint);
      this.#afterPaint = empty_list;
      requestAnimationFrame(() => {
        this.#shouldFlush = true;
        this.#tick(effects);
      });
    }
  }
}
function makeEffect(synchronous) {
  return {
    synchronous,
    after_paint: empty_list,
    before_paint: empty_list
  };
}
function listAppend(a, b) {
  if (a instanceof Empty) {
    return b;
  } else if (b instanceof Empty) {
    return a;
  } else {
    return append(a, b);
  }
}
var copiedStyleSheets = new WeakMap;

// build/dev/javascript/lustre/lustre/vdom/events.mjs
class Events extends CustomType {
  constructor(handlers, dispatched_paths, next_dispatched_paths) {
    super();
    this.handlers = handlers;
    this.dispatched_paths = dispatched_paths;
    this.next_dispatched_paths = next_dispatched_paths;
  }
}
function new$6() {
  return new Events(empty3(), empty_list, empty_list);
}
function tick(events) {
  return new Events(events.handlers, events.next_dispatched_paths, empty_list);
}
function do_remove_event(handlers, path, name2) {
  return remove(handlers, event2(path, name2));
}
function remove_event(events, path, name2) {
  let handlers = do_remove_event(events.handlers, path, name2);
  return new Events(handlers, events.dispatched_paths, events.next_dispatched_paths);
}
function remove_attributes(handlers, path, attributes) {
  return fold2(attributes, handlers, (events, attribute3) => {
    if (attribute3 instanceof Event2) {
      let name2 = attribute3.name;
      return do_remove_event(events, path, name2);
    } else {
      return events;
    }
  });
}
function handle(events, path, name2, event3) {
  let next_dispatched_paths = prepend(path, events.next_dispatched_paths);
  let events$1 = new Events(events.handlers, events.dispatched_paths, next_dispatched_paths);
  let $ = get2(events$1.handlers, path + separator_event + name2);
  if ($ instanceof Ok) {
    let handler = $[0];
    return [events$1, run(event3, handler)];
  } else {
    return [events$1, new Error(toList([]))];
  }
}
function has_dispatched_events(events, path) {
  return matches(path, events.dispatched_paths);
}
function do_add_event(handlers, mapper, path, name2, handler) {
  return insert3(handlers, event2(path, name2), map4(handler, identity3(mapper)));
}
function add_event(events, mapper, path, name2, handler) {
  let handlers = do_add_event(events.handlers, mapper, path, name2, handler);
  return new Events(handlers, events.dispatched_paths, events.next_dispatched_paths);
}
function add_attributes(handlers, mapper, path, attributes) {
  return fold2(attributes, handlers, (events, attribute3) => {
    if (attribute3 instanceof Event2) {
      let name2 = attribute3.name;
      let handler = attribute3.handler;
      return do_add_event(events, mapper, path, name2, handler);
    } else {
      return events;
    }
  });
}
function compose_mapper(mapper, child_mapper) {
  let $ = is_reference_equal(mapper, identity3);
  let $1 = is_reference_equal(child_mapper, identity3);
  if ($1) {
    return mapper;
  } else if ($) {
    return child_mapper;
  } else {
    return (msg) => {
      return mapper(child_mapper(msg));
    };
  }
}
function do_remove_children(loop$handlers, loop$path, loop$child_index, loop$children) {
  while (true) {
    let handlers = loop$handlers;
    let path = loop$path;
    let child_index = loop$child_index;
    let children = loop$children;
    if (children instanceof Empty) {
      return handlers;
    } else {
      let child = children.head;
      let rest2 = children.tail;
      let _pipe = handlers;
      let _pipe$1 = do_remove_child(_pipe, path, child_index, child);
      loop$handlers = _pipe$1;
      loop$path = path;
      loop$child_index = child_index + advance(child);
      loop$children = rest2;
    }
  }
}
function do_remove_child(handlers, parent, child_index, child) {
  if (child instanceof Fragment) {
    let children = child.children;
    return do_remove_children(handlers, parent, child_index + 1, children);
  } else if (child instanceof Element) {
    let attributes = child.attributes;
    let children = child.children;
    let path = add3(parent, child_index, child.key);
    let _pipe = handlers;
    let _pipe$1 = remove_attributes(_pipe, path, attributes);
    return do_remove_children(_pipe$1, path, 0, children);
  } else if (child instanceof Text) {
    return handlers;
  } else {
    let attributes = child.attributes;
    let path = add3(parent, child_index, child.key);
    return remove_attributes(handlers, path, attributes);
  }
}
function remove_child(events, parent, child_index, child) {
  let handlers = do_remove_child(events.handlers, parent, child_index, child);
  return new Events(handlers, events.dispatched_paths, events.next_dispatched_paths);
}
function do_add_children(loop$handlers, loop$mapper, loop$path, loop$child_index, loop$children) {
  while (true) {
    let handlers = loop$handlers;
    let mapper = loop$mapper;
    let path = loop$path;
    let child_index = loop$child_index;
    let children = loop$children;
    if (children instanceof Empty) {
      return handlers;
    } else {
      let child = children.head;
      let rest2 = children.tail;
      let _pipe = handlers;
      let _pipe$1 = do_add_child(_pipe, mapper, path, child_index, child);
      loop$handlers = _pipe$1;
      loop$mapper = mapper;
      loop$path = path;
      loop$child_index = child_index + advance(child);
      loop$children = rest2;
    }
  }
}
function do_add_child(handlers, mapper, parent, child_index, child) {
  if (child instanceof Fragment) {
    let children = child.children;
    let composed_mapper = compose_mapper(mapper, child.mapper);
    let child_index$1 = child_index + 1;
    return do_add_children(handlers, composed_mapper, parent, child_index$1, children);
  } else if (child instanceof Element) {
    let attributes = child.attributes;
    let children = child.children;
    let path = add3(parent, child_index, child.key);
    let composed_mapper = compose_mapper(mapper, child.mapper);
    let _pipe = handlers;
    let _pipe$1 = add_attributes(_pipe, composed_mapper, path, attributes);
    return do_add_children(_pipe$1, composed_mapper, path, 0, children);
  } else if (child instanceof Text) {
    return handlers;
  } else {
    let attributes = child.attributes;
    let path = add3(parent, child_index, child.key);
    let composed_mapper = compose_mapper(mapper, child.mapper);
    return add_attributes(handlers, composed_mapper, path, attributes);
  }
}
function add_child(events, mapper, parent, index4, child) {
  let handlers = do_add_child(events.handlers, mapper, parent, index4, child);
  return new Events(handlers, events.dispatched_paths, events.next_dispatched_paths);
}
function from_node(root3) {
  return add_child(new$6(), identity3, root2, 0, root3);
}
function add_children(events, mapper, path, child_index, children) {
  let handlers = do_add_children(events.handlers, mapper, path, child_index, children);
  return new Events(handlers, events.dispatched_paths, events.next_dispatched_paths);
}

// build/dev/javascript/lustre/lustre/element.mjs
function element2(tag, attributes, children) {
  return element("", identity3, "", tag, attributes, children, empty3(), false, false);
}
function namespaced(namespace, tag, attributes, children) {
  return element("", identity3, namespace, tag, attributes, children, empty3(), false, false);
}
function text2(content) {
  return text("", identity3, content);
}
function none3() {
  return text("", identity3, "");
}
function count_fragment_children(loop$children, loop$count) {
  while (true) {
    let children = loop$children;
    let count = loop$count;
    if (children instanceof Empty) {
      return count;
    } else {
      let $ = children.head;
      if ($ instanceof Fragment) {
        let rest2 = children.tail;
        let children_count = $.children_count;
        loop$children = rest2;
        loop$count = count + children_count;
      } else {
        let rest2 = children.tail;
        loop$children = rest2;
        loop$count = count + 1;
      }
    }
  }
}
function fragment2(children) {
  return fragment("", identity3, children, empty3(), count_fragment_children(children, 0));
}

// build/dev/javascript/lustre/lustre/element/html.mjs
function text3(content) {
  return text2(content);
}
function footer(attrs, children) {
  return element2("footer", attrs, children);
}
function h1(attrs, children) {
  return element2("h1", attrs, children);
}
function h3(attrs, children) {
  return element2("h3", attrs, children);
}
function h4(attrs, children) {
  return element2("h4", attrs, children);
}
function h5(attrs, children) {
  return element2("h5", attrs, children);
}
function main(attrs, children) {
  return element2("main", attrs, children);
}
function section(attrs, children) {
  return element2("section", attrs, children);
}
function div(attrs, children) {
  return element2("div", attrs, children);
}
function li(attrs, children) {
  return element2("li", attrs, children);
}
function p(attrs, children) {
  return element2("p", attrs, children);
}
function ul(attrs, children) {
  return element2("ul", attrs, children);
}
function a(attrs, children) {
  return element2("a", attrs, children);
}
function small(attrs, children) {
  return element2("small", attrs, children);
}
function span(attrs, children) {
  return element2("span", attrs, children);
}
function img(attrs) {
  return element2("img", attrs, empty_list);
}
function button(attrs, children) {
  return element2("button", attrs, children);
}
function fieldset(attrs, children) {
  return element2("fieldset", attrs, children);
}
function form(attrs, children) {
  return element2("form", attrs, children);
}
function input(attrs) {
  return element2("input", attrs, empty_list);
}
function label(attrs, children) {
  return element2("label", attrs, children);
}

// build/dev/javascript/lustre/lustre/runtime/transport.mjs
class Mount extends CustomType {
  constructor(kind, open_shadow_root, will_adopt_styles, observed_attributes, observed_properties, vdom) {
    super();
    this.kind = kind;
    this.open_shadow_root = open_shadow_root;
    this.will_adopt_styles = will_adopt_styles;
    this.observed_attributes = observed_attributes;
    this.observed_properties = observed_properties;
    this.vdom = vdom;
  }
}
class Reconcile extends CustomType {
  constructor(kind, patch) {
    super();
    this.kind = kind;
    this.patch = patch;
  }
}
class Emit extends CustomType {
  constructor(kind, name2, data) {
    super();
    this.kind = kind;
    this.name = name2;
    this.data = data;
  }
}
class AttributeChanged extends CustomType {
  constructor(kind, name2, value2) {
    super();
    this.kind = kind;
    this.name = name2;
    this.value = value2;
  }
}
class EventFired extends CustomType {
  constructor(kind, path, name2, event3) {
    super();
    this.kind = kind;
    this.path = path;
    this.name = name2;
    this.event = event3;
  }
}

// build/dev/javascript/lustre/lustre/runtime/server/runtime.mjs
class ClientDispatchedMessage extends CustomType {
  constructor(message) {
    super();
    this.message = message;
  }
}
class ClientRegisteredCallback extends CustomType {
  constructor(callback) {
    super();
    this.callback = callback;
  }
}
class ClientDeregisteredCallback extends CustomType {
  constructor(callback) {
    super();
    this.callback = callback;
  }
}
class EffectDispatchedMessage extends CustomType {
  constructor(message) {
    super();
    this.message = message;
  }
}
class EffectEmitEvent extends CustomType {
  constructor(name2, data) {
    super();
    this.name = name2;
    this.data = data;
  }
}
class SelfDispatchedMessages extends CustomType {
  constructor(messages, effect) {
    super();
    this.messages = messages;
    this.effect = effect;
  }
}
class SystemRequestedShutdown extends CustomType {
}

// build/dev/javascript/lustre/lustre/component.mjs
class Config2 extends CustomType {
  constructor(open_shadow_root, adopt_styles, attributes, properties, is_form_associated, on_form_autofill, on_form_reset, on_form_restore) {
    super();
    this.open_shadow_root = open_shadow_root;
    this.adopt_styles = adopt_styles;
    this.attributes = attributes;
    this.properties = properties;
    this.is_form_associated = is_form_associated;
    this.on_form_autofill = on_form_autofill;
    this.on_form_reset = on_form_reset;
    this.on_form_restore = on_form_restore;
  }
}
function new$7(options) {
  let init = new Config2(false, true, empty_dict(), empty_dict(), false, option_none, option_none, option_none);
  return fold2(options, init, (config, option) => {
    return option.apply(config);
  });
}

// build/dev/javascript/lustre/lustre/runtime/client/spa.ffi.mjs
class Spa {
  static start({ init, update: update2, view }, selector, flags) {
    if (!is_browser())
      return new Error(new NotABrowser);
    const root3 = selector instanceof HTMLElement ? selector : document2.querySelector(selector);
    if (!root3)
      return new Error(new ElementNotFound(selector));
    return new Ok(new Spa(root3, init(flags), update2, view));
  }
  #runtime;
  constructor(root3, [init, effects], update2, view) {
    this.#runtime = new Runtime(root3, [init, effects], view, update2);
  }
  send(message) {
    switch (message.constructor) {
      case EffectDispatchedMessage: {
        this.dispatch(message.message, false);
        break;
      }
      case EffectEmitEvent: {
        this.emit(message.name, message.data);
        break;
      }
      case SystemRequestedShutdown:
        break;
    }
  }
  dispatch(msg, immediate2) {
    this.#runtime.dispatch(msg, immediate2);
  }
  emit(event3, data) {
    this.#runtime.emit(event3, data);
  }
}
var start = Spa.start;

// build/dev/javascript/lustre/lustre/runtime/server/runtime.ffi.mjs
class Runtime2 {
  #model;
  #update;
  #view;
  #on_attribute_change;
  #vdom;
  #events;
  #callbacks = new Set;
  constructor([model, effects], view, update2, on_attribute_change) {
    this.#model = model;
    this.#update = update2;
    this.#view = view;
    this.#on_attribute_change = on_attribute_change;
    this.#vdom = this.#view(this.#model);
    this.#events = from_node(this.#vdom);
    this.#tick(effects.all, false);
  }
  send(message) {
    if (this.#model === null)
      return;
    switch (message.constructor) {
      case ClientDispatchedMessage:
        switch (message.message.constructor) {
          case AttributeChanged: {
            const { name: name2, value: value2 } = message.messgae;
            let effects = [];
            const decoder = this.#on_attribute_change.get(name2);
            if (!decoder)
              break;
            const result = run(value2, decoder);
            if (result.constructor !== Ok)
              break;
            const [model, more_effects] = this.#update(this.#model, result[0]);
            this.#model = model;
            effects.push(more_effects);
            while (effects.length) {
              this.#tick(effects.shift().all);
            }
          }
          case EventFired: {
            const { path, name: name2, event: event3 } = message.message;
            const [events, result] = handle(this.#events, path, name2, event3);
            this.#events = events;
            if (result.constructor === Ok) {
              this.dispatch(result[0]);
            }
            return;
          }
        }
      case ClientRegisteredCallback: {
        if (this.#callbacks.has(message.callback))
          return;
        const mount = new Mount(this.#vdom);
        this.#callbacks.add(message.callback);
        message.callback(mount);
        return;
      }
      case ClientDeregisteredCallback: {
        this.#callbacks.delete(message.callback);
        return;
      }
      case EffectDispatchedMessage: {
        this.dispatch(message.message);
        return;
      }
      case EffectEmitEvent: {
        const event3 = new Emit(message.name, message.data);
        for (const callback of this.#callbacks) {
          callback(event3);
        }
        return;
      }
      case SelfDispatchedMessages: {
        let messages = message.messages;
        let effects = [message.effect];
        for (let list4 = messages;messages.tail; list4 = list4.tail) {
          const [model, more_effects] = this.#update(this.#model, list4.head);
          this.#model = model;
          effects.push(more_effects);
        }
        while (effects.length) {
          this.#tick(effects.shift().all);
        }
        return;
      }
      case SystemRequestedShutdown: {
        this.#model = null;
        this.#update = null;
        this.#view = null;
        this.#on_attribute_change = null;
        this.#events = new$6();
        this.#callbacks.clear();
      }
    }
  }
  dispatch(msg) {
    const [model, effects] = this.#update(this.#model, msg);
    this.#model = model;
    this.#tick(effects.all, immediate);
  }
  #tick(effects) {
    const queue = [];
    const effect_params = {
      root: null,
      emit: (event3, data) => this.#emit(event3, data),
      dispatch: (msg) => queue.push(msg),
      select: () => {}
    };
    while (true) {
      for (let list4 = effects;list4.tail; list4 = list4.tail) {
        list4.head(effect_params);
      }
      if (!queue.length) {
        break;
      }
      const msg = queue.shift();
      [this.#model, effects] = this.#update(this.#model, msg);
    }
    this.#render();
  }
  #render() {
    const next = this.#view(this.#model);
    const { patch, events } = diff(this.#events, this.#vdom, next);
    this.#events = events;
    this.#vdom = next;
    const reconcile = new Reconcile(patch);
    for (const callback of this.#callbacks) {
      callback(reconcile);
    }
  }
  #emit(event3, data) {
    const message = new Emit(event3, data);
    for (const callback of this.#callbacks) {
      callback(message);
    }
  }
}

// build/dev/javascript/lustre/lustre.mjs
class App extends CustomType {
  constructor(init, update2, view, config) {
    super();
    this.init = init;
    this.update = update2;
    this.view = view;
    this.config = config;
  }
}
class ElementNotFound extends CustomType {
  constructor(selector) {
    super();
    this.selector = selector;
  }
}
class NotABrowser extends CustomType {
}
function application(init, update2, view) {
  return new App(init, update2, view, new$7(empty_list));
}
function start3(app, selector, start_args) {
  return guard(!is_browser(), new Error(new NotABrowser), () => {
    return start(app, selector, start_args);
  });
}

// build/dev/javascript/gleam_stdlib/gleam/uri.mjs
class Uri extends CustomType {
  constructor(scheme, userinfo, host, port, path, query, fragment3) {
    super();
    this.scheme = scheme;
    this.userinfo = userinfo;
    this.host = host;
    this.port = port;
    this.path = path;
    this.query = query;
    this.fragment = fragment3;
  }
}
var empty4 = /* @__PURE__ */ new Uri(/* @__PURE__ */ new None, /* @__PURE__ */ new None, /* @__PURE__ */ new None, /* @__PURE__ */ new None, "", /* @__PURE__ */ new None, /* @__PURE__ */ new None);
function is_valid_host_within_brackets_char(char) {
  return 48 >= char && char <= 57 || 65 >= char && char <= 90 || 97 >= char && char <= 122 || char === 58 || char === 46;
}
function parse_fragment(rest2, pieces) {
  return new Ok(new Uri(pieces.scheme, pieces.userinfo, pieces.host, pieces.port, pieces.path, pieces.query, new Some(rest2)));
}
function parse_query_with_question_mark_loop(loop$original, loop$uri_string, loop$pieces, loop$size) {
  while (true) {
    let original = loop$original;
    let uri_string = loop$uri_string;
    let pieces = loop$pieces;
    let size2 = loop$size;
    if (uri_string.startsWith("#")) {
      if (size2 === 0) {
        let rest2 = uri_string.slice(1);
        return parse_fragment(rest2, pieces);
      } else {
        let rest2 = uri_string.slice(1);
        let query = string_codeunit_slice(original, 0, size2);
        let pieces$1 = new Uri(pieces.scheme, pieces.userinfo, pieces.host, pieces.port, pieces.path, new Some(query), pieces.fragment);
        return parse_fragment(rest2, pieces$1);
      }
    } else if (uri_string === "") {
      return new Ok(new Uri(pieces.scheme, pieces.userinfo, pieces.host, pieces.port, pieces.path, new Some(original), pieces.fragment));
    } else {
      let $ = pop_codeunit(uri_string);
      let rest2;
      rest2 = $[1];
      loop$original = original;
      loop$uri_string = rest2;
      loop$pieces = pieces;
      loop$size = size2 + 1;
    }
  }
}
function parse_query_with_question_mark(uri_string, pieces) {
  return parse_query_with_question_mark_loop(uri_string, uri_string, pieces, 0);
}
function parse_path_loop(loop$original, loop$uri_string, loop$pieces, loop$size) {
  while (true) {
    let original = loop$original;
    let uri_string = loop$uri_string;
    let pieces = loop$pieces;
    let size2 = loop$size;
    if (uri_string.startsWith("?")) {
      let rest2 = uri_string.slice(1);
      let path = string_codeunit_slice(original, 0, size2);
      let pieces$1 = new Uri(pieces.scheme, pieces.userinfo, pieces.host, pieces.port, path, pieces.query, pieces.fragment);
      return parse_query_with_question_mark(rest2, pieces$1);
    } else if (uri_string.startsWith("#")) {
      let rest2 = uri_string.slice(1);
      let path = string_codeunit_slice(original, 0, size2);
      let pieces$1 = new Uri(pieces.scheme, pieces.userinfo, pieces.host, pieces.port, path, pieces.query, pieces.fragment);
      return parse_fragment(rest2, pieces$1);
    } else if (uri_string === "") {
      return new Ok(new Uri(pieces.scheme, pieces.userinfo, pieces.host, pieces.port, original, pieces.query, pieces.fragment));
    } else {
      let $ = pop_codeunit(uri_string);
      let rest2;
      rest2 = $[1];
      loop$original = original;
      loop$uri_string = rest2;
      loop$pieces = pieces;
      loop$size = size2 + 1;
    }
  }
}
function parse_path(uri_string, pieces) {
  return parse_path_loop(uri_string, uri_string, pieces, 0);
}
function parse_port_loop(loop$uri_string, loop$pieces, loop$port) {
  while (true) {
    let uri_string = loop$uri_string;
    let pieces = loop$pieces;
    let port = loop$port;
    if (uri_string.startsWith("0")) {
      let rest2 = uri_string.slice(1);
      loop$uri_string = rest2;
      loop$pieces = pieces;
      loop$port = port * 10;
    } else if (uri_string.startsWith("1")) {
      let rest2 = uri_string.slice(1);
      loop$uri_string = rest2;
      loop$pieces = pieces;
      loop$port = port * 10 + 1;
    } else if (uri_string.startsWith("2")) {
      let rest2 = uri_string.slice(1);
      loop$uri_string = rest2;
      loop$pieces = pieces;
      loop$port = port * 10 + 2;
    } else if (uri_string.startsWith("3")) {
      let rest2 = uri_string.slice(1);
      loop$uri_string = rest2;
      loop$pieces = pieces;
      loop$port = port * 10 + 3;
    } else if (uri_string.startsWith("4")) {
      let rest2 = uri_string.slice(1);
      loop$uri_string = rest2;
      loop$pieces = pieces;
      loop$port = port * 10 + 4;
    } else if (uri_string.startsWith("5")) {
      let rest2 = uri_string.slice(1);
      loop$uri_string = rest2;
      loop$pieces = pieces;
      loop$port = port * 10 + 5;
    } else if (uri_string.startsWith("6")) {
      let rest2 = uri_string.slice(1);
      loop$uri_string = rest2;
      loop$pieces = pieces;
      loop$port = port * 10 + 6;
    } else if (uri_string.startsWith("7")) {
      let rest2 = uri_string.slice(1);
      loop$uri_string = rest2;
      loop$pieces = pieces;
      loop$port = port * 10 + 7;
    } else if (uri_string.startsWith("8")) {
      let rest2 = uri_string.slice(1);
      loop$uri_string = rest2;
      loop$pieces = pieces;
      loop$port = port * 10 + 8;
    } else if (uri_string.startsWith("9")) {
      let rest2 = uri_string.slice(1);
      loop$uri_string = rest2;
      loop$pieces = pieces;
      loop$port = port * 10 + 9;
    } else if (uri_string.startsWith("?")) {
      let rest2 = uri_string.slice(1);
      let pieces$1 = new Uri(pieces.scheme, pieces.userinfo, pieces.host, new Some(port), pieces.path, pieces.query, pieces.fragment);
      return parse_query_with_question_mark(rest2, pieces$1);
    } else if (uri_string.startsWith("#")) {
      let rest2 = uri_string.slice(1);
      let pieces$1 = new Uri(pieces.scheme, pieces.userinfo, pieces.host, new Some(port), pieces.path, pieces.query, pieces.fragment);
      return parse_fragment(rest2, pieces$1);
    } else if (uri_string.startsWith("/")) {
      let pieces$1 = new Uri(pieces.scheme, pieces.userinfo, pieces.host, new Some(port), pieces.path, pieces.query, pieces.fragment);
      return parse_path(uri_string, pieces$1);
    } else if (uri_string === "") {
      return new Ok(new Uri(pieces.scheme, pieces.userinfo, pieces.host, new Some(port), pieces.path, pieces.query, pieces.fragment));
    } else {
      return new Error(undefined);
    }
  }
}
function parse_port(uri_string, pieces) {
  if (uri_string.startsWith(":0")) {
    let rest2 = uri_string.slice(2);
    return parse_port_loop(rest2, pieces, 0);
  } else if (uri_string.startsWith(":1")) {
    let rest2 = uri_string.slice(2);
    return parse_port_loop(rest2, pieces, 1);
  } else if (uri_string.startsWith(":2")) {
    let rest2 = uri_string.slice(2);
    return parse_port_loop(rest2, pieces, 2);
  } else if (uri_string.startsWith(":3")) {
    let rest2 = uri_string.slice(2);
    return parse_port_loop(rest2, pieces, 3);
  } else if (uri_string.startsWith(":4")) {
    let rest2 = uri_string.slice(2);
    return parse_port_loop(rest2, pieces, 4);
  } else if (uri_string.startsWith(":5")) {
    let rest2 = uri_string.slice(2);
    return parse_port_loop(rest2, pieces, 5);
  } else if (uri_string.startsWith(":6")) {
    let rest2 = uri_string.slice(2);
    return parse_port_loop(rest2, pieces, 6);
  } else if (uri_string.startsWith(":7")) {
    let rest2 = uri_string.slice(2);
    return parse_port_loop(rest2, pieces, 7);
  } else if (uri_string.startsWith(":8")) {
    let rest2 = uri_string.slice(2);
    return parse_port_loop(rest2, pieces, 8);
  } else if (uri_string.startsWith(":9")) {
    let rest2 = uri_string.slice(2);
    return parse_port_loop(rest2, pieces, 9);
  } else if (uri_string.startsWith(":")) {
    return new Error(undefined);
  } else if (uri_string.startsWith("?")) {
    let rest2 = uri_string.slice(1);
    return parse_query_with_question_mark(rest2, pieces);
  } else if (uri_string.startsWith("#")) {
    let rest2 = uri_string.slice(1);
    return parse_fragment(rest2, pieces);
  } else if (uri_string.startsWith("/")) {
    return parse_path(uri_string, pieces);
  } else if (uri_string === "") {
    return new Ok(pieces);
  } else {
    return new Error(undefined);
  }
}
function parse_host_outside_of_brackets_loop(loop$original, loop$uri_string, loop$pieces, loop$size) {
  while (true) {
    let original = loop$original;
    let uri_string = loop$uri_string;
    let pieces = loop$pieces;
    let size2 = loop$size;
    if (uri_string === "") {
      return new Ok(new Uri(pieces.scheme, pieces.userinfo, new Some(original), pieces.port, pieces.path, pieces.query, pieces.fragment));
    } else if (uri_string.startsWith(":")) {
      let host = string_codeunit_slice(original, 0, size2);
      let pieces$1 = new Uri(pieces.scheme, pieces.userinfo, new Some(host), pieces.port, pieces.path, pieces.query, pieces.fragment);
      return parse_port(uri_string, pieces$1);
    } else if (uri_string.startsWith("/")) {
      let host = string_codeunit_slice(original, 0, size2);
      let pieces$1 = new Uri(pieces.scheme, pieces.userinfo, new Some(host), pieces.port, pieces.path, pieces.query, pieces.fragment);
      return parse_path(uri_string, pieces$1);
    } else if (uri_string.startsWith("?")) {
      let rest2 = uri_string.slice(1);
      let host = string_codeunit_slice(original, 0, size2);
      let pieces$1 = new Uri(pieces.scheme, pieces.userinfo, new Some(host), pieces.port, pieces.path, pieces.query, pieces.fragment);
      return parse_query_with_question_mark(rest2, pieces$1);
    } else if (uri_string.startsWith("#")) {
      let rest2 = uri_string.slice(1);
      let host = string_codeunit_slice(original, 0, size2);
      let pieces$1 = new Uri(pieces.scheme, pieces.userinfo, new Some(host), pieces.port, pieces.path, pieces.query, pieces.fragment);
      return parse_fragment(rest2, pieces$1);
    } else {
      let $ = pop_codeunit(uri_string);
      let rest2;
      rest2 = $[1];
      loop$original = original;
      loop$uri_string = rest2;
      loop$pieces = pieces;
      loop$size = size2 + 1;
    }
  }
}
function parse_host_within_brackets_loop(loop$original, loop$uri_string, loop$pieces, loop$size) {
  while (true) {
    let original = loop$original;
    let uri_string = loop$uri_string;
    let pieces = loop$pieces;
    let size2 = loop$size;
    if (uri_string === "") {
      return new Ok(new Uri(pieces.scheme, pieces.userinfo, new Some(uri_string), pieces.port, pieces.path, pieces.query, pieces.fragment));
    } else if (uri_string.startsWith("]")) {
      if (size2 === 0) {
        let rest2 = uri_string.slice(1);
        return parse_port(rest2, pieces);
      } else {
        let rest2 = uri_string.slice(1);
        let host = string_codeunit_slice(original, 0, size2 + 1);
        let pieces$1 = new Uri(pieces.scheme, pieces.userinfo, new Some(host), pieces.port, pieces.path, pieces.query, pieces.fragment);
        return parse_port(rest2, pieces$1);
      }
    } else if (uri_string.startsWith("/")) {
      if (size2 === 0) {
        return parse_path(uri_string, pieces);
      } else {
        let host = string_codeunit_slice(original, 0, size2);
        let pieces$1 = new Uri(pieces.scheme, pieces.userinfo, new Some(host), pieces.port, pieces.path, pieces.query, pieces.fragment);
        return parse_path(uri_string, pieces$1);
      }
    } else if (uri_string.startsWith("?")) {
      if (size2 === 0) {
        let rest2 = uri_string.slice(1);
        return parse_query_with_question_mark(rest2, pieces);
      } else {
        let rest2 = uri_string.slice(1);
        let host = string_codeunit_slice(original, 0, size2);
        let pieces$1 = new Uri(pieces.scheme, pieces.userinfo, new Some(host), pieces.port, pieces.path, pieces.query, pieces.fragment);
        return parse_query_with_question_mark(rest2, pieces$1);
      }
    } else if (uri_string.startsWith("#")) {
      if (size2 === 0) {
        let rest2 = uri_string.slice(1);
        return parse_fragment(rest2, pieces);
      } else {
        let rest2 = uri_string.slice(1);
        let host = string_codeunit_slice(original, 0, size2);
        let pieces$1 = new Uri(pieces.scheme, pieces.userinfo, new Some(host), pieces.port, pieces.path, pieces.query, pieces.fragment);
        return parse_fragment(rest2, pieces$1);
      }
    } else {
      let $ = pop_codeunit(uri_string);
      let char;
      let rest2;
      char = $[0];
      rest2 = $[1];
      let $1 = is_valid_host_within_brackets_char(char);
      if ($1) {
        loop$original = original;
        loop$uri_string = rest2;
        loop$pieces = pieces;
        loop$size = size2 + 1;
      } else {
        return parse_host_outside_of_brackets_loop(original, original, pieces, 0);
      }
    }
  }
}
function parse_host_within_brackets(uri_string, pieces) {
  return parse_host_within_brackets_loop(uri_string, uri_string, pieces, 0);
}
function parse_host_outside_of_brackets(uri_string, pieces) {
  return parse_host_outside_of_brackets_loop(uri_string, uri_string, pieces, 0);
}
function parse_host(uri_string, pieces) {
  if (uri_string.startsWith("[")) {
    return parse_host_within_brackets(uri_string, pieces);
  } else if (uri_string.startsWith(":")) {
    let pieces$1 = new Uri(pieces.scheme, pieces.userinfo, new Some(""), pieces.port, pieces.path, pieces.query, pieces.fragment);
    return parse_port(uri_string, pieces$1);
  } else if (uri_string === "") {
    return new Ok(new Uri(pieces.scheme, pieces.userinfo, new Some(""), pieces.port, pieces.path, pieces.query, pieces.fragment));
  } else {
    return parse_host_outside_of_brackets(uri_string, pieces);
  }
}
function parse_userinfo_loop(loop$original, loop$uri_string, loop$pieces, loop$size) {
  while (true) {
    let original = loop$original;
    let uri_string = loop$uri_string;
    let pieces = loop$pieces;
    let size2 = loop$size;
    if (uri_string.startsWith("@")) {
      if (size2 === 0) {
        let rest2 = uri_string.slice(1);
        return parse_host(rest2, pieces);
      } else {
        let rest2 = uri_string.slice(1);
        let userinfo = string_codeunit_slice(original, 0, size2);
        let pieces$1 = new Uri(pieces.scheme, new Some(userinfo), pieces.host, pieces.port, pieces.path, pieces.query, pieces.fragment);
        return parse_host(rest2, pieces$1);
      }
    } else if (uri_string === "") {
      return parse_host(original, pieces);
    } else if (uri_string.startsWith("/")) {
      return parse_host(original, pieces);
    } else if (uri_string.startsWith("?")) {
      return parse_host(original, pieces);
    } else if (uri_string.startsWith("#")) {
      return parse_host(original, pieces);
    } else {
      let $ = pop_codeunit(uri_string);
      let rest2;
      rest2 = $[1];
      loop$original = original;
      loop$uri_string = rest2;
      loop$pieces = pieces;
      loop$size = size2 + 1;
    }
  }
}
function parse_authority_pieces(string5, pieces) {
  return parse_userinfo_loop(string5, string5, pieces, 0);
}
function parse_authority_with_slashes(uri_string, pieces) {
  if (uri_string === "//") {
    return new Ok(new Uri(pieces.scheme, pieces.userinfo, new Some(""), pieces.port, pieces.path, pieces.query, pieces.fragment));
  } else if (uri_string.startsWith("//")) {
    let rest2 = uri_string.slice(2);
    return parse_authority_pieces(rest2, pieces);
  } else {
    return parse_path(uri_string, pieces);
  }
}
function parse_scheme_loop(loop$original, loop$uri_string, loop$pieces, loop$size) {
  while (true) {
    let original = loop$original;
    let uri_string = loop$uri_string;
    let pieces = loop$pieces;
    let size2 = loop$size;
    if (uri_string.startsWith("/")) {
      if (size2 === 0) {
        return parse_authority_with_slashes(uri_string, pieces);
      } else {
        let scheme = string_codeunit_slice(original, 0, size2);
        let pieces$1 = new Uri(new Some(lowercase(scheme)), pieces.userinfo, pieces.host, pieces.port, pieces.path, pieces.query, pieces.fragment);
        return parse_authority_with_slashes(uri_string, pieces$1);
      }
    } else if (uri_string.startsWith("?")) {
      if (size2 === 0) {
        let rest2 = uri_string.slice(1);
        return parse_query_with_question_mark(rest2, pieces);
      } else {
        let rest2 = uri_string.slice(1);
        let scheme = string_codeunit_slice(original, 0, size2);
        let pieces$1 = new Uri(new Some(lowercase(scheme)), pieces.userinfo, pieces.host, pieces.port, pieces.path, pieces.query, pieces.fragment);
        return parse_query_with_question_mark(rest2, pieces$1);
      }
    } else if (uri_string.startsWith("#")) {
      if (size2 === 0) {
        let rest2 = uri_string.slice(1);
        return parse_fragment(rest2, pieces);
      } else {
        let rest2 = uri_string.slice(1);
        let scheme = string_codeunit_slice(original, 0, size2);
        let pieces$1 = new Uri(new Some(lowercase(scheme)), pieces.userinfo, pieces.host, pieces.port, pieces.path, pieces.query, pieces.fragment);
        return parse_fragment(rest2, pieces$1);
      }
    } else if (uri_string.startsWith(":")) {
      if (size2 === 0) {
        return new Error(undefined);
      } else {
        let rest2 = uri_string.slice(1);
        let scheme = string_codeunit_slice(original, 0, size2);
        let pieces$1 = new Uri(new Some(lowercase(scheme)), pieces.userinfo, pieces.host, pieces.port, pieces.path, pieces.query, pieces.fragment);
        return parse_authority_with_slashes(rest2, pieces$1);
      }
    } else if (uri_string === "") {
      return new Ok(new Uri(pieces.scheme, pieces.userinfo, pieces.host, pieces.port, original, pieces.query, pieces.fragment));
    } else {
      let $ = pop_codeunit(uri_string);
      let rest2;
      rest2 = $[1];
      loop$original = original;
      loop$uri_string = rest2;
      loop$pieces = pieces;
      loop$size = size2 + 1;
    }
  }
}
function remove_dot_segments_loop(loop$input, loop$accumulator) {
  while (true) {
    let input2 = loop$input;
    let accumulator = loop$accumulator;
    if (input2 instanceof Empty) {
      return reverse(accumulator);
    } else {
      let segment = input2.head;
      let rest2 = input2.tail;
      let _block;
      if (segment === "") {
        _block = accumulator;
      } else if (segment === ".") {
        _block = accumulator;
      } else if (segment === "..") {
        if (accumulator instanceof Empty) {
          _block = accumulator;
        } else {
          let accumulator$12 = accumulator.tail;
          _block = accumulator$12;
        }
      } else {
        let segment$1 = segment;
        let accumulator$12 = accumulator;
        _block = prepend(segment$1, accumulator$12);
      }
      let accumulator$1 = _block;
      loop$input = rest2;
      loop$accumulator = accumulator$1;
    }
  }
}
function remove_dot_segments(input2) {
  return remove_dot_segments_loop(input2, toList([]));
}
function to_string6(uri) {
  let _block;
  let $ = uri.fragment;
  if ($ instanceof Some) {
    let fragment3 = $[0];
    _block = toList(["#", fragment3]);
  } else {
    _block = toList([]);
  }
  let parts = _block;
  let _block$1;
  let $1 = uri.query;
  if ($1 instanceof Some) {
    let query = $1[0];
    _block$1 = prepend("?", prepend(query, parts));
  } else {
    _block$1 = parts;
  }
  let parts$1 = _block$1;
  let parts$2 = prepend(uri.path, parts$1);
  let _block$2;
  let $2 = uri.host;
  let $3 = starts_with(uri.path, "/");
  if ($2 instanceof Some && !$3) {
    let host = $2[0];
    if (host !== "") {
      _block$2 = prepend("/", parts$2);
    } else {
      _block$2 = parts$2;
    }
  } else {
    _block$2 = parts$2;
  }
  let parts$3 = _block$2;
  let _block$3;
  let $4 = uri.host;
  let $5 = uri.port;
  if ($4 instanceof Some && $5 instanceof Some) {
    let port = $5[0];
    _block$3 = prepend(":", prepend(to_string(port), parts$3));
  } else {
    _block$3 = parts$3;
  }
  let parts$4 = _block$3;
  let _block$4;
  let $6 = uri.scheme;
  let $7 = uri.userinfo;
  let $8 = uri.host;
  if ($6 instanceof Some) {
    if ($7 instanceof Some) {
      if ($8 instanceof Some) {
        let s = $6[0];
        let u = $7[0];
        let h = $8[0];
        _block$4 = prepend(s, prepend("://", prepend(u, prepend("@", prepend(h, parts$4)))));
      } else {
        let s = $6[0];
        _block$4 = prepend(s, prepend(":", parts$4));
      }
    } else if ($8 instanceof Some) {
      let s = $6[0];
      let h = $8[0];
      _block$4 = prepend(s, prepend("://", prepend(h, parts$4)));
    } else {
      let s = $6[0];
      _block$4 = prepend(s, prepend(":", parts$4));
    }
  } else if ($7 instanceof None && $8 instanceof Some) {
    let h = $8[0];
    _block$4 = prepend("//", prepend(h, parts$4));
  } else {
    _block$4 = parts$4;
  }
  let parts$5 = _block$4;
  return concat2(parts$5);
}
function drop_last(elements) {
  return take(elements, length(elements) - 1);
}
function join_segments(segments) {
  return join(prepend("", segments), "/");
}
function merge2(base, relative) {
  let $ = base.scheme;
  if ($ instanceof Some) {
    let $1 = base.host;
    if ($1 instanceof Some) {
      let $2 = relative.host;
      if ($2 instanceof Some) {
        let _block;
        let _pipe = split2(relative.path, "/");
        let _pipe$1 = remove_dot_segments(_pipe);
        _block = join_segments(_pipe$1);
        let path = _block;
        let resolved = new Uri(or(relative.scheme, base.scheme), new None, relative.host, or(relative.port, base.port), path, relative.query, relative.fragment);
        return new Ok(resolved);
      } else {
        let _block;
        let $4 = relative.path;
        if ($4 === "") {
          _block = [base.path, or(relative.query, base.query)];
        } else {
          let _block$1;
          let $5 = starts_with(relative.path, "/");
          if ($5) {
            _block$1 = split2(relative.path, "/");
          } else {
            let _pipe2 = split2(base.path, "/");
            let _pipe$12 = drop_last(_pipe2);
            _block$1 = append(_pipe$12, split2(relative.path, "/"));
          }
          let path_segments$1 = _block$1;
          let _block$2;
          let _pipe = path_segments$1;
          let _pipe$1 = remove_dot_segments(_pipe);
          _block$2 = join_segments(_pipe$1);
          let path = _block$2;
          _block = [path, relative.query];
        }
        let $3 = _block;
        let new_path;
        let new_query;
        new_path = $3[0];
        new_query = $3[1];
        let resolved = new Uri(base.scheme, new None, base.host, base.port, new_path, new_query, relative.fragment);
        return new Ok(resolved);
      }
    } else {
      return new Error(undefined);
    }
  } else {
    return new Error(undefined);
  }
}
function parse2(uri_string) {
  return parse_scheme_loop(uri_string, uri_string, empty4, 0);
}

// build/dev/javascript/lustre_websocket/ffi.mjs
var init_websocket = (url, on_open, on_text, on_binary, on_close) => {
  let ws;
  if (typeof WebSocket === "function") {
    ws = new WebSocket(url);
  } else {
    ws = {};
  }
  ws.onopen = (_) => on_open(ws);
  ws.onmessage = (event3) => {
    if (typeof event3.data === "string") {
      on_text(event3.data);
    } else {
      on_binary(event3.data);
    }
  };
  ws.onclose = (event3) => on_close(event3.code);
};
var send_over_websocket = (ws, msg) => ws.send(msg);
var get_page_url = () => document.URL;
// build/dev/javascript/lustre_websocket/lustre_websocket.mjs
class Normal extends CustomType {
}
class GoingAway extends CustomType {
}
class ProtocolError extends CustomType {
}
class UnexpectedTypeOfData extends CustomType {
}
class NoCodeFromServer extends CustomType {
}
class AbnormalClose extends CustomType {
}
class IncomprehensibleFrame extends CustomType {
}
class PolicyViolated extends CustomType {
}
class MessageTooBig extends CustomType {
}
class FailedExtensionNegotation extends CustomType {
}
class UnexpectedFailure extends CustomType {
}
class FailedTLSHandshake extends CustomType {
}
class OtherCloseReason extends CustomType {
}
class InvalidUrl extends CustomType {
}
class OnOpen extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class OnTextMessage extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class OnBinaryMessage extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class OnClose extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
function code_to_reason(code) {
  if (code === 1000) {
    return new Normal;
  } else if (code === 1001) {
    return new GoingAway;
  } else if (code === 1002) {
    return new ProtocolError;
  } else if (code === 1003) {
    return new UnexpectedTypeOfData;
  } else if (code === 1005) {
    return new NoCodeFromServer;
  } else if (code === 1006) {
    return new AbnormalClose;
  } else if (code === 1007) {
    return new IncomprehensibleFrame;
  } else if (code === 1008) {
    return new PolicyViolated;
  } else if (code === 1009) {
    return new MessageTooBig;
  } else if (code === 1010) {
    return new FailedExtensionNegotation;
  } else if (code === 1011) {
    return new UnexpectedFailure;
  } else if (code === 1015) {
    return new FailedTLSHandshake;
  } else {
    return new OtherCloseReason;
  }
}
function convert_scheme(scheme) {
  if (scheme === "https") {
    return new Ok("wss");
  } else if (scheme === "http") {
    return new Ok("ws");
  } else if (scheme === "ws") {
    return new Ok(scheme);
  } else if (scheme === "wss") {
    return new Ok(scheme);
  } else {
    return new Error(undefined);
  }
}
function do_get_websocket_path(path, page_uri) {
  let _block;
  let _pipe = parse2(path);
  _block = unwrap2(_pipe, new Uri(new None, new None, new None, new None, path, new None, new None));
  let path_uri = _block;
  return try$(merge2(page_uri, path_uri), (merged) => {
    return try$(to_result(merged.scheme, undefined), (merged_scheme) => {
      return try$(convert_scheme(merged_scheme), (ws_scheme) => {
        let _pipe$1 = new Uri(new Some(ws_scheme), merged.userinfo, merged.host, merged.port, merged.path, merged.query, merged.fragment);
        let _pipe$2 = to_string6(_pipe$1);
        return new Ok(_pipe$2);
      });
    });
  });
}
function send2(ws, msg) {
  return from((_) => {
    return send_over_websocket(ws, msg);
  });
}
function page_uri() {
  let _pipe = get_page_url();
  return parse2(_pipe);
}
function get_websocket_path(path) {
  let _pipe = page_uri();
  return try$(_pipe, (_capture) => {
    return do_get_websocket_path(path, _capture);
  });
}
function init(path, wrapper) {
  let _pipe = (dispatch) => {
    let $ = get_websocket_path(path);
    if ($ instanceof Ok) {
      let url = $[0];
      return init_websocket(url, (ws) => {
        return dispatch(wrapper(new OnOpen(ws)));
      }, (text4) => {
        return dispatch(wrapper(new OnTextMessage(text4)));
      }, (data) => {
        return dispatch(wrapper(new OnBinaryMessage(data)));
      }, (code) => {
        let _pipe2 = code;
        let _pipe$1 = code_to_reason(_pipe2);
        let _pipe$2 = new OnClose(_pipe$1);
        let _pipe$3 = wrapper(_pipe$2);
        return dispatch(_pipe$3);
      });
    } else {
      let _pipe2 = new InvalidUrl;
      let _pipe$1 = wrapper(_pipe2);
      return dispatch(_pipe$1);
    }
  };
  return from(_pipe);
}
// build/dev/javascript/plinth/storage_ffi.mjs
function localStorage() {
  try {
    if (globalThis.Storage && globalThis.localStorage instanceof globalThis.Storage) {
      return new Ok(globalThis.localStorage);
    } else {
      return new Error(null);
    }
  } catch {
    return new Error(null);
  }
}
function getItem(storage, keyName) {
  return null_or(storage.getItem(keyName));
}
function setItem(storage, keyName, keyValue) {
  try {
    storage.setItem(keyName, keyValue);
    return new Ok(null);
  } catch {
    return new Error(null);
  }
}
function clear(storage) {
  storage.clear();
}
function null_or(val) {
  if (val !== null) {
    return new Ok(val);
  } else {
    return new Error(null);
  }
}
// build/dev/javascript/lumina_client/lumina_client/model_type.mjs
class WSTryReconnect extends CustomType {
}
class EffectPast150ms extends CustomType {
}
class UpdateLastRefreshRequestTime extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class WsDisconnectDefinitive extends CustomType {
}
class WebSocketIncomingMessage extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class UserNavigatedToLoginPage extends CustomType {
}
class UserNavigatedToRegisterPage extends CustomType {
}
class UserNavigatedToLandingPage extends CustomType {
}
class UserSubmittedLogin extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class UserSubmittedSignup extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class UserUpdatedControlledEmailField extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class UserUpdatedControlledPasswordField extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class UserUpdatedControlledUsernameField extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class UserUpdatedControlledPasswordConfirmField extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class EmailFieldLostFocus extends CustomType {
}
class UserSwitchedTimeLineTo extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class LoadMorePosts extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class UserClickedLogout extends CustomType {
}
class UserClosedModal extends CustomType {
}
class SetModal extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class StartDraggingModalBox extends CustomType {
  constructor($0, $1) {
    super();
    this[0] = $0;
    this[1] = $1;
  }
}
class MoveModalBoxTo extends CustomType {
  constructor($0, $1) {
    super();
    this[0] = $0;
    this[1] = $1;
  }
}
class Landing extends CustomType {
}
class Register extends CustomType {
  constructor(fields, ready) {
    super();
    this.fields = fields;
    this.ready = ready;
  }
}
class Login extends CustomType {
  constructor(fields, success2) {
    super();
    this.fields = fields;
    this.success = success2;
  }
}
class HomeTimeline extends CustomType {
  constructor(timeline_name, modal) {
    super();
    this.timeline_name = timeline_name;
    this.modal = modal;
  }
}
class Licence extends CustomType {
}
class Model extends CustomType {
  constructor(page, user, ws, token2, status, cache, has_been_running_for_150ms, last_refresh_request_time) {
    super();
    this.page = page;
    this.user = user;
    this.ws = ws;
    this.token = token2;
    this.status = status;
    this.cache = cache;
    this.has_been_running_for_150ms = has_been_running_for_150ms;
    this.last_refresh_request_time = last_refresh_request_time;
  }
}
class NotificationsSubModel extends CustomType {
  constructor(unread_count, cached_notifications) {
    super();
    this.unread_count = unread_count;
    this.cached_notifications = cached_notifications;
  }
}
class WsConnectionInitial extends CustomType {
}
class WsConnectionConnected extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class WsConnectionDisconnected extends CustomType {
}
class WsConnectionUnsure extends CustomType {
}
class WsConnectionRetrying extends CustomType {
}
class Cached extends CustomType {
  constructor(cached_posts, cached_users, cached_timelines) {
    super();
    this.cached_posts = cached_posts;
    this.cached_users = cached_users;
    this.cached_timelines = cached_timelines;
  }
}
class CachedUser extends CustomType {
  constructor(source_instance, username, avatar, last_updated) {
    super();
    this.source_instance = source_instance;
    this.username = username;
    this.avatar = avatar;
    this.last_updated = last_updated;
  }
}
class CachedTimeline extends CustomType {
  constructor(id2, pages, total_count, current_page, has_more, last_updated) {
    super();
    this.id = id2;
    this.pages = pages;
    this.total_count = total_count;
    this.current_page = current_page;
    this.has_more = has_more;
    this.last_updated = last_updated;
  }
}
class RegisterPageFields extends CustomType {
  constructor(usernamefield, emailfield, passwordfield, passwordconfirmfield) {
    super();
    this.usernamefield = usernamefield;
    this.emailfield = emailfield;
    this.passwordfield = passwordfield;
    this.passwordconfirmfield = passwordconfirmfield;
  }
}
class LoginFields extends CustomType {
  constructor(emailfield, passwordfield) {
    super();
    this.emailfield = emailfield;
    this.passwordfield = passwordfield;
  }
}
class UserSubmodel extends CustomType {
  constructor(uid, username, email, avatar, notifs) {
    super();
    this.uid = uid;
    this.username = username;
    this.email = email;
    this.avatar = avatar;
    this.notifs = notifs;
  }
}
class SerializableModel extends CustomType {
  constructor(page, token2) {
    super();
    this.page = page;
    this.token = token2;
  }
}
function encode_page(page) {
  if (page instanceof Landing) {
    return object2(toList([["type", string3("landing")]]));
  } else if (page instanceof Register) {
    let fields = page.fields;
    let ready = page.ready;
    return object2(toList([
      ["type", string3("register")],
      [
        "fields",
        (() => {
          let usernamefield;
          let emailfield;
          let passwordfield;
          let passwordconfirmfield;
          usernamefield = fields.usernamefield;
          emailfield = fields.emailfield;
          passwordfield = fields.passwordfield;
          passwordconfirmfield = fields.passwordconfirmfield;
          return object2(toList([
            ["usernamefield", string3(usernamefield)],
            ["emailfield", string3(emailfield)],
            ["passwordfield", string3(passwordfield)],
            ["passwordconfirmfield", string3(passwordconfirmfield)]
          ]));
        })()
      ],
      [
        "ready",
        (() => {
          return null$();
        })()
      ]
    ]));
  } else if (page instanceof Login) {
    let fields = page.fields;
    return object2(toList([
      ["type", string3("login")],
      [
        "fields",
        (() => {
          let emailfield;
          let passwordfield;
          emailfield = fields.emailfield;
          passwordfield = fields.passwordfield;
          return object2(toList([
            ["emailfield", string3(emailfield)],
            ["passwordfield", string3(passwordfield)]
          ]));
        })()
      ]
    ]));
  } else if (page instanceof HomeTimeline) {
    let timeline_name = page.timeline_name;
    let modal = page.modal;
    return object2((() => {
      let _pipe = toList([["type", string3("home_timeline")]]);
      let _pipe$1 = append(_pipe, (() => {
        if (timeline_name instanceof Some) {
          let i = timeline_name[0];
          return toList([["timeline_name", string3(i)]]);
        } else {
          return toList([]);
        }
      })());
      return append(_pipe$1, (() => {
        if (modal instanceof Some) {
          let i = modal[0];
          return toList([["modal", string3(i[0])]]);
        } else {
          return toList([]);
        }
      })());
    })());
  } else if (page instanceof Licence) {
    return object2(toList([["type", string3("licence")]]));
  } else {
    return object2(toList([["type", string3("landing")]]));
  }
}
function page_decoder() {
  return field("type", string2, (variant) => {
    if (variant === "landing") {
      return success(new Landing);
    } else if (variant === "licence") {
      return success(new Licence);
    } else if (variant === "register") {
      return field("fields", field("usernamefield", string2, (usernamefield) => {
        return field("emailfield", string2, (emailfield) => {
          return field("passwordfield", string2, (passwordfield) => {
            return field("passwordconfirmfield", string2, (passwordconfirmfield) => {
              return success(new RegisterPageFields(usernamefield, emailfield, passwordfield, passwordconfirmfield));
            });
          });
        });
      }), (fields) => {
        let ready = new None;
        return success(new Register(fields, ready));
      });
    } else if (variant === "login") {
      return field("fields", field("emailfield", string2, (emailfield) => {
        return field("passwordfield", string2, (passwordfield) => {
          return success(new LoginFields(emailfield, passwordfield));
        });
      }), (fields) => {
        return success(new Login(fields, new None));
      });
    } else if (variant === "home_timeline") {
      return optional_field("timeline_name", new None, optional(string2), (timeline_name) => {
        return optional_field("modal", new None, optional(string2), (modal_n) => {
          let _block;
          let _pipe = modal_n;
          _block = map(_pipe, (m) => {
            return [m, new_map()];
          });
          let modal = _block;
          return success(new HomeTimeline(timeline_name, modal));
        });
      });
    } else {
      return failure(new Landing, "Page");
    }
  });
}
function serialize_serializable_model(serializable_model) {
  let page;
  let token2;
  page = serializable_model.page;
  token2 = serializable_model.token;
  return object2(toList([
    ["page", encode_page(page)],
    [
      "token",
      (() => {
        if (token2 instanceof Some) {
          let value2 = token2[0];
          return string3(value2);
        } else {
          return null$();
        }
      })()
    ]
  ]));
}
function serializable_model_decoder() {
  return field("page", page_decoder(), (page) => {
    return field("token", optional(string2), (token2) => {
      return success(new SerializableModel(page, token2));
    });
  });
}
function deserialize_serializable_model(jsod) {
  return parse(jsod, serializable_model_decoder());
}
function serialize(normal_model) {
  let page;
  let token2;
  page = normal_model.page;
  token2 = normal_model.token;
  let _pipe = new SerializableModel(page, token2);
  let _pipe$1 = serialize_serializable_model(_pipe);
  return to_string2(_pipe$1);
}

// build/dev/javascript/lumina_client/lumina_client/dom_ffi.mjs
function classfoundintree(starting_element, className) {
  let element3 = starting_element;
  do {
    if (element3.classList && element3.classList.contains(className)) {
      return true;
    }
    element3 = element3.parentElement;
  } while (element3);
  return false;
}
function start_dragging_modal_box(start_x, start_y, constructor, dispatcher) {
  let current_x = start_x;
  let current_y = start_y;
  const dispatchnewlocation = () => {
    const msg = constructor(current_x, current_y);
    dispatcher(msg);
  };
  const on_mouse_move = (event3) => {
    current_x += event3.movementX;
    current_y += event3.movementY;
    dispatchnewlocation();
  };
  const on_mouse_up = () => {
    window.removeEventListener("mousemove", on_mouse_move);
    window.removeEventListener("mouseup", on_mouse_up);
  };
  window.addEventListener("mousemove", on_mouse_move);
  window.addEventListener("mouseup", on_mouse_up);
  return;
}
function get_window_dimensions_px() {
  return [window.innerWidth, window.innerHeight];
}

// build/dev/javascript/plinth/global_ffi.mjs
function setTimeout2(delay, callback) {
  return globalThis.setTimeout(callback, delay);
}

// build/dev/javascript/lumina_client/lumina_client/helpers.mjs
var model_local_storage_key = "luminaModelJSOB";
function get_color_scheme2(_) {
  return none();
}
function login_view_checker(fieldvalues) {
  let _pipe = toList([
    fieldvalues.passwordfield !== "",
    fieldvalues.emailfield !== ""
  ]);
  return all(_pipe, (x) => {
    return x;
  });
}
function set_timeout_nilled(delay, cb) {
  setTimeout2(delay, cb);
  return;
}
function get_center_positioned_style_px() {
  let _block;
  let _pipe = get_window_dimensions_px();
  _block = echo(_pipe, undefined, "src/lumina_client/helpers.gleam", 51);
  let $ = _block;
  let window_w;
  let window_h;
  window_w = $[0];
  window_h = $[1];
  let x_int = globalThis.Math.trunc(window_h / 2);
  let y_int = globalThis.Math.trunc(window_w / 2);
  let x = identity(x_int);
  let y = identity(y_int);
  return [x, y];
}
function echo(value2, message, file, line) {
  const grey = "\x1B[90m";
  const reset_color = "\x1B[39m";
  const file_line = `${file}:${line}`;
  const inspector = new Echo$Inspector;
  const string_value = inspector.inspect(value2);
  const string_message = message === undefined ? "" : " " + message;
  if (globalThis.process?.stderr?.write) {
    const string5 = `${grey}${file_line}${reset_color}${string_message}
${string_value}
`;
    globalThis.process.stderr.write(string5);
  } else if (globalThis.Deno) {
    const string5 = `${grey}${file_line}${reset_color}${string_message}
${string_value}
`;
    globalThis.Deno.stderr.writeSync(new TextEncoder().encode(string5));
  } else {
    const string5 = `${file_line}${string_message}
${string_value}`;
    globalThis.console.log(string5);
  }
  return value2;
}

class Echo$Inspector {
  #references = new globalThis.Set;
  #isDict(value2) {
    try {
      const empty_dict2 = new_map();
      const dict_class = empty_dict2.constructor;
      return value2 instanceof dict_class;
    } catch {
      return false;
    }
  }
  #float(float4) {
    const string5 = float4.toString().replace("+", "");
    if (string5.indexOf(".") >= 0) {
      return string5;
    } else {
      const index4 = string5.indexOf("e");
      if (index4 >= 0) {
        return string5.slice(0, index4) + ".0" + string5.slice(index4);
      } else {
        return string5 + ".0";
      }
    }
  }
  inspect(v) {
    const t = typeof v;
    if (v === true)
      return "True";
    if (v === false)
      return "False";
    if (v === null)
      return "//js(null)";
    if (v === undefined)
      return "Nil";
    if (t === "string")
      return this.#string(v);
    if (t === "bigint" || globalThis.Number.isInteger(v))
      return v.toString();
    if (t === "number")
      return this.#float(v);
    if (v instanceof UtfCodepoint)
      return this.#utfCodepoint(v);
    if (v instanceof BitArray)
      return this.#bit_array(v);
    if (v instanceof globalThis.RegExp)
      return `//js(${v})`;
    if (v instanceof globalThis.Date)
      return `//js(Date("${v.toISOString()}"))`;
    if (v instanceof globalThis.Error)
      return `//js(${v.toString()})`;
    if (v instanceof globalThis.Function) {
      const args = [];
      for (const i of globalThis.Array(v.length).keys())
        args.push(globalThis.String.fromCharCode(i + 97));
      return `//fn(${args.join(", ")}) { ... }`;
    }
    if (this.#references.size === this.#references.add(v).size) {
      return "//js(circular reference)";
    }
    let printed;
    if (globalThis.Array.isArray(v)) {
      printed = `#(${v.map((v2) => this.inspect(v2)).join(", ")})`;
    } else if (v instanceof List) {
      printed = this.#list(v);
    } else if (v instanceof CustomType) {
      printed = this.#customType(v);
    } else if (this.#isDict(v)) {
      printed = this.#dict(v);
    } else if (v instanceof Set) {
      return `//js(Set(${[...v].map((v2) => this.inspect(v2)).join(", ")}))`;
    } else {
      printed = this.#object(v);
    }
    this.#references.delete(v);
    return printed;
  }
  #object(v) {
    const name2 = globalThis.Object.getPrototypeOf(v)?.constructor?.name || "Object";
    const props = [];
    for (const k of globalThis.Object.keys(v)) {
      props.push(`${this.inspect(k)}: ${this.inspect(v[k])}`);
    }
    const body = props.length ? " " + props.join(", ") + " " : "";
    const head = name2 === "Object" ? "" : name2 + " ";
    return `//js(${head}{${body}})`;
  }
  #dict(map5) {
    let body = "dict.from_list([";
    let first2 = true;
    let key_value_pairs = fold(map5, [], (pairs, key2, value2) => {
      pairs.push([key2, value2]);
      return pairs;
    });
    key_value_pairs.sort();
    key_value_pairs.forEach(([key2, value2]) => {
      if (!first2)
        body = body + ", ";
      body = body + "#(" + this.inspect(key2) + ", " + this.inspect(value2) + ")";
      first2 = false;
    });
    return body + "])";
  }
  #customType(record) {
    const props = globalThis.Object.keys(record).map((label2) => {
      const value2 = this.inspect(record[label2]);
      return isNaN(parseInt(label2)) ? `${label2}: ${value2}` : value2;
    }).join(", ");
    return props ? `${record.constructor.name}(${props})` : record.constructor.name;
  }
  #list(list4) {
    if (list4 instanceof Empty) {
      return "[]";
    }
    let char_out = 'charlist.from_string("';
    let list_out = "[";
    let current = list4;
    while (current instanceof NonEmpty) {
      let element3 = current.head;
      current = current.tail;
      if (list_out !== "[") {
        list_out += ", ";
      }
      list_out += this.inspect(element3);
      if (char_out) {
        if (globalThis.Number.isInteger(element3) && element3 >= 32 && element3 <= 126) {
          char_out += globalThis.String.fromCharCode(element3);
        } else {
          char_out = null;
        }
      }
    }
    if (char_out) {
      return char_out + '")';
    } else {
      return list_out + "]";
    }
  }
  #string(str) {
    let new_str = '"';
    for (let i = 0;i < str.length; i++) {
      const char = str[i];
      switch (char) {
        case `
`:
          new_str += "\\n";
          break;
        case "\r":
          new_str += "\\r";
          break;
        case "\t":
          new_str += "\\t";
          break;
        case "\f":
          new_str += "\\f";
          break;
        case "\\":
          new_str += "\\\\";
          break;
        case '"':
          new_str += "\\\"";
          break;
        default:
          if (char < " " || char > "~" && char < " ") {
            new_str += "\\u{" + char.charCodeAt(0).toString(16).toUpperCase().padStart(4, "0") + "}";
          } else {
            new_str += char;
          }
      }
    }
    new_str += '"';
    return new_str;
  }
  #utfCodepoint(codepoint2) {
    return `//utfcodepoint(${globalThis.String.fromCodePoint(codepoint2.value)})`;
  }
  #bit_array(bits) {
    if (bits.bitSize === 0) {
      return "<<>>";
    }
    let acc = "<<";
    for (let i = 0;i < bits.byteSize - 1; i++) {
      acc += bits.byteAt(i).toString();
      acc += ", ";
    }
    if (bits.byteSize * 8 === bits.bitSize) {
      acc += bits.byteAt(bits.byteSize - 1).toString();
    } else {
      const trailingBitsCount = bits.bitSize % 8;
      acc += bits.byteAt(bits.byteSize - 1) >> 8 - trailingBitsCount;
      acc += `:size(${trailingBitsCount})`;
    }
    acc += ">>";
    return acc;
  }
}

// build/dev/javascript/lustre/lustre/event.mjs
function is_immediate_event(name2) {
  if (name2 === "input") {
    return true;
  } else if (name2 === "change") {
    return true;
  } else if (name2 === "focus") {
    return true;
  } else if (name2 === "focusin") {
    return true;
  } else if (name2 === "focusout") {
    return true;
  } else if (name2 === "blur") {
    return true;
  } else if (name2 === "select") {
    return true;
  } else {
    return false;
  }
}
function on(name2, handler) {
  return event(name2, handler, empty_list, false, false, is_immediate_event(name2), new NoLimit(0));
}
function prevent_default(event4) {
  if (event4 instanceof Event2) {
    return new Event2(event4.kind, event4.name, event4.handler, event4.include, true, event4.stop_propagation, event4.immediate, event4.limit);
  } else {
    return event4;
  }
}
function on_click(msg) {
  return on("click", success(msg));
}
function on_mouse_down(msg) {
  return on("mousedown", success(msg));
}
function on_input(msg) {
  return on("input", subfield(toList(["target", "value"]), string2, (value2) => {
    return success(msg(value2));
  }));
}
function formdata_decoder() {
  let string_value_decoder = field(0, string2, (key2) => {
    return field(1, one_of(map4(string2, (var0) => {
      return new Ok(var0);
    }), toList([success(new Error(undefined))])), (value2) => {
      let _pipe2 = value2;
      let _pipe$12 = map3(_pipe2, (_capture) => {
        return new$(key2, _capture);
      });
      return success(_pipe$12);
    });
  });
  let _pipe = string_value_decoder;
  let _pipe$1 = list2(_pipe);
  return map4(_pipe$1, values2);
}
function on_submit(msg) {
  let _pipe = on("submit", subfield(toList(["detail", "formData"]), formdata_decoder(), (formdata) => {
    let _pipe2 = formdata;
    let _pipe$1 = msg(_pipe2);
    return success(_pipe$1);
  }));
  return prevent_default(_pipe);
}

// build/dev/javascript/lumina_client/lumina_client/view/common_view_parts.mjs
function common_view_parts(main_body, menuitems) {
  return div(toList([class$("font-sans")]), toList([
    div(toList([
      class$("navbar bg-base-100 dark:bg-neutral-800 shadow-sm")
    ]), toList([
      div(toList([class$("flex-none")]), toList([
        button(toList([class$("")]), toList([
          img(toList([
            src("/static/logo.svg"),
            alt("Lumina logo"),
            class$("h-8")
          ]))
        ]))
      ])),
      div(toList([class$("flex-1")]), toList([
        a(toList([class$("btn btn-ghost text-xl font-logo")]), toList([text2("Lumina")]))
      ])),
      div(toList([class$("flex-none")]), toList([
        ul(toList([
          class$("menu menu-horizontal px-1 font-menuitems")
        ]), menuitems)
      ]))
    ])),
    div(toList([
      class$("bg-base-200 h-screen max-h-[calc(100vh-4rem)]")
    ]), main_body)
  ]));
}

// build/dev/javascript/lustre/lustre/element/svg.mjs
var namespace = "http://www.w3.org/2000/svg";
function circle(attrs) {
  return namespaced(namespace, "circle", attrs, empty_list);
}
function svg(attrs, children) {
  return namespaced(namespace, "svg", attrs, children);
}
function path(attrs) {
  return namespaced(namespace, "path", attrs, empty_list);
}

// build/dev/javascript/lumina_client/lumina_client/view/common_view_parts/svgs.mjs
var sourcelist_solar_linear = /* @__PURE__ */ toList([
  [globe, "https://www.svgrepo.com/svg/524520/earth"],
  [pen, "https://www.svgrepo.com/svg/524793/pen-2"],
  [camera, "https://www.svgrepo.com/svg/524361/camera"],
  [pen_paper, "https://www.svgrepo.com/svg/524800/pen-new-square"],
  [hashtag_square, "https://www.svgrepo.com/svg/524621/hashtag-square"],
  [add_square, "https://www.svgrepo.com/svg/524223/add-square"],
  [archive_box, "https://www.svgrepo.com/svg/523982/archive"]
]);
function globe(classes) {
  return svg(toList([
    attribute2("xmlns", "http://www.w3.org/2000/svg"),
    class$(classes),
    attribute2("fill", "none"),
    attribute2("viewBox", "0 0 24 24")
  ]), toList([
    circle(toList([
      attribute2("stroke-width", "1.5"),
      attribute2("stroke", "currentColor"),
      attribute2("r", "10"),
      attribute2("cy", "12"),
      attribute2("cx", "12")
    ])),
    path(toList([
      attribute2("stroke-width", "1.5"),
      attribute2("stroke", "currentColor"),
      attribute2("d", "M6 4.71053C6.78024 5.42105 8.38755 7.36316 8.57481 9.44737C8.74984 11.3955 10.0357 12.9786 12 13C12.7549 13.0082 13.5183 12.4629 13.5164 11.708C13.5158 11.4745 13.4773 11.2358 13.417 11.0163C13.3331 10.7108 13.3257 10.3595 13.5 10C14.1099 8.74254 15.3094 8.40477 16.2599 7.72186C16.6814 7.41898 17.0659 7.09947 17.2355 6.84211C17.7037 6.13158 18.1718 4.71053 17.9377 4")
    ])),
    path(toList([
      attribute2("stroke-width", "1.5"),
      attribute2("stroke", "currentColor"),
      attribute2("d", "M22 13C21.6706 13.931 21.4375 16.375 17.7182 16.4138C17.7182 16.4138 14.4246 16.4138 13.4365 18.2759C12.646 19.7655 13.1071 21.3793 13.4365 22")
    ]))
  ]));
}
function follows(classes) {
  return svg(toList([
    class$(classes),
    attribute2("fill", "none"),
    attribute2("stroke", "currentColor"),
    attribute2("viewBox", "0 0 24 24"),
    attribute2("xmlns", "http://www.w3.org/2000/svg")
  ]), toList([
    circle(toList([
      attribute2("cx", "8"),
      attribute2("cy", "8"),
      attribute2("r", "3"),
      attribute2("opacity", "0.6"),
      attribute2("stroke-width", "2")
    ])),
    circle(toList([
      attribute2("cx", "16"),
      attribute2("cy", "8"),
      attribute2("r", "3"),
      attribute2("opacity", "0.6"),
      attribute2("stroke-width", "2")
    ])),
    path(toList([
      attribute2("stroke-width", "2"),
      attribute2("stroke-linecap", "round"),
      attribute2("opacity", "0.6"),
      attribute2("stroke-linejoin", "round"),
      attribute2("d", "M2 20v-1a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v1")
    ])),
    path(toList([
      attribute2("stroke-width", "2"),
      attribute2("opacity", "0.6"),
      attribute2("stroke-linecap", "round"),
      attribute2("stroke-linejoin", "round"),
      attribute2("d", "M14 20v-1a4 4 0 0 1 4-4h0a4 4 0 0 1 4 4v1")
    ]))
  ]));
}
function mutuals(classes) {
  return svg(toList([
    class$(classes),
    attribute2("fill", "none"),
    attribute2("stroke", "currentColor"),
    attribute2("viewBox", "0 0 24 24"),
    attribute2("xmlns", "http://www.w3.org/2000/svg")
  ]), toList([
    path(toList([
      attribute2("stroke-width", "2"),
      attribute2("stroke-linecap", "round"),
      attribute2("stroke-linejoin", "round"),
      attribute2("d", "M9 19C5 15 2 12.5 2 9.5C2 7 4 5 6.5 5C8 5 9 6.5 9 6.5C9 6.5 10 5 11.5 5C14 5 16 7 16 9.5C16 12.5 13 15 9 19Z"),
      attribute2("opacity", "0.6")
    ])),
    path(toList([
      attribute2("stroke-width", "2"),
      attribute2("stroke-linecap", "round"),
      attribute2("stroke-linejoin", "round"),
      attribute2("d", "M15 4.5l2.09 4.24 4.68.68-3.39 3.3.8 4.63L15 15.77l-4.18 2.18.8-4.63-3.39-3.3 4.68-.68L15 4.5z"),
      attribute2("opacity", "0.6")
    ]))
  ]));
}
function pen(classes) {
  return svg(toList([
    attribute2("xmlns", "http://www.w3.org/2000/svg"),
    attribute2("fill", "none"),
    attribute2("viewBox", "0 0 24 24"),
    class$(classes)
  ]), toList([
    path(toList([
      attribute2("stroke-linecap", "round"),
      attribute2("stroke-width", "1.5"),
      attribute2("stroke", "currentColor"),
      attribute2("d", "M4 22H20")
    ])),
    path(toList([
      attribute2("stroke-width", "1.5"),
      attribute2("stroke", "currentColor"),
      attribute2("d", "M13.8881 3.66293L14.6296 2.92142C15.8581 1.69286 17.85 1.69286 19.0786 2.92142C20.3071 4.14999 20.3071 6.14188 19.0786 7.37044L18.3371 8.11195M13.8881 3.66293C13.8881 3.66293 13.9807 5.23862 15.3711 6.62894C16.7614 8.01926 18.3371 8.11195 18.3371 8.11195M13.8881 3.66293L7.07106 10.4799C6.60933 10.9416 6.37846 11.1725 6.17992 11.4271C5.94571 11.7273 5.74491 12.0522 5.58107 12.396C5.44219 12.6874 5.33894 12.9972 5.13245 13.6167L4.25745 16.2417M18.3371 8.11195L11.5201 14.9289C11.0584 15.3907 10.8275 15.6215 10.5729 15.8201C10.2727 16.0543 9.94775 16.2551 9.60398 16.4189C9.31256 16.5578 9.00282 16.6611 8.38334 16.8675L5.75834 17.7426M5.75834 17.7426L5.11667 17.9564C4.81182 18.0581 4.47573 17.9787 4.2485 17.7515C4.02128 17.5243 3.94194 17.1882 4.04356 16.8833L4.25745 16.2417M5.75834 17.7426L4.25745 16.2417")
    ]))
  ]));
}
function camera(classes) {
  return svg(toList([
    attribute2("xmlns", "http://www.w3.org/2000/svg"),
    attribute2("fill", "none"),
    attribute2("viewBox", "0 0 24 24"),
    class$(classes)
  ]), toList([
    circle(toList([
      attribute2("stroke-width", "1.5"),
      attribute2("stroke", "currentColor"),
      attribute2("r", "3"),
      attribute2("cy", "13"),
      attribute2("cx", "12")
    ])),
    path(toList([
      attribute2("stroke-width", "1.5"),
      attribute2("stroke", "currentColor"),
      attribute2("d", "M9.77778 21H14.2222C17.3433 21 18.9038 21 20.0248 20.2646C20.51 19.9462 20.9267 19.5371 21.251 19.0607C22 17.9601 22 16.4279 22 13.3636C22 10.2994 22 8.76721 21.251 7.6666C20.9267 7.19014 20.51 6.78104 20.0248 6.46268C19.3044 5.99013 18.4027 5.82123 17.022 5.76086C16.3631 5.76086 15.7959 5.27068 15.6667 4.63636C15.4728 3.68489 14.6219 3 13.6337 3H10.3663C9.37805 3 8.52715 3.68489 8.33333 4.63636C8.20412 5.27068 7.63685 5.76086 6.978 5.76086C5.59733 5.82123 4.69555 5.99013 3.97524 6.46268C3.48995 6.78104 3.07328 7.19014 2.74902 7.6666C2 8.76721 2 10.2994 2 13.3636C2 16.4279 2 17.9601 2.74902 19.0607C3.07328 19.5371 3.48995 19.9462 3.97524 20.2646C5.09624 21 6.65675 21 9.77778 21Z")
    ])),
    path(toList([
      attribute2("stroke-linecap", "round"),
      attribute2("stroke-width", "1.5"),
      attribute2("stroke", "currentColor"),
      attribute2("d", "M19 10H18")
    ]))
  ]));
}
function pen_paper(classes) {
  return svg(toList([
    attribute2("xmlns", "http://www.w3.org/2000/svg"),
    attribute2("fill", "none"),
    attribute2("viewBox", "0 0 24 24"),
    class$(classes)
  ]), toList([
    path(toList([
      attribute2("stroke-linecap", "round"),
      attribute2("stroke-width", "1.5"),
      attribute2("stroke", "currentColor"),
      attribute2("d", "M22 10.5V12C22 16.714 22 19.0711 20.5355 20.5355C19.0711 22 16.714 22 12 22C7.28595 22 4.92893 22 3.46447 20.5355C2 19.0711 2 16.714 2 12C2 7.28595 2 4.92893 3.46447 3.46447C4.92893 2 7.28595 2 12 2H13.5")
    ])),
    path(toList([
      attribute2("stroke-width", "1.5"),
      attribute2("stroke", "currentColor"),
      attribute2("d", "M16.652 3.45506L17.3009 2.80624C18.3759 1.73125 20.1188 1.73125 21.1938 2.80624C22.2687 3.88124 22.2687 5.62415 21.1938 6.69914L20.5449 7.34795M16.652 3.45506C16.652 3.45506 16.7331 4.83379 17.9497 6.05032C19.1662 7.26685 20.5449 7.34795 20.5449 7.34795M16.652 3.45506L10.6872 9.41993C10.2832 9.82394 10.0812 10.0259 9.90743 10.2487C9.70249 10.5114 9.52679 10.7957 9.38344 11.0965C9.26191 11.3515 9.17157 11.6225 8.99089 12.1646L8.41242 13.9M20.5449 7.34795L14.5801 13.3128C14.1761 13.7168 13.9741 13.9188 13.7513 14.0926C13.4886 14.2975 13.2043 14.4732 12.9035 14.6166C12.6485 14.7381 12.3775 14.8284 11.8354 15.0091L10.1 15.5876M10.1 15.5876L8.97709 15.9619C8.71035 16.0508 8.41626 15.9814 8.21744 15.7826C8.01862 15.5837 7.9492 15.2897 8.03811 15.0229L8.41242 13.9M10.1 15.5876L8.41242 13.9")
    ]))
  ]));
}
function hashtag_square(classes) {
  return svg(toList([
    attribute2("xmlns", "http://www.w3.org/2000/svg"),
    attribute2("fill", "none"),
    attribute2("viewBox", "0 0 24 24"),
    class$(classes)
  ]), toList([
    path(toList([
      attribute2("stroke-linejoin", "round"),
      attribute2("stroke-linecap", "round"),
      attribute2("stroke-width", "1.5"),
      attribute2("stroke", "currentColor"),
      attribute2("d", "M11 7L8 17")
    ])),
    path(toList([
      attribute2("stroke-linejoin", "round"),
      attribute2("stroke-linecap", "round"),
      attribute2("stroke-width", "1.5"),
      attribute2("stroke", "currentColor"),
      attribute2("d", "M16 7L13 17")
    ])),
    path(toList([
      attribute2("stroke-linejoin", "round"),
      attribute2("stroke-linecap", "round"),
      attribute2("stroke-width", "1.5"),
      attribute2("stroke", "currentColor"),
      attribute2("d", "M18 10H7")
    ])),
    path(toList([
      attribute2("stroke-linejoin", "round"),
      attribute2("stroke-linecap", "round"),
      attribute2("stroke-width", "1.5"),
      attribute2("stroke", "currentColor"),
      attribute2("d", "M17 14H6")
    ])),
    path(toList([
      attribute2("stroke-width", "1.5"),
      attribute2("stroke", "currentColor"),
      attribute2("d", "M2 12C2 7.28595 2 4.92893 3.46447 3.46447C4.92893 2 7.28595 2 12 2C16.714 2 19.0711 2 20.5355 3.46447C22 4.92893 22 7.28595 22 12C22 16.714 22 19.0711 20.5355 20.5355C19.0711 22 16.714 22 12 22C7.28595 22 4.92893 22 3.46447 20.5355C2 19.0711 2 16.714 2 12Z")
    ]))
  ]));
}
function add_square(classes) {
  return svg(toList([
    attribute2("xmlns", "http://www.w3.org/2000/svg"),
    attribute2("fill", "none"),
    attribute2("viewBox", "0 0 24 24"),
    class$(classes)
  ]), toList([
    path(toList([
      attribute2("stroke-width", "1.5"),
      attribute2("stroke", "currentColor"),
      attribute2("d", "M2 12C2 7.28595 2 4.92893 3.46447 3.46447C4.92893 2 7.28595 2 12 2C16.714 2 19.0711 2 20.5355 3.46447C22 4.92893 22 7.28595 22 12C22 16.714 22 19.0711 20.5355 20.5355C19.0711 22 16.714 22 12 22C7.28595 22 4.92893 22 3.46447 20.5355C2 19.0711 2 16.714 2 12Z")
    ])),
    path(toList([
      attribute2("stroke-linecap", "round"),
      attribute2("stroke-width", "1.5"),
      attribute2("stroke", "currentColor"),
      attribute2("d", "M15 12L12 12M12 12L9 12M12 12L12 9M12 12L12 15")
    ]))
  ]));
}
function archive_box(classes) {
  return svg(toList([
    attribute2("xmlns", "http://www.w3.org/2000/svg"),
    attribute2("fill", "none"),
    attribute2("viewBox", "0 0 24 24"),
    class$(classes)
  ]), toList([
    path(toList([
      attribute2("stroke-width", "1.5"),
      attribute2("stroke", "currentColor"),
      attribute2("d", "M9 12C9 11.5341 9 11.3011 9.07612 11.1173C9.17761 10.8723 9.37229 10.6776 9.61732 10.5761C9.80109 10.5 10.0341 10.5 10.5 10.5H13.5C13.9659 10.5 14.1989 10.5 14.3827 10.5761C14.6277 10.6776 14.8224 10.8723 14.9239 11.1173C15 11.3011 15 11.5341 15 12C15 12.4659 15 12.6989 14.9239 12.8827C14.8224 13.1277 14.6277 13.3224 14.3827 13.4239C14.1989 13.5 13.9659 13.5 13.5 13.5H10.5C10.0341 13.5 9.80109 13.5 9.61732 13.4239C9.37229 13.3224 9.17761 13.1277 9.07612 12.8827C9 12.6989 9 12.4659 9 12Z")
    ])),
    path(toList([
      attribute2("stroke-linecap", "round"),
      attribute2("stroke-width", "1.5"),
      attribute2("stroke", "currentColor"),
      attribute2("d", "M20.5 7V13C20.5 16.7712 20.5 18.6569 19.3284 19.8284C18.1569 21 16.2712 21 12.5 21H11.5C7.72876 21 5.84315 21 4.67157 19.8284C3.5 18.6569 3.5 16.7712 3.5 13V7")
    ])),
    path(toList([
      attribute2("stroke-width", "1.5"),
      attribute2("stroke", "currentColor"),
      attribute2("d", "M2 5C2 4.05719 2 3.58579 2.29289 3.29289C2.58579 3 3.05719 3 4 3H20C20.9428 3 21.4142 3 21.7071 3.29289C22 3.58579 22 4.05719 22 5C22 5.94281 22 6.41421 21.7071 6.70711C21.4142 7 20.9428 7 20 7H4C3.05719 7 2.58579 7 2.29289 6.70711C2 6.41421 2 5.94281 2 5Z")
    ]))
  ]));
}
function sources_solar_linear() {
  let _pipe = sourcelist_solar_linear;
  return shuffle(_pipe);
}

// build/dev/javascript/lumina_client/lumina_client/view/homepage/post_editor.mjs
function text_post_editor(params, _) {
  return div(toList([]), toList([text3("This is the text post editor!")]));
}
function media_post_editor(params, _) {
  return div(toList([]), toList([text3("This is the media post editor!")]));
}
function article_post_editor(params, _) {
  return div(toList([]), toList([text3("This is the article post editor!")]));
}
function main2(params, model) {
  return div(toList([class$("tabs tabs-lift h-full")]), toList([
    label(toList([class$("tab")]), toList([
      input(toList([
        name("editortypeswitch"),
        type_("radio")
      ])),
      camera("class size-4 me-2"),
      text3(" Snap ")
    ])),
    label(toList([class$("tab")]), toList([
      input(toList([
        name("editortypeswitch"),
        type_("radio"),
        checked(true)
      ])),
      pen("class size-4 me-2"),
      text3(" Jot ")
    ])),
    div(toList([
      class$("tab-content bg-base-100 border-base-300 p-6")
    ]), toList([text_post_editor(params, model)])),
    div(toList([
      class$("tab-content bg-base-100 border-base-300 p-6")
    ]), toList([media_post_editor(params, model)])),
    label(toList([class$("tab")]), toList([
      input(toList([
        name("editortypeswitch"),
        type_("radio")
      ])),
      pen_paper("class size-4 me-2"),
      text3(" Compose ")
    ])),
    div(toList([
      class$("tab-content bg-base-100 border-base-300 p-6")
    ]), toList([article_post_editor(params, model)]))
  ]));
}

// build/dev/javascript/lumina_client/lumina_client/view/homepage/posts.mjs
var FILEPATH = "src/lumina_client/view/homepage/posts.gleam";
function element_from_id(model, post_id) {
  let post = map_get(model.cache.cached_posts, post_id);
  return div(toList([
    class$("flex flex-col gap-2 p-4 m-8 bg-base-300 text-base-300-content rounded-md w-full bg-opacity-25 font-content")
  ]), (() => {
    let _block;
    if (post instanceof Ok) {
      throw makeError("todo", FILEPATH, "lumina_client/view/homepage/posts", 41, "element_from_id", "Post rendering not yet implemented", {});
    } else {
      _block = toList([
        p(toList([]), toList([
          text2("Loading post..."),
          span(toList([
            class$("loading loading-spinner loading-md float-right")
          ]), toList([]))
        ]))
      ]);
    }
    let _pipe = _block;
    return append(_pipe, toList([
      small(toList([class$("opacity-50 text-xs font-script")]), toList([text2("ID:" + post_id)]))
    ]));
  })());
}

// build/dev/javascript/lumina_client/lumina_client/view/homepage.mjs
var FILEPATH2 = "src/lumina_client/view/homepage.gleam";

class Right extends CustomType {
}
class CentralBig extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}

class CentralSmall extends CustomType {
  constructor(id2, title, containing, closeable, params) {
    super();
    this.id = id2;
    this.title = title;
    this.containing = containing;
    this.closeable = closeable;
    this.params = params;
  }
}

class SideOrCentral extends CustomType {
  constructor($0, $1) {
    super();
    this[0] = $0;
    this[1] = $1;
  }
}

class NoModal extends CustomType {
}
function closemodal_not_for_modal_box() {
  return field("target", dynamic, (target2) => {
    let $ = negate2(classfoundintree(target2, "modal-box"));
    if ($) {
      return success(new UserClosedModal);
    } else {
      return failure(new UserClosedModal, "Clicked inside modal-box, ignoring");
    }
  });
}
function get_all_posts(timeline) {
  let _pipe = timeline.pages;
  let _pipe$1 = map_to_list(_pipe);
  let _pipe$2 = sort(_pipe$1, (a2, b) => {
    let page_a;
    page_a = a2[0];
    let page_b;
    page_b = b[0];
    let $ = page_a < page_b;
    if ($) {
      return new Lt;
    } else {
      let $1 = page_a === page_b;
      if ($1) {
        return new Eq;
      } else {
        return new Gt;
      }
    }
  });
  let _pipe$3 = map2(_pipe$2, (x) => {
    let posts;
    posts = x[1];
    return posts;
  });
  return flatten(_pipe$3);
}
function timeline(model) {
  let timeline_name;
  let cache;
  let $ = model.page;
  if ($ instanceof HomeTimeline) {
    cache = model.cache;
    timeline_name = $.timeline_name;
  } else {
    throw makeError("let_assert", FILEPATH2, "lumina_client/view/homepage", 473, "timeline", "Pattern match failed, no pattern matched the value.", {
      value: model,
      start: 16385,
      end: 16506,
      pattern_start: 16396,
      pattern_end: 16498
    });
  }
  let timeline_name$1 = unwrap(timeline_name, "global");
  let timeline_posts = map_get(cache.cached_timelines, timeline_name$1);
  if (timeline_posts instanceof Ok) {
    let cached_timeline = timeline_posts[0];
    let post_ids = get_all_posts(cached_timeline);
    let show_load_more = cached_timeline.has_more;
    return div(toList([class$("flex w-4/6 flex-col gap-4 items-start")]), (() => {
      if (post_ids instanceof Empty) {
        return toList([
          div(toList([class$("justify-center p-4")]), toList([
            text2("This timeline is empty! Make sure to fill it!")
          ]))
        ]);
      } else {
        let post_elements = map2(post_ids, (_capture) => {
          return element_from_id(model, _capture);
        });
        if (show_load_more) {
          return append(post_elements, toList([
            div(toList([class$("flex justify-center p-4")]), toList([
              button(toList([
                class$("btn btn-primary font-menuitems"),
                on_click(new LoadMorePosts(timeline_name$1))
              ]), toList([text2("Load More Posts")]))
            ]))
          ]));
        } else {
          return post_elements;
        }
      }
    })());
  } else {
    return div(toList([class$("flex w-4/6 flex-col gap-4 items-start")]), toList([
      text2('Loading timeline "' + timeline_name$1 + '" ...'),
      div(toList([class$("skeleton h-32 w-full")]), toList([])),
      div(toList([class$("skeleton h-4 w-28")]), toList([])),
      div(toList([class$("skeleton h-4 w-full")]), toList([])),
      div(toList([class$("skeleton h-32 w-full")]), toList([])),
      div(toList([class$("skeleton h-4 w-28")]), toList([])),
      div(toList([class$("skeleton h-4 w-full")]), toList([])),
      div(toList([class$("skeleton h-4 w-full")]), toList([])),
      div(toList([class$("skeleton h-32 w-full")]), toList([])),
      div(toList([class$("skeleton h-4 w-28")]), toList([])),
      div(toList([class$("skeleton h-4 w-full")]), toList([])),
      div(toList([class$("skeleton h-32 w-full")]), toList([])),
      div(toList([class$("skeleton h-4 w-28")]), toList([])),
      div(toList([class$("skeleton h-4 w-full")]), toList([])),
      text2("Skeleton should be remodeled after the actual post view later.")
    ]));
  }
}
function get_highest_cached_page(timeline2) {
  let _pipe = timeline2.pages;
  let _pipe$1 = keys(_pipe);
  return fold2(_pipe$1, 0, (max2, page) => {
    let $ = page > max2;
    if ($) {
      return page;
    } else {
      return max2;
    }
  });
}
function get_cached_posts_count(timeline2) {
  let _pipe = timeline2.pages;
  let _pipe$1 = values(_pipe);
  let _pipe$2 = map2(_pipe$1, length);
  return fold2(_pipe$2, 0, (acc, count) => {
    return acc + count;
  });
}
function should_load_more(timeline2, position, lookahead) {
  let cached_count = get_cached_posts_count(timeline2);
  let needs_more = position + lookahead >= cached_count;
  return needs_more && timeline2.has_more;
}
function create_empty_timeline() {
  return new CachedTimeline("", new_map(), 0, 0, false, 0);
}
function add_page_to_timeline(timeline2, tlid, page, posts, total_count, has_more) {
  return new CachedTimeline(tlid, (() => {
    let _pipe = timeline2.pages;
    return insert(_pipe, page, posts);
  })(), total_count, page, has_more, truncate(to_unix_seconds(system_time2())));
}
function get_next_page_to_load(timeline2) {
  let $ = timeline2.has_more;
  if ($) {
    let highest_page = get_highest_cached_page(timeline2);
    return new Some(highest_page + 1);
  } else {
    return new None;
  }
}
function timeline_info_string(timeline2, timeline_name) {
  let cached_count = get_cached_posts_count(timeline2);
  let highest_page = get_highest_cached_page(timeline2);
  return "Timeline '" + timeline_name + "': " + to_string(cached_count) + "/" + to_string(timeline2.total_count) + " posts cached, pages 0-" + to_string(highest_page) + ", has_more: " + to_string3(timeline2.has_more);
}
function modal_by_id(f, model) {
  let id2;
  let params;
  id2 = f[0];
  params = f[1];
  let user;
  let $ = model.user;
  if ($ instanceof Some) {
    let $1 = model.page;
    if ($1 instanceof HomeTimeline) {
      user = $[0];
    } else {
      throw makeError("let_assert", FILEPATH2, "lumina_client/view/homepage", 761, "modal_by_id", "Pattern match failed, no pattern matched the value.", {
        value: model,
        start: 24954,
        end: 25094,
        pattern_start: 24965,
        pattern_end: 25079
      });
    }
  } else {
    throw makeError("let_assert", FILEPATH2, "lumina_client/view/homepage", 761, "modal_by_id", "Pattern match failed, no pattern matched the value.", {
      value: model,
      start: 24954,
      end: 25094,
      pattern_start: 24965,
      pattern_end: 25079
    });
  }
  if (id2 === "test") {
    return new CentralBig(div(toList([]), toList([
      text2("Welcome to Lumina! This is a test modal screen.")
    ])));
  } else if (id2 === "selfmenu") {
    return new SideOrCentral(new Right, ul(toList([
      class$("menu menu-xl rounded-box w-2/3 justify-center text-center items-center space-y-4")
    ]), toList([
      li(toList([class$("menu-title")]), toList([text2("Hi, @" + user.username)])),
      li(toList([]), toList([text2("There's not much in this menu as of yet.")])),
      li(toList([class$("md:hidden")]), toList([
        a(toList([
          class$("btn btn-info font-menuitems"),
          on_click(new SetModal("selfsettings"))
        ]), toList([text2("Settings")]))
      ])),
      li(toList([]), toList([
        a(toList([
          class$("btn btn-warn font-menuitems"),
          on_click(new UserClickedLogout)
        ]), toList([text2("Log out")]))
      ]))
    ])));
  } else if (id2 === "selfsettings") {
    return new CentralBig(div(toList([]), toList([text2("User settings will be here eventually.")])));
  } else if (id2 === "mdl-postedit") {
    return new CentralSmall("mdl-postedit", "New Post", main2(params, model), true, params);
  } else {
    return new NoModal;
  }
}
function view(model) {
  let timeline_name;
  let modal;
  let user;
  let $ = model.page;
  if ($ instanceof HomeTimeline) {
    user = model.user;
    timeline_name = $.timeline_name;
    modal = $.modal;
  } else {
    throw makeError("let_assert", FILEPATH2, "lumina_client/view/homepage", 57, "view", "Pattern match failed, no pattern matched the value.", {
      value: model,
      start: 2141,
      end: 2259,
      pattern_start: 2152,
      pattern_end: 2251
    });
  }
  return ((_capture) => {
    return lazy_guard(is_some(user), _capture, () => {
      return text2("Loading user...");
    });
  })(() => {
    let user$1;
    if (user instanceof Some) {
      user$1 = user[0];
    } else {
      throw makeError("let_assert", FILEPATH2, "lumina_client/view/homepage", 66, "view", "User must be logged in to see homepage, got None from model where a user-submodel was expected. (Got past a guard?)", {
        value: user,
        start: 2368,
        end: 2396,
        pattern_start: 2379,
        pattern_end: 2389
      });
    }
    let timeline_name$1 = unwrap(timeline_name, "global");
    let _block;
    let $1 = (() => {
      let _pipe2 = modal;
      let _pipe$1 = map(_pipe2, (_capture) => {
        return modal_by_id(_capture, model);
      });
      return unwrap(_pipe$1, new NoModal);
    })();
    if ($1 instanceof CentralBig) {
      let mod = $1[0];
      _block = div(toList([
        class$("modal modal-open fixed inset-0 flex items-center justify-center z-50 bg-black bg-opacity-50 w-screen h-screen"),
        on("click", closemodal_not_for_modal_box())
      ]), toList([
        div(toList([
          class$("modal-box w-[99vw] lg:w-[80vw] max-w-[unset] h-[80lvh] flex flex-col justify-center items-center bg-base-100 shadow-2xl relative")
        ]), toList([
          button(toList([
            class$("btn rounded-none rounded-bl-sm btn-error absolute top-0 right-0 text-2xl"),
            on_click(new UserClosedModal)
          ]), toList([text2("×")])),
          mod,
          div(toList([class$("modal-action")]), toList([]))
        ]))
      ]));
    } else if ($1 instanceof CentralSmall) {
      let id2 = $1.id;
      let title = $1.title;
      let mod = $1.containing;
      let closable = $1.closeable;
      let params = $1.params;
      let def_x = get_center_positioned_style_px()[1];
      let def_y = get_center_positioned_style_px()[0];
      let set_x = map_get(params, "pos_x");
      let set_y = map_get(params, "pos_y");
      let _block$1;
      if (set_x instanceof Ok) {
        let v = set_x[0];
        let _pipe2 = parse_float(v);
        _block$1 = unwrap2(_pipe2, def_x);
      } else {
        _block$1 = def_x;
      }
      let pos_x = _block$1;
      let _block$2;
      if (set_y instanceof Ok) {
        let v = set_y[0];
        let _pipe2 = parse_float(v);
        _block$2 = unwrap2(_pipe2, def_y);
      } else {
        _block$2 = def_y;
      }
      let pos_y = _block$2;
      _block = div(toList([
        class$("modal modal-open fixed inset-0 flex items-center justify-center z-50 bg-black bg-opacity-50 w-screen h-screen"),
        on("click", closemodal_not_for_modal_box())
      ]), toList([
        div(toList([
          id(id2),
          class$("modal-box lg:freeroam flex flex-col justify-center items-center bg-base-100 shadow-2xl w-[99vw] lg:w-[32rem] max-w-[unset] lg:max-w-[99vw] h-[80lvh] lg:h-[80lvh] lg:max-h-[90vh] relative lg:absolute"),
          style("--left", (() => {
            let _pipe2 = pos_x;
            return float_to_string(_pipe2);
          })() + "px"),
          style("--top", (() => {
            let _pipe2 = pos_y;
            return float_to_string(_pipe2);
          })() + "px"),
          style("--transform", "translate(-50%, -50%)")
        ]), toList([
          section(toList([
            class$("w-full h-10 absolute top-0 left-0 bg-transparent cursor-move bg-info text-info-content rounded-t-xl flex items-center justify-center"),
            on_mouse_down(new StartDraggingModalBox(pos_x, pos_y))
          ]), toList([text2(title)])),
          (() => {
            if (closable) {
              return button(toList([
                class$("btn rounded-none rounded-bl-sm btn-error absolute top-0 right-0 text-2xl"),
                on_click(new UserClosedModal)
              ]), toList([text2("×")]));
            } else {
              return none3();
            }
          })(),
          div(toList([class$("w-full h-full mt-10")]), toList([mod]))
        ]))
      ]));
    } else if ($1 instanceof SideOrCentral) {
      let $2 = $1[0];
      if ($2 instanceof Right) {
        let mod = $1[1];
        _block = div(toList([
          class$("modal modal-open fixed top-[4rem] right-0 left-0 bottom-0 flex items-end justify-end z-50 bg-black bg-opacity-50 w-screen max-h-[calc(100vh-4rem)]"),
          on("click", closemodal_not_for_modal_box())
        ]), toList([
          div(toList([
            class$("modal-box w-[24rem]  lg:max-h-[calc(100vh-4rem)] flex flex-col justify-start items-center bg-base-100 shadow-2xl relative rounded-xl md:max-h-[calc(100vh-4rem)] h-[60vh] max-h-[60vh] mb-[20vh]")
          ]), toList([
            button(toList([
              class$("btn rounded-none rounded-bl-sm btn-error absolute top-0 right-0 text-2xl"),
              on_click(new UserClosedModal)
            ]), toList([text2("×")])),
            mod,
            div(toList([class$("modal-action")]), toList([]))
          ]))
        ]));
      } else {
        let mod = $1[1];
        _block = div(toList([
          class$("modal modal-open fixed top-[4rem] right-0 left-0 bottom-0 flex items-end justify-start z-50 bg-black bg-opacity-50 w-screen max-h-[calc(100vh-4rem)]"),
          on("click", closemodal_not_for_modal_box())
        ]), toList([
          div(toList([
            class$("modal-box w-[24rem] lg:max-h-[calc(100vh-4rem)] flex flex-col justify-start items-center bg-base-100 shadow-2xl relative rounded-xl md:max-h-[calc(100vh-4rem)] h-[60vh] max-h-[60vh] mb-[20vh]")
          ]), toList([
            button(toList([
              class$("btn btn-circle btn-error absolute top-4 right-4 text-2xl"),
              on_click(new UserClosedModal)
            ]), toList([text2("×")])),
            mod,
            div(toList([class$("modal-action")]), toList([]))
          ]))
        ]));
      }
    } else {
      _block = div(toList([class$("items")]), toList([
        div(toList([class$("dock lg:hidden")]), toList([
          label(toList([
            class$("drawer-button"),
            for$("timelineswitcher")
          ]), toList([
            hashtag_square("size-[1.2em]"),
            span(toList([class$("dock-label")]), toList([text3("Switch")]))
          ])),
          button(toList([
            class$(""),
            on_click(new SetModal("mdl-postedit"))
          ]), toList([
            add_square("size-[1.2em]"),
            span(toList([class$("dock-label")]), toList([text3("Create")]))
          ])),
          button(toList([]), toList([
            div(toList([class$("indicator")]), toList([
              (() => {
                let $2 = user$1.notifs.unread_count;
                if ($2 === 0) {
                  return none3();
                } else {
                  let n = $2;
                  return span(toList([
                    class$("indicator-item badge badge-secondary")
                  ]), toList([text3(to_string(n))]));
                }
              })(),
              archive_box("size-[1.2em]")
            ])),
            span(toList([class$("dock-label")]), toList([text3("Notifications")]))
          ]))
        ])),
        div(toList([
          class$("absolute bottom-4 right-4 p-4 z-50 hidden lg:block")
        ]), toList([
          button(toList([
            class$("btn btn-circle btn-success btn-lg text-3xl"),
            id("btn-new-post"),
            on_click(new SetModal("mdl-postedit"))
          ]), toList([text2("+")]))
        ])),
        div(toList([class$("fixed bottom-20 right-4 p-4 z-50 ")]), toList([]))
      ]));
    }
    let modal_element = _block;
    let _pipe = toList([
      modal_element,
      div(toList([
        class$("drawer lg:drawer-open max-h-[calc(100vh-4rem)]")
      ]), toList([
        input(toList([
          class$("drawer-toggle"),
          type_("checkbox"),
          id("timelineswitcher")
        ])),
        main(toList([
          class$("drawer-content items-center flex flex-col bg-neutral text-neutral-content h-screen max-h-[calc(100vh-4rem)] overflow-y-auto" + (() => {
            let rn = system_time2();
            let $2 = to_calendar(rn, local_offset());
            let year;
            let month;
            let day;
            year = $2[0].year;
            month = $2[0].month;
            day = $2[0].day;
            return " " + ("yearclass-" + to_string(year)) + " " + (() => {
              if (month instanceof January) {
                return "monthclass-1";
              } else if (month instanceof February) {
                return "monthclass-2";
              } else if (month instanceof March) {
                return "monthclass-3";
              } else if (month instanceof April) {
                return "monthclass-4";
              } else if (month instanceof May) {
                return "monthclass-5";
              } else if (month instanceof June) {
                return "monthclass-6";
              } else if (month instanceof July) {
                return "monthclass-7";
              } else if (month instanceof August) {
                return "monthclass-8";
              } else if (month instanceof September) {
                return "monthclass-9";
              } else if (month instanceof October) {
                return "monthclass-10";
              } else if (month instanceof November) {
                return "monthclass-11";
              } else {
                return "monthclass-12";
              }
            })() + " " + ("dayclass-" + to_string(day));
          })())
        ]), toList([timeline(model)])),
        div(toList([class$("drawer-side font-menuitems")]), toList([
          label(toList([
            class$("drawer-overlay"),
            attribute2("aria-label", "close sidebar"),
            for$("timelineswitcher")
          ]), toList([])),
          ul(toList([
            class$("menu bg-base-200 bg-opacity-75 text-base-content h-screen lg:max-h-[calc(100vh-4rem)] w-80 p-4")
          ]), toList([
            li(toList([class$("menu-title font-sans")]), toList([text2("Timeline")])),
            ul(toList([]), toList([
              li(toList([]), toList([
                a(toList([
                  lazy_guard(timeline_name$1 === "global", () => {
                    return class$("menu-active");
                  }, () => {
                    return none();
                  }),
                  on_click(new UserSwitchedTimeLineTo("global"))
                ]), toList([
                  globe("inline h-5 w-5 mr-2"),
                  text2("Global")
                ]))
              ])),
              li(toList([]), toList([
                a(toList([
                  lazy_guard(timeline_name$1 === "following", () => {
                    return class$("menu-active");
                  }, () => {
                    return none();
                  }),
                  on_click(new UserSwitchedTimeLineTo("following"))
                ]), toList([
                  follows("inline h-5 w-5 mr-2"),
                  text2("Following")
                ]))
              ])),
              li(toList([]), toList([
                a(toList([
                  lazy_guard(timeline_name$1 === "mutuals", () => {
                    return class$("menu-active");
                  }, () => {
                    return none();
                  }),
                  on_click(new UserSwitchedTimeLineTo("mutuals"))
                ]), toList([
                  mutuals("inline h-5 w-5 mr-2"),
                  text2("Mutuals")
                ]))
              ]))
            ]))
          ]))
        ]))
      ]))
    ]);
    return common_view_parts(_pipe, toList([
      li(toList([
        class$("hidden md:flex"),
        on_click(new SetModal("selfsettings"))
      ]), toList([
        button(toList([class$("btn md:btn-neutral btn-ghost")]), toList([text2("Settings")]))
      ])),
      li(toList([]), toList([
        button(toList([
          class$("btn md:btn-neutral btn-ghost"),
          on_click(new SetModal("selfmenu"))
        ]), toList([
          span(toList([class$("hidden md:inline")]), toList([text2("@" + user$1.username)])),
          div(toList([class$("avatar")]), toList([
            div(toList([class$("h-8 w-8 mask-squircle mask")]), toList([
              img(toList([
                src(user$1.avatar),
                alt(user$1.username)
              ]))
            ]))
          ]))
        ]))
      ]))
    ]));
  });
}

// build/dev/javascript/lumina_client/lumina_client/view.mjs
var FILEPATH3 = "src/lumina_client/view.gleam";
function attributions() {
  return div(toList([class$("overflow-y-auto max-h-[45vh]")]), toList([
    ul(toList([]), toList([
      li(toList([
        class$("card block bg-neutral p-4 mb-4 rounded-lg")
      ]), toList([
        h4(toList([class$("text-lg font-bold mb-2")]), toList([text3("Icons from SVGrepo.com")])),
        h5(toList([class$("text-[1.100rem] font-bold mb-2")]), toList([text3("Solar Linear icon set")])),
        div(toList([class$("flex flex-row items-center w-full")]), (() => {
          let _pipe = sources_solar_linear();
          return map2(_pipe, (am) => {
            let svg_fn;
            let link;
            svg_fn = am[0];
            link = am[1];
            return a(toList([href(link)]), toList([svg_fn("w-6 h-6 me-2 hover:scale-110")]));
          });
        })()),
        text3("Vectors and icons by "),
        a(toList([
          target("_blank"),
          class$("link"),
          href("https://www.figma.com/community/file/1166831539721848736?ref=svgrepo.com")
        ]), toList([text3("Solar Icons")])),
        text3(" in CC Attribution License via "),
        a(toList([
          class$("link"),
          target("_blank"),
          href("https://www.svgrepo.com/")
        ]), toList([text3("SVG Repo")]))
      ])),
      li(toList([
        class$("card block bg-neutral p-4 mb-4 rounded-lg")
      ]), toList([
        h4(toList([class$("text-lg font-bold mb-2")]), toList([
          img(toList([
            src("https://gleam.run/images/lucy/lucy.svg"),
            class$("inline-block w-5 h-auto ms-2 align-middle")
          ])),
          text3("Gleam")
        ])),
        text2("Much thanks to the "),
        a(toList([
          href("https://gleam.run/"),
          class$("link ")
        ]), toList([text3("Gleam programming language")])),
        text2(" and its community!")
      ])),
      li(toList([
        class$("card block bg-neutral p-4 mb-4 rounded-lg")
      ]), toList([
        h4(toList([class$("text-lg font-bold mb-2")]), toList([text3("Fonts used")])),
        ul(toList([class$("list-disc list-inside")]), toList([
          li(toList([]), toList([
            span(toList([]), toList([
              a(toList([
                href("https://fonts.google.com/specimen/Vend+Sans"),
                class$("link font-sans")
              ]), toList([text3("Vend Sans")])),
              text2("  "),
              span(toList([
                class$("badge badge-xs badge-soft badge-secondary text-xs")
              ]), toList([text2("font-sans")]))
            ])),
            p(toList([class$("text-xs")]), toList([
              text2("Designed by Bloom Type Foundry and Baptiste Guesnon under SIL Open Font License.")
            ]))
          ])),
          li(toList([]), toList([
            span(toList([]), toList([
              a(toList([
                href("https://fonts.google.com/specimen/Gantari"),
                class$("link  font-logo")
              ]), toList([text3("Gantari")])),
              text2("  "),
              span(toList([
                class$("badge badge-xs badge-soft badge-secondary text-xs")
              ]), toList([text2("font-logo")]))
            ])),
            p(toList([class$("text-xs")]), toList([text2("Designed by Lafontype")]))
          ])),
          li(toList([]), toList([
            span(toList([]), toList([
              a(toList([
                href("https://fonts.google.com/specimen/Elms+Sans"),
                class$("link  font-content")
              ]), toList([text3("Elms Sans")])),
              text2("  "),
              span(toList([
                class$("badge badge-xs badge-soft badge-secondary text-xs")
              ]), toList([text2("font-content")]))
            ])),
            p(toList([class$("text-xs")]), toList([
              text2("Designed by Amarachi Nwauwa under SIL Open Font License")
            ]))
          ])),
          li(toList([]), toList([
            span(toList([]), toList([
              a(toList([
                href("https://fonts.google.com/specimen/Josefin+Sans"),
                class$("link  font-menuitems")
              ]), toList([text3("Josefin Sans")])),
              text2("  "),
              span(toList([
                class$("badge badge-xs badge-soft badge-secondary text-xs")
              ]), toList([text2("font-menuitems")]))
            ])),
            p(toList([class$("text-xs")]), toList([
              text2("Designed by Santiago Orozco under SIL Open Font License")
            ]))
          ])),
          li(toList([]), toList([
            span(toList([]), toList([
              a(toList([
                href("https://fonts.google.com/specimen/DM+Mono"),
                class$("link  font-script")
              ]), toList([text3("DM Mono")])),
              text2("  "),
              span(toList([
                class$("badge badge-xs badge-soft badge-secondary text-xs")
              ]), toList([text2("font-script")]))
            ])),
            p(toList([class$("text-xs")]), toList([
              text2("Designed by Colophon Foundry under SIL Open Font License")
            ]))
          ]))
        ]))
      ]))
    ]))
  ]));
}
function view_landing() {
  let _pipe = toList([
    div(toList([
      class$("hero h-screen max-h-[calc(100vh-4rem)] overflow-auto")
    ]), toList([
      div(toList([class$("hero-content text-center")]), toList([
        div(toList([class$("max-w-md")]), toList([
          h1(toList([class$("text-5xl font-bold")]), toList([text2("Welcome to Lumina!")])),
          p(toList([class$("py-6")]), toList([
            text2("This should be a nice landing page, but I don't know what to put here right now. Go away! Skram!")
          ])),
          button(toList([
            class$("btn btn-primary font-menuitems"),
            on_click(new UserNavigatedToLoginPage)
          ]), toList([text2("Login")])),
          button(toList([
            class$("btn btn-secondary font-menuitems"),
            on_click(new UserNavigatedToRegisterPage)
          ]), toList([text2("Register")]))
        ]))
      ]))
    ])),
    input(toList([
      class$("modal-toggle"),
      id("landing-attributions-show"),
      type_("checkbox")
    ])),
    div(toList([role("dialog"), class$("modal")]), toList([
      div(toList([class$("modal-box max-h-[70VH] overflow-y-clip")]), toList([
        h3(toList([class$("text-lg font-bold")]), toList([text3("Attributions")])),
        p(toList([class$("py-4")]), toList([attributions()])),
        div(toList([class$("modal-action")]), toList([
          label(toList([
            class$("btn btn-error font-menuitems"),
            for$("landing-attributions-show")
          ]), toList([text3("Close")]))
        ]))
      ]))
    ])),
    footer(toList([
      class$("absolute footer footer-center p-4 bg-base-300 text-base-content bottom-0")
    ]), toList([
      div(toList([]), toList([
        p(toList([]), toList([
          text2("The Lumina/Peonies project, by MLC 'Strawmelonjuice' Bloeiman and contributors. "),
          a(toList([
            href("/licence"),
            class$("link link-neutral-content")
          ]), toList([
            text2("Licensed under the European Union Public Licence, with special notice for AI usage.")
          ])),
          text2(".")
        ])),
        p(toList([]), toList([
          text2("Also uses some CC-BY and other open-source assets, "),
          label(toList([
            class$("link link-neutral-content"),
            for$("landing-attributions-show")
          ]), toList([text3("see attributions")])),
          text2(".")
        ]))
      ]))
    ]))
  ]);
  return common_view_parts(_pipe, toList([]));
}
function view_login(model) {
  let $ = model.page;
  let fieldvalues;
  let successful;
  if ($ instanceof Login) {
    fieldvalues = $.fields;
    successful = $.success;
  } else {
    throw makeError("let_assert", FILEPATH3, "lumina_client/view", 477, "view_login", "Pattern match failed, no pattern matched the value.", {
      value: $,
      start: 15758,
      end: 15812,
      pattern_start: 15769,
      pattern_end: 15799
    });
  }
  let values_ok = login_view_checker(fieldvalues);
  let _pipe = toList([
    div(toList([
      class$("hero h-screen max-h-[calc(100vh-4rem)] overflow-auto")
    ]), toList([
      div(toList([
        class$("hero-content flex-col lg:flex-row-reverse")
      ]), toList([
        div(toList([class$("text-center lg:text-left")]), toList([
          h1(toList([class$("text-5xl font-bold")]), toList([text2("Log in to Lumina!")])),
          p(toList([class$("py-6")]), toList([
            text2("And we have boiling water. I REALLY don't know what to put here right now.")
          ]))
        ])),
        div(toList([
          class$("card w-full max-w-sm shrink-0 shadow-2xl transition-colors bg-neutral")
        ]), toList([
          form(toList([
            class$("card-body m-4 transition-[height] duration-300 ease-in-out transition"),
            on_submit((var0) => {
              return new UserSubmittedLogin(var0);
            })
          ]), toList([
            fieldset(toList([class$("fieldset")]), toList([
              label(toList([class$("fieldset-label")]), toList([text2("Email or username")])),
              input(toList([
                placeholder("me@mymail.com"),
                class$("input input-primary bg-primary font-content"),
                type_("text"),
                value(fieldvalues.emailfield),
                on_input((var0) => {
                  return new UserUpdatedControlledEmailField(var0);
                }),
                on("focusout", success(new EmailFieldLostFocus))
              ])),
              label(toList([class$("fieldset-label")]), toList([text2("Password")])),
              input(toList([
                value(fieldvalues.passwordfield),
                on_input((var0) => {
                  return new UserUpdatedControlledPasswordField(var0);
                }),
                placeholder("Password"),
                class$("input input-primary bg-primary font-content"),
                type_("password")
              ])),
              div(toList([]), toList([
                a(toList([class$("link link-hover")]), toList([text2("Forgot password?")]))
              ])),
              (() => {
                if (successful instanceof Some) {
                  let $1 = successful[0];
                  if (!$1) {
                    return div(toList([
                      class$("text-error-content bg-error p-3 rounded-lg")
                    ]), toList([
                      text2("Incorrect password and/or username!")
                    ]));
                  } else {
                    return none3();
                  }
                } else {
                  return none3();
                }
              })(),
              button((() => {
                if (values_ok) {
                  return toList([
                    class$("btn btn-accent w-full mt-4 font-menuitems"),
                    type_("submit")
                  ]);
                } else {
                  return toList([
                    class$("btn btn-accent w-full mt-4 btn-disabled font-menuitems bg-accent hidden"),
                    disabled(true)
                  ]);
                }
              })(), toList([text2("Login")]))
            ]))
          ]))
        ]))
      ]))
    ]))
  ]);
  return common_view_parts(_pipe, toList([
    li(toList([on_click(new UserNavigatedToLandingPage)]), toList([a(toList([]), toList([text2("Back")]))])),
    li(toList([on_click(new UserNavigatedToRegisterPage)]), toList([a(toList([]), toList([text2("Register")]))])),
    li(toList([on_click(new UserNavigatedToLoginPage)]), toList([
      a(toList([class$("bg-primary text-primary-content")]), toList([text2("Login")]))
    ]))
  ]));
}
function view_register(model_) {
  let $ = model_.page;
  let fieldvalues;
  let ready;
  if ($ instanceof Register) {
    fieldvalues = $.fields;
    ready = $.ready;
  } else {
    throw makeError("let_assert", FILEPATH3, "lumina_client/view", 604, "view_register", "Pattern match failed, no pattern matched the value.", {
      value: $,
      start: 20770,
      end: 20840,
      pattern_start: 20781,
      pattern_end: 20809
    });
  }
  let _pipe = toList([
    div(toList([
      class$("hero h-screen max-h-[calc(100vh-4rem)] overflow-auto")
    ]), toList([
      div(toList([
        class$("hero-content flex-col lg:flex-row-reverse")
      ]), toList([
        div(toList([
          class$("card bg-neutral w-full max-w-sm shrink-0 shadow-2xl")
        ]), toList([
          form(toList([
            class$("card-body m-4 delay-150 duration-300 ease-in-out transition-[height]"),
            on_submit((var0) => {
              return new UserSubmittedSignup(var0);
            })
          ]), toList([
            fieldset(toList([class$("fieldset")]), toList([
              label(toList([class$("fieldset-label")]), toList([text2("Email")])),
              input(toList([
                placeholder("Email"),
                class$("input input-primary bg-primary font-content"),
                type_("email"),
                value(fieldvalues.emailfield),
                on_input((var0) => {
                  return new UserUpdatedControlledEmailField(var0);
                })
              ])),
              label(toList([class$("fieldset-label")]), toList([text2("Username")])),
              input(toList([
                placeholder("Username"),
                class$("input input-primary bg-primary font-content"),
                type_("string"),
                value(fieldvalues.usernamefield),
                on_input((var0) => {
                  return new UserUpdatedControlledUsernameField(var0);
                })
              ])),
              label(toList([class$("fieldset-label")]), toList([text2("Password")])),
              input(toList([
                value(fieldvalues.passwordfield),
                on_input((var0) => {
                  return new UserUpdatedControlledPasswordField(var0);
                }),
                placeholder("Password"),
                class$("input input-primary bg-primary font-content"),
                type_("password")
              ])),
              label(toList([class$("fieldset-label")]), toList([text2("Confirm Password")])),
              input(toList([
                value(fieldvalues.passwordconfirmfield),
                on_input((var0) => {
                  return new UserUpdatedControlledPasswordConfirmField(var0);
                }),
                placeholder("Re-type password"),
                class$("input input-primary bg-primary font-content"),
                type_("password")
              ])),
              (() => {
                let $1 = (() => {
                  let _pipe2 = ready;
                  return is_some(_pipe2);
                })() && (() => {
                  let _pipe2 = ready;
                  let _pipe$1 = unwrap(_pipe2, new Error(""));
                  return is_ok(_pipe$1);
                })() && fieldvalues.passwordfield === fieldvalues.passwordconfirmfield;
                if ($1) {
                  return button(toList([
                    class$("btn btn-accent font-menuitems w-full m-0 p-0 mt-2"),
                    type_("submit")
                  ]), toList([
                    text3((() => {
                      let $2 = (() => {
                        let _pipe2 = ready;
                        return is_some(_pipe2);
                      })() && (() => {
                        let _pipe2 = ready;
                        let _pipe$1 = unwrap(_pipe2, new Error(""));
                        return is_ok(_pipe$1);
                      })();
                      if ($2) {
                        return "Sign up as " + fieldvalues.usernamefield;
                      } else {
                        return "Sign up";
                      }
                    })())
                  ]));
                } else {
                  return div(toList([
                    class$((() => {
                      let $2 = (() => {
                        let _pipe2 = ready;
                        return is_some(_pipe2);
                      })();
                      if ($2) {
                        return "btn bg-base-200 hover:bg-base-200 text-warning-content font-menuitems w-full m-0 p-0 rounded-lg mt-2 opacity-80 hover:opacity-80 cursor-default no-animation disabled";
                      } else {
                        return "hidden";
                      }
                    })())
                  ]), toList([
                    (() => {
                      let $2 = (() => {
                        let _pipe2 = ready;
                        return unwrap(_pipe2, new Ok(undefined));
                      })();
                      let $3 = fieldvalues.passwordfield === fieldvalues.passwordconfirmfield;
                      if ($2 instanceof Ok) {
                        if ($3) {
                          return none3();
                        } else {
                          return div(toList([class$("")]), toList([
                            text2("Passwords don't match!")
                          ]));
                        }
                      } else {
                        let why = $2[0];
                        return div(toList([class$("")]), toList([
                          span(toList([]), (() => {
                            let $4 = contains_string(why, "in use");
                            if ($4) {
                              return toList([
                                text2(" " + why + ", do you want to "),
                                a(toList([
                                  on_click(new UserNavigatedToLoginPage),
                                  class$("link link-primary")
                                ]), toList([
                                  text2("log in instead")
                                ])),
                                text2("?")
                              ]);
                            } else {
                              return toList([
                                text2(" " + why)
                              ]);
                            }
                          })())
                        ]));
                      }
                    })()
                  ]));
                }
              })()
            ]))
          ]))
        ])),
        div(toList([class$("text-center lg:text-left")]), toList([
          h1(toList([class$("text-5xl font-bold")]), toList([text2("Sign up for Lumina!")])),
          p(toList([class$("py-6")]), toList([
            text2("We have real good food, I don't know what to put here right now.")
          ]))
        ]))
      ]))
    ]))
  ]);
  return common_view_parts(_pipe, toList([
    li(toList([on_click(new UserNavigatedToLandingPage)]), toList([a(toList([]), toList([text2("Back")]))])),
    li(toList([on_click(new UserNavigatedToRegisterPage)]), toList([
      a(toList([class$("bg-primary text-primary-content")]), toList([text2("Register")]))
    ])),
    li(toList([on_click(new UserNavigatedToLoginPage)]), toList([a(toList([]), toList([text2("Login")]))]))
  ]));
}
function view2(model) {
  let $ = localStorage();
  let localstorage;
  if ($ instanceof Ok) {
    localstorage = $[0];
  } else {
    throw makeError("let_assert", FILEPATH3, "lumina_client/view", 45, "view", "localstorage should be available on ALL major browsers.", {
      value: $,
      start: 1839,
      end: 1884,
      pattern_start: 1850,
      pattern_end: 1866
    });
  }
  let $1 = setItem(localstorage, model_local_storage_key, serialize(model));
  let _block;
  let $2 = model.page;
  if ($2 instanceof Landing) {
    _block = view_landing();
  } else if ($2 instanceof Register) {
    _block = view_register(model);
  } else if ($2 instanceof Login) {
    _block = view_login(model);
  } else if ($2 instanceof HomeTimeline) {
    _block = view(model);
  } else if ($2 instanceof Licence) {
    throw makeError("todo", FILEPATH3, "lumina_client/view", 60, "view", "Licence should be shown by the client if it's not shown by the server.", {});
  } else {
    let uri = $2.uri;
    throw makeError("todo", FILEPATH3, "lumina_client/view", 58, "view", "No 404 page yet.", {});
  }
  let content = _block;
  return div(toList([
    get_color_scheme2(model),
    class$("w-screen h-screen content")
  ]), toList([
    (() => {
      let $3 = model.ws;
      if ($3 instanceof WsConnectionInitial) {
        return div(toList([
          attribute2("open", ""),
          class$("modal modal-bottom sm:modal-middle")
        ]), toList([
          div(toList([class$("modal-box")]), toList([
            text2("Connecting to server..."),
            div(toList([class$("float-right")]), toList([
              span(toList([
                class$("loading loading-spinner loading-xl")
              ]), toList([]))
            ]))
          ]))
        ]));
      } else if ($3 instanceof WsConnectionConnected) {
        return none3();
      } else if ($3 instanceof WsConnectionDisconnected) {
        return div(toList([
          attribute2("open", ""),
          class$("toast toast-top toast-center z-100")
        ]), toList([
          div(toList([class$("alert alert-info")]), toList([
            text2("Connection to server ended! "),
            button(toList([
              class$("btn btn-primary font-menuitems"),
              on_click(new WSTryReconnect)
            ]), toList([text2("Reconnect")]))
          ]))
        ]));
      } else if ($3 instanceof WsConnectionUnsure) {
        return none3();
      } else {
        return div(toList([
          attribute2("open", ""),
          class$("toast toast-top toast-center z-100")
        ]), toList([
          div(toList([class$("alert alert-info")]), toList([
            text2("Connection to server ended! Reconnecting..."),
            div(toList([class$("float-right")]), toList([
              span(toList([
                class$("loading loading-spinner loading-lg")
              ]), toList([]))
            ]))
          ]))
        ]));
      }
    })(),
    content
  ]));
}

// build/dev/javascript/lumina_client/lumina_client.mjs
var FILEPATH4 = "src/lumina_client.gleam";

class Greeting extends CustomType {
  constructor(greeting) {
    super();
    this.greeting = greeting;
  }
}

class RegisterPrecheckResponse extends CustomType {
  constructor(ok, why) {
    super();
    this.ok = ok;
    this.why = why;
  }
}

class AuthenticationSuccess extends CustomType {
  constructor(username, token2) {
    super();
    this.username = username;
    this.token = token2;
  }
}

class AuthenticationFailure extends CustomType {
}

class TimeLineResponse extends CustomType {
  constructor(timeline_name, timeline_id, items, total_count, page, has_more) {
    super();
    this.timeline_name = timeline_name;
    this.timeline_id = timeline_id;
    this.items = items;
    this.total_count = total_count;
    this.page = page;
    this.has_more = has_more;
  }
}

class OwnUserInformationResponse extends CustomType {
  constructor(username, email, avatar, uuid, unread_notifications) {
    super();
    this.username = username;
    this.email = email;
    this.avatar = avatar;
    this.uuid = uuid;
    this.unread_notifications = unread_notifications;
  }
}

class Undecodable extends CustomType {
}

class OwnUserInformationRequest extends CustomType {
}

class LoginAuthenticationRequest extends CustomType {
  constructor(email_username, password) {
    super();
    this.email_username = email_username;
    this.password = password;
  }
}

class RegisterRequest extends CustomType {
  constructor(email, username, password) {
    super();
    this.email = email;
    this.username = username;
    this.password = password;
  }
}

class TimeLineRequest extends CustomType {
  constructor(timeline_name, page) {
    super();
    this.timeline_name = timeline_name;
    this.page = page;
  }
}

class RegisterPrecheck extends CustomType {
  constructor(email, username, password) {
    super();
    this.email = email;
    this.username = username;
    this.password = password;
  }
}

class PostContentRequest extends CustomType {
  constructor(post_id) {
    super();
    this.post_id = post_id;
  }
}
function start_tracking_mouse_movements(x, y) {
  return from((dispatcher) => {
    return start_dragging_modal_box(x, y, (var0, var1) => {
      return new MoveModalBoxTo(var0, var1);
    }, dispatcher);
  });
}
function count_to_150() {
  return from((dispatch) => {
    return set_timeout_nilled(150, () => {
      return dispatch(new EffectPast150ms);
    });
  });
}
function init2(rerun) {
  let $ = localStorage();
  let localstorage;
  if ($ instanceof Ok) {
    localstorage = $[0];
  } else {
    throw makeError("let_assert", FILEPATH4, "lumina_client", 115, "init", "localstorage should be available on ALL major browsers.", {
      value: $,
      start: 4002,
      end: 4047,
      pattern_start: 4013,
      pattern_end: 4029
    });
  }
  let empty_model = new Model(new Landing, new None, new WsConnectionInitial, new None, new Ok(undefined), new Cached(new_map(), new_map(), new_map()), rerun, truncate(to_unix_seconds(system_time2())));
  return [
    (() => {
      let $1 = getItem(localstorage, model_local_storage_key);
      if ($1 instanceof Ok) {
        let l = $1[0];
        let $2 = deserialize_serializable_model(l);
        if ($2 instanceof Ok) {
          let loadable_model = $2[0];
          return new Model(loadable_model.page, new None, (() => {
            if (rerun) {
              return new WsConnectionRetrying;
            } else {
              return new WsConnectionInitial;
            }
          })(), loadable_model.token, new Ok(undefined), new Cached(new_map(), new_map(), new_map()), rerun, truncate(to_unix_seconds(system_time2())));
        } else {
          error("Could not deserialise last saved model.");
          return empty_model;
        }
      } else {
        log2("No model to restore");
        return empty_model;
      }
    })(),
    batch(toList([
      init("/connection", (var0) => {
        return new WebSocketIncomingMessage(var0);
      }),
      count_to_150()
    ]))
  ];
}
function let_definitely_disconnect(model) {
  return from((dispatch) => {
    let $ = model.ws;
    let $1 = model.has_been_running_for_150ms;
    if ($1) {
      if ($ instanceof WsConnectionInitial) {
        return;
      } else if ($ instanceof WsConnectionConnected) {
        return;
      } else if ($ instanceof WsConnectionDisconnected) {
        return;
      } else if ($ instanceof WsConnectionUnsure) {
        return dispatch(new WsDisconnectDefinitive);
      } else {
        return;
      }
    } else if ($ instanceof WsConnectionInitial) {
      return;
    } else if ($ instanceof WsConnectionConnected) {
      return;
    } else if ($ instanceof WsConnectionDisconnected) {
      return;
    } else if ($ instanceof WsConnectionUnsure) {
      return;
    } else {
      return;
    }
  });
}
function encode_ws_msg(message) {
  if (message instanceof OwnUserInformationRequest) {
    return object2(toList([["type", string3("own_user_information_request")]]));
  } else if (message instanceof LoginAuthenticationRequest) {
    let email_username = message.email_username;
    let password = message.password;
    return object2(toList([
      ["type", string3("login_authentication_request")],
      ["email_username", string3(email_username)],
      ["password", string3(password)]
    ]));
  } else if (message instanceof RegisterRequest) {
    let email = message.email;
    let username = message.username;
    let password = message.password;
    return object2(toList([
      ["type", string3("register_request")],
      ["email", string3(email)],
      ["username", string3(username)],
      ["password", string3(password)]
    ]));
  } else if (message instanceof TimeLineRequest) {
    let timeline_name = message.timeline_name;
    let page = message.page;
    return object2(toList([
      ["type", string3("timeline_request")],
      ["by_name", string3(timeline_name)],
      ["page", int3(page)]
    ]));
  } else if (message instanceof RegisterPrecheck) {
    let email = message.email;
    let username = message.username;
    let password = message.password;
    return object2(toList([
      ["type", string3("register_precheck")],
      ["email", string3(email)],
      ["username", string3(username)],
      ["password", string3(password)]
    ]));
  } else {
    let post_id = message.post_id;
    return object2(toList([
      ["type", string3("post_view_request")],
      ["post_id", string3(post_id)]
    ]));
  }
}
function request_next_timeline_page(model, timeline_name) {
  let $ = model.ws;
  let socket;
  if ($ instanceof WsConnectionConnected) {
    socket = $[0];
  } else {
    throw makeError("let_assert", FILEPATH4, "lumina_client", 83, "request_next_timeline_page", "Socket not connected", {
      value: $,
      start: 3053,
      end: 3115,
      pattern_start: 3064,
      pattern_end: 3104
    });
  }
  let $1 = (() => {
    let _pipe = model.cache.cached_timelines;
    return map_get(_pipe, timeline_name);
  })();
  if ($1 instanceof Ok) {
    let timeline2 = $1[0];
    let $2 = get_next_page_to_load(timeline2);
    if ($2 instanceof Some) {
      let next_page = $2[0];
      let _pipe = new TimeLineRequest(timeline_name, next_page);
      let _pipe$1 = encode_ws_msg(_pipe);
      let _pipe$2 = to_string2(_pipe$1);
      return ((_capture) => {
        return send2(socket, _capture);
      })(_pipe$2);
    } else {
      return none2();
    }
  } else {
    let _pipe = new TimeLineRequest(timeline_name, 0);
    let _pipe$1 = encode_ws_msg(_pipe);
    let _pipe$2 = to_string2(_pipe$1);
    return ((_capture) => {
      return send2(socket, _capture);
    })(_pipe$2);
  }
}
function ws_msg_decoder(variant) {
  if (variant === "auth_success") {
    return field("username", string2, (username) => {
      return field("token", string2, (token2) => {
        return success(new AuthenticationSuccess(username, token2));
      });
    });
  } else if (variant === "auth_failure") {
    return success(new AuthenticationFailure);
  } else if (variant === "unknown") {
    return success(new Undecodable);
  } else if (variant === "register_precheck_response") {
    return field("ok", bool, (ok) => {
      return field("why", string2, (why) => {
        return success(new RegisterPrecheckResponse(ok, why));
      });
    });
  } else if (variant === "greeting") {
    return field("greeting", string2, (greeting) => {
      return success(new Greeting(greeting));
    });
  } else if (variant === "timeline_response") {
    log2("Decoding timeline response: " + variant);
    return field("timeline_name", string2, (timeline_name) => {
      return field("timeline_id", string2, (timeline_id) => {
        return field("post_ids", list2(string2), (items) => {
          return field("total_count", int2, (total_count) => {
            return field("page", int2, (page) => {
              return field("has_more", bool, (has_more) => {
                return success(new TimeLineResponse(timeline_name, timeline_id, items, total_count, page, has_more));
              });
            });
          });
        });
      });
    });
  } else if (variant === "own_user_information_response") {
    return field("username", string2, (username) => {
      return field("email", string2, (email) => {
        return field("unread_notifications", int2, (unread_notifications) => {
          return field("avatar", optional(list2(string2)), (avatar_list_opt) => {
            let _block;
            if (avatar_list_opt instanceof Some) {
              let list4 = avatar_list_opt[0];
              if (list4 instanceof Empty) {
                _block = new None;
              } else {
                let $ = list4.tail;
                if ($ instanceof Empty) {
                  _block = new None;
                } else {
                  let $1 = $.tail;
                  if ($1 instanceof Empty) {
                    let mime = list4.head;
                    let b64 = $.head;
                    _block = new Some([mime, b64]);
                  } else {
                    _block = new None;
                  }
                }
              }
            } else {
              _block = avatar_list_opt;
            }
            let avatar = _block;
            return field("uuid", string2, (uuid) => {
              return success(new OwnUserInformationResponse(username, email, avatar, uuid, unread_notifications));
            });
          });
        });
      });
    });
  } else {
    let g = variant;
    error("Unknown message type: " + g);
    return failure(new Undecodable, g);
  }
}
function ws_msg_typedefiner() {
  return field("type", string2, (variant) => {
    return success(variant);
  });
}
function session_destroy() {
  info("Destroying session.");
  let $ = localStorage();
  let s;
  if ($ instanceof Ok) {
    s = $[0];
  } else {
    throw makeError("let_assert", FILEPATH4, "lumina_client", 1049, "session_destroy", "Pattern match failed, no pattern matched the value.", {
      value: $,
      start: 34306,
      end: 34340,
      pattern_start: 34317,
      pattern_end: 34322
    });
  }
  clear(s);
  info("Recreating model.");
  return init2(false);
}
function update_ws(model, wsevent) {
  echo2(wsevent, undefined, "src/lumina_client.gleam", 590);
  if (wsevent instanceof InvalidUrl) {
    throw makeError("panic", FILEPATH4, "lumina_client", 592, "update_ws", "`panic` expression evaluated.", {});
  } else if (wsevent instanceof OnOpen) {
    let socket = wsevent[0];
    return [
      new Model(model.page, model.user, new WsConnectionConnected(socket), model.token, model.status, model.cache, model.has_been_running_for_150ms, model.last_refresh_request_time),
      send2(socket, (() => {
        let _block;
        {
          let x = toList([
            ["type", string3("introduction")],
            ["client_kind", string3("web")]
          ]);
          _block = object2((() => {
            let $ = model.user;
            let $1 = model.token;
            if ($ instanceof None && $1 instanceof Some) {
              let token2 = $1[0];
              return append(x, toList([["try_revive", string3(token2)]]));
            } else {
              return x;
            }
          })());
        }
        let _pipe = _block;
        return to_string2(_pipe);
      })())
    ];
  } else if (wsevent instanceof OnTextMessage) {
    let notice = wsevent[0];
    let $ = parse(notice, ws_msg_decoder((() => {
      let _pipe = parse(notice, ws_msg_typedefiner());
      return unwrap2(_pipe, "Unparsable message");
    })()));
    if ($ instanceof Ok) {
      let $1 = $[0];
      if ($1 instanceof Greeting) {
        let m = $1.greeting;
        log2("The server says hi! '" + m + "'");
        return [model, none2()];
      } else if ($1 instanceof RegisterPrecheckResponse) {
        let ok = $1.ok;
        let why = $1.why;
        log2("Register precheck response: " + inspect2(ok));
        let _block;
        let _block$1;
        if (ok) {
          _block$1 = new Ok(undefined);
        } else {
          _block$1 = new Error(why);
        }
        let _pipe = _block$1;
        _block = new Some(_pipe);
        let ready = _block;
        let $2 = model.page;
        if ($2 instanceof Register) {
          let fields = $2.fields;
          return [
            new Model(new Register(fields, ready), model.user, model.ws, model.token, model.status, model.cache, model.has_been_running_for_150ms, model.last_refresh_request_time),
            none2()
          ];
        } else {
          return [model, none2()];
        }
      } else if ($1 instanceof AuthenticationSuccess) {
        let token2 = $1.token;
        let $2 = model.ws;
        let socket;
        if ($2 instanceof WsConnectionConnected) {
          socket = $2[0];
        } else {
          throw makeError("let_assert", FILEPATH4, "lumina_client", 667, "update_ws", "Socket not connected", {
            value: $2,
            start: 21412,
            end: 21474,
            pattern_start: 21423,
            pattern_end: 21463
          });
        }
        return [
          new Model(new HomeTimeline(new None, new None), model.user, model.ws, new Some(token2), model.status, model.cache, model.has_been_running_for_150ms, model.last_refresh_request_time),
          batch(toList([
            (() => {
              let _pipe = new OwnUserInformationRequest;
              let _pipe$1 = encode_ws_msg(_pipe);
              let _pipe$2 = to_string2(_pipe$1);
              return ((_capture) => {
                return send2(socket, _capture);
              })(_pipe$2);
            })(),
            (() => {
              let _pipe = new TimeLineRequest("global", 0);
              let _pipe$1 = encode_ws_msg(_pipe);
              let _pipe$2 = to_string2(_pipe$1);
              return ((_capture) => {
                return send2(socket, _capture);
              })(_pipe$2);
            })()
          ]))
        ];
      } else if ($1 instanceof AuthenticationFailure) {
        let $2 = model.page;
        if ($2 instanceof Landing) {
          return session_destroy();
        } else if ($2 instanceof Register) {
          return [model, none2()];
        } else if ($2 instanceof Login) {
          let fields = $2.fields;
          return [
            new Model(new Login(fields, new Some(false)), model.user, model.ws, model.token, model.status, model.cache, model.has_been_running_for_150ms, model.last_refresh_request_time),
            none2()
          ];
        } else if ($2 instanceof HomeTimeline) {
          return session_destroy();
        } else if ($2 instanceof Licence) {
          return session_destroy();
        } else {
          return session_destroy();
        }
      } else if ($1 instanceof TimeLineResponse) {
        let timeline_name = $1.timeline_name;
        let timeline_id = $1.timeline_id;
        let items = $1.items;
        let total_count = $1.total_count;
        let page = $1.page;
        let has_more = $1.has_more;
        log2("Received timeline response for " + timeline_name + " (id: " + timeline_id + ")" + " with " + to_string(length(items)) + " items (page " + to_string(page) + " of " + to_string(total_count) + " total, has_more: " + to_string3(has_more) + ").");
        let $2 = model.ws;
        let socket;
        if ($2 instanceof WsConnectionConnected) {
          socket = $2[0];
        } else {
          throw makeError("let_assert", FILEPATH4, "lumina_client", 725, "update_ws", "Socket not connected", {
            value: $2,
            start: 23474,
            end: 23536,
            pattern_start: 23485,
            pattern_end: 23525
          });
        }
        let posts_fetches = batch(map2(items, (post_id) => {
          let _pipe2 = new PostContentRequest(post_id);
          let _pipe$1 = encode_ws_msg(_pipe2);
          let _pipe$2 = to_string2(_pipe$1);
          return ((_capture) => {
            return send2(socket, _capture);
          })(_pipe$2);
        }));
        let _block;
        let $3 = (() => {
          let _pipe2 = model.cache.cached_timelines;
          return map_get(_pipe2, timeline_name);
        })();
        if ($3 instanceof Ok) {
          let existing = $3[0];
          _block = add_page_to_timeline(existing, timeline_id, page, items, total_count, has_more);
        } else {
          let _pipe2 = create_empty_timeline();
          _block = add_page_to_timeline(_pipe2, timeline_id, page, items, total_count, has_more);
        }
        let cached_timeline = _block;
        log2(timeline_info_string(cached_timeline, timeline_name));
        let _block$1;
        let _pipe = model.cache.cached_timelines;
        _block$1 = insert(_pipe, timeline_name, cached_timeline);
        let cached_timelines = _block$1;
        return [
          new Model(model.page, model.user, model.ws, model.token, model.status, (() => {
            let _record = model.cache;
            return new Cached(_record.cached_posts, _record.cached_users, cached_timelines);
          })(), model.has_been_running_for_150ms, model.last_refresh_request_time),
          posts_fetches
        ];
      } else if ($1 instanceof OwnUserInformationResponse) {
        let username = $1.username;
        let email = $1.email;
        let avatar = $1.avatar;
        let uuid = $1.uuid;
        let unread_notifications = $1.unread_notifications;
        let _block;
        if (avatar instanceof Some) {
          let mime = avatar[0][0];
          let b64 = avatar[0][1];
          _block = "data:" + mime + ";base64," + b64;
        } else {
          _block = "";
        }
        let avatar_string = _block;
        let _block$1;
        let _pipe = model.cache.cached_users;
        _block$1 = insert(_pipe, uuid, new CachedUser("local", username, avatar_string, truncate(to_unix_seconds(system_time2()))));
        let new_users = _block$1;
        return [
          new Model(model.page, new Some(new UserSubmodel(uuid, username, email, avatar_string, new NotificationsSubModel(unread_notifications, toList([])))), model.ws, model.token, model.status, (() => {
            let _record = model.cache;
            return new Cached(_record.cached_posts, new_users, _record.cached_timelines);
          })(), model.has_been_running_for_150ms, model.last_refresh_request_time),
          none2()
        ];
      } else {
        throw makeError("panic", FILEPATH4, "lumina_client", 790, "update_ws", `Received message that was explicitly marked as undecodable, this should not happen
	as the decoder should have returned an error instead of Undecodable. Check the decoder implementation and the logs
	for the raw message.`, {});
      }
    } else {
      let err = $[0];
      error("Message could not be parsed:" + text_error_red(inspect2(err)) + `
in:
` + text_error_red(notice));
      return [model, none2()];
    }
  } else if (wsevent instanceof OnBinaryMessage) {
    let msg = wsevent[0];
    warn("Received unexpected: " + text_cyan(inspect2(msg)));
    return [model, none2()];
  } else {
    let reason = wsevent[0];
    warn("Given close reason: " + text_cyan((() => {
      if (reason instanceof Normal) {
        return "Normal close";
      } else if (reason instanceof GoingAway) {
        return "Going away";
      } else if (reason instanceof ProtocolError) {
        return "Protocol error";
      } else if (reason instanceof UnexpectedTypeOfData) {
        return "Unexpected type of data";
      } else if (reason instanceof NoCodeFromServer) {
        return "No code from server";
      } else if (reason instanceof AbnormalClose) {
        return "Abnormal close (no close frame was received)";
      } else if (reason instanceof IncomprehensibleFrame) {
        return "Incomprehensible frame";
      } else if (reason instanceof PolicyViolated) {
        return "Policy violation";
      } else if (reason instanceof MessageTooBig) {
        return "Message was too big";
      } else if (reason instanceof FailedExtensionNegotation) {
        return "Failed extension negotation";
      } else if (reason instanceof UnexpectedFailure) {
        return "Unexpected faillure";
      } else if (reason instanceof FailedTLSHandshake) {
        return "Failed TLS handshake";
      } else {
        return "Other close reason (unknown)";
      }
    })()));
    let $ = model.ws;
    if ($ instanceof WsConnectionInitial) {
      return [model, none2()];
    } else if ($ instanceof WsConnectionRetrying) {
      return [
        new Model(model.page, model.user, new WsConnectionDisconnected, model.token, model.status, model.cache, model.has_been_running_for_150ms, model.last_refresh_request_time),
        none2()
      ];
    } else {
      let new_model = new Model(model.page, model.user, new WsConnectionUnsure, model.token, model.status, model.cache, model.has_been_running_for_150ms, model.last_refresh_request_time);
      return [new_model, let_definitely_disconnect(new_model)];
    }
  }
}
function update2(model, msg) {
  if (msg instanceof WSTryReconnect) {
    let $ = model.ws;
    if ($ instanceof WsConnectionDisconnected) {
      return init2(model.has_been_running_for_150ms);
    } else {
      return [model, none2()];
    }
  } else if (msg instanceof EffectPast150ms) {
    return [
      new Model(model.page, model.user, model.ws, model.token, model.status, model.cache, true, model.last_refresh_request_time),
      none2()
    ];
  } else if (msg instanceof UpdateLastRefreshRequestTime) {
    let new_time = msg[0];
    return [
      new Model(model.page, model.user, model.ws, model.token, model.status, model.cache, model.has_been_running_for_150ms, new_time),
      none2()
    ];
  } else if (msg instanceof WsDisconnectDefinitive) {
    let timed_trigger_to_retry_connect = (h) => {
      return from((dispatch) => {
        return set_timeout_nilled(h, () => {
          return dispatch(new WSTryReconnect);
        });
      });
    };
    return [
      new Model(model.page, model.user, new WsConnectionDisconnected, model.token, model.status, model.cache, model.has_been_running_for_150ms, model.last_refresh_request_time),
      batch(toList([
        timed_trigger_to_retry_connect(1500),
        timed_trigger_to_retry_connect(3000),
        timed_trigger_to_retry_connect(6000),
        timed_trigger_to_retry_connect(12000),
        timed_trigger_to_retry_connect(24000)
      ]))
    ];
  } else if (msg instanceof WebSocketIncomingMessage) {
    let event4 = msg[0];
    return update_ws(model, event4);
  } else if (msg instanceof UserNavigatedToLoginPage) {
    return [
      new Model(new Login(new LoginFields("", ""), new None), model.user, model.ws, model.token, model.status, model.cache, model.has_been_running_for_150ms, model.last_refresh_request_time),
      none2()
    ];
  } else if (msg instanceof UserNavigatedToRegisterPage) {
    return [
      new Model(new Register(new RegisterPageFields("", "", "", ""), new None), model.user, model.ws, model.token, model.status, model.cache, model.has_been_running_for_150ms, model.last_refresh_request_time),
      none2()
    ];
  } else if (msg instanceof UserNavigatedToLandingPage) {
    return [
      new Model(new Landing, model.user, model.ws, model.token, model.status, model.cache, model.has_been_running_for_150ms, model.last_refresh_request_time),
      none2()
    ];
  } else if (msg instanceof UserSubmittedLogin) {
    let $ = model.page;
    let fields;
    if ($ instanceof Login) {
      fields = $.fields;
    } else {
      throw makeError("let_assert", FILEPATH4, "lumina_client", 445, "update", "Pattern match failed, no pattern matched the value.", {
        value: $,
        start: 14400,
        end: 14440,
        pattern_start: 14411,
        pattern_end: 14427
      });
    }
    let values_ok = login_view_checker(fields);
    if (values_ok) {
      log2("Submitting login form");
      let _block;
      let _pipe = encode_ws_msg(new LoginAuthenticationRequest(fields.emailfield, fields.passwordfield));
      _block = to_string2(_pipe);
      let json2 = _block;
      let $1 = model.ws;
      let socket;
      if ($1 instanceof WsConnectionConnected) {
        socket = $1[0];
      } else {
        throw makeError("let_assert", FILEPATH4, "lumina_client", 456, "update", "Socket not connected", {
          value: $1,
          start: 14779,
          end: 14841,
          pattern_start: 14790,
          pattern_end: 14830
        });
      }
      return [
        new Model(model.page, model.user, new WsConnectionConnected(socket), model.token, model.status, model.cache, model.has_been_running_for_150ms, model.last_refresh_request_time),
        send2(socket, json2)
      ];
    } else {
      error("Form not ready to submit");
      return [model, none2()];
    }
  } else if (msg instanceof UserSubmittedSignup) {
    let $ = model.page;
    let fields;
    let ready;
    if ($ instanceof Register) {
      fields = $.fields;
      ready = $.ready;
    } else {
      throw makeError("let_assert", FILEPATH4, "lumina_client", 470, "update", "Pattern match failed, no pattern matched the value.", {
        value: $,
        start: 15205,
        end: 15252,
        pattern_start: 15216,
        pattern_end: 15239
      });
    }
    let $1 = (() => {
      let _pipe = ready;
      return is_some(_pipe);
    })() && (() => {
      let _pipe = ready;
      let _pipe$1 = unwrap(_pipe, new Error(""));
      return is_ok(_pipe$1);
    })() && fields.passwordfield === fields.passwordconfirmfield;
    if ($1) {
      log2("Submitting signup form");
      let _block;
      let _pipe = encode_ws_msg(new RegisterRequest(fields.emailfield, fields.usernamefield, fields.passwordfield));
      _block = to_string2(_pipe);
      let json2 = _block;
      let $2 = model.ws;
      let socket;
      if ($2 instanceof WsConnectionConnected) {
        socket = $2[0];
      } else {
        throw makeError("let_assert", FILEPATH4, "lumina_client", 488, "update", "Socket not connected", {
          value: $2,
          start: 15763,
          end: 15825,
          pattern_start: 15774,
          pattern_end: 15814
        });
      }
      return [
        new Model(model.page, model.user, new WsConnectionConnected(socket), model.token, model.status, model.cache, model.has_been_running_for_150ms, model.last_refresh_request_time),
        send2(socket, json2)
      ];
    } else {
      error("Form not ready to submit");
      return [model, none2()];
    }
  } else if (msg instanceof UserUpdatedControlledEmailField) {
    let new_email = msg[0];
    let $ = model.page;
    if ($ instanceof Register) {
      let fields = $.fields;
      let ready = $.ready;
      return [
        new Model(new Register(new RegisterPageFields(fields.usernamefield, new_email, fields.passwordfield, fields.passwordconfirmfield), ready), model.user, model.ws, model.token, model.status, model.cache, model.has_been_running_for_150ms, model.last_refresh_request_time),
        (() => {
          let $1 = model.ws;
          let socket;
          if ($1 instanceof WsConnectionConnected) {
            socket = $1[0];
          } else {
            throw makeError("let_assert", FILEPATH4, "lumina_client", 266, "update", "Socket not connected", {
              value: $1,
              start: 8791,
              end: 8853,
              pattern_start: 8802,
              pattern_end: 8842
            });
          }
          let _pipe = encode_ws_msg(new RegisterPrecheck(fields.emailfield, fields.usernamefield, fields.passwordfield));
          let _pipe$1 = to_string2(_pipe);
          return ((_capture) => {
            return send2(socket, _capture);
          })(_pipe$1);
        })()
      ];
    } else if ($ instanceof Login) {
      let fields = $.fields;
      return [
        new Model(new Login(new LoginFields(new_email, fields.passwordfield), new None), model.user, model.ws, model.token, model.status, model.cache, model.has_been_running_for_150ms, model.last_refresh_request_time),
        none2()
      ];
    } else {
      return [model, none2()];
    }
  } else if (msg instanceof UserUpdatedControlledPasswordField) {
    let new_password = msg[0];
    let $ = model.page;
    if ($ instanceof Register) {
      let fields = $.fields;
      let ready = $.ready;
      return [
        new Model(new Register(new RegisterPageFields(fields.usernamefield, fields.emailfield, new_password, fields.passwordconfirmfield), ready), model.user, model.ws, model.token, model.status, model.cache, model.has_been_running_for_150ms, model.last_refresh_request_time),
        (() => {
          let $1 = model.ws;
          let socket;
          if ($1 instanceof WsConnectionConnected) {
            socket = $1[0];
          } else {
            throw makeError("let_assert", FILEPATH4, "lumina_client", 302, "update", "Socket not connected", {
              value: $1,
              start: 9888,
              end: 9950,
              pattern_start: 9899,
              pattern_end: 9939
            });
          }
          let _pipe = encode_ws_msg(new RegisterPrecheck(fields.emailfield, fields.usernamefield, fields.passwordfield));
          let _pipe$1 = to_string2(_pipe);
          return ((_capture) => {
            return send2(socket, _capture);
          })(_pipe$1);
        })()
      ];
    } else if ($ instanceof Login) {
      let fields = $.fields;
      let _block;
      let $1 = starts_with(fields.emailfield, "@");
      if ($1) {
        _block = drop_start(fields.emailfield, 1);
      } else {
        _block = fields.emailfield;
      }
      let username_email = _block;
      let _block$1;
      let $2 = contains_string(username_email, "@");
      if ($2) {
        _block$1 = username_email;
      } else {
        let _pipe = trim(username_email);
        let _pipe$1 = replace(_pipe, " ", "");
        let _pipe$2 = lowercase(_pipe$1);
        let _pipe$3 = replace(_pipe$2, "@", "");
        _block$1 = replace(_pipe$3, ".", "");
      }
      let new_username_email = _block$1;
      return [
        new Model(new Login(new LoginFields(new_username_email, new_password), new None), model.user, model.ws, model.token, model.status, model.cache, model.has_been_running_for_150ms, model.last_refresh_request_time),
        none2()
      ];
    } else {
      return [model, none2()];
    }
  } else if (msg instanceof UserUpdatedControlledUsernameField) {
    let new_username = msg[0];
    let $ = model.page;
    if ($ instanceof Register) {
      let fields = $.fields;
      let ready = $.ready;
      return [
        new Model(new Register(new RegisterPageFields((() => {
          let _block;
          let $1 = starts_with(new_username, "@");
          if ($1) {
            _block = drop_start(new_username, 1);
          } else {
            _block = new_username;
          }
          let _pipe = _block;
          let _pipe$1 = trim(_pipe);
          let _pipe$2 = replace(_pipe$1, " ", "");
          let _pipe$3 = lowercase(_pipe$2);
          let _pipe$4 = replace(_pipe$3, "@", "");
          return replace(_pipe$4, ".", "");
        })(), fields.emailfield, fields.passwordfield, fields.passwordconfirmfield), ready), model.user, model.ws, model.token, model.status, model.cache, model.has_been_running_for_150ms, model.last_refresh_request_time),
        (() => {
          let $1 = model.ws;
          let socket;
          if ($1 instanceof WsConnectionConnected) {
            socket = $1[0];
          } else {
            throw makeError("let_assert", FILEPATH4, "lumina_client", 398, "update", "Socket not connected", {
              value: $1,
              start: 12985,
              end: 13047,
              pattern_start: 12996,
              pattern_end: 13036
            });
          }
          let _pipe = encode_ws_msg(new RegisterPrecheck(fields.emailfield, fields.usernamefield, fields.passwordfield));
          let _pipe$1 = to_string2(_pipe);
          return ((_capture) => {
            return send2(socket, _capture);
          })(_pipe$1);
        })()
      ];
    } else {
      return [model, none2()];
    }
  } else if (msg instanceof UserUpdatedControlledPasswordConfirmField) {
    let new_password_confirmation = msg[0];
    let $ = model.page;
    if ($ instanceof Register) {
      let fields = $.fields;
      let ready = $.ready;
      return [
        new Model(new Register(new RegisterPageFields(fields.usernamefield, fields.emailfield, fields.passwordfield, new_password_confirmation), ready), model.user, model.ws, model.token, model.status, model.cache, model.has_been_running_for_150ms, model.last_refresh_request_time),
        (() => {
          let $1 = model.ws;
          let socket;
          if ($1 instanceof WsConnectionConnected) {
            socket = $1[0];
          } else {
            throw makeError("let_assert", FILEPATH4, "lumina_client", 363, "update", "Socket not connected", {
              value: $1,
              start: 11838,
              end: 11900,
              pattern_start: 11849,
              pattern_end: 11889
            });
          }
          let _pipe = encode_ws_msg(new RegisterPrecheck(fields.emailfield, fields.usernamefield, fields.passwordfield));
          let _pipe$1 = to_string2(_pipe);
          return ((_capture) => {
            return send2(socket, _capture);
          })(_pipe$1);
        })()
      ];
    } else {
      return [model, none2()];
    }
  } else if (msg instanceof EmailFieldLostFocus) {
    let $ = model.page;
    let fields;
    if ($ instanceof Login) {
      fields = $.fields;
    } else {
      throw makeError("let_assert", FILEPATH4, "lumina_client", 414, "update", "Pattern match failed, no pattern matched the value.", {
        value: $,
        start: 13539,
        end: 13586,
        pattern_start: 13550,
        pattern_end: 13573
      });
    }
    let _block;
    let $1 = starts_with(fields.emailfield, "@");
    if ($1) {
      _block = drop_start(fields.emailfield, 1);
    } else {
      _block = fields.emailfield;
    }
    let value2 = _block;
    let _block$1;
    let $2 = contains_string(value2, "@");
    if ($2) {
      _block$1 = value2;
    } else {
      let _pipe = trim(value2);
      let _pipe$1 = replace(_pipe, " ", "");
      let _pipe$2 = lowercase(_pipe$1);
      let _pipe$3 = replace(_pipe$2, "@", "");
      _block$1 = replace(_pipe$3, ".", "");
    }
    let new_value = _block$1;
    return [
      new Model(new Login(new LoginFields(new_value, fields.passwordfield), new None), model.user, model.ws, model.token, model.status, model.cache, model.has_been_running_for_150ms, model.last_refresh_request_time),
      none2()
    ];
  } else if (msg instanceof UserSwitchedTimeLineTo) {
    let tid = msg[0];
    let $ = model.ws;
    let socket;
    if ($ instanceof WsConnectionConnected) {
      socket = $[0];
    } else {
      throw makeError("let_assert", FILEPATH4, "lumina_client", 502, "update", "Socket not connected", {
        value: $,
        start: 16205,
        end: 16267,
        pattern_start: 16216,
        pattern_end: 16256
      });
    }
    let _block;
    let $1 = model.page;
    if ($1 instanceof HomeTimeline) {
      let modal = $1.modal;
      _block = new Model(new HomeTimeline(new Some(tid), modal), model.user, model.ws, model.token, model.status, model.cache, model.has_been_running_for_150ms, model.last_refresh_request_time);
    } else {
      _block = model;
    }
    let model$1 = _block;
    let _block$1;
    let $2 = (() => {
      let _pipe = model$1.cache.cached_timelines;
      return map_get(_pipe, tid);
    })();
    if ($2 instanceof Ok) {
      let timeline2 = $2[0];
      let $3 = should_load_more(timeline2, 20, 10);
      if ($3) {
        let $4 = get_next_page_to_load(timeline2);
        if ($4 instanceof Some) {
          let next_page = $4[0];
          let _pipe = new TimeLineRequest(tid, next_page);
          let _pipe$1 = encode_ws_msg(_pipe);
          let _pipe$2 = to_string2(_pipe$1);
          _block$1 = ((_capture) => {
            return send2(socket, _capture);
          })(_pipe$2);
        } else {
          _block$1 = none2();
        }
      } else {
        _block$1 = none2();
      }
    } else {
      let _pipe = new TimeLineRequest(tid, 0);
      let _pipe$1 = encode_ws_msg(_pipe);
      let _pipe$2 = to_string2(_pipe$1);
      _block$1 = ((_capture) => {
        return send2(socket, _capture);
      })(_pipe$2);
    }
    let requ = _block$1;
    return [model$1, requ];
  } else if (msg instanceof LoadMorePosts) {
    let timeline_name = msg[0];
    let effect = request_next_timeline_page(model, timeline_name);
    return [model, effect];
  } else if (msg instanceof UserClickedLogout) {
    return session_destroy();
  } else if (msg instanceof UserClosedModal) {
    let $ = model.page;
    if ($ instanceof HomeTimeline) {
      let timeline_name = $.timeline_name;
      return [
        new Model(new HomeTimeline(timeline_name, new None), model.user, model.ws, model.token, model.status, model.cache, model.has_been_running_for_150ms, model.last_refresh_request_time),
        none2()
      ];
    } else {
      return [model, none2()];
    }
  } else if (msg instanceof SetModal) {
    let to = msg[0];
    let $ = model.page;
    if ($ instanceof HomeTimeline) {
      let timeline_name = $.timeline_name;
      return [
        new Model(new HomeTimeline(timeline_name, new Some([to, new_map()])), model.user, model.ws, model.token, model.status, model.cache, model.has_been_running_for_150ms, model.last_refresh_request_time),
        none2()
      ];
    } else {
      return [model, none2()];
    }
  } else if (msg instanceof StartDraggingModalBox) {
    let x = msg[0];
    let y = msg[1];
    return [model, start_tracking_mouse_movements(x, y)];
  } else {
    let x = msg[0];
    let y = msg[1];
    let $ = model.page;
    if ($ instanceof HomeTimeline) {
      let $1 = $.modal;
      if ($1 instanceof Some) {
        let $2 = $1[0][0];
        if ($2 === "mdl-postedit") {
          let timeline_name = $.timeline_name;
          let params = $1[0][1];
          let _block;
          let _pipe = params;
          let _pipe$1 = insert(_pipe, "pos_x", float_to_string(x));
          _block = insert(_pipe$1, "pos_y", float_to_string(y));
          let new_params = _block;
          return [
            new Model(new HomeTimeline(timeline_name, new Some(["mdl-postedit", new_params])), model.user, model.ws, model.token, model.status, model.cache, model.has_been_running_for_150ms, model.last_refresh_request_time),
            none2()
          ];
        } else {
          return [model, none2()];
        }
      } else {
        return [model, none2()];
      }
    } else {
      return [model, none2()];
    }
  }
}
function main3() {
  let app = application(init2, update2, view2);
  let $ = start3(app, "#app", false);
  if (!($ instanceof Ok)) {
    throw makeError("let_assert", FILEPATH4, "lumina_client", 109, "main", "Pattern match failed, no pattern matched the value.", {
      value: $,
      start: 3815,
      end: 3866,
      pattern_start: 3826,
      pattern_end: 3831
    });
  }
  return $;
}
function echo2(value2, message, file, line) {
  const grey = "\x1B[90m";
  const reset_color = "\x1B[39m";
  const file_line = `${file}:${line}`;
  const inspector = new Echo$Inspector2;
  const string_value = inspector.inspect(value2);
  const string_message = message === undefined ? "" : " " + message;
  if (globalThis.process?.stderr?.write) {
    const string5 = `${grey}${file_line}${reset_color}${string_message}
${string_value}
`;
    globalThis.process.stderr.write(string5);
  } else if (globalThis.Deno) {
    const string5 = `${grey}${file_line}${reset_color}${string_message}
${string_value}
`;
    globalThis.Deno.stderr.writeSync(new TextEncoder().encode(string5));
  } else {
    const string5 = `${file_line}${string_message}
${string_value}`;
    globalThis.console.log(string5);
  }
  return value2;
}

class Echo$Inspector2 {
  #references = new globalThis.Set;
  #isDict(value2) {
    try {
      const empty_dict2 = new_map();
      const dict_class = empty_dict2.constructor;
      return value2 instanceof dict_class;
    } catch {
      return false;
    }
  }
  #float(float4) {
    const string5 = float4.toString().replace("+", "");
    if (string5.indexOf(".") >= 0) {
      return string5;
    } else {
      const index4 = string5.indexOf("e");
      if (index4 >= 0) {
        return string5.slice(0, index4) + ".0" + string5.slice(index4);
      } else {
        return string5 + ".0";
      }
    }
  }
  inspect(v) {
    const t = typeof v;
    if (v === true)
      return "True";
    if (v === false)
      return "False";
    if (v === null)
      return "//js(null)";
    if (v === undefined)
      return "Nil";
    if (t === "string")
      return this.#string(v);
    if (t === "bigint" || globalThis.Number.isInteger(v))
      return v.toString();
    if (t === "number")
      return this.#float(v);
    if (v instanceof UtfCodepoint)
      return this.#utfCodepoint(v);
    if (v instanceof BitArray)
      return this.#bit_array(v);
    if (v instanceof globalThis.RegExp)
      return `//js(${v})`;
    if (v instanceof globalThis.Date)
      return `//js(Date("${v.toISOString()}"))`;
    if (v instanceof globalThis.Error)
      return `//js(${v.toString()})`;
    if (v instanceof globalThis.Function) {
      const args = [];
      for (const i of globalThis.Array(v.length).keys())
        args.push(globalThis.String.fromCharCode(i + 97));
      return `//fn(${args.join(", ")}) { ... }`;
    }
    if (this.#references.size === this.#references.add(v).size) {
      return "//js(circular reference)";
    }
    let printed;
    if (globalThis.Array.isArray(v)) {
      printed = `#(${v.map((v2) => this.inspect(v2)).join(", ")})`;
    } else if (v instanceof List) {
      printed = this.#list(v);
    } else if (v instanceof CustomType) {
      printed = this.#customType(v);
    } else if (this.#isDict(v)) {
      printed = this.#dict(v);
    } else if (v instanceof Set) {
      return `//js(Set(${[...v].map((v2) => this.inspect(v2)).join(", ")}))`;
    } else {
      printed = this.#object(v);
    }
    this.#references.delete(v);
    return printed;
  }
  #object(v) {
    const name2 = globalThis.Object.getPrototypeOf(v)?.constructor?.name || "Object";
    const props = [];
    for (const k of globalThis.Object.keys(v)) {
      props.push(`${this.inspect(k)}: ${this.inspect(v[k])}`);
    }
    const body = props.length ? " " + props.join(", ") + " " : "";
    const head = name2 === "Object" ? "" : name2 + " ";
    return `//js(${head}{${body}})`;
  }
  #dict(map5) {
    let body = "dict.from_list([";
    let first2 = true;
    let key_value_pairs = fold(map5, [], (pairs, key2, value2) => {
      pairs.push([key2, value2]);
      return pairs;
    });
    key_value_pairs.sort();
    key_value_pairs.forEach(([key2, value2]) => {
      if (!first2)
        body = body + ", ";
      body = body + "#(" + this.inspect(key2) + ", " + this.inspect(value2) + ")";
      first2 = false;
    });
    return body + "])";
  }
  #customType(record) {
    const props = globalThis.Object.keys(record).map((label2) => {
      const value2 = this.inspect(record[label2]);
      return isNaN(parseInt(label2)) ? `${label2}: ${value2}` : value2;
    }).join(", ");
    return props ? `${record.constructor.name}(${props})` : record.constructor.name;
  }
  #list(list4) {
    if (list4 instanceof Empty) {
      return "[]";
    }
    let char_out = 'charlist.from_string("';
    let list_out = "[";
    let current = list4;
    while (current instanceof NonEmpty) {
      let element3 = current.head;
      current = current.tail;
      if (list_out !== "[") {
        list_out += ", ";
      }
      list_out += this.inspect(element3);
      if (char_out) {
        if (globalThis.Number.isInteger(element3) && element3 >= 32 && element3 <= 126) {
          char_out += globalThis.String.fromCharCode(element3);
        } else {
          char_out = null;
        }
      }
    }
    if (char_out) {
      return char_out + '")';
    } else {
      return list_out + "]";
    }
  }
  #string(str) {
    let new_str = '"';
    for (let i = 0;i < str.length; i++) {
      const char = str[i];
      switch (char) {
        case `
`:
          new_str += "\\n";
          break;
        case "\r":
          new_str += "\\r";
          break;
        case "\t":
          new_str += "\\t";
          break;
        case "\f":
          new_str += "\\f";
          break;
        case "\\":
          new_str += "\\\\";
          break;
        case '"':
          new_str += "\\\"";
          break;
        default:
          if (char < " " || char > "~" && char < " ") {
            new_str += "\\u{" + char.charCodeAt(0).toString(16).toUpperCase().padStart(4, "0") + "}";
          } else {
            new_str += char;
          }
      }
    }
    new_str += '"';
    return new_str;
  }
  #utfCodepoint(codepoint2) {
    return `//utfcodepoint(${globalThis.String.fromCodePoint(codepoint2.value)})`;
  }
  #bit_array(bits) {
    if (bits.bitSize === 0) {
      return "<<>>";
    }
    let acc = "<<";
    for (let i = 0;i < bits.byteSize - 1; i++) {
      acc += bits.byteAt(i).toString();
      acc += ", ";
    }
    if (bits.byteSize * 8 === bits.bitSize) {
      acc += bits.byteAt(bits.byteSize - 1).toString();
    } else {
      const trailingBitsCount = bits.bitSize % 8;
      acc += bits.byteAt(bits.byteSize - 1) >> 8 - trailingBitsCount;
      acc += `:size(${trailingBitsCount})`;
    }
    acc += ">>";
    return acc;
  }
}

// build/dev/javascript/lumina_client/lumina_client.ts
document.addEventListener("DOMContentLoaded", main3());
