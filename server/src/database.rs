use crate::errors::LuminaError::{self, ConfMissing};
use cynthia_con::{CynthiaColors, CynthiaStyles};
use r2d2::Pool;
use r2d2_sqlite::SqliteConnectionManager;
use tokio_postgres as postgres;
use tokio_postgres::tls::NoTlsStream;
use tokio_postgres::{Client, Connection, Socket};

pub(crate) async fn setup() -> Result<DbConn, LuminaError> {
    let warn = "[WARN]".color_bright_orange().style_bold();
    match (std::env::var("LUMINA_DB_TYPE")
        .map_err(|_| ConfMissing("LUMINA_DB_TYPE".to_string()))
        .unwrap_or(String::from("sqlite")))
    .as_str()
    {
        "sqlite" => {
            let db_path =
                std::env::var("LUMINA_SQLITE_PATH").unwrap_or("instance.sqlite".to_string());
            let manager = SqliteConnectionManager::file(db_path);
            let pool = Pool::new(manager).map_err(LuminaError::SqlitePool)?;
            {
                let conn = pool.get().map_err(LuminaError::SqlitePool)?;
                let _ = conn.execute(
                    "CREATE TABLE IF NOT EXISTS users (
						id TEXT PRIMARY KEY,
						email TEXT NOT NULL UNIQUE,
						username TEXT NOT NULL UNIQUE,
						password TEXT NOT NULL)",
                    [],
                );
                let _ = conn.execute(
                    "CREATE TABLE IF NOT EXISTS sessions (
						id TEXT PRIMARY KEY NOT NULL,
						user_id TEXT NOT NULL,
						session_key TEXT NOT NULL,
						created_at INT NOT NULL)",
                    [],
                );
                let _ = conn.execute("PRAGMA journal_mode = WAL;", []);
                let _ = conn.execute("PRAGMA foreign_keys = ON;", []);
                let _ = conn.execute("PRAGMA temp_store = '2'", []);
            };
            let _ = tokio::spawn(maintain(DbConn::SqliteConnectionPool(pool.clone())));
            Ok(DbConn::SqliteConnectionPool(pool))
        }
        "postgres" => {
            let pg_config = {
                let mut pg_config = postgres::Config::new();
                pg_config.user(&{
                    std::env::var("LUMINA_POSTGRES_USERNAME")
                        .map_err(|_| ConfMissing("LUMINA_POSTGRES_USERNAME".to_string()))?
                });
                pg_config.dbname(&{
                    std::env::var("LUMINA_POSTGRES_DATABASE")
                        .map_err(|_| ConfMissing("LUMINA_POSTGRES_DATABASE".to_string()))?
                });
                pg_config.port(std::env::var("LUMINA_POSTGRES_PORT").unwrap_or_else(|_| {
                    eprintln!("{warn} No Postgres database port provided under environment variable 'LUMINA_POSTGRES_PORT'. Using default value '5432'.");
                    "5432".to_string()
                }).parse::<u16>().map_err(|_| { LuminaError::ConfInvalid("LUMINA_POSTGRES_PORT is not a valid integer number".to_string()) })?);
                match std::env::var("LUMINA_POSTGRES_HOST") {
                    Ok(val) => {
                        pg_config.host(&val);
                    }
                    Err(_) => {
                        eprintln!(
                            "{warn} No Postgres database host provided under environment variable 'LUMINA_POSTGRES_HOST'. Using default value 'localhost'."
                        );
                        pg_config.host("localhost");
                    }
                };
                match std::env::var("LUMINA_POSTGRES_PASSWORD") {
                    Ok(val) => {
                        pg_config.password(&val);
                    }
                    Err(_) => {
                        println!(
                            "{warn} No Postgres database password provided under environment variable 'LUMINA_POSTGRES_PASSWORD'. Trying passwordless authentication."
                        );
                    }
                };
                pg_config
            };
            // Connect to the database
            let conn: (Client, Connection<Socket, NoTlsStream>) = pg_config
                .connect(postgres::tls::NoTls)
                .await
                .map_err(LuminaError::Postgres)?;
            let _ = tokio::spawn(conn.1);
            // Create a second connection to the database for spawning the maintain function
            let conn_two: (Client, Connection<Socket, NoTlsStream>) = pg_config
                .connect(postgres::tls::NoTls)
                .await
                .map_err(LuminaError::Postgres)?;
            let _ = tokio::spawn(conn_two.1);
            {
                // Set up the database tables
                //
                // Users table
                let _ = conn
                    .0
                    .execute(
                        "CREATE TABLE IF NOT EXISTS users (
						id UUID DEFAULT gen_random_uuid (),
						email VARCHAR NOT NULL UNIQUE,
						username VARCHAR NOT NULL UNIQUE,
						password VARCHAR NOT NULL
					)",
                        &[],
                    )
                    .await
                    .map_err(LuminaError::Postgres)?;
                // Sessions table
                let _ = conn
                    .0
                    .execute(
                        "CREATE TABLE IF NOT EXISTS sessions (
						id UUID DEFAULT gen_random_uuid (),
						user_id UUID NOT NULL,
						session_key VARCHAR NOT NULL,
						created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
					)",
                        &[],
                    )
                    .await
                    .map_err(LuminaError::Postgres)?;
            };
            let _ = tokio::spawn(maintain(DbConn::PgsqlConnection(conn_two.0)));
            Ok(DbConn::PgsqlConnection(conn.0))
        }

        c => {
            println!("{:?}", c);
            Err(LuminaError::ConfInvalid(format!(
                "LUMINA_DB_TYPE does not contain a valid value, only 'sqlite' or 'postgres' are allowed. Found: {}",
                c
            )))
        }
    }
}

// This will be an enum containing either a pgsql connection or a sqlite connection
#[derive()]
pub enum DbConn {
    PgsqlConnection(postgres::Client),
    SqliteConnectionPool(Pool<SqliteConnectionManager>),
}

// This function will be used to maintain the database, such as deleting old sessions
pub async fn maintain(db: DbConn) {
    match db {
        DbConn::PgsqlConnection(client) => {
            let mut interval = tokio::time::interval(std::time::Duration::from_secs(60));
            loop {
                interval.tick().await;
                // Delete any sessions older than 20 days
                let _ = client
                    .execute(
                        "DELETE FROM sessions WHERE created_at < NOW() - INTERVAL '20 days'",
                        &[],
                    )
                    .await;
            }
        }
        DbConn::SqliteConnectionPool(pool) => {
            let mut interval = tokio::time::interval(std::time::Duration::from_secs(60));
            loop {
                interval.tick().await;
                let conn = pool.get().unwrap();
                // Delete any sessions older than 20 days
                let _ = conn.execute(
                    "DELETE FROM sessions WHERE created_at < strftime('%s', 'now') - 1728000",
                    [],
                );
            }
        }
    }
}
