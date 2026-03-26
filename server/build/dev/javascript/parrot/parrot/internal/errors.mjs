import { CustomType as $CustomType } from "../../gleam.mjs";

export class UnknownEngine extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const ParrotError$UnknownEngine = ($0) => new UnknownEngine($0);
export const ParrotError$isUnknownEngine = (value) =>
  value instanceof UnknownEngine;
export const ParrotError$UnknownEngine$0 = (value) => value[0];

export class SqliteDBNotFound extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const ParrotError$SqliteDBNotFound = ($0) => new SqliteDBNotFound($0);
export const ParrotError$isSqliteDBNotFound = (value) =>
  value instanceof SqliteDBNotFound;
export const ParrotError$SqliteDBNotFound$0 = (value) => value[0];

export class MySqlDBNotFound extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const ParrotError$MySqlDBNotFound = ($0) => new MySqlDBNotFound($0);
export const ParrotError$isMySqlDBNotFound = (value) =>
  value instanceof MySqlDBNotFound;
export const ParrotError$MySqlDBNotFound$0 = (value) => value[0];

export class PostgreSqlDBNotFound extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const ParrotError$PostgreSqlDBNotFound = ($0) =>
  new PostgreSqlDBNotFound($0);
export const ParrotError$isPostgreSqlDBNotFound = (value) =>
  value instanceof PostgreSqlDBNotFound;
export const ParrotError$PostgreSqlDBNotFound$0 = (value) => value[0];

export class SqlcDownloadError extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const ParrotError$SqlcDownloadError = ($0) => new SqlcDownloadError($0);
export const ParrotError$isSqlcDownloadError = (value) =>
  value instanceof SqlcDownloadError;
export const ParrotError$SqlcDownloadError$0 = (value) => value[0];

export class SqlcVersionError extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const ParrotError$SqlcVersionError = ($0) => new SqlcVersionError($0);
export const ParrotError$isSqlcVersionError = (value) =>
  value instanceof SqlcVersionError;
export const ParrotError$SqlcVersionError$0 = (value) => value[0];

export class SqlcGenerateError extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const ParrotError$SqlcGenerateError = ($0) => new SqlcGenerateError($0);
export const ParrotError$isSqlcGenerateError = (value) =>
  value instanceof SqlcGenerateError;
export const ParrotError$SqlcGenerateError$0 = (value) => value[0];

export class GleamFormatError extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const ParrotError$GleamFormatError = ($0) => new GleamFormatError($0);
export const ParrotError$isGleamFormatError = (value) =>
  value instanceof GleamFormatError;
export const ParrotError$GleamFormatError$0 = (value) => value[0];

export class NoQueriesFound extends $CustomType {}
export const ParrotError$NoQueriesFound = () => new NoQueriesFound();
export const ParrotError$isNoQueriesFound = (value) =>
  value instanceof NoQueriesFound;

export class MysqldumpError extends $CustomType {}
export const ParrotError$MysqldumpError = () => new MysqldumpError();
export const ParrotError$isMysqldumpError = (value) =>
  value instanceof MysqldumpError;

export class PgdumpError extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const ParrotError$PgdumpError = ($0) => new PgdumpError($0);
export const ParrotError$isPgdumpError = (value) =>
  value instanceof PgdumpError;
export const ParrotError$PgdumpError$0 = (value) => value[0];

export class CodegenError extends $CustomType {}
export const ParrotError$CodegenError = () => new CodegenError();
export const ParrotError$isCodegenError = (value) =>
  value instanceof CodegenError;

export class DuplicateDefinitionError extends $CustomType {
  constructor($0, $1) {
    super();
    this[0] = $0;
    this[1] = $1;
  }
}
export const ParrotError$DuplicateDefinitionError = ($0, $1) =>
  new DuplicateDefinitionError($0, $1);
export const ParrotError$isDuplicateDefinitionError = (value) =>
  value instanceof DuplicateDefinitionError;
export const ParrotError$DuplicateDefinitionError$0 = (value) => value[0];
export const ParrotError$DuplicateDefinitionError$1 = (value) => value[1];

export class EmptyEnumError extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const ParrotError$EmptyEnumError = ($0) => new EmptyEnumError($0);
export const ParrotError$isEmptyEnumError = (value) =>
  value instanceof EmptyEnumError;
export const ParrotError$EmptyEnumError$0 = (value) => value[0];

export class DuplicateEnumValueError extends $CustomType {
  constructor($0, $1, $2) {
    super();
    this[0] = $0;
    this[1] = $1;
    this[2] = $2;
  }
}
export const ParrotError$DuplicateEnumValueError = ($0, $1, $2) =>
  new DuplicateEnumValueError($0, $1, $2);
export const ParrotError$isDuplicateEnumValueError = (value) =>
  value instanceof DuplicateEnumValueError;
export const ParrotError$DuplicateEnumValueError$0 = (value) => value[0];
export const ParrotError$DuplicateEnumValueError$1 = (value) => value[1];
export const ParrotError$DuplicateEnumValueError$2 = (value) => value[2];

export function err_to_string(error) {
  if (error instanceof UnknownEngine) {
    let engine = error[0];
    return "unknown engine: " + engine;
  } else if (error instanceof SqliteDBNotFound) {
    return "sqlite db not found";
  } else if (error instanceof MySqlDBNotFound) {
    return "mysql db not found";
  } else if (error instanceof PostgreSqlDBNotFound) {
    return "postgresql db not found";
  } else if (error instanceof SqlcDownloadError) {
    let e = error[0];
    return "there was an error downloading sqlc: " + e;
  } else if (error instanceof SqlcVersionError) {
    let e = error[0];
    return "incompatible sqlc version found: " + e;
  } else if (error instanceof SqlcGenerateError) {
    let e = error[0];
    return "could not call `sqlc generate`:\n" + e;
  } else if (error instanceof GleamFormatError) {
    let err = error[0];
    return "there was an error formatting the generated code:" + err;
  } else if (error instanceof NoQueriesFound) {
    return "no queries were found to codegen";
  } else if (error instanceof MysqldumpError) {
    return "there was an error with mysqldump";
  } else if (error instanceof PgdumpError) {
    let e = error[0];
    return e;
  } else if (error instanceof CodegenError) {
    return "there was an error during codegen";
  } else if (error instanceof DuplicateDefinitionError) {
    let name = error[0];
    return (((((("duplicate definition found: '" + name) + "' is defined both as an enum and as a query. ") + "Consider renaming your query (e.g., to 'Get") + name) + "' or 'List") + name) + "') to avoid the collision.";
  } else if (error instanceof EmptyEnumError) {
    let name = error[0];
    return ((("enum '" + name) + "' has no variants. ") + "Empty enums cannot be represented in Gleam. ") + "Please add values to the enum or remove it from your schema.";
  } else {
    let val_name = error[0];
    let enum1 = error[1];
    let enum2 = error[2];
    return (((((("duplicate enum value '" + val_name) + "' found in both '") + enum1) + "' and '") + enum2) + "'. ") + "Enum values must be unique across all enums to avoid naming conflicts in generated Gleam code.";
  }
}
