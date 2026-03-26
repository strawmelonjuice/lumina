import * as $filepath from "../../../filepath/filepath.mjs";
import * as $crypto from "../../../gleam_crypto/gleam/crypto.mjs";
import * as $json from "../../../gleam_json/gleam/json.mjs";
import * as $bit_array from "../../../gleam_stdlib/gleam/bit_array.mjs";
import * as $bool from "../../../gleam_stdlib/gleam/bool.mjs";
import * as $dynamic from "../../../gleam_stdlib/gleam/dynamic.mjs";
import * as $decode from "../../../gleam_stdlib/gleam/dynamic/decode.mjs";
import * as $option from "../../../gleam_stdlib/gleam/option.mjs";
import { Some } from "../../../gleam_stdlib/gleam/option.mjs";
import * as $result from "../../../gleam_stdlib/gleam/result.mjs";
import * as $set from "../../../gleam_stdlib/gleam/set.mjs";
import * as $string from "../../../gleam_stdlib/gleam/string.mjs";
import * as $simplifile from "../../../simplifile/simplifile.mjs";
import { Execute, FilePermissions, Read, Write } from "../../../simplifile/simplifile.mjs";
import {
  Ok,
  toList,
  prepend as listPrepend,
  CustomType as $CustomType,
  makeError,
} from "../../gleam.mjs";
import * as $errors from "../../parrot/internal/errors.mjs";
import * as $project from "../../parrot/internal/project.mjs";
import * as $shellout from "../../parrot/internal/shellout.mjs";

const FILEPATH = "src/parrot/internal/sqlc.gleam";

export class SQLite extends $CustomType {}
export const Engine$SQLite = () => new SQLite();
export const Engine$isSQLite = (value) => value instanceof SQLite;

export class MySQL extends $CustomType {}
export const Engine$MySQL = () => new MySQL();
export const Engine$isMySQL = (value) => value instanceof MySQL;

export class PostgreSQL extends $CustomType {}
export const Engine$PostgreSQL = () => new PostgreSQL();
export const Engine$isPostgreSQL = (value) => value instanceof PostgreSQL;

class QueriesSingle extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}

class QueriesMultiple extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}

class GenJson extends $CustomType {
  constructor(out, indent, filename) {
    super();
    this.out = out;
    this.indent = indent;
    this.filename = filename;
  }
}

class Gen extends $CustomType {
  constructor(json) {
    super();
    this.json = json;
  }
}

class Sql extends $CustomType {
  constructor(schema, queries, engine, gen) {
    super();
    this.schema = schema;
    this.queries = queries;
    this.engine = engine;
    this.gen = gen;
  }
}

class Version2 extends $CustomType {}

class Config extends $CustomType {
  constructor(version, sql) {
    super();
    this.version = version;
    this.sql = sql;
  }
}

export class TypeRef extends $CustomType {
  constructor(catalog, schema, name) {
    super();
    this.catalog = catalog;
    this.schema = schema;
    this.name = name;
  }
}
export const TypeRef$TypeRef = (catalog, schema, name) =>
  new TypeRef(catalog, schema, name);
export const TypeRef$isTypeRef = (value) => value instanceof TypeRef;
export const TypeRef$TypeRef$catalog = (value) => value.catalog;
export const TypeRef$TypeRef$0 = (value) => value.catalog;
export const TypeRef$TypeRef$schema = (value) => value.schema;
export const TypeRef$TypeRef$1 = (value) => value.schema;
export const TypeRef$TypeRef$name = (value) => value.name;
export const TypeRef$TypeRef$2 = (value) => value.name;

