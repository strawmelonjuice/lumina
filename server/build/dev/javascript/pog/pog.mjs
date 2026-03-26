import * as $exception from "../exception/exception.mjs";
import * as $process from "../gleam_erlang/gleam/erlang/process.mjs";
import * as $reference from "../gleam_erlang/gleam/erlang/reference.mjs";
import * as $actor from "../gleam_otp/gleam/otp/actor.mjs";
import * as $supervision from "../gleam_otp/gleam/otp/supervision.mjs";
import * as $dynamic from "../gleam_stdlib/gleam/dynamic.mjs";
import * as $decode from "../gleam_stdlib/gleam/dynamic/decode.mjs";
import * as $float from "../gleam_stdlib/gleam/float.mjs";
import * as $int from "../gleam_stdlib/gleam/int.mjs";
import * as $list from "../gleam_stdlib/gleam/list.mjs";
import * as $option from "../gleam_stdlib/gleam/option.mjs";
import { None, Some } from "../gleam_stdlib/gleam/option.mjs";
import * as $result from "../gleam_stdlib/gleam/result.mjs";
import * as $string from "../gleam_stdlib/gleam/string.mjs";
import * as $uri from "../gleam_stdlib/gleam/uri.mjs";
import { Uri } from "../gleam_stdlib/gleam/uri.mjs";
import * as $calendar from "../gleam_time/gleam/time/calendar.mjs";
import * as $timestamp from "../gleam_time/gleam/time/timestamp.mjs";
import {
  Ok,
  Error,
  toList,
  Empty as $Empty,
  prepend as listPrepend,
  CustomType as $CustomType,
} from "./gleam.mjs";

class Pool extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}

class SingleConnection extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}

export class Config extends $CustomType {
  constructor(pool_name, host, port, database, user, password, ssl, connection_parameters, pool_size, queue_target, queue_interval, idle_interval, trace, ip_version, rows_as_map) {
    super();
    this.pool_name = pool_name;
    this.host = host;
    this.port = port;
    this.database = database;
    this.user = user;
    this.password = password;
    this.ssl = ssl;
    this.connection_parameters = connection_parameters;
    this.pool_size = pool_size;
    this.queue_target = queue_target;
    this.queue_interval = queue_interval;
    this.idle_interval = idle_interval;
    this.trace = trace;
    this.ip_version = ip_version;
    this.rows_as_map = rows_as_map;
  }
}
export const Config$Config = (pool_name, host, port, database, user, password, ssl, connection_parameters, pool_size, queue_target, queue_interval, idle_interval, trace, ip_version, rows_as_map) =>
  new Config(pool_name,
  host,
  port,
  database,
  user,
  password,
  ssl,
  connection_parameters,
  pool_size,
  queue_target,
  queue_interval,
  idle_interval,
  trace,
  ip_version,
  rows_as_map);
export const Config$isConfig = (value) => value instanceof Config;
export const Config$Config$pool_name = (value) => value.pool_name;
export const Config$Config$0 = (value) => value.pool_name;
export const Config$Config$host = (value) => value.host;
export const Config$Config$1 = (value) => value.host;
export const Config$Config$port = (value) => value.port;
export const Config$Config$2 = (value) => value.port;
export const Config$Config$database = (value) => value.database;
export const Config$Config$3 = (value) => value.database;
export const Config$Config$user = (value) => value.user;
export const Config$Config$4 = (value) => value.user;
export const Config$Config$password = (value) => value.password;
export const Config$Config$5 = (value) => value.password;
export const Config$Config$ssl = (value) => value.ssl;
export const Config$Config$6 = (value) => value.ssl;
export const Config$Config$connection_parameters = (value) =>
  value.connection_parameters;
export const Config$Config$7 = (value) => value.connection_parameters;
export const Config$Config$pool_size = (value) => value.pool_size;
export const Config$Config$8 = (value) => value.pool_size;
export const Config$Config$queue_target = (value) => value.queue_target;
export const Config$Config$9 = (value) => value.queue_target;
export const Config$Config$queue_interval = (value) => value.queue_interval;
export const Config$Config$10 = (value) => value.queue_interval;
export const Config$Config$idle_interval = (value) => value.idle_interval;
export const Config$Config$11 = (value) => value.idle_interval;
export const Config$Config$trace = (value) => value.trace;
export const Config$Config$12 = (value) => value.trace;
export const Config$Config$ip_version = (value) => value.ip_version;
export const Config$Config$13 = (value) => value.ip_version;
export const Config$Config$rows_as_map = (value) => value.rows_as_map;
export const Config$Config$14 = (value) => value.rows_as_map;

export class SslVerified extends $CustomType {}
export const Ssl$SslVerified = () => new SslVerified();
export const Ssl$isSslVerified = (value) => value instanceof SslVerified;

export class SslUnverified extends $CustomType {}
export const Ssl$SslUnverified = () => new SslUnverified();
export const Ssl$isSslUnverified = (value) => value instanceof SslUnverified;

export class SslDisabled extends $CustomType {}
export const Ssl$SslDisabled = () => new SslDisabled();
export const Ssl$isSslDisabled = (value) => value instanceof SslDisabled;

export class Ipv4 extends $CustomType {}
export const IpVersion$Ipv4 = () => new Ipv4();
export const IpVersion$isIpv4 = (value) => value instanceof Ipv4;

export class Ipv6 extends $CustomType {}
export const IpVersion$Ipv6 = () => new Ipv6();
export const IpVersion$isIpv6 = (value) => value instanceof Ipv6;

export class TransactionQueryError extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const TransactionError$TransactionQueryError = ($0) =>
  new TransactionQueryError($0);
export const TransactionError$isTransactionQueryError = (value) =>
  value instanceof TransactionQueryError;
export const TransactionError$TransactionQueryError$0 = (value) => value[0];

export class TransactionRolledBack extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const TransactionError$TransactionRolledBack = ($0) =>
  new TransactionRolledBack($0);
