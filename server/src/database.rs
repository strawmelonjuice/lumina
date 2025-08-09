use crate::errors::LuminaError::{self, ConfMissing};
use crate::helpers::events::EventLogger;
use crate::timeline;
use crate::{info_elog, success_elog, warn_elog};
use cynthia_con::{CynthiaColors, CynthiaStyles};
use r2d2::Pool;
use r2d2_sqlite::SqliteConnectionManager;
use redis::Commands;
use tokio_postgres as postgres;
use tokio_postgres::tls::NoTlsStream;
use tokio_postgres::{Client, Connection, Socket};

pub(crate) async fn setup() -> Result<DbConn, LuminaError> {
    let ev_log = EventLogger::new(&None).await;
    let redis_url =
        std::env::var("LUMINA_REDIS_URL").unwrap_or_else(|_| "redis://127.0.0.1/".into());
    let redis_pool: Pool<redis::Client> = {
        info_elog!(ev_log, "Setting up Redis connection to {}...", redis_url);
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
                let _ = conn
                    .execute(
                        "CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY UNIQUE,
    foreign_instance_id TEXT,
    foreign_user_id TEXT,
    email TEXT NOT NULL UNIQUE,
    username TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL)",
                        [],
                    )
                    .map_err(LuminaError::Sqlite)?;
                let _ = conn
                    .execute(
                        "CREATE TABLE IF NOT EXISTS timelines (
                    tlid TEXT NOT NULL,
                    item_id TEXT NOT NULL,
                    timestamp TEXT NOT NULL
                )",
                        [],
                    )
                    .map_err(LuminaError::Sqlite)?;

                let _ = conn
                    .execute(
                        "CREATE TABLE IF NOT EXISTS itemtypelookupdb (
                    itemtype TEXT,
                    item_id TEXT NOT NULL
                )",
                        [],
                    )
                    .map_err(LuminaError::Sqlite)?;
                let _ = conn
                    .execute(
                        "CREATE TABLE IF NOT EXISTS sessions (
    id TEXT PRIMARY KEY NOT NULL,
    user_id TEXT NOT NULL,
    session_key TEXT NOT NULL,
    created_at INT NOT NULL)",
                        [],
                    )
                    .map_err(LuminaError::Sqlite)?;

                let _ = conn
                    .execute(
                        "CREATE TABLE IF NOT EXISTS post_text (
    id TEXT PRIMARY KEY,
    author_id TEXT,
    content TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d %H:%M:%f', 'now')),
    foreign_instance_id TEXT,
    foreign_post_id TEXT,
    FOREIGN KEY (author_id) REFERENCES users(id)
)",
                        [],
                    )
                    .map_err(LuminaError::Sqlite)?;

                let _ = conn
                    .execute(
                        "CREATE TABLE IF NOT EXISTS post_media (
    id TEXT PRIMARY KEY,
    author_id TEXT,
    minio_object_id TEXT NOT NULL,
    caption TEXT,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d %H:%M:%f', 'now')),
    foreign_instance_id TEXT,
    foreign_post_id TEXT,
    FOREIGN KEY (author_id) REFERENCES users(id)
)",
                        [],
                    )
                    .map_err(LuminaError::Sqlite)?;

                let _ = conn
                    .execute(
                        "CREATE TABLE IF NOT EXISTS post_article (
    id TEXT PRIMARY KEY,
    author_id TEXT,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d %H:%M:%f', 'now')),
    foreign_instance_id TEXT,
    foreign_post_id TEXT,
    FOREIGN KEY (author_id) REFERENCES users(id)
)",
                        [],
                    )
                    .map_err(LuminaError::Sqlite)?;

                let _ = conn
                    .execute(
                        "CREATE TABLE IF NOT EXISTS logs (
                    type TEXT NOT NULL,
                    message TEXT NOT NULL,
                    timestamp TEXT NOT NULL
                )",
                        [],
                    )
                    .map_err(LuminaError::Sqlite)?;
                let _ = conn
                    .pragma_update(None, "journal_mode", "WAL")
                    .map_err(LuminaError::Sqlite)?;
                let _ = conn
                    .pragma_update(None, "foreign_keys", "ON")
                    .map_err(LuminaError::Sqlite)?;
                let _ = conn
                    .pragma_update(None, "temp_store", "2")
                    .map_err(LuminaError::Sqlite)?;

                // Populate bloom filters
                let mut redis_conn = redis_pool.get().map_err(LuminaError::R2D2Pool)?;
                let email_key = "bloom:email";
                let username_key = "bloom:username";

                let mut stmt = conn
                    .prepare("SELECT email, username FROM users")
                    .map_err(LuminaError::Sqlite)?;
                let user_iter = stmt
                    .query_map([], |row| {
                        Ok((row.get::<_, String>(0)?, row.get::<_, String>(1)?))
                    })
                    .map_err(LuminaError::Sqlite)?;

                for user in user_iter {
                    let (email, username) = user.map_err(LuminaError::Sqlite)?;
                    let _: () = redis::cmd("BF.ADD")
                        .arg(email_key)
                        .arg(email)
                        .query(&mut *redis_conn)
                        .map_err(LuminaError::Redis)?;
                    let _: () = redis::cmd("BF.ADD")
                        .arg(username_key)
                        .arg(username)
                        .query(&mut *redis_conn)
                        .map_err(LuminaError::Redis)?;
                }
                println!(
                    "{} Bloom filters populated from SQLite.",
                    crate::helpers::message_prefixes().0
                );
            };
            let pool_clone = pool.clone();
            let redis_pool_clone = redis_pool.clone();
            let _ = tokio::spawn(async move {
                maintain(DbConn::SqliteConnectionPool(pool_clone, redis_pool_clone)).await
            });
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
    id UUID DEFAULT gen_random_uuid () UNIQUE PRIMARY KEY,
    foreign_instance_id VARCHAR,
    foreign_user_id UUID,
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
                        "CREATE TABLE IF NOT EXISTS post_text (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    author_id UUID REFERENCES users(id),
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    foreign_instance_id VARCHAR,
    foreign_post_id VARCHAR
)",
                        &[],
                    )
                    .await
                    .map_err(LuminaError::Postgres)?;

                let _ = conn
                    .0
                    .execute(
                        "CREATE TABLE IF NOT EXISTS post_media (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    author_id UUID REFERENCES users(id),
    minio_object_id VARCHAR NOT NULL,
    caption TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    foreign_instance_id VARCHAR,
    foreign_post_id VARCHAR
)",
                        &[],
                    )
                    .await
                    .map_err(LuminaError::Postgres)?;

                let _ = conn
                    .0
                    .execute(
                        "CREATE TABLE IF NOT EXISTS post_article (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    author_id UUID REFERENCES users(id),
    title VARCHAR NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    foreign_instance_id VARCHAR,
    foreign_post_id VARCHAR
)",
                        &[],
                    )
                    .await
                    .map_err(LuminaError::Postgres)?;

                let _ = conn
                    .0
                    .execute(
                        "CREATE TABLE IF NOT EXISTS logs (
                        type VARCHAR NOT NULL,
                        message TEXT NOT NULL,
                        timestamp TIMESTAMP NOT NULL
                    )",
                        &[],
                    )
                    .await
                    .map_err(LuminaError::Postgres)?;

                // Populate bloom filters
                let mut redis_conn = redis_pool.get().map_err(LuminaError::R2D2Pool)?;
                let email_key = "bloom:email";
                let username_key = "bloom:username";

                let rows = conn
                    .0
                    .query("SELECT email, username FROM users", &[])
                    .await
                    .map_err(LuminaError::Postgres)?;
                for row in rows {
                    let email: String = row.get(0);
                    let username: String = row.get(1);
                    let _: () = redis::cmd("BF.ADD")
                        .arg(email_key)
                        .arg(email)
                        .query(&mut *redis_conn)
                        .map_err(LuminaError::Redis)?;
                    let _: () = redis::cmd("BF.ADD")
                        .arg(username_key)
                        .arg(username)
                        .query(&mut *redis_conn)
                        .map_err(LuminaError::Redis)?;
                }
                println!(
                    "{} Bloom filters populated from PostgreSQL.",
                    crate::helpers::message_prefixes().0
                );
            };
            let conn_clone = conn_two.0;
            let pg_config_clone = pg_config.clone();
            let redis_pool_clone = redis_pool.clone();
            let _ = tokio::spawn(async move {
                maintain(DbConn::PgsqlConnection(
                    (conn_clone, pg_config_clone),
                    redis_pool_clone,
                ))
                .await
            });
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
// and managing timeline caches
pub async fn maintain(db: DbConn) {
    match db {
        DbConn::PgsqlConnection((client, _), redis_pool) => {
            let mut session_interval = tokio::time::interval(std::time::Duration::from_secs(60));
            let mut cache_interval = tokio::time::interval(std::time::Duration::from_secs(300)); // 5 minutes

            loop {
                tokio::select! {
                    _ = session_interval.tick() => {
                        // Delete any sessions older than 20 days
                        let _ = client
                            .execute(
                                "DELETE FROM sessions WHERE created_at < NOW() - INTERVAL '20 days'",
                                &[],
                            )
                            .await;
                    }
                    _ = cache_interval.tick() => {
                        // Clean up expired timeline caches and manage cache invalidation
                        if let Ok(mut redis_conn) = redis_pool.get() {
                            let _ = cleanup_timeline_caches(&mut redis_conn).await;
                            let _ = check_timeline_invalidations(&mut redis_conn, &client).await;
                        }
                    }
                }
            }
        }
        DbConn::SqliteConnectionPool(pool, redis_pool) => {
            let mut session_interval = tokio::time::interval(std::time::Duration::from_secs(60));
            let mut cache_interval = tokio::time::interval(std::time::Duration::from_secs(300)); // 5 minutes

            loop {
                tokio::select! {
                    _ = session_interval.tick() => {
                        if let Ok(conn) = pool.get() {
                            // Delete any sessions older than 20 days
                            let _ = conn.execute(
                                "DELETE FROM sessions WHERE created_at < strftime('%s', 'now') - 1728000",
                                [],
                            );
                        }
                    }
                    _ = cache_interval.tick() => {
                        // Clean up expired timeline caches and manage cache invalidation
                        if let Ok(mut redis_conn) = redis_pool.get() {
                            let _ = cleanup_timeline_caches(&mut redis_conn).await;
                            let _ = check_timeline_invalidations_sqlite(&mut redis_conn, &pool).await;
                        }
                    }
                }
            }
        }
    }
}

