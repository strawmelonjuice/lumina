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
use bb8::Pool;
use bb8_postgres::PostgresConnectionManager;
use bb8_redis::RedisConnectionManager;
use cynthia_con::{CynthiaColors, CynthiaStyles};
use std::time::Duration;
use crate::postgres;
use tokio_postgres::NoTls;

pub(crate) async fn setup() -> Result<PgConn, LuminaError> {
    let ev_log = EventLogger::new(&None);
    let redis_url =
        std::env::var("LUMINA_REDIS_URL").unwrap_or_else(|_| "redis://127.0.0.1/".into());
    let redis_pool = {
        info_elog!(ev_log, "Setting up Redis connection to {}...", redis_url);
        let manager = RedisConnectionManager::new(redis_url.clone())?;
        // Configure pool sizes
        let redis_pool = Pool::builder()
            .max_size(50)
            .connection_timeout(Duration::from_secs(5))
            .idle_timeout(Some(Duration::from_secs(300)))
            .build(manager)
            .await?;
        success_elog!(
            ev_log,
            "Redis connection to {} created successfully.",
            redis_url
        );

        redis_pool
    };

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

        // Create Postgres connection pool
        let pg_manager = PostgresConnectionManager::new(pg_config.clone(), NoTls);
        let pg_pool = Pool::builder()
            .build(pg_manager)
            .await?;
        {
            let pg_conn = pg_pool
                .get()
                .await?;
            pg_conn
                .batch_execute(include_str!("../../SQL/create_pg.sql"))
                .await?;
            // Populate bloom filters
            let mut redis_conn = redis_pool
                .get()
                .await?;
            let email_key = "bloom:email";
            let username_key = "bloom:username";

            let rows = pg_conn
                .query("SELECT email, username FROM users", &[])
                .await?;
            for row in rows {
                let email: String = row.get(0);
                let username: String = row.get(1);
                let _: () = redis::cmd("BF.ADD")
                    .arg(email_key)
                    .arg(email)
                    .query_async(&mut *redis_conn)
                    .await
                    ?;
                let _: () = redis::cmd("BF.ADD")
                    .arg(username_key)
                    .arg(username)
                    .query_async(&mut *redis_conn)
                    .await
                    ?;
            }
            info_elog!(ev_log, "Bloom filters populated from PostgreSQL.",);
        };
        let pg_pool_clone = pg_pool.clone();
        let redis_pool_clone = redis_pool.clone();
        tokio::spawn(async move {
            maintain(PgConn {
                postgres_pool: pg_pool_clone,
                redis_pool: redis_pool_clone,
            })
            .await
        });
        Ok(PgConn {
            postgres_pool: pg_pool,
            redis_pool,
        })
    }
}

/// This enum contains the postgres and redis connection and pool respectively. It used to have more variants before, and maybe it will once again.
#[derive()]
pub enum DbConn {
    /// The main database is a Postgres database in this variant.
    PgsqlConnection(
        Pool<PostgresConnectionManager<NoTls>>,
        Pool<RedisConnectionManager>,
    ),
}

pub(crate) trait DatabaseConnections {
    /// Get a reference to the redis pool
    /// This is useful for functions that need to access redis but not the main database
    /// such as timeline cache management
    /// This returns a clone of the pool without recreating it entirely, so it is cheap to call
    fn get_redis_pool(&self) -> Pool<RedisConnectionManager>;

    /// Get a reference to the Postgres pool
    /// This returns a clone of the pool without recreating it entirely, so it is cheap to call
    fn get_postgres_pool(&self) -> Pool<PostgresConnectionManager<NoTls>>;

    /// Recreate the database connection.
    async fn recreate(&self) -> PgConn
    where
        Self: Sized;
}

impl DatabaseConnections for DbConn {
    /// Recreate the database connection.
    /// This clones the pools - bb8 pools are cheap to clone as they share the underlying connections.
    // This function converts a generic DbConn to the more concrete PgConn type.
    async fn recreate(&self) -> PgConn {
        PgConn {
            postgres_pool: self.get_postgres_pool(),
            redis_pool: self.get_redis_pool(),
        }
    }

    fn get_redis_pool(&self) -> Pool<RedisConnectionManager> {
        match self {
            DbConn::PgsqlConnection(_, redis_pool) => redis_pool.clone(),
        }
    }
    fn get_postgres_pool(&self) -> Pool<PostgresConnectionManager<NoTls>> {
        match self {
            DbConn::PgsqlConnection(pg_pool, _) => pg_pool.clone(),
        }
    }
}

impl DatabaseConnections for PgConn {
    fn get_redis_pool(&self) -> Pool<RedisConnectionManager> {
        self.redis_pool.clone()
    }

    fn get_postgres_pool(&self) -> Pool<PostgresConnectionManager<NoTls>> {
        self.postgres_pool.clone()
    }

    async fn recreate(&self) -> PgConn
    where
        Self: Sized,
    {
        self.clone()
    }
}
/// Simplified type only accounting for the Postgres struct, since the enum adds some future flexibility, but also a lot of overhead.
/// If all goes well, this PgConn type will have replaced DbConn entirely after a few iterations of improvement over the years.
pub struct PgConn {
    pub(crate) postgres_pool: Pool<PostgresConnectionManager<NoTls>>,
    pub(crate) redis_pool: Pool<RedisConnectionManager>,
}

