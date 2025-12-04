//! Lumina > Server > Database
//!
//! Database management and connection pooling module.

/*
 *     Lumina/Peonies
 *     Copyright (C) 2018-2026 MLC 'Strawmelonjuice'  Bloeiman and contributors.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU Affero General Public License as published
 *     by the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU Affero General Public License for more details.
 *
 *     You should have received a copy of the GNU Affero General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

use crate::errors::LuminaError::{self};
use crate::helpers::events::EventLogger;
use crate::timeline;
use crate::{info_elog, success_elog, warn_elog};
use cynthia_con::{CynthiaColors, CynthiaStyles};
use r2d2::Pool;
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
        Pool::builder().build(client).map_err(LuminaError::R2D2Pool)
    }?;
    success_elog!(
        ev_log,
        "Redis connection to {} created successfully.",
        redis_url
    );

    {
        let pg_config: tokio_postgres::Config = {
            let mut uuu = (
                "unspecified database".to_string(),
                "unspecified host".to_string(),
                "unknown port".to_string(),
            );
            let mut pg_config = postgres::Config::new();
            pg_config.user(&{
                std::env::var("LUMINA_POSTGRES_USERNAME").unwrap_or("lumina".to_string())
            });
            let dbname =
                std::env::var("LUMINA_POSTGRES_DATABASE").unwrap_or("lumina_config".to_string());
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
        tokio::spawn(conn.1);
        // Create a second connection to the database for spawning the maintain function
        let conn_two: (Client, Connection<Socket, NoTlsStream>) = pg_config
            .connect(postgres::tls::NoTls)
            .await
            .map_err(LuminaError::Postgres)?;
        tokio::spawn(conn_two.1);
        {
            conn
                .0
                .batch_execute(include_str!("../../SQL/create_pg.sql"))
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
            info_elog!(ev_log, "Bloom filters populated from PostgreSQL.",);
        };
        let conn_clone = conn_two.0;
        let pg_config_clone = pg_config.clone();
        let redis_pool_clone = redis_pool.clone();
        tokio::spawn(async move {
            maintain(DbConn::PgsqlConnection(
                (conn_clone, pg_config_clone),
                redis_pool_clone,
            ))
            .await
        });
        Ok(DbConn::PgsqlConnection((conn.0, pg_config), redis_pool))
    }
}

/// This enum contains the postgres and redis connection and pool respectively. It used to have more variants before, and maybe it will once again.
#[derive()]
pub enum DbConn {
    // The config is also shared, so that for example the logger can set up its own connection, use this sparingly.
    /// The main database is a Postgres database in this variant.
    PgsqlConnection((Client, postgres::Config), Pool<redis::Client>),
}

pub(crate) trait DatabaseConnections {
    /// Get a reference to the redis pool
    /// This is useful for functions that need to access redis but not the main database
    /// such as timeline cache management
    /// This returns a clone of the pool without recreating it entirely, so it is cheap to call
    fn get_redis_pool(&self) -> Pool<redis::Client>;

    /// Recreate the database connection.
    async fn recreate(&self) -> Result<Self, LuminaError>
    where
        Self: Sized;
}

impl DatabaseConnections for DbConn {
    /// Recreate the database connection.
    /// This clones the pool on sqlite and for redis, and creates a new connection on postgres.
    async fn recreate(&self) -> Result<Self, LuminaError> {
        match self {
            DbConn::PgsqlConnection((_, config), redis_pool) => {
                let c = config
                    .connect(tokio_postgres::tls::NoTls)
                    .await
                    .map_err(LuminaError::Postgres)?
                    .0;
                let r = redis_pool.clone();

                Ok(DbConn::PgsqlConnection((c, config.to_owned()), r))
            }
        }
    }

    fn get_redis_pool(&self) -> Pool<redis::Client> {
        match self {
            DbConn::PgsqlConnection((_, _), redis_pool) => redis_pool.clone(),
        }
    }
}

impl DatabaseConnections for PgConn {
    fn get_redis_pool(&self) -> Pool<redis::Client> {
        self.redis_pool.clone()
    }

    async fn recreate(&self) -> Result<Self, LuminaError> {
        let postgres = self
            .postgres_config
            .connect(tokio_postgres::tls::NoTls)
            .await
            .map_err(LuminaError::Postgres)?
            .0;
        let postgres_config = self.postgres_config.to_owned();
        let redis_pool = self.redis_pool.clone();
        Ok(PgConn {
            postgres,
            postgres_config,
            redis_pool,
        })
    }
}
/// Simplified type only accounting for the Postgres struct, since the enum adds some future flexibility, but also a lot of overhead.
/// If all goes well, this PgConn type will have replaced DbConn entirely after a few iterations of improvement over the years.
pub struct PgConn {
    pub(crate) postgres: Client,
    postgres_config: postgres::Config,
    pub(crate) redis_pool: Pool<redis::Client>,
}

impl DbConn {
    /// Converts/unwraps the generic DbConn type to it's more concrete PgConn counterpart.
    pub(crate) fn to_pgconn(db: Self) -> PgConn {
        match db {
            Self::PgsqlConnection((a, b), c) => PgConn {
                postgres: a,
                postgres_config: b,
                redis_pool: c,
            },
        }
    }
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
    client: &Client,
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
            .set(
                "timeline_cache_last_check",
                time::OffsetDateTime::now_utc()
                    .format(&time::format_description::well_known::Rfc3339)
                    .unwrap(),
            )
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
                .set(
                    "timeline_cache_last_check",
                    time::OffsetDateTime::now_utc()
                        .format(&time::format_description::well_known::Rfc3339)
                        .unwrap(),
                )
                .map_err(LuminaError::Redis)?;
        }
        Err(_) => {
            // If query fails, just update timestamp to avoid repeated failures
            let _: () = redis_conn
                .set(
                    "timeline_cache_last_check",
                    time::OffsetDateTime::now_utc()
                        .format(&time::format_description::well_known::Rfc3339)
                        .unwrap(),
                )
                .map_err(LuminaError::Redis)?;
        }
    }

    Ok(())
}
