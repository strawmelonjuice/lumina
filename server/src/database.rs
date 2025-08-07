use crate::errors::LuminaError::{self, ConfMissing};
use crate::helpers::events::EventLogger;
use crate::{info_elog, success_elog, warn_elog};
use cynthia_con::{CynthiaColors, CynthiaStyles};
use r2d2::Pool;
use r2d2_sqlite::SqliteConnectionManager;
use tokio_postgres as postgres;
use tokio_postgres::tls::NoTlsStream;
use tokio_postgres::{Client, Connection, Socket};

pub(crate) async fn setup() -> Result<DbConn, LuminaError> {
    let ev_log = EventLogger::new(&None).await;
    let redis_url =
        std::env::var("LUMINA_REDIS_URL").unwrap_or_else(|_| "redis://127.0.0.1/".into());
    let redis_pool: Pool<redis::Client> = {
        info_elog!(ev_log, "Setting up Redis connection...");
        let client = redis::Client::open(redis_url.clone()).map_err(LuminaError::Redis)?;
        r2d2::Pool::builder()
            .build(client)
            .map_err(LuminaError::R2D2Pool)
    }?;
    success_elog!(
        ev_log,
        "Redis connection to {} created successfully.",
        redis_url
    );

    match (std::env::var("LUMINA_DB_TYPE")
        .map_err(|_| ConfMissing("LUMINA_DB_TYPE".to_string()))
        .unwrap_or(String::from("sqlite")))
    .as_str()
    {
        "sqlite" => {
            let db_path =
                std::env::var("LUMINA_SQLITE_FILE").unwrap_or("instance.sqlite".to_string());
            let db_full_path = std::fs::canonicalize(&db_path)
                .map(|p| p.display().to_string())
                .unwrap_or(db_path.clone());
            info_elog!(
                ev_log,
                "Using SQLite database at path: {}",
                db_full_path.color_bright_cyan().style_bold()
            );
            let manager = SqliteConnectionManager::file(db_path);
            let pool = Pool::new(manager).map_err(LuminaError::R2D2Pool)?;
            {
                let conn = pool.get().map_err(LuminaError::R2D2Pool)?;
                let _ = conn.execute(
                    "CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    username TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL)",
                    [],
                ).map_err(LuminaError::Sqlite)?;
                let _ = conn.execute(
                    "CREATE TABLE IF NOT EXISTS timelines ( 
                    tlid TEXT NOT NULL,
                    item_id TEXT NOT NULL,
                    timestamp TEXT NOT NULL
                )",
                    [],
                ).map_err(LuminaError::Sqlite)?;
                
                let _ = conn.execute(
                    "CREATE TABLE IF NOT EXISTS itemtypelookupdb (
                    itemtype TEXT,
                    item_id TEXT NOT NULL
                )",
                    [],
                ).map_err(LuminaError::Sqlite)?;
                let _ = conn.execute(
                    "CREATE TABLE IF NOT EXISTS sessions (
    id TEXT PRIMARY KEY NOT NULL,
    user_id TEXT NOT NULL,
    session_key TEXT NOT NULL,
    created_at INT NOT NULL)",
                    [],
                ).map_err(LuminaError::Sqlite)?;
               
                let _ = conn.execute(
                    "CREATE TABLE IF NOT EXISTS logs (
                    type TEXT NOT NULL,
                    message TEXT NOT NULL,
                    timestamp TEXT NOT NULL
                )",
                    [],
                ).map_err(LuminaError::Sqlite)?;
                let _ = conn.pragma_update(None, "journal_mode", "WAL").map_err(LuminaError::Sqlite)?;
                let _ = conn.pragma_update(None, "foreign_keys", "ON").map_err(LuminaError::Sqlite)?;
                let _ = conn.pragma_update(None, "temp_store", "2").map_err(LuminaError::Sqlite)?;
            };
            let _ = tokio::spawn(maintain(DbConn::SqliteConnectionPool(
                pool.clone(),
                redis_pool.clone(),
            )));
            Ok(DbConn::SqliteConnectionPool(pool, redis_pool))
        }
        "postgres" => {
            let pg_config: tokio_postgres::Config = {
                let mut uuu = (
                    "unspecified database".to_string(),
                    "unspecified host".to_string(),
                    "unkwown port".to_string(),
                );
                let mut pg_config = postgres::Config::new();
                pg_config.user(&{
                    std::env::var("LUMINA_POSTGRES_USERNAME")
                        .map_err(|_| ConfMissing("LUMINA_POSTGRES_USERNAME".to_string()))?
                });
                let dbname = std::env::var("LUMINA_POSTGRES_DATABASE")
                    .map_err(|_| ConfMissing("LUMINA_POSTGRES_DATABASE".to_string()))?;
                uuu.0 = dbname.clone();
                pg_config.dbname(&dbname);
                let port = match std::env::var("LUMINA_POSTGRES_PORT") {
                    Err(..) => {
                        warn_elog!(
                            ev_log,
                            "No Postgres database port provided under environment variable 'LUMINA_POSTGRES_PORT'. Using default value '5432'."
                        );
                        "5432".to_string()
                    }
                    Ok(c) => c,
                };
                uuu.2 = port.clone();
                // Parse the port as u16, if it fails, return an error
                pg_config.port(port.parse::<u16>().map_err(|_| {
                    LuminaError::ConfInvalid(
                        "LUMINA_POSTGRES_PORT is not a valid integer number".to_string(),
                    )
                })?);
                match std::env::var("LUMINA_POSTGRES_HOST") {
                    Ok(val) => {
                        uuu.1 = val.clone();
                        pg_config.host(&val);
                    }
                    Err(_) => {
                        warn_elog!(
                            ev_log,
                            "No Postgres database host provided under environment variable 'LUMINA_POSTGRES_HOST'. Using default value 'localhost'."
                        );
                        // Default to localhost if not set
                        uuu.1 = "localhost".to_string();
                        pg_config.host("localhost");
                    }
                };
                match std::env::var("LUMINA_POSTGRES_PASSWORD") {
                    Ok(val) => {
                        pg_config.password(&val);
                    }
                    Err(_) => {
                        warn_elog!(
                            ev_log,
                            "No Postgres database password provided under environment variable 'LUMINA_POSTGRES_PASSWORD'. Trying passwordless authentication."
                        );
                    }
                };
                info_elog!(
                    ev_log,
                    "Using Postgres database at: {} on host: {} at port: {}",
                    uuu.0.color_bright_cyan().style_bold(),
                    uuu.1.color_bright_cyan().style_bold(),
                    uuu.2.color_bright_cyan().style_bold(),
                );
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
                // Timelines table
                let _ = conn
                    .0
                    .execute(
                        "CREATE TABLE IF NOT EXISTS timelines (
    tlid UUID DEFAULT gen_random_uuid (),
    item_id UUID NOT NULL,
    timestamp TIMESTAMP NOT NULL
)",
                        &[],
                    )
                    .await
                    .map_err(LuminaError::Postgres)?;
                // Item type lookup table
                let _ = conn
                    .0
                    .execute(
                        "CREATE TABLE IF NOT EXISTS itemtypelookupdb (
    itemtype VARCHAR NOT NULL,
    item_id UUID NOT NULL
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
                let _ = conn
                    .0
                    .execute(
                        "CREATE TABLE IF NOT EXISTS logs (\
                        type VARCHAR NOT NULL, \
                        message TEXT NOT NULL, \
                        timestamp TIMESTAMP NOT NULL\
                    )",
                        &[],
                    )
                    .await
                    .map_err(LuminaError::Postgres)?;
            };
            let _ = tokio::spawn(maintain(DbConn::PgsqlConnection(
                (conn_two.0, pg_config.clone()),
                redis_pool.clone(),
            )));
            Ok(DbConn::PgsqlConnection((conn.0, pg_config), redis_pool))
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
    // The config is also shared, so that for example the logger can set up it's own connection, use this sparingly.
    PgsqlConnection(
        (postgres::Client, tokio_postgres::Config),
        Pool<redis::Client>,
    ),
    SqliteConnectionPool(Pool<SqliteConnectionManager>, Pool<redis::Client>),
}

// This function will be used to maintain the database, such as deleting old sessions
pub async fn maintain(db: DbConn) {
    match db {
        DbConn::PgsqlConnection((client, _), _redis) => {
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
        DbConn::SqliteConnectionPool(pool, _redis) => {
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
