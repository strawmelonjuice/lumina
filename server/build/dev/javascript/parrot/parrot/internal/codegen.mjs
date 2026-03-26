import * as $json from "../../../gleam_json/gleam/json.mjs";
import * as $bool from "../../../gleam_stdlib/gleam/bool.mjs";
import * as $d from "../../../gleam_stdlib/gleam/dynamic/decode.mjs";
import * as $int from "../../../gleam_stdlib/gleam/int.mjs";
import * as $list from "../../../gleam_stdlib/gleam/list.mjs";
import * as $option from "../../../gleam_stdlib/gleam/option.mjs";
import * as $result from "../../../gleam_stdlib/gleam/result.mjs";
import * as $set from "../../../gleam_stdlib/gleam/set.mjs";
import * as $string from "../../../gleam_stdlib/gleam/string.mjs";
import * as $simplifile from "../../../simplifile/simplifile.mjs";
import {
  Ok,
  Error,
  toList,
  Empty as $Empty,
  CustomType as $CustomType,
  makeError,
} from "../../gleam.mjs";
import * as $config from "../../parrot/internal/config.mjs";
import { get_json_file, get_module_directory, get_module_path } from "../../parrot/internal/config.mjs";
import * as $errors from "../../parrot/internal/errors.mjs";
import * as $sqlc from "../../parrot/internal/sqlc.mjs";
import * as $string_case from "../../parrot/internal/string_case.mjs";

const FILEPATH = "src/parrot/internal/codegen.gleam";

export class Codegen extends $CustomType {
  constructor(unknown_types) {
    super();
    this.unknown_types = unknown_types;
  }
}
export const Codegen$Codegen = (unknown_types) => new Codegen(unknown_types);
export const Codegen$isCodegen = (value) => value instanceof Codegen;
export const Codegen$Codegen$unknown_types = (value) => value.unknown_types;
export const Codegen$Codegen$0 = (value) => value.unknown_types;

export class GleamString extends $CustomType {}
export const GleamType$GleamString = () => new GleamString();
export const GleamType$isGleamString = (value) => value instanceof GleamString;

export class GleamInt extends $CustomType {}
export const GleamType$GleamInt = () => new GleamInt();
export const GleamType$isGleamInt = (value) => value instanceof GleamInt;

export class GleamFloat extends $CustomType {}
export const GleamType$GleamFloat = () => new GleamFloat();
export const GleamType$isGleamFloat = (value) => value instanceof GleamFloat;

export class GleamBool extends $CustomType {}
export const GleamType$GleamBool = () => new GleamBool();
export const GleamType$isGleamBool = (value) => value instanceof GleamBool;

export class GleamTimestamp extends $CustomType {}
export const GleamType$GleamTimestamp = () => new GleamTimestamp();
export const GleamType$isGleamTimestamp = (value) =>
  value instanceof GleamTimestamp;

export class GleamDate extends $CustomType {}
export const GleamType$GleamDate = () => new GleamDate();
export const GleamType$isGleamDate = (value) => value instanceof GleamDate;

export class GleamBitArray extends $CustomType {}
export const GleamType$GleamBitArray = () => new GleamBitArray();
export const GleamType$isGleamBitArray = (value) =>
  value instanceof GleamBitArray;

export class GleamList extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const GleamType$GleamList = ($0) => new GleamList($0);
export const GleamType$isGleamList = (value) => value instanceof GleamList;
export const GleamType$GleamList$0 = (value) => value[0];

export class GleamEnum extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const GleamType$GleamEnum = ($0) => new GleamEnum($0);
export const GleamType$isGleamEnum = (value) => value instanceof GleamEnum;
export const GleamType$GleamEnum$0 = (value) => value[0];

export class GleamOption extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const GleamType$GleamOption = ($0) => new GleamOption($0);
export const GleamType$isGleamOption = (value) => value instanceof GleamOption;
export const GleamType$GleamOption$0 = (value) => value[0];

export class GleamDynamic extends $CustomType {}
export const GleamType$GleamDynamic = () => new GleamDynamic();
export const GleamType$isGleamDynamic = (value) =>
  value instanceof GleamDynamic;

export function gleam_type_to_string(gleamtype) {
  if (gleamtype instanceof GleamString) {
    return "String";
  } else if (gleamtype instanceof GleamInt) {
    return "Int";
  } else if (gleamtype instanceof GleamFloat) {
    return "Float";
  } else if (gleamtype instanceof GleamBool) {
    return "Bool";
  } else if (gleamtype instanceof GleamTimestamp) {
    return "Timestamp";
  } else if (gleamtype instanceof GleamDate) {
    return "Date";
  } else if (gleamtype instanceof GleamBitArray) {
    return "BitArray";
  } else if (gleamtype instanceof GleamList) {
    let sub = gleamtype[0];
    return ("List(" + gleam_type_to_string(sub)) + ")";
  } else if (gleamtype instanceof GleamEnum) {
    let name = gleamtype[0];
    return $string_case.pascal_case(name);
  } else if (gleamtype instanceof GleamOption) {
    let sub = gleamtype[0];
    return ("Option(" + gleam_type_to_string(sub)) + ")";
  } else {
    return "decode.Dynamic";
  }
}

function normalise_col_type(col) {
  let type_ = col.type_ref.name;
  if (type_.startsWith("pg_catalog.")) {
    let x = type_.slice(11);
    return x;
  } else if (type_.startsWith("public.")) {
    let x = type_.slice(7);
    return x;
  } else {
    return type_;
  }
}

/**
 *Keywords built into gleam
 * 
 * @ignore
 */