export const TransactionError$isTransactionRolledBack = (value) =>
  value instanceof TransactionRolledBack;
export const TransactionError$TransactionRolledBack$0 = (value) => value[0];

export class Returned extends $CustomType {
  constructor(count, rows) {
    super();
    this.count = count;
    this.rows = rows;
  }
}
export const Returned$Returned = (count, rows) => new Returned(count, rows);
export const Returned$isReturned = (value) => value instanceof Returned;
export const Returned$Returned$count = (value) => value.count;
export const Returned$Returned$0 = (value) => value.count;
export const Returned$Returned$rows = (value) => value.rows;
export const Returned$Returned$1 = (value) => value.rows;

/**
 * The query failed as a database constraint would have been violated by the
 * change.
 */
export class ConstraintViolated extends $CustomType {
  constructor(message, constraint, detail) {
    super();
    this.message = message;
    this.constraint = constraint;
    this.detail = detail;
  }
}
export const QueryError$ConstraintViolated = (message, constraint, detail) =>
  new ConstraintViolated(message, constraint, detail);
export const QueryError$isConstraintViolated = (value) =>
  value instanceof ConstraintViolated;
export const QueryError$ConstraintViolated$message = (value) => value.message;
export const QueryError$ConstraintViolated$0 = (value) => value.message;
export const QueryError$ConstraintViolated$constraint = (value) =>
  value.constraint;
export const QueryError$ConstraintViolated$1 = (value) => value.constraint;
export const QueryError$ConstraintViolated$detail = (value) => value.detail;
export const QueryError$ConstraintViolated$2 = (value) => value.detail;

/**
 * The query failed within the database.
 * https://www.postgresql.org/docs/current/errcodes-appendix.html
 */
export class PostgresqlError extends $CustomType {
  constructor(code, name, message) {
    super();
    this.code = code;
    this.name = name;
    this.message = message;
  }
}
export const QueryError$PostgresqlError = (code, name, message) =>
  new PostgresqlError(code, name, message);
export const QueryError$isPostgresqlError = (value) =>
  value instanceof PostgresqlError;
export const QueryError$PostgresqlError$code = (value) => value.code;
export const QueryError$PostgresqlError$0 = (value) => value.code;
export const QueryError$PostgresqlError$name = (value) => value.name;
export const QueryError$PostgresqlError$1 = (value) => value.name;
export const QueryError$PostgresqlError$message = (value) => value.message;
export const QueryError$PostgresqlError$2 = (value) => value.message;

export class UnexpectedArgumentCount extends $CustomType {
  constructor(expected, got) {
    super();
    this.expected = expected;
    this.got = got;
  }
}
export const QueryError$UnexpectedArgumentCount = (expected, got) =>
  new UnexpectedArgumentCount(expected, got);
export const QueryError$isUnexpectedArgumentCount = (value) =>
  value instanceof UnexpectedArgumentCount;
export const QueryError$UnexpectedArgumentCount$expected = (value) =>
  value.expected;
export const QueryError$UnexpectedArgumentCount$0 = (value) => value.expected;
export const QueryError$UnexpectedArgumentCount$got = (value) => value.got;
export const QueryError$UnexpectedArgumentCount$1 = (value) => value.got;

/**
 * One of the arguments supplied was not of the type that the query required.
 */
export class UnexpectedArgumentType extends $CustomType {
  constructor(expected, got) {
    super();
    this.expected = expected;
    this.got = got;
  }
}
export const QueryError$UnexpectedArgumentType = (expected, got) =>
  new UnexpectedArgumentType(expected, got);
export const QueryError$isUnexpectedArgumentType = (value) =>
  value instanceof UnexpectedArgumentType;
export const QueryError$UnexpectedArgumentType$expected = (value) =>
  value.expected;
export const QueryError$UnexpectedArgumentType$0 = (value) => value.expected;
export const QueryError$UnexpectedArgumentType$got = (value) => value.got;
export const QueryError$UnexpectedArgumentType$1 = (value) => value.got;

/**
 * The rows returned by the database could not be decoded using the supplied
 * dynamic decoder.
 */
export class UnexpectedResultType extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const QueryError$UnexpectedResultType = ($0) =>
  new UnexpectedResultType($0);
export const QueryError$isUnexpectedResultType = (value) =>
  value instanceof UnexpectedResultType;
export const QueryError$UnexpectedResultType$0 = (value) => value[0];

export class QueryTimeout extends $CustomType {}
export const QueryError$QueryTimeout = () => new QueryTimeout();
export const QueryError$isQueryTimeout = (value) =>
  value instanceof QueryTimeout;

export class ConnectionUnavailable extends $CustomType {}
export const QueryError$ConnectionUnavailable = () =>
  new ConnectionUnavailable();
export const QueryError$isConnectionUnavailable = (value) =>
  value instanceof ConnectionUnavailable;

class Query extends $CustomType {
  constructor(sql, parameters, row_decoder, timeout) {
    super();
    this.sql = sql;
    this.parameters = parameters;
    this.row_decoder = row_decoder;
    this.timeout = timeout;
  }
}

/**
 * The port that will be used when none is specified.
 * 
 * @ignore
 */
const default_port = 5432;

/**
 * Create a reference to a pool using the pool's name.
 *
 * If no pool has been started using this name then queries using this
 * connection will fail.
 */
export function named_connection(name) {
  return new Pool(name);
}

/**
 * Database server hostname.
 *
 * (default: 127.0.0.1)
 */
export function host(config, host) {
  return new Config(
    config.pool_name,
    host,
    config.port,
    config.database,
    config.user,
    config.password,
    config.ssl,
    config.connection_parameters,
    config.pool_size,
    config.queue_target,
    config.queue_interval,
    config.idle_interval,
    config.trace,
    config.ip_version,
    config.rows_as_map,
  );
}

/**
 * Port the server is listening on.
 *
 * (default: 5432)
 */
