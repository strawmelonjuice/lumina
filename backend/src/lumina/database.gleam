import gleam/dynamic
import gleam/list
import gleam/option
import gleam/string
import gleamy_lights/premixed.{text_error_red, text_lime}
import gmysql
import lumina/data/config.{
  type LuminaConfig, type LuminaDBConnectionInfo, LuminaDBConnectionInfoPOSTGRES,
  LuminaDBConnectionInfoSQLite,
}
import pog
import sqlight
import wisp

pub type LuminaDBConnection {
  POSTGRESConnection(pog.Connection)
  // SQLight shouldn't keep the connection, easier if it just stores the path and reconnects everytime.
  SQLiteConnection(String)
}

pub fn connect(lc: LuminaConfig, in: String) -> LuminaDBConnection {
  case lc.db_connection_info {
    LuminaDBConnectionInfoPOSTGRES(config) -> {
      wisp.log_info("Connecting to Postgres database...")
      pog.connect(config)
      |> POSTGRESConnection
    }
    LuminaDBConnectionInfoSQLite(file_) -> {
      // Always relative to the instance folder.
      let file = in <> "/" <> file_
      wisp.log_info("Connecting to SQLite database...")
      let conn = case sqlight.open(file) {
        Ok(connection) -> connection
        Error(e) -> {
          wisp.log_critical("SQLite Connection error: " <> e.message)
          panic
        }
      }
      let assert Ok(_) = sqlight.close(conn)
      SQLiteConnection(file)
    }
  }
}

pub fn c(connection: LuminaDBConnection, conf: LuminaConfig) {
  case connection {
    POSTGRESConnection(con) -> {
      i(con)
    }
    SQLiteConnection(con) -> {
      // SQLite doesn't need to check for tables, it's 'IF NOT EXISTS' in the query is much more efficient.
      i_sqlite(con)
    }
  }
}

/// Sets up the tables in the POSTGRES database.
fn i(con: pog.Connection) {
  case
    pog.query(
      "
CREATE TABLE IF NOT EXISTS external_posts(
	host_id INTEGER PRIMARY KEY,
	source_id INTEGER NOT NULL,
	source_instance TEXT NOT NULL
			);
CREATE TABLE IF NOT EXISTS interinstance_relations(
	instance_id TEXT PRIMARY KEY,
	synclevel TEXT NOT NULL,
	last_contact INTEGER NOT NULL
			);
CREATE TABLE IF NOT EXISTS local_posts(
	host_id INTEGER PRIMARY KEY,
	user_id INTEGER NOT NULL,
	privacy INTEGER NOT NULL
			);
CREATE TABLE IF NOT EXISTS posts_pool(
	postid INTEGER PRIMARY KEY,
	kind TEXT NOT NULL,
	content TEXT NOT NULL,
	from_local INTEGER NOT NULL
			);
CREATE TABLE IF NOT EXISTS users(
	id INTEGER PRIMARY KEY,
	username TEXT NOT NULL,
	password TEXT NOT NULL,
	email TEXT NOT NULL
			);
",
    )
    |> pog.execute(con)
  {
    Ok(_) -> Nil
    Error(e) -> {
      wisp.log_info(
        text_error_red("Error creating tables in PostGres. ")
        <> text_lime(
          "Some tips: \r\n\t- are the environment variables set correctly?\n\t - Is PostGres up and running?",
        ),
      )
      wisp.log_error(string.inspect(e))
    }
  }
}

/// Sets up the tables in the sqlite database.
fn i_sqlite(con: String) {
  use conn <- sqlight.with_connection(con)
  case
    sqlight.exec(
      "
CREATE TABLE IF NOT EXISTS external_posts(
	host_id INTEGER PRIMARY KEY,
	source_id INTEGER NOT NULL,
	source_instance TEXT NOT NULL
			);
CREATE TABLE IF NOT EXISTS interinstance_relations(
	instance_id TEXT PRIMARY KEY,
	synclevel TEXT NOT NULL,
	last_contact INTEGER NOT NULL
			);
CREATE TABLE IF NOT EXISTS local_posts(
	host_id INTEGER PRIMARY KEY,
	user_id INTEGER NOT NULL,
	privacy INTEGER NOT NULL
			);
CREATE TABLE IF NOT EXISTS posts_pool(
	postid INTEGER PRIMARY KEY,
	kind TEXT NOT NULL,
	content TEXT NOT NULL,
	from_local INTEGER NOT NULL
			);
CREATE TABLE IF NOT EXISTS users(
	id INTEGER PRIMARY KEY,
	username TEXT NOT NULL,
	password TEXT NOT NULL,
	email TEXT NOT NULL
			);
",
      conn,
    )
  {
    Ok(_) -> {
      Nil
    }
    Error(e) -> {
      wisp.log_info(
        text_error_red("Error creating tables in SQLite. ")
        <> text_lime(
          "Some tips: \r\n\t- are the environment variables set correctly?\n\t - Does the file already exist with corrupt data?",
        ),
      )
      wisp.log_error(string.inspect(e))
    }
  }
}