export class TableColumn extends $CustomType {
  constructor(name, not_null, is_array, comment, length, is_named_param, is_func_call, scope, table_alias, is_sqlc_slice, original_name, unsigned, array_dims, table, type_ref) {
    super();
    this.name = name;
    this.not_null = not_null;
    this.is_array = is_array;
    this.comment = comment;
    this.length = length;
    this.is_named_param = is_named_param;
    this.is_func_call = is_func_call;
    this.scope = scope;
    this.table_alias = table_alias;
    this.is_sqlc_slice = is_sqlc_slice;
    this.original_name = original_name;
    this.unsigned = unsigned;
    this.array_dims = array_dims;
    this.table = table;
    this.type_ref = type_ref;
  }
}
export const TableColumn$TableColumn = (name, not_null, is_array, comment, length, is_named_param, is_func_call, scope, table_alias, is_sqlc_slice, original_name, unsigned, array_dims, table, type_ref) =>
  new TableColumn(name,
  not_null,
  is_array,
  comment,
  length,
  is_named_param,
  is_func_call,
  scope,
  table_alias,
  is_sqlc_slice,
  original_name,
  unsigned,
  array_dims,
  table,
  type_ref);
export const TableColumn$isTableColumn = (value) =>
  value instanceof TableColumn;
export const TableColumn$TableColumn$name = (value) => value.name;
export const TableColumn$TableColumn$0 = (value) => value.name;
export const TableColumn$TableColumn$not_null = (value) => value.not_null;
export const TableColumn$TableColumn$1 = (value) => value.not_null;
export const TableColumn$TableColumn$is_array = (value) => value.is_array;
export const TableColumn$TableColumn$2 = (value) => value.is_array;
export const TableColumn$TableColumn$comment = (value) => value.comment;
export const TableColumn$TableColumn$3 = (value) => value.comment;
export const TableColumn$TableColumn$length = (value) => value.length;
export const TableColumn$TableColumn$4 = (value) => value.length;
export const TableColumn$TableColumn$is_named_param = (value) =>
  value.is_named_param;
export const TableColumn$TableColumn$5 = (value) => value.is_named_param;
export const TableColumn$TableColumn$is_func_call = (value) =>
  value.is_func_call;
export const TableColumn$TableColumn$6 = (value) => value.is_func_call;
export const TableColumn$TableColumn$scope = (value) => value.scope;
export const TableColumn$TableColumn$7 = (value) => value.scope;
export const TableColumn$TableColumn$table_alias = (value) => value.table_alias;
export const TableColumn$TableColumn$8 = (value) => value.table_alias;
export const TableColumn$TableColumn$is_sqlc_slice = (value) =>
  value.is_sqlc_slice;
export const TableColumn$TableColumn$9 = (value) => value.is_sqlc_slice;
export const TableColumn$TableColumn$original_name = (value) =>
  value.original_name;
export const TableColumn$TableColumn$10 = (value) => value.original_name;
export const TableColumn$TableColumn$unsigned = (value) => value.unsigned;
export const TableColumn$TableColumn$11 = (value) => value.unsigned;
export const TableColumn$TableColumn$array_dims = (value) => value.array_dims;
export const TableColumn$TableColumn$12 = (value) => value.array_dims;
export const TableColumn$TableColumn$table = (value) => value.table;
export const TableColumn$TableColumn$13 = (value) => value.table;
export const TableColumn$TableColumn$type_ref = (value) => value.type_ref;
export const TableColumn$TableColumn$14 = (value) => value.type_ref;

export class TableRef extends $CustomType {
  constructor(catalog, schema, name) {
    super();
    this.catalog = catalog;
    this.schema = schema;
    this.name = name;
  }
}
export const TableRef$TableRef = (catalog, schema, name) =>
  new TableRef(catalog, schema, name);
export const TableRef$isTableRef = (value) => value instanceof TableRef;
export const TableRef$TableRef$catalog = (value) => value.catalog;
export const TableRef$TableRef$0 = (value) => value.catalog;
export const TableRef$TableRef$schema = (value) => value.schema;
export const TableRef$TableRef$1 = (value) => value.schema;
export const TableRef$TableRef$name = (value) => value.name;
export const TableRef$TableRef$2 = (value) => value.name;

export class Table extends $CustomType {
  constructor(rel, comment, columns) {
    super();
    this.rel = rel;
    this.comment = comment;
    this.columns = columns;
  }
}
export const Table$Table = (rel, comment, columns) =>
  new Table(rel, comment, columns);
export const Table$isTable = (value) => value instanceof Table;
export const Table$Table$rel = (value) => value.rel;
export const Table$Table$0 = (value) => value.rel;
export const Table$Table$comment = (value) => value.comment;
export const Table$Table$1 = (value) => value.comment;
export const Table$Table$columns = (value) => value.columns;
export const Table$Table$2 = (value) => value.columns;