export function port(config, port) {
  return new Config(
    config.pool_name,
    config.host,
    port,
    config.database,
    config.user,
    config.password,
    config.ssl,
    config.connection_parameters,
    config.pool_size,
    config.queue_target,
    config.queue_interval,
    config.idle_interval,
    config.trace,
    config.ip_version,
    config.rows_as_map,
  );
}

/**
 * Name of database to use.
 */
export function database(config, database) {
  return new Config(
    config.pool_name,
    config.host,
    config.port,
    database,
    config.user,
    config.password,
    config.ssl,
    config.connection_parameters,
    config.pool_size,
    config.queue_target,
    config.queue_interval,
    config.idle_interval,
    config.trace,
    config.ip_version,
    config.rows_as_map,
  );
}

/**
 * Username to connect to database as.
 */
export function user(config, user) {
  return new Config(
    config.pool_name,
    config.host,
    config.port,
    config.database,
    user,
    config.password,
    config.ssl,
    config.connection_parameters,
    config.pool_size,
    config.queue_target,
    config.queue_interval,
    config.idle_interval,
    config.trace,
    config.ip_version,
    config.rows_as_map,
  );
}

/**
 * Password for the user.
 */
export function password(config, password) {
  return new Config(
    config.pool_name,
    config.host,
    config.port,
    config.database,
    config.user,
    password,
    config.ssl,
    config.connection_parameters,
    config.pool_size,
    config.queue_target,
    config.queue_interval,
    config.idle_interval,
    config.trace,
    config.ip_version,
    config.rows_as_map,
  );
}

/**
 * Whether to use SSL or not.
 *
 * (default: False)
 */
export function ssl(config, ssl) {
  return new Config(
    config.pool_name,
    config.host,
    config.port,
    config.database,
    config.user,
    config.password,
    ssl,
    config.connection_parameters,
    config.pool_size,
    config.queue_target,
    config.queue_interval,
    config.idle_interval,
    config.trace,
    config.ip_version,
    config.rows_as_map,
  );
}

/**
 * Any Postgres connection parameter here, such as
 * `"application_name: myappname"` and `"timezone: GMT"`
 */
export function connection_parameter(config, name, value) {
  return new Config(
    config.pool_name,
    config.host,
    config.port,
    config.database,
    config.user,
    config.password,
    config.ssl,
    listPrepend([name, value], config.connection_parameters),
    config.pool_size,
    config.queue_target,
    config.queue_interval,
    config.idle_interval,
    config.trace,
    config.ip_version,
    config.rows_as_map,
  );
}

/**
 * Number of connections to keep open with the database
 *
 * default: 10
 */
export function pool_size(config, pool_size) {
  return new Config(
    config.pool_name,
    config.host,
    config.port,
    config.database,
    config.user,
    config.password,
    config.ssl,
    config.connection_parameters,
    pool_size,
    config.queue_target,
    config.queue_interval,
    config.idle_interval,
    config.trace,
    config.ip_version,
    config.rows_as_map,
  );
}

/**
 * Checking out connections is handled through a queue. If it
 * takes longer than queue_target to get out of the queue for longer than
 * queue_interval then the queue_target will be doubled and checkouts will
 * start to be dropped if that target is surpassed.
 *
 * default: 50
 */
export function queue_target(config, queue_target) {
  return new Config(
    config.pool_name,
    config.host,
    config.port,
    config.database,
    config.user,
    config.password,
    config.ssl,
    config.connection_parameters,
    config.pool_size,
    queue_target,
    config.queue_interval,
    config.idle_interval,
    config.trace,
    config.ip_version,
    config.rows_as_map,
  );
}

/**
 * Checking out connections is handled through a queue. If it
 * takes longer than queue_target to get out of the queue for longer than
 * queue_interval then the queue_target will be doubled and checkouts will
 * start to be dropped if that target is surpassed.
 *
 * default: 1000
 */
export function queue_interval(config, queue_interval) {
  return new Config(
    config.pool_name,
    config.host,
    config.port,
    config.database,
    config.user,
    config.password,
    config.ssl,
    config.connection_parameters,
    config.pool_size,
    config.queue_target,
    queue_interval,
    config.idle_interval,
    config.trace,
    config.ip_version,
    config.rows_as_map,
  );
}

/**
 * The database is pinged every idle_interval when the connection is idle.
 *
 * default: 1000
 */
export function idle_interval(config, idle_interval) {
  return new Config(
    config.pool_name,
    config.host,
    config.port,
    config.database,
    config.user,
    config.password,
    config.ssl,
    config.connection_parameters,
    config.pool_size,
    config.queue_target,
    config.queue_interval,
    idle_interval,
    config.trace,
    config.ip_version,
    config.rows_as_map,
  );
}

/**
 * Trace pgo is instrumented with [OpenTelemetry][1] and
 * when this option is true a span will be created (if sampled).
 *
 * default: False
 *
 * [1]: https://opentelemetry.io
 */
export function trace(config, trace) {
  return new Config(
    config.pool_name,
    config.host,
    config.port,
    config.database,
    config.user,
    config.password,
    config.ssl,
    config.connection_parameters,
    config.pool_size,
    config.queue_target,
    config.queue_interval,
    config.idle_interval,
    trace,
    config.ip_version,
    config.rows_as_map,
  );
}

/**
 * Which internet protocol to use for this connection
 */
export function ip_version(config, ip_version) {
  return new Config(
    config.pool_name,
    config.host,
    config.port,
    config.database,
    config.user,
    config.password,
    config.ssl,
    config.connection_parameters,
    config.pool_size,
    config.queue_target,
    config.queue_interval,
    config.idle_interval,
    config.trace,
    ip_version,
    config.rows_as_map,
  );
}

/**
 * By default, pgo will return a n-tuple, in the order of the query.
 * By setting `rows_as_map` to `True`, the result will be `Dict`.
 */
export function rows_as_map(config, rows_as_map) {
  return new Config(
    config.pool_name,
    config.host,
    config.port,
    config.database,
    config.user,
    config.password,
    config.ssl,
    config.connection_parameters,
    config.pool_size,
    config.queue_target,
    config.queue_interval,
    config.idle_interval,
    config.trace,
    config.ip_version,
    rows_as_map,
  );
}