impl From<PgConn> for DbConn {
    /// Converts/unwraps the more concrete PgConn type to the generic DbConn counterpart.
    fn from(db: PgConn) -> Self {
        Self::PgsqlConnection(db.postgres_pool, db.redis_pool)
    }
}

impl Clone for PgConn {
    fn clone(&self) -> Self {
        PgConn {
            postgres_pool: self.postgres_pool.clone(),
            redis_pool: self.redis_pool.clone(),
        }
    }
}

// This function will be used to maintain the database, such as deleting old sessions
// and managing timeline caches
pub async fn maintain(db: PgConn) {
    let db = DbConn::from(db);
    match db {
        DbConn::PgsqlConnection(pg_pool, redis_pool) => {
            let mut session_interval = tokio::time::interval(std::time::Duration::from_secs(60));
            let mut cache_interval = tokio::time::interval(std::time::Duration::from_secs(300)); // 5 minutes

            loop {
                tokio::select! {
                    _ = session_interval.tick() => {
                        // Delete any sessions older than 20 days
                        if let Ok(client) = pg_pool.get().await {
                            let _ = client
                                .execute(
                                    "DELETE FROM sessions WHERE created_at < NOW() - INTERVAL '20 days'",
                                    &[],
                                )
                                .await;
                        }
                    }
                    _ = cache_interval.tick() => {
                        // Clean up expired timeline caches and manage cache invalidation
                        if let Ok(mut redis_conn) = redis_pool.get().await {
                            let _ = cleanup_timeline_caches(&mut redis_conn).await;
                            if let Ok(pg_conn) = pg_pool.get().await {
                                let _ = check_timeline_invalidations(&mut redis_conn, &pg_conn).await;
                            }
                        }
                    }
                }
            }
        }
    }
}

// Clean up expired timeline cache entries
async fn cleanup_timeline_caches(
    redis_conn: &mut bb8::PooledConnection<'_, RedisConnectionManager>,
) -> Result<(), LuminaError> {
    let pattern = "timeline_cache:*";
    let mut cursor = 0;

    loop {
        let result: (u64, Vec<String>) = redis::cmd("SCAN")
            .cursor_arg(cursor)
            .arg("MATCH")
            .arg(pattern)
            .query_async(&mut **redis_conn)
            .await
            ?;

        cursor = result.0;
        let keys = result.1;

        let mut expired_keys = Vec::new();

        for key in keys {
            // Check TTL, if -1 or 0, it should be cleaned up
            let ttl: i64 = redis::cmd("TTL")
                .arg(&key)
                .query_async(&mut **redis_conn)
                .await
                ?;
            if ttl == -1 || ttl == 0 {
                expired_keys.push(key);
            }
        }

        if !expired_keys.is_empty() {
            let _: () = redis::cmd("DEL")
                .arg(&expired_keys)
                .query_async(&mut **redis_conn)
                .await
                ?;
        }

        if cursor == 0 {
            break;
        }
    }

    Ok(())
}

// Check for timeline changes and invalidate caches accordingly (PostgreSQL)
async fn check_timeline_invalidations(
    redis_conn: &mut bb8::PooledConnection<'_, RedisConnectionManager>,
    client: &bb8::PooledConnection<'_, PostgresConnectionManager<NoTls>>,
) -> Result<(), LuminaError> {
    // Get the last check timestamp
    let last_check: Option<String> = redis::cmd("GET")
        .arg("timeline_cache_last_check")
        .query_async(&mut **redis_conn)
        .await
        .unwrap_or(None);

    let query = if let Some(timestamp) = last_check {
        client
            .query(
                "SELECT DISTINCT tlid FROM timelines WHERE timestamp > $1",
                &[&timestamp],
            )
            .await
    } else {
        // First run, don't invalidate anything
        let _: () = redis::cmd("SET")
            .arg("timeline_cache_last_check")
            .arg(
                time::OffsetDateTime::now_utc()
                    .format(&time::format_description::well_known::Rfc3339)
                    .unwrap(),
            )
            .query_async(&mut **redis_conn)
            .await
            ?;
        return Ok(());
    };

    match query {
        Ok(rows) => {
            for row in rows {
                let timeline_id: String = row.get(0);
                let _ = timeline::invalidate_timeline_cache(redis_conn, &timeline_id).await;
            }

            // Update last check timestamp
            let _: () = redis::cmd("SET")
                .arg("timeline_cache_last_check")
                .arg(
                    time::OffsetDateTime::now_utc()
                        .format(&time::format_description::well_known::Rfc3339)
                        .unwrap(),
                )
                .query_async(&mut **redis_conn)
                .await
                ?;
        }
        Err(_) => {
            // If query fails, just update timestamp to avoid repeated failures
            let _: () = redis::cmd("SET")
                .arg("timeline_cache_last_check")
                .arg(
                    time::OffsetDateTime::now_utc()
                        .format(&time::format_description::well_known::Rfc3339)
                        .unwrap(),
                )
                .query_async(&mut **redis_conn)
                .await
                ?;
        }
    }

    Ok(())
}