export class Schema extends $CustomType {
  constructor(comment, name, tables, enums) {
    super();
    this.comment = comment;
    this.name = name;
    this.tables = tables;
    this.enums = enums;
  }
}
export const Schema$Schema = (comment, name, tables, enums) =>
  new Schema(comment, name, tables, enums);
export const Schema$isSchema = (value) => value instanceof Schema;
export const Schema$Schema$comment = (value) => value.comment;
export const Schema$Schema$0 = (value) => value.comment;
export const Schema$Schema$name = (value) => value.name;
export const Schema$Schema$1 = (value) => value.name;
export const Schema$Schema$tables = (value) => value.tables;
export const Schema$Schema$2 = (value) => value.tables;
export const Schema$Schema$enums = (value) => value.enums;
export const Schema$Schema$3 = (value) => value.enums;

export class Enum extends $CustomType {
  constructor(name, vals, comment) {
    super();
    this.name = name;
    this.vals = vals;
    this.comment = comment;
  }
}
export const Enum$Enum = (name, vals, comment) => new Enum(name, vals, comment);
export const Enum$isEnum = (value) => value instanceof Enum;
export const Enum$Enum$name = (value) => value.name;
export const Enum$Enum$0 = (value) => value.name;
export const Enum$Enum$vals = (value) => value.vals;
export const Enum$Enum$1 = (value) => value.vals;
export const Enum$Enum$comment = (value) => value.comment;
export const Enum$Enum$2 = (value) => value.comment;

export class Catalog extends $CustomType {
  constructor(comment, default_schema, name, schemas) {
    super();
    this.comment = comment;
    this.default_schema = default_schema;
    this.name = name;
    this.schemas = schemas;
  }
}
export const Catalog$Catalog = (comment, default_schema, name, schemas) =>
  new Catalog(comment, default_schema, name, schemas);
export const Catalog$isCatalog = (value) => value instanceof Catalog;
export const Catalog$Catalog$comment = (value) => value.comment;
export const Catalog$Catalog$0 = (value) => value.comment;
export const Catalog$Catalog$default_schema = (value) => value.default_schema;
export const Catalog$Catalog$1 = (value) => value.default_schema;
export const Catalog$Catalog$name = (value) => value.name;
export const Catalog$Catalog$2 = (value) => value.name;
export const Catalog$Catalog$schemas = (value) => value.schemas;
export const Catalog$Catalog$3 = (value) => value.schemas;

export class One extends $CustomType {}
export const QueryCmd$One = () => new One();
export const QueryCmd$isOne = (value) => value instanceof One;

export class Many extends $CustomType {}
export const QueryCmd$Many = () => new Many();
export const QueryCmd$isMany = (value) => value instanceof Many;

export class Exec extends $CustomType {}
export const QueryCmd$Exec = () => new Exec();
export const QueryCmd$isExec = (value) => value instanceof Exec;

export class ExecResult extends $CustomType {}
export const QueryCmd$ExecResult = () => new ExecResult();
export const QueryCmd$isExecResult = (value) => value instanceof ExecResult;

export class ExecRows extends $CustomType {}
export const QueryCmd$ExecRows = () => new ExecRows();
export const QueryCmd$isExecRows = (value) => value instanceof ExecRows;

export class ExecLastId extends $CustomType {}
export const QueryCmd$ExecLastId = () => new ExecLastId();
export const QueryCmd$isExecLastId = (value) => value instanceof ExecLastId;

export class BatchExec extends $CustomType {}
export const QueryCmd$BatchExec = () => new BatchExec();
export const QueryCmd$isBatchExec = (value) => value instanceof BatchExec;

export class BatchMany extends $CustomType {}
export const QueryCmd$BatchMany = () => new BatchMany();
export const QueryCmd$isBatchMany = (value) => value instanceof BatchMany;

export class BatchOne extends $CustomType {}
export const QueryCmd$BatchOne = () => new BatchOne();
export const QueryCmd$isBatchOne = (value) => value instanceof BatchOne;