/**
 * Expects `userinfo` as `"username"` or `"username:password"`. Fails otherwise.
 * 
 * @ignore
 */
function extract_user_password(userinfo) {
  let $ = $string.split(userinfo, ":");
  if ($ instanceof $Empty) {
    return new Error(undefined);
  } else {
    let $1 = $.tail;
    if ($1 instanceof $Empty) {
      let user$1 = $.head;
      return new Ok([user$1, new None()]);
    } else {
      let $2 = $1.tail;
      if ($2 instanceof $Empty) {
        let user$1 = $.head;
        let password$1 = $1.head;
        return new Ok([user$1, new Some(password$1)]);
      } else {
        return new Error(undefined);
      }
    }
  }
}

/**
 * Expects `sslmode` to be `require`, `verify-ca`, `verify-full` or `disable`.
 *
 * If `sslmode` is set, but not one of those value, fails.
 *
 * If `sslmode` is `verify-ca` or `verify-full`, returns `SslVerified`.
 *
 * If `sslmode` is `require`, returns `SslUnverified`.
 *
 * If `sslmode` is unset, returns `SslDisabled`.
 * 
 * @ignore
 */
function extract_ssl_mode(query) {
  if (query instanceof $option.Some) {
    let query$1 = query[0];
    return $result.try$(
      $uri.parse_query(query$1),
      (query) => {
        return $result.try$(
          $list.key_find(query, "sslmode"),
          (sslmode) => {
            if (sslmode === "require") {
              return new Ok(new SslUnverified());
            } else if (sslmode === "verify-ca") {
              return new Ok(new SslVerified());
            } else if (sslmode === "verify-full") {
              return new Ok(new SslVerified());
            } else if (sslmode === "disable") {
              return new Ok(new SslDisabled());
            } else {
              return new Error(undefined);
            }
          },
        );
      },
    );
  } else {
    return new Ok(new SslDisabled());
  }
}

/**
 * Create a new query to use with the `execute`, `returning`, and `parameter`
 * functions.
 */
export function query(sql) {
  return new Query(sql, toList([]), $decode.success(undefined), 5000);
}

/**
 * Set the decoder to use for the type of row returned by executing this
 * query.
 *
 * If the decoder is unable to decode the row value then the query will return
 * an error from the `exec` function, but the query will still have been run
 * against the database.
 */
export function returning(query, decoder) {
  let sql;
  let parameters;
  let timeout$1;
  sql = query.sql;
  parameters = query.parameters;
  timeout$1 = query.timeout;
  return new Query(sql, parameters, decoder, timeout$1);
}

/**
 * Push a new query parameter value for the query.
 */
export function parameter(query, parameter) {
  return new Query(
    query.sql,
    listPrepend(parameter, query.parameters),
    query.row_decoder,
    query.timeout,
  );
}

/**
 * Use a custom timeout for the query, in milliseconds.
 * the default connection timeout.
 *
 * If this function is not used to give a timeout then default of 5000 ms is
 * used.
 */
export function timeout(query, timeout) {
  return new Query(query.sql, query.parameters, query.row_decoder, timeout);
}

/**
 * Get the name for a PostgreSQL error code.
 *
 * ```gleam
 * > error_code_name("01007")
 * Ok("privilege_not_granted")
 * ```
 *
 * https://www.postgresql.org/docs/current/errcodes-appendix.html
 */