function built_into_gleam(value) {
  if (value === "as") {
    return true;
  } else if (value === "assert") {
    return true;
  } else if (value === "auto") {
    return true;
  } else if (value === "case") {
    return true;
  } else if (value === "const") {
    return true;
  } else if (value === "delegate") {
    return true;
  } else if (value === "derive") {
    return true;
  } else if (value === "echo") {
    return true;
  } else if (value === "else") {
    return true;
  } else if (value === "fn") {
    return true;
  } else if (value === "if") {
    return true;
  } else if (value === "implement") {
    return true;
  } else if (value === "import") {
    return true;
  } else if (value === "let") {
    return true;
  } else if (value === "macro") {
    return true;
  } else if (value === "opaque") {
    return true;
  } else if (value === "panic") {
    return true;
  } else if (value === "pub") {
    return true;
  } else if (value === "test") {
    return true;
  } else if (value === "todo") {
    return true;
  } else if (value === "type") {
    return true;
  } else if (value === "use") {
    return true;
  } else {
    return false;
  }
}

function find_col_schema(col, context) {
  let schema_name = col.type_ref.schema;
  let _block;
  if (schema_name === "") {
    _block = context.catalog.default_schema;
  } else if (schema_name === "pg_catalog") {
    _block = context.catalog.default_schema;
  } else {
    _block = schema_name;
  }
  let schema_name$1 = _block;
  let $ = $list.find(
    context.catalog.schemas,
    (s) => { return s.name === schema_name$1; },
  );
  let schema;
  if ($ instanceof Ok) {
    schema = $[0];
  } else {
    throw makeError(
      "let_assert",
      FILEPATH,
      "parrot/internal/codegen",
      270,
      "find_col_schema",
      "Pattern match failed, no pattern matched the value.",
      {
        value: $,
        start: 7049,
        end: 7144,
        pattern_start: 7060,
        pattern_end: 7070
      }
    )
  }
  return schema;
}