export class CopyFrom extends $CustomType {}
export const QueryCmd$CopyFrom = () => new CopyFrom();
export const QueryCmd$isCopyFrom = (value) => value instanceof CopyFrom;

export class QueryParam extends $CustomType {
  constructor(number, column) {
    super();
    this.number = number;
    this.column = column;
  }
}
export const QueryParam$QueryParam = (number, column) =>
  new QueryParam(number, column);
export const QueryParam$isQueryParam = (value) => value instanceof QueryParam;
export const QueryParam$QueryParam$number = (value) => value.number;
export const QueryParam$QueryParam$0 = (value) => value.number;
export const QueryParam$QueryParam$column = (value) => value.column;
export const QueryParam$QueryParam$1 = (value) => value.column;

export class Query extends $CustomType {
  constructor(text, name, cmd, filename, columns, insert_into_table, comments, params) {
    super();
    this.text = text;
    this.name = name;
    this.cmd = cmd;
    this.filename = filename;
    this.columns = columns;
    this.insert_into_table = insert_into_table;
    this.comments = comments;
    this.params = params;
  }
}
export const Query$Query = (text, name, cmd, filename, columns, insert_into_table, comments, params) =>
  new Query(text,
  name,
  cmd,
  filename,
  columns,
  insert_into_table,
  comments,
  params);
export const Query$isQuery = (value) => value instanceof Query;
export const Query$Query$text = (value) => value.text;
export const Query$Query$0 = (value) => value.text;
export const Query$Query$name = (value) => value.name;
export const Query$Query$1 = (value) => value.name;
export const Query$Query$cmd = (value) => value.cmd;
export const Query$Query$2 = (value) => value.cmd;
export const Query$Query$filename = (value) => value.filename;
export const Query$Query$3 = (value) => value.filename;
export const Query$Query$columns = (value) => value.columns;
export const Query$Query$4 = (value) => value.columns;
export const Query$Query$insert_into_table = (value) => value.insert_into_table;
export const Query$Query$5 = (value) => value.insert_into_table;
export const Query$Query$comments = (value) => value.comments;
export const Query$Query$6 = (value) => value.comments;
export const Query$Query$params = (value) => value.params;
export const Query$Query$7 = (value) => value.params;

export class SQLC extends $CustomType {
  constructor(sqlc_version, plugin_options, global_options, catalog, queries) {
    super();
    this.sqlc_version = sqlc_version;
    this.plugin_options = plugin_options;
    this.global_options = global_options;
    this.catalog = catalog;
    this.queries = queries;
  }
}
export const SQLC$SQLC = (sqlc_version, plugin_options, global_options, catalog, queries) =>
  new SQLC(sqlc_version, plugin_options, global_options, catalog, queries);
export const SQLC$isSQLC = (value) => value instanceof SQLC;
export const SQLC$SQLC$sqlc_version = (value) => value.sqlc_version;
export const SQLC$SQLC$0 = (value) => value.sqlc_version;
export const SQLC$SQLC$plugin_options = (value) => value.plugin_options;
export const SQLC$SQLC$1 = (value) => value.plugin_options;
export const SQLC$SQLC$global_options = (value) => value.global_options;
export const SQLC$SQLC$2 = (value) => value.global_options;
export const SQLC$SQLC$catalog = (value) => value.catalog;
export const SQLC$SQLC$3 = (value) => value.catalog;
export const SQLC$SQLC$queries = (value) => value.queries;
export const SQLC$SQLC$4 = (value) => value.queries;

const sqlc_version = "1.30.0";

function queries_to_json(queries) {
  if (queries instanceof QueriesSingle) {
    let query = queries[0];
    return $json.string(query);
  } else {
    let queries$1 = queries[0];
    return $json.array(queries$1, $json.string);
  }
}

function engine_to_json(engine) {
  let _block;
  if (engine instanceof SQLite) {
    _block = "sqlite";
  } else if (engine instanceof MySQL) {
    _block = "mysql";
  } else {
    _block = "postgresql";
  }
  let engine$1 = _block;
  return $json.string(engine$1);
}

