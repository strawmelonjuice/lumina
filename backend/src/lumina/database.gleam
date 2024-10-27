import gleam/dynamic
import gleam/list
import gleam/option
import gleam/string
import gleamy_lights/premixed.{text_error_red, text_lime}
import gmysql
import lumina/data/config.{
  type LuminaConfig, MySQLConnectionInfo, SQLiteConnectionInfo,
}
import sqlight
import wisp

pub type LuminaDBConnection {
  MySQLConnection(gmysql.Connection)
  // SQLight shouldn't keep the connection, easier if it just stores the path and reconnects everytime.
  SQLiteConnection(String)
}

pub fn connect(lc: LuminaConfig, in: String) -> LuminaDBConnection {
  case lc.db_connection_info {
    MySQLConnectionInfo(port, host, username, password, name) -> {
      let config =
        gmysql.Config(
          // default "localhost"
          host: host,
          // default 3306
          port: port,
          // default ""
          user: option.Some(username),
          password: password,
          // default "lumina_db"
          database: name,
          connection_mode: gmysql.Asynchronous,
          connection_timeout: gmysql.Infinity,
          keep_alive: 1000,
        )
      case gmysql.connect(config) {
        Ok(connection) -> {
          wisp.log_info("Connecting to MySQL database...")
          MySQLConnection(connection)
        }
        Error(_) -> {
          panic as "Error connecting to MySQL database"
        }
      }
    }
    SQLiteConnectionInfo(file_) -> {
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
    MySQLConnection(con) -> {
      let assert MySQLConnectionInfo(_, _, _, _, name) = conf.db_connection_info
      case
        // [
        //   "external_posts", "interinstance_relations", "local_posts", "posts_pool",
        //   "users",
        // ]
        // Wait no. Only one test should be enough.
        gmysql.query("
SELECT count(*)
FROM information_schema.tables
WHERE table_schema = '" <> name <> "'
AND table_name = '" <> "external_posts" <> "';
	", con, [], dynamic.list(dynamic.int))
      {
        Ok([count]) -> {
          let assert Ok(c) = list.first(count)
          case c >= 1 {
            True -> wisp.log_info("Database configuration skipped, seems OK.")
            False -> i(con)
          }
        }
        Error(e) -> {
          wisp.log_error(string.inspect(e))
        }
        _ -> {
          panic as "Error checking if tables exist"
        }
      }
    }
    SQLiteConnection(con) -> {
      // SQLite doesn't need to check for tables, it's 'IF NOT EXISTS' in the query is much more efficient.
      i_sqlite(con)
    }
  }
}

/// Sets up the tables in the mysql database.
fn i(con: gmysql.Connection) {
  let d =
    [
      "CREATE TABLE IF NOT EXISTS external_posts(
    host_id INT(11) NOT NULL,
    source_id INT(11) NOT NULL,
    source_instance VARCHAR(100) NOT NULL,
    KEY host_id(host_id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;",
      "CREATE TABLE IF NOT EXISTS interinstance_relations(
    instance_id TEXT NOT NULL,
    synclevel SET
        ('block', 'in moderation', 'full') NOT NULL,
        last_contact INT(11) NOT NULL DEFAULT CURRENT_TIMESTAMP(), UNIQUE KEY instance_id(instance_id) USING HASH) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;",
      "CREATE TABLE IF NOT EXISTS local_posts(
        host_id INT(11) NOT NULL,
        user_id INT(11) NOT NULL,
        privacy TINYINT(1) NOT NULL,
        PRIMARY KEY(host_id),
        KEY user_id(user_id)
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;",
      "CREATE TABLE IF NOT EXISTS posts_pool(
        postid INT(11) NOT NULL AUTO_INCREMENT,
        kind ENUM('SHORT', 'LONG', 'MEDIA', 'REPOST') NOT NULL,
        content LONGTEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK
            (JSON_VALID(content)),
            from_local TINYINT(1) NOT NULL,
            PRIMARY KEY(postid)
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;",
      "CREATE TABLE IF NOT EXISTS users(
    id INT(11) NOT NULL AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL,
    PASSWORD VARCHAR(255) NOT NULL,
    email VARCHAR(150) NOT NULL,
    PRIMARY KEY(id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;",
      "ALTER TABLE
    external_posts ADD CONSTRAINT external_posts_ibfk_1 FOREIGN KEY(host_id) REFERENCES posts_pool(postid) ON DELETE CASCADE ON UPDATE CASCADE;",
      "ALTER TABLE
    local_posts ADD CONSTRAINT local_posts_ibfk_1 FOREIGN KEY(host_id) REFERENCES posts_pool(postid) ON DELETE CASCADE ON UPDATE CASCADE,
    ADD CONSTRAINT local_posts_ibfk_2 FOREIGN KEY(user_id) REFERENCES `users`(id) ON DELETE CASCADE ON UPDATE CASCADE;",
    ]
    |> list.try_each(fn(x) { gmysql.exec(x, con) })
  case d {
    Ok(_) -> {
      Nil
    }
    Error(e) -> {
      wisp.log_info(
        text_error_red("Error creating tables. ")
        <> text_lime(
          "Some tips: \n\t- are the environment variables set correctly? \n\t- Make sure the database is pre-created.",
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