// Clean up expired timeline cache entries
async fn cleanup_timeline_caches(redis_conn: &mut redis::Connection) -> Result<(), LuminaError> {
    let pattern = "timeline_cache:*";
    let mut cursor = 0;

    loop {
        let result: (u64, Vec<String>) = redis::cmd("SCAN")
            .cursor_arg(cursor)
            .arg("MATCH")
            .arg(pattern)
            .query(redis_conn)
            .map_err(LuminaError::Redis)?;

        cursor = result.0;
        let keys = result.1;

        let mut expired_keys = Vec::new();

        for key in keys {
            // Check TTL, if -1 or 0, it should be cleaned up
            let ttl: i64 = redis_conn.ttl(&key).map_err(LuminaError::Redis)?;
            if ttl == -1 || ttl == 0 {
                expired_keys.push(key);
            }
        }

        if !expired_keys.is_empty() {
            let _: () = redis_conn.del(&expired_keys).map_err(LuminaError::Redis)?;
        }

        if cursor == 0 {
            break;
        }
    }

    Ok(())
}

// Check for timeline changes and invalidate caches accordingly (PostgreSQL)
async fn check_timeline_invalidations(
    redis_conn: &mut redis::Connection,
    client: &postgres::Client,
) -> Result<(), LuminaError> {
    // Get the last check timestamp
    let last_check: Option<String> = redis_conn.get("timeline_cache_last_check").unwrap_or(None);

    let query = if let Some(timestamp) = last_check {
        client
            .query(
                "SELECT DISTINCT tlid FROM timelines WHERE timestamp > $1",
                &[&timestamp],
            )
            .await
    } else {
        // First run, don't invalidate anything
        let _: () = redis_conn
            .set("timeline_cache_last_check", chrono::Utc::now().to_rfc3339())
            .map_err(LuminaError::Redis)?;
        return Ok(());
    };

    match query {
        Ok(rows) => {
            for row in rows {
                let timeline_id: String = row.get(0);
                let _ = timeline::invalidate_timeline_cache(redis_conn, &timeline_id).await;
            }

            // Update last check timestamp
            let _: () = redis_conn
                .set("timeline_cache_last_check", chrono::Utc::now().to_rfc3339())
                .map_err(LuminaError::Redis)?;
        }
        Err(_) => {
            // If query fails, just update timestamp to avoid repeated failures
            let _: () = redis_conn
                .set("timeline_cache_last_check", chrono::Utc::now().to_rfc3339())
                .map_err(LuminaError::Redis)?;
        }
    }

    Ok(())
}