function gen_json_to_json(gen_json) {
  let out;
  let indent;
  let filename;
  out = gen_json.out;
  indent = gen_json.indent;
  filename = gen_json.filename;
  let _block;
  if (out instanceof $option.Some) {
    let out$1 = out[0];
    _block = toList([["out", $json.string(out$1)]]);
  } else {
    _block = toList([]);
  }
  let json_object = _block;
  let _block$1;
  if (indent instanceof $option.Some) {
    let indent$1 = indent[0];
    _block$1 = listPrepend(["indent", $json.string(indent$1)], json_object);
  } else {
    _block$1 = json_object;
  }
  let json_object$1 = _block$1;
  let _block$2;
  if (filename instanceof $option.Some) {
    let filename$1 = filename[0];
    _block$2 = listPrepend(
      ["filename", $json.string(filename$1)],
      json_object$1,
    );
  } else {
    _block$2 = json_object$1;
  }
  let json_object$2 = _block$2;
  return $json.object(json_object$2);
}

function gen_to_json(gen) {
  let json;
  json = gen.json;
  let _block;
  if (json instanceof $option.Some) {
    let json$1 = json[0];
    _block = toList([["json", gen_json_to_json(json$1)]]);
  } else {
    _block = toList([]);
  }
  let json_object = _block;
  return $json.object(json_object);
}

function sql_to_json(sql) {
  let schema;
  let queries;
  let engine;
  let gen;
  schema = sql.schema;
  queries = sql.queries;
  engine = sql.engine;
  gen = sql.gen;
  let json_object = toList([["engine", engine_to_json(engine)]]);
  let _block;
  if (schema instanceof $option.Some) {
    let schema$1 = schema[0];
    _block = listPrepend(["schema", $json.string(schema$1)], json_object);
  } else {
    _block = json_object;
  }
  let json_object$1 = _block;
  let _block$1;
  if (queries instanceof $option.Some) {
    let queries$1 = queries[0];
    _block$1 = listPrepend(
      ["queries", queries_to_json(queries$1)],
      json_object$1,
    );
  } else {
    _block$1 = json_object$1;
  }
  let json_object$2 = _block$1;
  let _block$2;
  if (gen instanceof $option.Some) {
    let gen$1 = gen[0];
    _block$2 = listPrepend(["gen", gen_to_json(gen$1)], json_object$2);
  } else {
    _block$2 = json_object$2;
  }
  let json_object$3 = _block$2;
  return $json.object(json_object$3);
}

function version2_to_json(_) {
  return $json.string("2");
}

function config_to_json(config) {
  let version = config.version;
  let sql = config.sql;
  return $json.object(
    toList([
      ["version", version2_to_json(version)],
      ["sql", $json.array(sql, sql_to_json)],
    ]),
  );
}

function config_to_json_string(config) {
  let _pipe = config_to_json(config);
  return $json.to_string(_pipe);
}

export function query_cmd_to_string(query_cmd) {
  if (query_cmd instanceof One) {
    return "one";
  } else if (query_cmd instanceof Many) {
    return "many";
  } else if (query_cmd instanceof Exec) {
    return "exec";
  } else if (query_cmd instanceof ExecResult) {
    return "exec_result";
  } else if (query_cmd instanceof ExecRows) {
    return "exec_rows";
  } else if (query_cmd instanceof ExecLastId) {
    return "exec_last_id";
  } else if (query_cmd instanceof BatchExec) {
    return "batch_exec";
  } else if (query_cmd instanceof BatchMany) {
    return "batch_many";
  } else if (query_cmd instanceof BatchOne) {
    return "batch_one";
  } else {
    return "copy_from";
  }
}