export function error_code_name(error_code) {
  if (error_code === "00000") {
    return new Ok("successful_completion");
  } else if (error_code === "01000") {
    return new Ok("warning");
  } else if (error_code === "0100C") {
    return new Ok("dynamic_result_sets_returned");
  } else if (error_code === "01008") {
    return new Ok("implicit_zero_bit_padding");
  } else if (error_code === "01003") {
    return new Ok("null_value_eliminated_in_set_function");
  } else if (error_code === "01007") {
    return new Ok("privilege_not_granted");
  } else if (error_code === "01006") {
    return new Ok("privilege_not_revoked");
  } else if (error_code === "01004") {
    return new Ok("string_data_right_truncation");
  } else if (error_code === "01P01") {
    return new Ok("deprecated_feature");
  } else if (error_code === "02000") {
    return new Ok("no_data");
  } else if (error_code === "02001") {
    return new Ok("no_additional_dynamic_result_sets_returned");
  } else if (error_code === "03000") {
    return new Ok("sql_statement_not_yet_complete");
  } else if (error_code === "08000") {
    return new Ok("connection_exception");
  } else if (error_code === "08003") {
    return new Ok("connection_does_not_exist");
  } else if (error_code === "08006") {
    return new Ok("connection_failure");
  } else if (error_code === "08001") {
    return new Ok("sqlclient_unable_to_establish_sqlconnection");
  } else if (error_code === "08004") {
    return new Ok("sqlserver_rejected_establishment_of_sqlconnection");
  } else if (error_code === "08007") {
    return new Ok("transaction_resolution_unknown");
  } else if (error_code === "08P01") {
    return new Ok("protocol_violation");
  } else if (error_code === "09000") {
    return new Ok("triggered_action_exception");
  } else if (error_code === "0A000") {
    return new Ok("feature_not_supported");
  } else if (error_code === "0B000") {
    return new Ok("invalid_transaction_initiation");
  } else if (error_code === "0F000") {
    return new Ok("locator_exception");
  } else if (error_code === "0F001") {
    return new Ok("invalid_locator_specification");
  } else if (error_code === "0L000") {
    return new Ok("invalid_grantor");
  } else if (error_code === "0LP01") {
    return new Ok("invalid_grant_operation");
  } else if (error_code === "0P000") {
    return new Ok("invalid_role_specification");
  } else if (error_code === "0Z000") {
    return new Ok("diagnostics_exception");
  } else if (error_code === "0Z002") {
    return new Ok("stacked_diagnostics_accessed_without_active_handler");
  } else if (error_code === "20000") {
    return new Ok("case_not_found");
  } else if (error_code === "21000") {
    return new Ok("cardinality_violation");
  } else if (error_code === "22000") {
    return new Ok("data_exception");
  } else if (error_code === "2202E") {
    return new Ok("array_subscript_error");
  } else if (error_code === "22021") {
    return new Ok("character_not_in_repertoire");
  } else if (error_code === "22008") {
    return new Ok("datetime_field_overflow");
  } else if (error_code === "22012") {
    return new Ok("division_by_zero");
  } else if (error_code === "22005") {
    return new Ok("error_in_assignment");
  } else if (error_code === "2200B") {
    return new Ok("escape_character_conflict");
  } else if (error_code === "22022") {
    return new Ok("indicator_overflow");
  } else if (error_code === "22015") {
    return new Ok("interval_field_overflow");
  } else if (error_code === "2201E") {
    return new Ok("invalid_argument_for_logarithm");
  } else if (error_code === "22014") {
    return new Ok("invalid_argument_for_ntile_function");
  } else if (error_code === "22016") {
    return new Ok("invalid_argument_for_nth_value_function");
  } else if (error_code === "2201F") {
    return new Ok("invalid_argument_for_power_function");
  } else if (error_code === "2201G") {
    return new Ok("invalid_argument_for_width_bucket_function");
  } else if (error_code === "22018") {
    return new Ok("invalid_character_value_for_cast");
  } else if (error_code === "22007") {
    return new Ok("invalid_datetime_format");
  } else if (error_code === "22019") {
    return new Ok("invalid_escape_character");
  } else if (error_code === "2200D") {
    return new Ok("invalid_escape_octet");
  } else if (error_code === "22025") {
    return new Ok("invalid_escape_sequence");
  } else if (error_code === "22P06") {
    return new Ok("nonstandard_use_of_escape_character");
  } else if (error_code === "22010") {
    return new Ok("invalid_indicator_parameter_value");
  } else if (error_code === "22023") {
    return new Ok("invalid_parameter_value");
  } else if (error_code === "22013") {
    return new Ok("invalid_preceding_or_following_size");
  } else if (error_code === "2201B") {
    return new Ok("invalid_regular_expression");
  } else if (error_code === "2201W") {
    return new Ok("invalid_row_count_in_limit_clause");
  } else if (error_code === "2201X") {
    return new Ok("invalid_row_count_in_result_offset_clause");
  } else if (error_code === "2202H") {
    return new Ok("invalid_tablesample_argument");
  } else if (error_code === "2202G") {
    return new Ok("invalid_tablesample_repeat");
  } else if (error_code === "22009") {
    return new Ok("invalid_time_zone_displacement_value");
  } else if (error_code === "2200C") {
    return new Ok("invalid_use_of_escape_character");
  } else if (error_code === "2200G") {
    return new Ok("most_specific_type_mismatch");
  } else if (error_code === "22004") {
    return new Ok("null_value_not_allowed");
  } else if (error_code === "22002") {
    return new Ok("null_value_no_indicator_parameter");
  } else if (error_code === "22003") {
    return new Ok("numeric_value_out_of_range");
  } else if (error_code === "2200H") {
    return new Ok("sequence_generator_limit_exceeded");
  } else if (error_code === "22026") {
    return new Ok("string_data_length_mismatch");
  } else if (error_code === "22001") {
    return new Ok("string_data_right_truncation");
  } else if (error_code === "22011") {
    return new Ok("substring_error");
  } else if (error_code === "22027") {
    return new Ok("trim_error");
  } else if (error_code === "22024") {
    return new Ok("unterminated_c_string");
  } else if (error_code === "2200F") {
    return new Ok("zero_length_character_string");
  } else if (error_code === "22P01") {
    return new Ok("floating_point_exception");
  } else if (error_code === "22P02") {
    return new Ok("invalid_text_representation");
  } else if (error_code === "22P03") {
    return new Ok("invalid_binary_representation");
  } else if (error_code === "22P04") {
    return new Ok("bad_copy_file_format");
  } else if (error_code === "22P05") {
    return new Ok("untranslatable_character");
  } else if (error_code === "2200L") {
    return new Ok("not_an_xml_document");
  } else if (error_code === "2200M") {
    return new Ok("invalid_xml_document");
  } else if (error_code === "2200N") {
    return new Ok("invalid_xml_content");
  } else if (error_code === "2200S") {
    return new Ok("invalid_xml_comment");
  } else if (error_code === "2200T") {
    return new Ok("invalid_xml_processing_instruction");
  } else if (error_code === "22030") {
    return new Ok("duplicate_json_object_key_value");
  } else if (error_code === "22031") {
    return new Ok("invalid_argument_for_sql_json_datetime_function");
  } else if (error_code === "22032") {
    return new Ok("invalid_json_text");
  } else if (error_code === "22033") {
    return new Ok("invalid_sql_json_subscript");
  } else if (error_code === "22034") {
    return new Ok("more_than_one_sql_json_item");
  } else if (error_code === "22035") {
    return new Ok("no_sql_json_item");
  } else if (error_code === "22036") {
    return new Ok("non_numeric_sql_json_item");
  } else if (error_code === "22037") {
    return new Ok("non_unique_keys_in_a_json_object");
  } else if (error_code === "22038") {
    return new Ok("singleton_sql_json_item_required");
  } else if (error_code === "22039") {
    return new Ok("sql_json_array_not_found");
  } else if (error_code === "2203A") {
    return new Ok("sql_json_member_not_found");
  } else if (error_code === "2203B") {
    return new Ok("sql_json_number_not_found");
  } else if (error_code === "2203C") {
    return new Ok("sql_json_object_not_found");
  } else if (error_code === "2203D") {
    return new Ok("too_many_json_array_elements");
  } else if (error_code === "2203E") {
    return new Ok("too_many_json_object_members");
  } else if (error_code === "2203F") {
    return new Ok("sql_json_scalar_required");
  } else if (error_code === "23000") {
    return new Ok("integrity_constraint_violation");
  } else if (error_code === "23001") {
    return new Ok("restrict_violation");
  } else if (error_code === "23502") {
    return new Ok("not_null_violation");
  } else if (error_code === "23503") {
    return new Ok("foreign_key_violation");
  } else if (error_code === "23505") {
    return new Ok("unique_violation");
  } else if (error_code === "23514") {
    return new Ok("check_violation");
  } else if (error_code === "23P01") {
    return new Ok("exclusion_violation");
  } else if (error_code === "24000") {
    return new Ok("invalid_cursor_state");
  } else if (error_code === "25000") {
    return new Ok("invalid_transaction_state");
  } else if (error_code === "25001") {
    return new Ok("active_sql_transaction");
  } else if (error_code === "25002") {
    return new Ok("branch_transaction_already_active");
  } else if (error_code === "25008") {
    return new Ok("held_cursor_requires_same_isolation_level");
  } else if (error_code === "25003") {
    return new Ok("inappropriate_access_mode_for_branch_transaction");
  } else if (error_code === "25004") {
    return new Ok("inappropriate_isolation_level_for_branch_transaction");
  } else if (error_code === "25005") {
    return new Ok("no_active_sql_transaction_for_branch_transaction");
  } else if (error_code === "25006") {
    return new Ok("read_only_sql_transaction");
  } else if (error_code === "25007") {
    return new Ok("schema_and_data_statement_mixing_not_supported");
  } else if (error_code === "25P01") {
    return new Ok("no_active_sql_transaction");
  } else if (error_code === "25P02") {
    return new Ok("in_failed_sql_transaction");
  } else if (error_code === "25P03") {
    return new Ok("idle_in_transaction_session_timeout");
  } else if (error_code === "26000") {
    return new Ok("invalid_sql_statement_name");
  } else if (error_code === "27000") {
    return new Ok("triggered_data_change_violation");
  } else if (error_code === "28000") {
    return new Ok("invalid_authorization_specification");
  } else if (error_code === "28P01") {
    return new Ok("invalid_password");
  } else if (error_code === "2B000") {
    return new Ok("dependent_privilege_descriptors_still_exist");
  } else if (error_code === "2BP01") {
    return new Ok("dependent_objects_still_exist");
  } else if (error_code === "2D000") {
    return new Ok("invalid_transaction_termination");
  } else if (error_code === "2F000") {
    return new Ok("sql_routine_exception");
  } else if (error_code === "2F005") {
    return new Ok("function_executed_no_return_statement");
  } else if (error_code === "2F002") {
    return new Ok("modifying_sql_data_not_permitted");
  } else if (error_code === "2F003") {
    return new Ok("prohibited_sql_statement_attempted");
  } else if (error_code === "2F004") {
    return new Ok("reading_sql_data_not_permitted");
  } else if (error_code === "34000") {
    return new Ok("invalid_cursor_name");
  } else if (error_code === "38000") {
    return new Ok("external_routine_exception");
  } else if (error_code === "38001") {
    return new Ok("containing_sql_not_permitted");
  } else if (error_code === "38002") {
    return new Ok("modifying_sql_data_not_permitted");
  } else if (error_code === "38003") {
    return new Ok("prohibited_sql_statement_attempted");
  } else if (error_code === "38004") {
    return new Ok("reading_sql_data_not_permitted");
  } else if (error_code === "39000") {
    return new Ok("external_routine_invocation_exception");
  } else if (error_code === "39001") {
    return new Ok("invalid_sqlstate_returned");
  } else if (error_code === "39004") {
    return new Ok("null_value_not_allowed");
  } else if (error_code === "39P01") {
    return new Ok("trigger_protocol_violated");
  } else if (error_code === "39P02") {
    return new Ok("srf_protocol_violated");
  } else if (error_code === "39P03") {
    return new Ok("event_trigger_protocol_violated");
  } else if (error_code === "3B000") {
    return new Ok("savepoint_exception");
  } else if (error_code === "3B001") {
    return new Ok("invalid_savepoint_specification");
  } else if (error_code === "3D000") {
    return new Ok("invalid_catalog_name");
  } else if (error_code === "3F000") {
    return new Ok("invalid_schema_name");
  } else if (error_code === "40000") {
    return new Ok("transaction_rollback");
  } else if (error_code === "40002") {
    return new Ok("transaction_integrity_constraint_violation");
  } else if (error_code === "40001") {
    return new Ok("serialization_failure");
  } else if (error_code === "40003") {
    return new Ok("statement_completion_unknown");
  } else if (error_code === "40P01") {
    return new Ok("deadlock_detected");
  } else if (error_code === "42000") {
    return new Ok("syntax_error_or_access_rule_violation");
  } else if (error_code === "42601") {
    return new Ok("syntax_error");
  } else if (error_code === "42501") {
    return new Ok("insufficient_privilege");
  } else if (error_code === "42846") {
    return new Ok("cannot_coerce");
  } else if (error_code === "42803") {
    return new Ok("grouping_error");
  } else if (error_code === "42P20") {
    return new Ok("windowing_error");
  } else if (error_code === "42P19") {
    return new Ok("invalid_recursion");
  } else if (error_code === "42830") {
    return new Ok("invalid_foreign_key");
  } else if (error_code === "42602") {
    return new Ok("invalid_name");
  } else if (error_code === "42622") {
    return new Ok("name_too_long");
  } else if (error_code === "42939") {
    return new Ok("reserved_name");
  } else if (error_code === "42804") {
    return new Ok("datatype_mismatch");
  } else if (error_code === "42P18") {
    return new Ok("indeterminate_datatype");
  } else if (error_code === "42P21") {
    return new Ok("collation_mismatch");
  } else if (error_code === "42P22") {
    return new Ok("indeterminate_collation");
  } else if (error_code === "42809") {
    return new Ok("wrong_object_type");
  } else if (error_code === "428C9") {
    return new Ok("generated_always");
  } else if (error_code === "42703") {
    return new Ok("undefined_column");
  } else if (error_code === "42883") {
    return new Ok("undefined_function");
  } else if (error_code === "42P01") {
    return new Ok("undefined_table");
  } else if (error_code === "42P02") {
    return new Ok("undefined_parameter");
  } else if (error_code === "42704") {
    return new Ok("undefined_object");
  } else if (error_code === "42701") {
    return new Ok("duplicate_column");
  } else if (error_code === "42P03") {
    return new Ok("duplicate_cursor");
  } else if (error_code === "42P04") {
    return new Ok("duplicate_database");
  } else if (error_code === "42723") {
    return new Ok("duplicate_function");
  } else if (error_code === "42P05") {
    return new Ok("duplicate_prepared_statement");
  } else if (error_code === "42P06") {
    return new Ok("duplicate_schema");
  } else if (error_code === "42P07") {
    return new Ok("duplicate_table");
  } else if (error_code === "42712") {
    return new Ok("duplicate_alias");
  } else if (error_code === "42710") {
    return new Ok("duplicate_object");
  } else if (error_code === "42702") {
    return new Ok("ambiguous_column");
  } else if (error_code === "42725") {
    return new Ok("ambiguous_function");
  } else if (error_code === "42P08") {
    return new Ok("ambiguous_parameter");
  } else if (error_code === "42P09") {
    return new Ok("ambiguous_alias");
  } else if (error_code === "42P10") {
    return new Ok("invalid_column_reference");
  } else if (error_code === "42611") {
    return new Ok("invalid_column_definition");
  } else if (error_code === "42P11") {
    return new Ok("invalid_cursor_definition");
  } else if (error_code === "42P12") {
    return new Ok("invalid_database_definition");
  } else if (error_code === "42P13") {
    return new Ok("invalid_function_definition");
  } else if (error_code === "42P14") {
    return new Ok("invalid_prepared_statement_definition");
  } else if (error_code === "42P15") {
    return new Ok("invalid_schema_definition");
  } else if (error_code === "42P16") {
    return new Ok("invalid_table_definition");
  } else if (error_code === "42P17") {
    return new Ok("invalid_object_definition");
  } else if (error_code === "44000") {
    return new Ok("with_check_option_violation");
  } else if (error_code === "53000") {
    return new Ok("insufficient_resources");
  } else if (error_code === "53100") {
    return new Ok("disk_full");
  } else if (error_code === "53200") {
    return new Ok("out_of_memory");
  } else if (error_code === "53300") {
    return new Ok("too_many_connections");
  } else if (error_code === "53400") {
    return new Ok("configuration_limit_exceeded");
  } else if (error_code === "54000") {
    return new Ok("program_limit_exceeded");
  } else if (error_code === "54001") {
    return new Ok("statement_too_complex");
  } else if (error_code === "54011") {
    return new Ok("too_many_columns");
  } else if (error_code === "54023") {
    return new Ok("too_many_arguments");
  } else if (error_code === "55000") {
    return new Ok("object_not_in_prerequisite_state");
  } else if (error_code === "55006") {
    return new Ok("object_in_use");
  } else if (error_code === "55P02") {
    return new Ok("cant_change_runtime_param");
  } else if (error_code === "55P03") {
    return new Ok("lock_not_available");
  } else if (error_code === "55P04") {
    return new Ok("unsafe_new_enum_value_usage");
  } else if (error_code === "57000") {
    return new Ok("operator_intervention");
  } else if (error_code === "57014") {
    return new Ok("query_canceled");
  } else if (error_code === "57P01") {
    return new Ok("admin_shutdown");
  } else if (error_code === "57P02") {
    return new Ok("crash_shutdown");
  } else if (error_code === "57P03") {
    return new Ok("cannot_connect_now");
  } else if (error_code === "57P04") {
    return new Ok("database_dropped");
  } else if (error_code === "57P05") {
    return new Ok("idle_session_timeout");
  } else if (error_code === "58000") {
    return new Ok("system_error");
  } else if (error_code === "58030") {
    return new Ok("io_error");
  } else if (error_code === "58P01") {
    return new Ok("undefined_file");
  } else if (error_code === "58P02") {
    return new Ok("duplicate_file");
  } else if (error_code === "72000") {
    return new Ok("snapshot_too_old");
  } else if (error_code === "F0000") {
    return new Ok("config_file_error");
  } else if (error_code === "F0001") {
    return new Ok("lock_file_exists");
  } else if (error_code === "HV000") {
    return new Ok("fdw_error");
  } else if (error_code === "HV005") {
    return new Ok("fdw_column_name_not_found");
  } else if (error_code === "HV002") {
    return new Ok("fdw_dynamic_parameter_value_needed");
  } else if (error_code === "HV010") {
    return new Ok("fdw_function_sequence_error");
  } else if (error_code === "HV021") {
    return new Ok("fdw_inconsistent_descriptor_information");
  } else if (error_code === "HV024") {
    return new Ok("fdw_invalid_attribute_value");
  } else if (error_code === "HV007") {
    return new Ok("fdw_invalid_column_name");
  } else if (error_code === "HV008") {
    return new Ok("fdw_invalid_column_number");
  } else if (error_code === "HV004") {
    return new Ok("fdw_invalid_data_type");
  } else if (error_code === "HV006") {
    return new Ok("fdw_invalid_data_type_descriptors");
  } else if (error_code === "HV091") {
    return new Ok("fdw_invalid_descriptor_field_identifier");
  } else if (error_code === "HV00B") {
    return new Ok("fdw_invalid_handle");
  } else if (error_code === "HV00C") {
    return new Ok("fdw_invalid_option_index");
  } else if (error_code === "HV00D") {
    return new Ok("fdw_invalid_option_name");
  } else if (error_code === "HV090") {
    return new Ok("fdw_invalid_string_length_or_buffer_length");
  } else if (error_code === "HV00A") {
    return new Ok("fdw_invalid_string_format");
  } else if (error_code === "HV009") {
    return new Ok("fdw_invalid_use_of_null_pointer");
  } else if (error_code === "HV014") {
    return new Ok("fdw_too_many_handles");
  } else if (error_code === "HV001") {
    return new Ok("fdw_out_of_memory");
  } else if (error_code === "HV00P") {
    return new Ok("fdw_no_schemas");
  } else if (error_code === "HV00J") {
    return new Ok("fdw_option_name_not_found");
  } else if (error_code === "HV00K") {
    return new Ok("fdw_reply_handle");
  } else if (error_code === "HV00Q") {
    return new Ok("fdw_schema_not_found");
  } else if (error_code === "HV00R") {
    return new Ok("fdw_table_not_found");
  } else if (error_code === "HV00L") {
    return new Ok("fdw_unable_to_create_execution");
  } else if (error_code === "HV00M") {
    return new Ok("fdw_unable_to_create_reply");
  } else if (error_code === "HV00N") {
    return new Ok("fdw_unable_to_establish_connection");
  } else if (error_code === "P0000") {
    return new Ok("plpgsql_error");
  } else if (error_code === "P0001") {
    return new Ok("raise_exception");
  } else if (error_code === "P0002") {
    return new Ok("no_data_found");
  } else if (error_code === "P0003") {
    return new Ok("too_many_rows");
  } else if (error_code === "P0004") {
    return new Ok("assert_failure");
  } else if (error_code === "XX000") {
    return new Ok("internal_error");
  } else if (error_code === "XX001") {
    return new Ok("data_corrupted");
  } else if (error_code === "XX002") {
    return new Ok("index_corrupted");
  } else {
    return new Error(undefined);
  }
}