// Check for timeline changes and invalidate caches accordingly (SQLite)
async fn check_timeline_invalidations_sqlite(
    redis_conn: &mut redis::Connection,
    pool: &Pool<SqliteConnectionManager>,
) -> Result<(), LuminaError> {
    // Get the last check timestamp
    let last_check: Option<String> = redis_conn.get("timeline_cache_last_check").unwrap_or(None);

    let result: Result<Vec<String>, LuminaError> = if let Some(timestamp) = last_check {
        let conn = pool.get().map_err(LuminaError::R2D2Pool)?;
        let mut stmt = conn
            .prepare("SELECT DISTINCT tlid FROM timelines WHERE timestamp > ?")
            .map_err(LuminaError::Sqlite)?;

        let mut rows = stmt.query([timestamp]).map_err(LuminaError::Sqlite)?;
        let mut timeline_ids = Vec::new();

        while let Some(row) = rows.next().map_err(LuminaError::Sqlite)? {
            let timeline_id: String = row.get(0).map_err(LuminaError::Sqlite)?;
            timeline_ids.push(timeline_id);
        }

        Ok(timeline_ids)
    } else {
        // First run, don't invalidate anything
        let _: () = redis_conn
            .set("timeline_cache_last_check", chrono::Utc::now().to_rfc3339())
            .map_err(LuminaError::Redis)?;
        return Ok(());
    };

    match result {
        Ok(timeline_ids) => {
            for timeline_id in timeline_ids {
                let _ = timeline::invalidate_timeline_cache(redis_conn, &timeline_id).await;
            }

            // Update last check timestamp
            let _: () = redis_conn
                .set("timeline_cache_last_check", chrono::Utc::now().to_rfc3339())
                .map_err(LuminaError::Redis)?;
        }
        Err(_) => {
            // If query fails, just update timestamp to avoid repeated failures
            let _: () = redis_conn
                .set("timeline_cache_last_check", chrono::Utc::now().to_rfc3339())
                .map_err(LuminaError::Redis)?;
        }
    }

    Ok(())
}