export function decode_sqlc(data) {
  let table_ref_decoder = $decode.field(
    "name",
    $decode.string,
    (name) => {
      return $decode.field(
        "schema",
        $decode.string,
        (schema) => {
          return $decode.field(
            "catalog",
            $decode.string,
            (catalog) => {
              return $decode.success(new TableRef(catalog, schema, name));
            },
          );
        },
      );
    },
  );
  let type_ref_decoder = $decode.field(
    "schema",
    $decode.string,
    (schema) => {
      return $decode.field(
        "catalog",
        $decode.string,
        (catalog) => {
          return $decode.field(
            "name",
            $decode.string,
            (name) => {
              return $decode.success(new TypeRef(catalog, schema, name));
            },
          );
        },
      );
    },
  );
  let table_col_decoder = $decode.field(
    "name",
    $decode.string,
    (name) => {
      return $decode.field(
        "not_null",
        $decode.bool,
        (not_null) => {
          return $decode.field(
            "is_array",
            $decode.bool,
            (is_array) => {
              return $decode.field(
                "comment",
                $decode.string,
                (comment) => {
                  return $decode.field(
                    "length",
                    $decode.int,
                    (length) => {
                      return $decode.field(
                        "is_named_param",
                        $decode.bool,
                        (is_named_param) => {
                          return $decode.field(
                            "is_func_call",
                            $decode.bool,
                            (is_func_call) => {
                              return $decode.field(
                                "scope",
                                $decode.string,
                                (scope) => {
                                  return $decode.field(
                                    "table_alias",
                                    $decode.string,
                                    (table_alias) => {
                                      return $decode.field(
                                        "is_sqlc_slice",
                                        $decode.bool,
                                        (is_sqlc_slice) => {
                                          return $decode.field(
                                            "original_name",
                                            $decode.string,
                                            (original_name) => {
                                              return $decode.field(
                                                "unsigned",
                                                $decode.bool,
                                                (unsigned) => {
                                                  return $decode.field(
                                                    "array_dims",
                                                    $decode.int,
                                                    (array_dims) => {
                                                      return $decode.field(
                                                        "table",
                                                        $decode.optional(
                                                          table_ref_decoder,
                                                        ),
                                                        (table) => {
                                                          return $decode.field(
                                                            "type",
                                                            type_ref_decoder,
                                                            (type_ref) => {
                                                              let _pipe = new TableColumn(
                                                                name,
                                                                not_null,
                                                                is_array,
                                                                comment,
                                                                length,
                                                                is_named_param,
                                                                is_func_call,
                                                                scope,
                                                                table_alias,
                                                                is_sqlc_slice,
                                                                original_name,
                                                                unsigned,
                                                                array_dims,
                                                                table,
                                                                type_ref,
                                                              );
                                                              return $decode.success(
                                                                _pipe,
                                                              );
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
  let table_decoder = $decode.field(
    "rel",
    table_ref_decoder,
    (rel) => {
      return $decode.field(
        "comment",
        $decode.string,
        (comment) => {
          return $decode.field(
            "columns",
            $decode.list(table_col_decoder),
            (columns) => {
              return $decode.success(new Table(rel, comment, columns));
            },
          );
        },
      );
    },
  );
  let enum_decoder = $decode.field(
    "name",
    $decode.string,
    (name) => {
      return $decode.field(
        "vals",
        $decode.list($decode.string),
        (vals) => {
          return $decode.field(
            "comment",
            $decode.string,
            (comment) => {
              return $decode.success(new Enum(name, vals, comment));
            },
          );
        },
      );
    },
  );
  let schema_decoder = $decode.field(
    "comment",
    $decode.string,
    (comment) => {
      return $decode.field(
        "name",
        $decode.string,
        (name) => {
          return $decode.field(
            "tables",
            $decode.list(table_decoder),
            (tables) => {
              return $decode.field(
                "enums",
                $decode.list(enum_decoder),
                (enums) => {
                  return $decode.success(
                    new Schema(comment, name, tables, enums),
                  );
                },
              );
            },
          );
        },
      );
    },
  );
  let catalog_decoder = $decode.field(
    "comment",
    $decode.string,
    (comment) => {
      return $decode.field(
        "default_schema",
        $decode.string,
        (default_schema) => {
          return $decode.field(
            "name",
            $decode.string,
            (name) => {
              return $decode.field(
                "schemas",
                $decode.list(schema_decoder),
                (schemas) => {
                  return $decode.success(
                    new Catalog(comment, default_schema, name, schemas),
                  );
                },
              );
            },
          );
        },
      );
    },
  );
  let params_decoder = $decode.field(
    "number",
    $decode.int,
    (number) => {
      return $decode.field(
        "column",
        table_col_decoder,
        (column) => { return $decode.success(new QueryParam(number, column)); },
      );
    },
  );
  let cmd_decoder = $decode.then$(
    $decode.string,
    (cmd) => {
      if (cmd === ":one") {
        return $decode.success(new One());
      } else if (cmd === ":many") {
        return $decode.success(new Many());
      } else if (cmd === ":exec") {
        return $decode.success(new ExecResult());
      } else if (cmd === ":execresult") {
        return $decode.success(new ExecResult());
      } else if (cmd === ":execrows") {
        return $decode.success(new ExecRows());
      } else if (cmd === ":execlastid") {
        return $decode.success(new ExecLastId());
      } else if (cmd === ":batchexec") {
        return $decode.success(new BatchExec());
      } else if (cmd === ":batchmany") {
        return $decode.success(new BatchMany());
      } else if (cmd === ":batchone") {
        return $decode.success(new BatchOne());
      } else if (cmd === ":copyfrom") {
        return $decode.success(new CopyFrom());
      } else {
        return $decode.failure(new One(), "QueryCmd");
      }
    },
  );
  let query_decoder = $decode.field(
    "text",
    $decode.string,
    (text) => {
      return $decode.field(
        "name",
        $decode.string,
        (name) => {
          return $decode.field(
            "cmd",
            cmd_decoder,
            (cmd) => {
              return $decode.field(
                "filename",
                $decode.string,
                (filename) => {
                  return $decode.field(
                    "columns",
                    $decode.list(table_col_decoder),
                    (columns) => {
                      return $decode.field(
                        "insert_into_table",
                        $decode.optional(table_ref_decoder),
                        (insert_into_table) => {
                          return $decode.field(
                            "comments",
                            $decode.list($decode.string),
                            (comments) => {
                              return $decode.field(
                                "params",
                                $decode.list(params_decoder),
                                (params) => {
                                  let _pipe = new Query(
                                    text,
                                    name,
                                    cmd,
                                    filename,
                                    columns,
                                    insert_into_table,
                                    comments,
                                    params,
                                  );
                                  return $decode.success(_pipe);
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
            },
          );
        },
      );
    },
  );
  let decoder = $decode.field(
    "sqlc_version",
    $decode.string,
    (sqlc_version) => {
      return $decode.field(
        "plugin_options",
        $decode.string,
        (plugin_options) => {
          return $decode.field(
            "global_options",
            $decode.string,
            (global_options) => {
              return $decode.field(
                "catalog",
                catalog_decoder,
                (catalog) => {
                  return $decode.field(
                    "queries",
                    $decode.list(query_decoder),
                    (queries) => {
                      let _pipe = new SQLC(
                        sqlc_version,
                        plugin_options,
                        global_options,
                        catalog,
                        queries,
                      );
                      return $decode.success(_pipe);
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
  return $decode.run(data, decoder);
}

export function gen_sqlc_json(engine, queries) {
  let config = new Config(
    new Version2(),
    toList([
      new Sql(
        new Some("schema.sql"),
        new Some(new QueriesMultiple(queries)),
        engine,
        new Some(
          new Gen(
            new Some(
              new GenJson(
                new Some("."),
                new Some("  "),
                new Some("queries.json"),
              ),
            ),
          ),
        ),
      ),
    ]),
  );
  return config_to_json_string(config);
}

export function sqlc_binary_path() {
  return $filepath.join($project.root(), "build/.parrot/sqlc");
}

function binary_exists(path) {
  let $ = $simplifile.is_file(path);
  if ($ instanceof Ok) {
    let $1 = $[0];
    if ($1) {
      return true;
    } else {
      return false;
    }
  } else {
    return false;
  }
}

function check_sqlc_integrity(bin, expected_hash) {
  let hash = $crypto.hash(new $crypto.Sha256(), bin);
  let hash_string = $bit_array.base16_encode(hash);
  let $ = $string.lowercase(hash_string) === $string.lowercase(expected_hash);
  if ($) {
    return undefined;
  } else {
    throw makeError(
      "panic",
      FILEPATH,
      "parrot/internal/sqlc",
      476,
      "check_sqlc_integrity",
      "sqlc binary hash did not match expected hash!",
      {}
    )
  }
}