export function sqlc_col_to_gleam(col, context) {
  return $bool.lazy_guard(
    !col.not_null,
    () => {
      let col$1 = new $sqlc.TableColumn(
        col.name,
        true,
        col.is_array,
        col.comment,
        col.length,
        col.is_named_param,
        col.is_func_call,
        col.scope,
        col.table_alias,
        col.is_sqlc_slice,
        col.original_name,
        col.unsigned,
        col.array_dims,
        col.table,
        col.type_ref,
      );
      let type_ = sqlc_col_to_gleam(col$1, context);
      return new GleamOption(type_);
    },
    () => {
      return $bool.lazy_guard(
        col.is_array,
        () => {
          let col$1 = new $sqlc.TableColumn(
            col.name,
            col.not_null,
            false,
            col.comment,
            col.length,
            col.is_named_param,
            col.is_func_call,
            col.scope,
            col.table_alias,
            col.is_sqlc_slice,
            col.original_name,
            col.unsigned,
            col.array_dims,
            col.table,
            col.type_ref,
          );
          let type_ = sqlc_col_to_gleam(col$1, context);
          return new GleamList(type_);
        },
        () => {
          return $bool.lazy_guard(
            col.is_sqlc_slice,
            () => {
              let col$1 = new $sqlc.TableColumn(
                col.name,
                col.not_null,
                col.is_array,
                col.comment,
                col.length,
                col.is_named_param,
                col.is_func_call,
                col.scope,
                col.table_alias,
                false,
                col.original_name,
                col.unsigned,
                col.array_dims,
                col.table,
                col.type_ref,
              );
              let type_ = sqlc_col_to_gleam(col$1, context);
              return new GleamList(type_);
            },
            () => {
              let sqltype = normalise_col_type(col);
              let schema = find_col_schema(col, context);
              let _block;
              let _pipe = schema.enums;
              _block = $list.find(_pipe, (e) => { return e.name === sqltype; });
              let enum$ = _block;
              return $bool.lazy_guard(
                $result.is_ok(enum$),
                () => {
                  let enum$1;
                  if (enum$ instanceof Ok) {
                    enum$1 = enum$[0];
                  } else {
                    throw makeError(
                      "let_assert",
                      FILEPATH,
                      "parrot/internal/codegen",
                      303,
                      "sqlc_col_to_gleam",
                      "Pattern match failed, no pattern matched the value.",
                      {
                        value: enum$,
                        start: 8051,
                        end: 8077,
                        pattern_start: 8062,
                        pattern_end: 8070
                      }
                    )
                  }
                  return new GleamEnum(enum$1.name);
                },
                () => {
                  let sqltype$1 = $string.lowercase(sqltype);
                  let tiny_bool = (sqltype$1 === "tinyint") && (col.length === 1);
                  return $bool.guard(
                    tiny_bool,
                    new GleamBool(),
                    () => {
                      if (sqltype$1.startsWith("int")) {
                        return new GleamInt();
                      } else if (sqltype$1 === "tinyint") {
                        return new GleamInt();
                      } else if (sqltype$1 === "smallint") {
                        return new GleamInt();
                      } else if (sqltype$1 === "mediumint") {
                        return new GleamInt();
                      } else if (sqltype$1 === "bigint") {
                        return new GleamInt();
                      } else if (sqltype$1.startsWith("serial")) {
                        return new GleamInt();
                      } else if (sqltype$1 === "smallserial") {
                        return new GleamInt();
                      } else if (sqltype$1 === "bigserial") {
                        return new GleamInt();
                      } else if (sqltype$1 === "year") {
                        return new GleamInt();
                      } else if (sqltype$1.startsWith("float")) {
                        return new GleamFloat();
                      } else if (sqltype$1.startsWith("dec")) {
                        return new GleamFloat();
                      } else if (sqltype$1 === "fixed") {
                        return new GleamFloat();
                      } else if (sqltype$1 === "real") {
                        return new GleamFloat();
                      } else if (sqltype$1 === "numeric") {
                        return new GleamFloat();
                      } else if (sqltype$1 === "double") {
                        return new GleamFloat();
                      } else if (sqltype$1.startsWith("money")) {
                        return new GleamFloat();
                      } else if (sqltype$1.startsWith("char")) {
                        return new GleamString();
                      } else if (sqltype$1.startsWith("varchar")) {
                        return new GleamString();
                      } else if (sqltype$1.startsWith("text")) {
                        return new GleamString();
                      } else if (sqltype$1.startsWith("mediumtext")) {
                        return new GleamString();
                      } else if (sqltype$1.startsWith("longtext")) {
                        return new GleamString();
                      } else if (sqltype$1.startsWith("citext")) {
                        return new GleamString();
                      } else if (sqltype$1.startsWith("json")) {
                        return new GleamString();
                      } else if (sqltype$1 === "uuid") {
                        return new GleamBitArray();
                      } else if (sqltype$1 === "bit") {
                        return new GleamBitArray();
                      } else if (sqltype$1 === "blob") {
                        return new GleamBitArray();
                      } else if (sqltype$1 === "tinyblob") {
                        return new GleamBitArray();
                      } else if (sqltype$1 === "smallblob") {
                        return new GleamBitArray();
                      } else if (sqltype$1 === "mediumblob") {
                        return new GleamBitArray();
                      } else if (sqltype$1 === "longblob") {
                        return new GleamBitArray();
                      } else if (sqltype$1 === "binary") {
                        return new GleamBitArray();
                      } else if (sqltype$1 === "varbinary") {
                        return new GleamBitArray();
                      } else if (sqltype$1.startsWith("byte")) {
                        return new GleamBitArray();
                      } else if (sqltype$1.startsWith("datetime")) {
                        return new GleamTimestamp();
                      } else if (sqltype$1.startsWith("time")) {
                        return new GleamTimestamp();
                      } else if (sqltype$1.startsWith("date")) {
                        return new GleamDate();
                      } else if (sqltype$1.startsWith("bool")) {
                        return new GleamBool();
                      } else {
                        return new GleamDynamic();
                      }
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

function find_duplicates(context) {
  let _block;
  let _pipe = $list.flat_map(
    context.queries,
    (query) => {
      let _pipe = $list.filter_map(
        query.columns,
        (col) => {
          let $ = sqlc_col_to_gleam(col, context);
          if ($ instanceof GleamEnum) {
            let type_ = normalise_col_type(col);
            let schema = find_col_schema(col, context);
            let $1 = $list.find(
              schema.enums,
              (e) => { return e.name === type_; },
            );
            if ($1 instanceof Ok) {
              let enum$ = $1[0];
              return new Ok([$string_case.pascal_case(enum$.name), enum$.vals]);
            } else {
              return new Error(undefined);
            }
          } else if ($ instanceof GleamOption) {
            let $1 = $[0];
            if ($1 instanceof GleamEnum) {
              let type_ = normalise_col_type(col);
              let schema = find_col_schema(col, context);
              let $2 = $list.find(
                schema.enums,
                (e) => { return e.name === type_; },
              );
              if ($2 instanceof Ok) {
                let enum$ = $2[0];
                return new Ok(
                  [$string_case.pascal_case(enum$.name), enum$.vals],
                );
              } else {
                return new Error(undefined);
              }
            } else {
              return new Error(undefined);
            }
          } else {
            return new Error(undefined);
          }
        },
      );
      return $list.append(
        _pipe,
        $list.filter_map(
          query.params,
          (param) => {
            let $ = sqlc_col_to_gleam(param.column, context);
            if ($ instanceof GleamEnum) {
              let type_ = normalise_col_type(param.column);
              let schema = find_col_schema(param.column, context);
              let $1 = $list.find(
                schema.enums,
                (e) => { return e.name === type_; },
              );
              if ($1 instanceof Ok) {
                let enum$ = $1[0];
                return new Ok(
                  [$string_case.pascal_case(enum$.name), enum$.vals],
                );
              } else {
                return new Error(undefined);
              }
            } else if ($ instanceof GleamOption) {
              let $1 = $[0];
              if ($1 instanceof GleamEnum) {
                let type_ = normalise_col_type(param.column);
                let schema = find_col_schema(param.column, context);
                let $2 = $list.find(
                  schema.enums,
                  (e) => { return e.name === type_; },
                );
                if ($2 instanceof Ok) {
                  let enum$ = $2[0];
                  return new Ok(
                    [$string_case.pascal_case(enum$.name), enum$.vals],
                  );
                } else {
                  return new Error(undefined);
                }
              } else {
                return new Error(undefined);
              }
            } else {
              return new Error(undefined);
            }
          },
        ),
      );
    },
  );
  _block = $list.unique(_pipe);
  let enums_for_duplicate_check = _block;
  let _block$1;
  let _pipe$1 = $list.map(
    context.queries,
    (q) => { return $string_case.pascal_case(q.name); },
  );
  let _pipe$2 = $set.from_list(_pipe$1);
  _block$1 = $set.to_list(_pipe$2);
  let query_names = _block$1;
  let has_duplicate = $list.any(
    enums_for_duplicate_check,
    (item) => {
      let enum_name = item[0];
      return $list.any(
        query_names,
        (query_name) => { return enum_name === query_name; },
      );
    },
  );
  if (has_duplicate) {
    let $ = $list.find(
      enums_for_duplicate_check,
      (item) => {
        let enum_name = item[0];
        return $list.any(
          query_names,
          (query_name) => { return enum_name === query_name; },
        );
      },
    );
    let first;
    if ($ instanceof Ok) {
      first = $[0][0];
    } else {
      throw makeError(
        "let_assert",
        FILEPATH,
        "parrot/internal/codegen",
        194,
        "find_duplicates",
        "Pattern match failed, no pattern matched the value.",
        {
          value: $,
          start: 4887,
          end: 5127,
          pattern_start: 4898,
          pattern_end: 4913
        }
      )
    }
    let $1 = $list.find(
      context.queries,
      (q) => { return $string_case.pascal_case(q.name) === first; },
    );
    let query;
    if ($1 instanceof Ok) {
      query = $1[0];
    } else {
      throw makeError(
        "let_assert",
        FILEPATH,
        "parrot/internal/codegen",
        201,
        "find_duplicates",
        "Pattern match failed, no pattern matched the value.",
        {
          value: $1,
          start: 5134,
          end: 5261,
          pattern_start: 5145,
          pattern_end: 5154
        }
      )
    }
    return new Error(new $errors.DuplicateDefinitionError(first, query.name));
  } else {
    let $ = $list.find(
      enums_for_duplicate_check,
      (item) => {
        let vals = item[1];
        return $list.is_empty(vals);
      },
    );
    if ($ instanceof Ok) {
      let name = $[0][0];
      return new Error(new $errors.EmptyEnumError(name));
    } else {
      let all_enum_values = $list.flat_map(
        enums_for_duplicate_check,
        (item) => {
          let enum_name = item[0];
          let vals = item[1];
          return $list.map(
            vals,
            (val) => { return [$string_case.pascal_case(val), enum_name]; },
          );
        },
      );
      let $1 = $list.find(
        all_enum_values,
        (item) => {
          let val_name = item[0];
          return $list.count(
            all_enum_values,
            (i) => {
              let v = i[0];
              return v === val_name;
            },
          ) > 1;
        },
      );
      if ($1 instanceof Ok) {
        let val_name = $1[0][0];
        let first_enum = $1[0][1];
        let $2 = $list.find(
          all_enum_values,
          (item) => {
            let v = item[0];
            let enum$ = item[1];
            return (v === val_name) && (enum$ !== first_enum);
          },
        );
        let second_enum;
        if ($2 instanceof Ok) {
          second_enum = $2[0][1];
        } else {
          throw makeError(
            "let_assert",
            FILEPATH,
            "parrot/internal/codegen",
            242,
            "find_duplicates",
            "Pattern match failed, no pattern matched the value.",
            {
              value: $2,
              start: 6357,
              end: 6584,
              pattern_start: 6368,
              pattern_end: 6389
            }
          )
        }
        return new Error(
          new $errors.DuplicateEnumValueError(val_name, first_enum, second_enum),
        );
      } else {
        return new Ok(undefined);
      }
    }
  }
}

export function gen_column_name(index, query, col) {
  let _block;
  let _pipe = query.columns;
  _block = $list.count(_pipe, (col2) => { return col.name === col2.name; });
  let occ = _block;
  let _block$1;
  if (occ === 0) {
    throw makeError(
      "panic",
      FILEPATH,
      "parrot/internal/codegen",
      361,
      "gen_column_name",
      ("could not find column name: " + col.name),
      {}
    )
  } else if (occ === 1) {
    _block$1 = col.name;
  } else {
    let $ = col.table;
    if ($ instanceof $option.Some) {
      let t = $[0];
      _block$1 = (t.name + "_") + col.name;
    } else {
      _block$1 = col.name;
    }
  }
  let result = _block$1;
  let _block$2;
  let $ = $string_case.snake_case(result);
  if ($ === "") {
    _block$2 = "col_" + $int.to_string(index);
  } else {
    _block$2 = $;
  }
  let result$1 = _block$2;
  let $1 = built_into_gleam(result$1);
  if ($1) {
    return result$1 + "_";
  } else {
    return result$1;
  }
}

export function gen_query_type(query, context) {
  let name = $string_case.pascal_case(query.name);
  let _block;
  let _pipe = query.columns;
  let _pipe$1 = $list.index_map(
    _pipe,
    (col, index) => {
      let gleam_type = sqlc_col_to_gleam(col, context);
      let col_type = gleam_type_to_string(gleam_type);
      let col_name = gen_column_name(index, query, col);
      return (col_name + ": ") + col_type;
    },
  );
  let _pipe$2 = $list.map(_pipe$1, (str) => { return "    " + str; });
  _block = $string.join(_pipe$2, ",\n");
  let args = _block;
  let _pipe$3 = toList([
    ("pub type " + name) + " {",
    ("  " + name) + "(",
    args,
    "  )",
    "}",
  ]);
  return $string.join(_pipe$3, "\n");
}

function gleam_type_to_param(gtype) {
  if (gtype instanceof GleamString) {
    return "dev.ParamString";
  } else if (gtype instanceof GleamInt) {
    return "dev.ParamInt";
  } else if (gtype instanceof GleamFloat) {
    return "dev.ParamFloat";
  } else if (gtype instanceof GleamBool) {
    return "dev.ParamBool";
  } else if (gtype instanceof GleamTimestamp) {
    return "dev.ParamTimestamp";
  } else if (gtype instanceof GleamDate) {
    return "dev.ParamDate";
  } else if (gtype instanceof GleamBitArray) {
    return "dev.ParamBitArray";
  } else if (gtype instanceof GleamList) {
    let sub = gtype[0];
    return ("dev.ParamList(" + gleam_type_to_param(sub)) + ")";
  } else if (gtype instanceof GleamEnum) {
    return "dev.ParamString";
  } else if (gtype instanceof GleamOption) {
    let sub = gtype[0];
    return ("dev.ParamNullable(" + gleam_type_to_param(sub)) + ")";
  } else {
    return "dev.ParamDynamic";
  }
}

function gleam_type_to_slice_param(gtype) {
  if (gtype instanceof GleamList) {
    let sub = gtype[0];
    return gleam_type_to_param(sub);
  } else {
    return gleam_type_to_param(gtype);
  }
}

function gleam_type_to_return_type(variable, gt) {
  let _block;
  let $ = built_into_gleam(variable);
  if ($) {
    _block = variable + "_";
  } else {
    _block = variable;
  }
  let variable$1 = _block;
  let _block$1;
  if (gt instanceof GleamEnum) {
    let name = gt[0];
    let name$1 = $string_case.snake_case(name);
    _block$1 = ((name$1 + "_to_string(") + variable$1) + ")";
  } else {
    _block$1 = variable$1;
  }
  let value = _block$1;
  if (gt instanceof GleamList) {
    let sub_type = gt[0];
    let sub_param = gleam_type_to_param(sub_type);
    return ((("dev.ParamList(list.map(" + value) + ", ") + sub_param) + "))";
  } else if (gt instanceof GleamOption) {
    let sub_type = gt[0];
    return ((("dev.ParamNullable(option.map(" + value) + ", fn (v) { ") + gleam_type_to_return_type(
      "v",
      sub_type,
    )) + " }))";
  } else {
    let param = gleam_type_to_param(gt);
    return ((param + "(") + value) + ")";
  }
}

export function gen_query_function(query, context) {
  let fn_name = $string_case.snake_case(query.name);
  let _block;
  let _pipe = query.params;
  let _pipe$1 = $list.map(
    _pipe,
    (p) => {
      let gleam_type = sqlc_col_to_gleam(p.column, context);
      let name = p.column.name;
      let _block$1;
      let $ = built_into_gleam(name);
      if ($) {
        _block$1 = name + "_";
      } else {
        _block$1 = name;
      }
      let name$1 = _block$1;
      if (name$1 === "") {
        throw makeError(
          "panic",
          FILEPATH,
          "parrot/internal/codegen",
          468,
          "gen_query_function",
          (("Parameter name for " + fn_name) + " is empty! Please use a named parameter instead (f.e. \"sqlc.arg(name)\" or \"@arg\")"),
          {}
        )
      } else {
        undefined
      }
      return (((name$1 + " ") + name$1) + ": ") + gleam_type_to_string(
        gleam_type,
      );
    },
  );
  _block = $string.join(_pipe$1, ", ");
  let def_fn_args = _block;
  let has_slices = $list.any(
    query.params,
    (p) => { return p.column.is_sqlc_slice; },
  );
  let _block$1;
  if (has_slices) {
    let _pipe$2 = query.params;
    let _pipe$3 = $list.filter(
      _pipe$2,
      (p) => { return p.column.is_sqlc_slice; },
    );
    let _pipe$4 = $list.map(
      _pipe$3,
      (p) => {
        let name = p.column.name;
        let _block$2;
        let $ = built_into_gleam(name);
        if ($) {
          _block$2 = name + "_";
        } else {
          _block$2 = name;
        }
        let safe_name = _block$2;
        return ((("let " + safe_name) + "_slice = string.repeat(\",?\", list.length(") + safe_name) + "))";
      },
    );
    _block$1 = $string.join(_pipe$4, "\n  ");
  } else {
    _block$1 = "";
  }
  let slice_decls = _block$1;
  let _block$2;
  if (has_slices) {
    let escaped = $string.replace(query.text, "\"", "\\\"");
    _block$2 = $list.fold(
      query.params,
      escaped,
      (acc, p) => {
        let $ = p.column.is_sqlc_slice;
        if ($) {
          let name = p.column.name;
          let _block$3;
          let $1 = built_into_gleam(name);
          if ($1) {
            _block$3 = name + "_";
          } else {
            _block$3 = name;
          }
          let safe_name = _block$3;
          return $string.replace(
            acc,
            ("/*SLICE:" + name) + "*/?",
            ("\" <> " + safe_name) + "_slice <> \"",
          );
        } else {
          return acc;
        }
      },
    );
  } else {
    _block$2 = $string.replace(query.text, "\"", "\\\"");
  }
  let text = _block$2;
  let _block$3;
  let $ = query.params;
  if ($ instanceof $Empty) {
    _block$3 = "[]";
  } else {
    let args = $;
    if (has_slices) {
      let all_slice = $list.all(args, (a) => { return a.column.is_sqlc_slice; });
      if (all_slice) {
        let _pipe$2 = args;
        let _pipe$3 = $list.map(
          _pipe$2,
          (arg) => {
            let arg_type = sqlc_col_to_gleam(arg.column, context);
            let sub_param = gleam_type_to_slice_param(arg_type);
            return ((("list.map(" + arg.column.name) + ", ") + sub_param) + ")";
          },
        );
        let _pipe$4 = $string.join(_pipe$3, ", ");
        _block$3 = ((joined) => { return ("list.flatten([" + joined) + "])"; })(
          _pipe$4,
        );
      } else {
        let _pipe$2 = args;
        let _pipe$3 = $list.map(
          _pipe$2,
          (arg) => {
            let arg_type = sqlc_col_to_gleam(arg.column, context);
            let $1 = arg.column.is_sqlc_slice;
            if ($1) {
              let sub_param = gleam_type_to_slice_param(arg_type);
              return ((("list.map(" + arg.column.name) + ", ") + sub_param) + ")";
            } else {
              return gleam_type_to_return_type(arg.column.name, arg_type);
            }
          },
        );
        _block$3 = $list.fold(
          _pipe$3,
          "list.new()",
          (acc, code) => {
            let $1 = $string.starts_with(code, "list.map");
            if ($1) {
              return ((acc + " |> list.append(") + code) + ")";
            } else {
              return ((acc + " |> list.append([") + code) + "])";
            }
          },
        );
      }
    } else {
      _block$3 = ("[" + (() => {
        let _pipe$2 = args;
        let _pipe$3 = $list.map(
          _pipe$2,
          (arg) => {
            let arg_type = sqlc_col_to_gleam(arg.column, context);
            return gleam_type_to_return_type(arg.column.name, arg_type);
          },
        );
        return $string.join(_pipe$3, ", ");
      })()) + "]";
    }
  }
  let def_return_params = _block$3;
  let def_fn = ((("pub fn " + fn_name) + "(") + def_fn_args) + ")";
  let _block$4;
  if (has_slices) {
    let escaped_text = $string.replace(query.text, "\"", "\\\"");
    let _block$5;
    let _pipe$2 = query.params;
    _block$5 = $list.fold(
      _pipe$2,
      escaped_text,
      (acc, p) => {
        let $1 = p.column.is_sqlc_slice;
        if ($1) {
          let name = p.column.name;
          let _block$6;
          let $2 = built_into_gleam(name);
          if ($2) {
            _block$6 = name + "_";
          } else {
            _block$6 = name;
          }
          let safe_name = _block$6;
          return $string.replace(
            acc,
            ("/*SLICE:" + name) + "*/?",
            ("\" <> " + safe_name) + "_slice <> \"",
          );
        } else {
          return acc;
        }
      },
    );
    let modified_sql = _block$5;
    _block$4 = ("let sql = \"" + modified_sql) + "\"";
  } else {
    _block$4 = ("let sql = \"" + text) + "\"";
  }
  let def_sql = _block$4;
  let _block$5;
  let $1 = query.cmd;
  if ($1 instanceof $sqlc.One) {
    _block$5 = fn_name + "_decoder()";
  } else if ($1 instanceof $sqlc.Many) {
    _block$5 = fn_name + "_decoder()";
  } else if ($1 instanceof $sqlc.Exec) {
    _block$5 = "";
  } else if ($1 instanceof $sqlc.ExecResult) {
    _block$5 = "";
  } else if ($1 instanceof $sqlc.ExecRows) {
    throw makeError(
      "panic",
      FILEPATH,
      "parrot/internal/codegen",
      612,
      "gen_query_function",
      ("parrot does not support this query annotation: " + $sqlc.query_cmd_to_string(
        query.cmd,
      )),
      {}
    )
  } else if ($1 instanceof $sqlc.ExecLastId) {
    throw makeError(
      "panic",
      FILEPATH,
      "parrot/internal/codegen",
      612,
      "gen_query_function",
      ("parrot does not support this query annotation: " + $sqlc.query_cmd_to_string(
        query.cmd,
      )),
      {}
    )
  } else if ($1 instanceof $sqlc.BatchExec) {
    throw makeError(
      "panic",
      FILEPATH,
      "parrot/internal/codegen",
      612,
      "gen_query_function",
      ("parrot does not support this query annotation: " + $sqlc.query_cmd_to_string(
        query.cmd,
      )),
      {}
    )
  } else if ($1 instanceof $sqlc.BatchMany) {
    throw makeError(
      "panic",
      FILEPATH,
      "parrot/internal/codegen",
      612,
      "gen_query_function",
      ("parrot does not support this query annotation: " + $sqlc.query_cmd_to_string(
        query.cmd,
      )),
      {}
    )
  } else if ($1 instanceof $sqlc.BatchOne) {
    throw makeError(
      "panic",
      FILEPATH,
      "parrot/internal/codegen",
      612,
      "gen_query_function",
      ("parrot does not support this query annotation: " + $sqlc.query_cmd_to_string(
        query.cmd,
      )),
      {}
    )
  } else {
    throw makeError(
      "panic",
      FILEPATH,
      "parrot/internal/codegen",
      612,
      "gen_query_function",
      ("parrot does not support this query annotation: " + $sqlc.query_cmd_to_string(
        query.cmd,
      )),
      {}
    )
  }
  let def_exp = _block$5;
  let def_return = ((("#(sql, " + def_return_params) + ", ") + def_exp) + ")";
  if (has_slices) {
    let _pipe$2 = toList([
      def_fn + "{",
      "  " + slice_decls,
      "  " + def_sql,
      "  " + def_return,
      "}",
    ]);
    return $string.join(_pipe$2, "\n");
  } else {
    let _pipe$2 = toList([def_fn + "{", "  " + def_sql, "  " + def_return, "}"]);
    return $string.join(_pipe$2, "\n");
  }
}

function gleam_type_to_decoder(gtype) {
  if (gtype instanceof GleamString) {
    return "decode.string";
  } else if (gtype instanceof GleamInt) {
    return "decode.int";
  } else if (gtype instanceof GleamFloat) {
    return "decode.float";
  } else if (gtype instanceof GleamBool) {
    return "dev.bool_decoder()";
  } else if (gtype instanceof GleamTimestamp) {
    return "dev.datetime_decoder()";
  } else if (gtype instanceof GleamDate) {
    return "dev.calendar_date_decoder()";
  } else if (gtype instanceof GleamBitArray) {
    return "decode.bit_array";
  } else if (gtype instanceof GleamList) {
    let x = gtype[0];
    return ("decode.list(of: " + gleam_type_to_decoder(x)) + ")";
  } else if (gtype instanceof GleamEnum) {
    let name = gtype[0];
    let name$1 = $string_case.snake_case(name);
    return name$1 + "_decoder()";
  } else if (gtype instanceof GleamOption) {
    let x = gtype[0];
    return ("decode.optional(" + gleam_type_to_decoder(x)) + ")";
  } else {
    return "decode.dynamic";
  }
}

export function gen_query_decoder(query, context) {
  let $ = $list.length(query.columns);
  if ($ === 0) {
    return "";
  } else {
    let type_name = $string_case.pascal_case(query.name);
    let fn_name = $string_case.snake_case(query.name) + "_decoder";
    let _block;
    let _pipe = query.columns;
    let _pipe$1 = $list.index_map(
      _pipe,
      (col, index) => {
        let col_type = sqlc_col_to_gleam(col, context);
        let decoder_type = gleam_type_to_decoder(col_type);
        let col_name = gen_column_name(index, query, col);
        return ((((("  use " + col_name) + " <- decode.field(") + $int.to_string(
          index,
        )) + ", ") + decoder_type) + ")";
      },
    );
    _block = $string.join(_pipe$1, "\n");
    let decoder_fields = _block;
    let _block$1;
    let _pipe$2 = query.columns;
    let _pipe$3 = $list.index_map(
      _pipe$2,
      (col, index) => { return gen_column_name(index, query, col) + ": "; },
    );
    _block$1 = $string.join(_pipe$3, ", ");
    let constructor_args = _block$1;
    let success_line = ((("  decode.success(" + type_name) + "(") + constructor_args) + "))";
    return ((((((("\n\npub fn " + fn_name) + "() -> decode.Decoder(") + type_name) + ") {\n") + decoder_fields) + "\n") + success_line) + "\n}";
  }
}

function gen_query(query, context) {
  let _block;
  let $ = $list.length(query.columns);
  if ($ === 0) {
    _block = "";
  } else {
    _block = gen_query_type(query, context) + "\n\n";
  }
  let type_str = _block;
  let func = gen_query_function(query, context);
  let deco = gen_query_decoder(query, context);
  return (type_str + func) + deco;
}

function uses_gleam_type(case_fn, context) {
  return $list.any(
    context.queries,
    (query) => {
      let col_ts = $list.any(query.columns, (col) => { return case_fn(col); });
      let param_ts = $list.any(
        query.params,
        (param) => { return case_fn(param.column); },
      );
      return $bool.or(col_ts, param_ts);
    },
  );
}

export function comment_dont_edit() {
  let _pipe = "\n//// Code generated by parrot. DO NOT EDIT.\n////\n  ";
  return $string.trim(_pipe);
}

export function gen_gleam_module(context) {
  return $result.try$(
    find_duplicates(context),
    (_) => {
      let _block;
      let _pipe = context.queries;
      let _pipe$1 = $list.map(
        _pipe,
        (_capture) => { return gen_query(_capture, context); },
      );
      _block = $string.join(_pipe$1, "\n\n");
      let queries = _block;
      let _block$1;
      let _pipe$2 = (col) => {
        let $ = sqlc_col_to_gleam(col, context);
        if ($ instanceof GleamTimestamp) {
          return true;
        } else if ($ instanceof GleamOption) {
          let $1 = $[0];
          if ($1 instanceof GleamTimestamp) {
            return true;
          } else {
            return false;
          }
        } else {
          return false;
        }
      };
      _block$1 = uses_gleam_type(_pipe$2, context);
      let uses_timestamp = _block$1;
      let _block$2;
      let _pipe$3 = (col) => {
        let $ = sqlc_col_to_gleam(col, context);
        if ($ instanceof GleamDate) {
          return true;
        } else if ($ instanceof GleamOption) {
          let $1 = $[0];
          if ($1 instanceof GleamDate) {
            return true;
          } else {
            return false;
          }
        } else {
          return false;
        }
      };
      _block$2 = uses_gleam_type(_pipe$3, context);
      let uses_date = _block$2;
      let _block$3;
      let _pipe$4 = (col) => {
        let $ = sqlc_col_to_gleam(col, context);
        if ($ instanceof GleamList) {
          return true;
        } else if ($ instanceof GleamOption) {
          let $1 = $[0];
          if ($1 instanceof GleamList) {
            return true;
          } else {
            return false;
          }
        } else {
          return false;
        }
      };
      _block$3 = uses_gleam_type(_pipe$4, context);
      let uses_list = _block$3;
      let _block$4;
      if (uses_timestamp) {
        _block$4 = "import gleam/time/timestamp.{type Timestamp}\n";
      } else {
        _block$4 = "";
      }
      let timestamp_import = _block$4;
      let _block$5;
      if (uses_date) {
        _block$5 = "import gleam/time/calendar.{type Date}\n";
      } else {
        _block$5 = "";
      }
      let date_import = _block$5;
      let _block$6;
      if (uses_list) {
        _block$6 = "import gleam/list\n";
      } else {
        _block$6 = "";
      }
      let list_import = _block$6;
      let uses_slice = $list.any(
        context.queries,
        (query) => {
          return $list.any(
            query.params,
            (param) => { return param.column.is_sqlc_slice; },
          );
        },
      );
      let _block$7;
      if (uses_slice) {
        _block$7 = "import gleam/string\n";
      } else {
        _block$7 = "";
      }
      let string_import = _block$7;
      let imports = ((((((("import gleam/dynamic/decode" + "\n") + "import gleam/option.{type Option}") + "\n") + date_import) + timestamp_import) + list_import) + string_import) + "import parrot/dev";
      let _block$8;
      let _pipe$5 = $list.flat_map(
        context.queries,
        (query) => {
          let columns = $list.filter_map(
            query.columns,
            (col) => {
              let $ = sqlc_col_to_gleam(col, context);
              if ($ instanceof GleamEnum) {
                let type_ = normalise_col_type(col);
                let schema = find_col_schema(col, context);
                let _block$9;
                let _pipe$5 = schema.enums;
                _block$9 = $list.find(
                  _pipe$5,
                  (e) => { return e.name === type_; },
                );
                let $1 = _block$9;
                let enum$;
                if ($1 instanceof Ok) {
                  enum$ = $1[0];
                } else {
                  throw makeError(
                    "let_assert",
                    FILEPATH,
                    "parrot/internal/codegen",
                    793,
                    "gen_gleam_module",
                    "Pattern match failed, no pattern matched the value.",
                    {
                      value: $1,
                      start: 21379,
                      end: 21485,
                      pattern_start: 21390,
                      pattern_end: 21398
                    }
                  )
                }
                return new Ok(enum$);
              } else if ($ instanceof GleamOption) {
                let $1 = $[0];
                if ($1 instanceof GleamEnum) {
                  let type_ = normalise_col_type(col);
                  let schema = find_col_schema(col, context);
                  let _block$9;
                  let _pipe$5 = schema.enums;
                  _block$9 = $list.find(
                    _pipe$5,
                    (e) => { return e.name === type_; },
                  );
                  let $2 = _block$9;
                  let enum$;
                  if ($2 instanceof Ok) {
                    enum$ = $2[0];
                  } else {
                    throw makeError(
                      "let_assert",
                      FILEPATH,
                      "parrot/internal/codegen",
                      793,
                      "gen_gleam_module",
                      "Pattern match failed, no pattern matched the value.",
                      {
                        value: $2,
                        start: 21379,
                        end: 21485,
                        pattern_start: 21390,
                        pattern_end: 21398
                      }
                    )
                  }
                  return new Ok(enum$);
                } else {
                  return new Error(undefined);
                }
              } else {
                return new Error(undefined);
              }
            },
          );
          let params = $list.filter_map(
            query.params,
            (param) => {
              let $ = sqlc_col_to_gleam(param.column, context);
              if ($ instanceof GleamEnum) {
                let type_ = normalise_col_type(param.column);
                let schema = find_col_schema(param.column, context);
                let _block$9;
                let _pipe$5 = schema.enums;
                _block$9 = $list.find(
                  _pipe$5,
                  (e) => { return e.name === type_; },
                );
                let $1 = _block$9;
                let enum$;
                if ($1 instanceof Ok) {
                  enum$ = $1[0];
                } else {
                  throw makeError(
                    "let_assert",
                    FILEPATH,
                    "parrot/internal/codegen",
                    809,
                    "gen_gleam_module",
                    "Pattern match failed, no pattern matched the value.",
                    {
                      value: $1,
                      start: 21900,
                      end: 22006,
                      pattern_start: 21911,
                      pattern_end: 21919
                    }
                  )
                }
                return new Ok(enum$);
              } else if ($ instanceof GleamOption) {
                let $1 = $[0];
                if ($1 instanceof GleamEnum) {
                  let type_ = normalise_col_type(param.column);
                  let schema = find_col_schema(param.column, context);
                  let _block$9;
                  let _pipe$5 = schema.enums;
                  _block$9 = $list.find(
                    _pipe$5,
                    (e) => { return e.name === type_; },
                  );
                  let $2 = _block$9;
                  let enum$;
                  if ($2 instanceof Ok) {
                    enum$ = $2[0];
                  } else {
                    throw makeError(
                      "let_assert",
                      FILEPATH,
                      "parrot/internal/codegen",
                      809,
                      "gen_gleam_module",
                      "Pattern match failed, no pattern matched the value.",
                      {
                        value: $2,
                        start: 21900,
                        end: 22006,
                        pattern_start: 21911,
                        pattern_end: 21919
                      }
                    )
                  }
                  return new Ok(enum$);
                } else {
                  return new Error(undefined);
                }
              } else {
                return new Error(undefined);
              }
            },
          );
          return $list.append(columns, params);
        },
      );
      _block$8 = $list.unique(_pipe$5);
      let enums = _block$8;
      let _block$9;
      let _pipe$6 = $list.map(
        enums,
        (enum$) => {
          let record_name = $string_case.pascal_case(enum$.name);
          let fn_name = $string_case.snake_case(enum$.name);
          let values = $list.map(
            enum$.vals,
            (val) => { return "  " + $string_case.pascal_case(val); },
          );
          let to_str_vals = $list.map(
            enum$.vals,
            (val) => {
              let type_ = $string_case.pascal_case(val);
              return (((("    " + type_) + " -> ") + "\"") + val) + "\"";
            },
          );
          let decode_str_vals = $list.map(
            enum$.vals,
            (val) => {
              let type_ = $string_case.pascal_case(val);
              return (((("    \"" + val) + "\" -> ") + "decode.success(") + type_) + ")";
            },
          );
          let $ = $list.first(enum$.vals);
          let first_value;
          if ($ instanceof Ok) {
            first_value = $[0];
          } else {
            throw makeError(
              "let_assert",
              FILEPATH,
              "parrot/internal/codegen",
              843,
              "gen_gleam_module",
              "Pattern match failed, no pattern matched the value.",
              {
                value: $,
                start: 22812,
                end: 22862,
                pattern_start: 22823,
                pattern_end: 22838
              }
            )
          }
          let zero_value = $string_case.pascal_case(first_value);
          return ((((((((((((((((((((((((("pub type " + record_name) + " {\n") + $string.join(
            values,
            "\n",
          )) + "\n}\n\n") + "pub fn ") + fn_name) + "_decoder() {\n") + "  use variant <- decode.then(decode.string)\n") + "  case variant {\n") + $string.join(
            decode_str_vals,
            "\n",
          )) + "\n    _ -> decode.failure(") + zero_value) + ", \"") + record_name) + "\")\n") + "  }\n") + "}\n\n") + "pub fn ") + fn_name) + "_to_string(val: ") + record_name) + ") {\n") + "  case val {\n") + $string.join(
            to_str_vals,
            "\n",
          )) + "\n  }\n") + "}";
        },
      );
      _block$9 = $string.join(_pipe$6, "\n\n");
      let enums$1 = _block$9;
      return new Ok(
        (((((comment_dont_edit() + "\n\n") + imports) + "\n\n") + enums$1) + "\n\n") + queries,
      );
    },
  );
}

export function codegen_from_config(config) {
  return $result.try$(
    (() => {
      let _pipe = get_json_file(config);
      return $result.map_error(
        _pipe,
        (_) => { return new $errors.CodegenError(); },
      );
    })(),
    (json_string) => {
      return $result.try$(
        (() => {
          let _pipe = $json.parse(json_string, $d.dynamic);
          return $result.map_error(
            _pipe,
            (_) => { return new $errors.CodegenError(); },
          );
        })(),
        (dyn_json) => {
          let $ = $sqlc.decode_sqlc(dyn_json);
          let context;
          if ($ instanceof Ok) {
            context = $[0];
          } else {
            throw makeError(
              "let_assert",
              FILEPATH,
              "parrot/internal/codegen",
              35,
              "codegen_from_config",
              "Pattern match failed, no pattern matched the value.",
              {
                value: $,
                start: 823,
                end: 874,
                pattern_start: 834,
                pattern_end: 845
              }
            )
          }
          let _block;
          let _pipe = $list.flat_map(
            context.queries,
            (query) => {
              return $list.map(
                query.columns,
                (col) => {
                  let $1 = sqlc_col_to_gleam(col, context);
                  if ($1 instanceof GleamDynamic) {
                    return new $option.Some(col.type_ref.name);
                  } else {
                    return new $option.None();
                  }
                },
              );
            },
          );
          let _pipe$1 = $list.filter(_pipe, $option.is_some);
          _block = $list.map(
            _pipe$1,
            (_capture) => { return $option.unwrap(_capture, ""); },
          );
          let unknowns = _block;
          return $result.try$(
            gen_gleam_module(context),
            (module_contents) => {
              return $result.try$(
                (() => {
                  let _pipe$2 = get_module_directory(config);
                  let _pipe$3 = $simplifile.create_directory_all(_pipe$2);
                  return $result.map_error(
                    _pipe$3,
                    (_) => { return new $errors.CodegenError(); },
                  );
                })(),
                (_) => {
                  return $result.try$(
                    (() => {
                      let _pipe$2 = $simplifile.write(
                        get_module_path(config),
                        module_contents,
                      );
                      return $result.map_error(
                        _pipe$2,
                        (_) => { return new $errors.CodegenError(); },
                      );
                    })(),
                    (_) => { return new Ok(new Codegen(unknowns)); },
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
