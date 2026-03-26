import * as $envoy from "../../../envoy/envoy.mjs";
import * as $result from "../../../gleam_stdlib/gleam/result.mjs";
import { Ok, Error, CustomType as $CustomType } from "../../gleam.mjs";
import * as $errors from "../../parrot/internal/errors.mjs";
import * as $sqlc from "../../parrot/internal/sqlc.mjs";

export class Usage extends $CustomType {}
export const Command$Usage = () => new Usage();
export const Command$isUsage = (value) => value instanceof Usage;

export class Generate extends $CustomType {
  constructor(engine, db) {
    super();
    this.engine = engine;
    this.db = db;
  }
}
export const Command$Generate = (engine, db) => new Generate(engine, db);
export const Command$isGenerate = (value) => value instanceof Generate;
export const Command$Generate$engine = (value) => value.engine;
export const Command$Generate$0 = (value) => value.engine;
export const Command$Generate$db = (value) => value.db;
export const Command$Generate$1 = (value) => value.db;

export const usage = "\n  🦜 Parrot - type-safe SQL in gleam for sqlite, postgresql & mysql\n\n  USAGE:\n    gleam run -m parrot -- [OPTIONS]\n    gleam run -m parrot help\n\n  DESCRIPTION:\n    This tool generates type-safe Gleam code from your raw SQL queries.\n    It connects to your database to introspect schemas and validate queries,\n    then generates Gleam functions that you can use in your application.\n\n    By default, it automatically detects your database driver (PostgreSQL,\n    MySQL, or SQLite) by reading the DATABASE_URL environment variable.\n\n  OPTIONS:\n    --sqlite <FILE_PATH>\n      Directly specify the path to a SQLite database file. When this\n      option is used, it bypasses the DATABASE_URL environment\n      variable entirely.\n\n    -e, --env-var <VAR_NAME>\n      Specify the name of an alternative environment variable to use\n      for the database connection URL.\n      Defaults to 'DATABASE_URL'.\n\n  DATABASE_URL:\n    Parrot automatically detects the driver from the URL scheme.\n\n    Formats:\n    - PostgreSQL: postgres://user:password@host:port/dbname\n    - MySQL:      mysql://user:password@host:port/dbname\n    - SQLite:     file:/path/to/your/database.db\n\n  EXAMPLES:\n    # 1. The default: run with a DATABASE_URL environment variable set.\n    $ export DATABASE_URL=\"postgres://user:pass@localhost/mydb\"\n    $ gleam run -m parrot\n\n    # 2. Using Sqlite: directly point to a database file.\n    $ gleam run -m parrot -- --sqlite ./priv/app.db\n\n    # 3. Different environment variable\n    $ export STAGING_DB_URL=\"mysql://staging:pass@remote/db\"\n    $ gleam run -m parrot -- --env-var STAGING_DB_URL\n\n    # 4. Get help\n    $ gleam run -m parrot help\n";

export function engine_from_env(str) {
  if (str.startsWith("postgres")) {
    return new Ok(new $sqlc.PostgreSQL());
  } else if (str.startsWith("mysql")) {
    return new Ok(new $sqlc.MySQL());
  } else if (str === "file") {
    return new Ok(new $sqlc.SQLite());
  } else if (str.startsWith("sqlite")) {
    return new Ok(new $sqlc.SQLite());
  } else {
    return new Error(new $errors.UnknownEngine(str));
  }
}

export function parse_env(env) {
  let env_result = $envoy.get(env);
  return $result.try$(
    $result.replace_error(
      env_result,
      ("Environment Variable \"" + env) + "\" is empty!",
    ),
    (env_var) => {
      let engine_result = engine_from_env(env_var);
      return $result.try$(
        $result.replace_error(
          engine_result,
          ("\"" + env) + "\" does not match any of the supported formats (MySQL, PostgreSQL, SQLite)",
        ),
        (engine) => { return new Ok([engine, env_var]); },
      );
    },
  );
}