export function calendar_date_decoder() {
  return $decode.field(
    0,
    $decode.int,
    (year) => {
      return $decode.field(
        1,
        $decode.int,
        (month) => {
          return $decode.field(
            2,
            $decode.int,
            (day) => {
              let $ = $calendar.month_from_int(month);
              if ($ instanceof Ok) {
                let month$1 = $[0];
                return $decode.success(new $calendar.Date(year, month$1, day));
              } else {
                return $decode.failure(
                  new $calendar.Date(0, new $calendar.January(), 1),
                  "Calendar date",
                );
              }
            },
          );
        },
      );
    },
  );
}

/**
 * The default configuration for a connection pool, with a single connection.
 * You will likely want to increase the size of the pool for your application.
 */
export function default_config(pool_name) {
  return new Config(
    pool_name,
    "127.0.0.1",
    default_port,
    "postgres",
    "postgres",
    new None(),
    new SslDisabled(),
    toList([]),
    10,
    50,
    1000,
    1000,
    false,
    new Ipv4(),
    false,
  );
}

/**
 * Parse a database url into configuration that can be used to start a pool.
 */
export function url_config(name, database_url) {
  return $result.try$(
    $uri.parse(database_url),
    (uri) => {
      let _block;
      let $ = uri.port;
      if ($ instanceof Some) {
        _block = uri;
      } else {
        _block = new Uri(
          uri.scheme,
          uri.userinfo,
          uri.host,
          new Some(default_port),
          uri.path,
          uri.query,
          uri.fragment,
        );
      }
      let uri$1 = _block;
      return $result.try$(
        (() => {
          let $1 = uri$1.scheme;
          if ($1 instanceof Some) {
            let $2 = uri$1.userinfo;
            if ($2 instanceof Some) {
              let $3 = uri$1.host;
              if ($3 instanceof Some) {
                let $4 = uri$1.port;
                if ($4 instanceof Some) {
                  let path = uri$1.path;
                  let query$1 = uri$1.query;
                  let scheme = $1[0];
                  let userinfo = $2[0];
                  let host$1 = $3[0];
                  let db_port = $4[0];
                  if (scheme === "postgres") {
                    return new Ok([userinfo, host$1, path, db_port, query$1]);
                  } else if (scheme === "postgresql") {
                    return new Ok([userinfo, host$1, path, db_port, query$1]);
                  } else {
                    return new Error(undefined);
                  }
                } else {
                  return new Error(undefined);
                }
              } else {
                return new Error(undefined);
              }
            } else {
              return new Error(undefined);
            }
          } else {
            return new Error(undefined);
          }
        })(),
        (_use0) => {
          let userinfo;
          let host$1;
          let path;
          let db_port;
          let query$1;
          userinfo = _use0[0];
          host$1 = _use0[1];
          path = _use0[2];
          db_port = _use0[3];
          query$1 = _use0[4];
          return $result.try$(
            extract_user_password(userinfo),
            (_use0) => {
              let user$1;
              let password$1;
              user$1 = _use0[0];
              password$1 = _use0[1];
              return $result.try$(
                extract_ssl_mode(query$1),
                (ssl) => {
                  let $1 = $string.split(path, "/");
                  if ($1 instanceof $Empty) {
                    return new Error(undefined);
                  } else {
                    let $2 = $1.tail;
                    if ($2 instanceof $Empty) {
                      return new Error(undefined);
                    } else {
                      let $3 = $2.tail;
                      if ($3 instanceof $Empty) {
                        let $4 = $1.head;
                        if ($4 === "") {
                          let database$1 = $2.head;
                          return new Ok(
                            (() => {
                              let _record = default_config(name);
                              return new Config(
                                _record.pool_name,
                                host$1,
                                db_port,
                                database$1,
                                user$1,
                                password$1,
                                ssl,
                                _record.connection_parameters,
                                _record.pool_size,
                                _record.queue_target,
                                _record.queue_interval,
                                _record.idle_interval,
                                _record.trace,
                                _record.ip_version,
                                _record.rows_as_map,
                              );
                            })(),
                          );
                        } else {
                          return new Error(undefined);
                        }
                      } else {
                        return new Error(undefined);
                      }
                    }
                  }
                },
              );
            },
          );
        },
      );
    },
  );
}
