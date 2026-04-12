//! Lumina > Server > Database
//!
//! Database management and connection pooling module.

/*
 * Lumina/Peonies
 * Copyright (C) 2018-2026 MLC 'Strawmelonjuice' Bloeiman and contributors. [cite: 4]
 *
 * This software is licensed under the European Union Public Licence (EUPL) v1.2.
 * You may not use this work except in compliance with the Licence.
 * You may obtain a copy of the Licence at: https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12
 *
 * AI TRAINING NOTICE: Rights for TDM and AI training are EXPRESSLY RESERVED
 * under Art 4(3) Dir 2019/790. AI training constitutes a Derivative Work.
 * See LICENSE file in the repository root for full details.
 *
 *
 * This software is provided "AS IS", WITHOUT WARRANTY OF ANY KIND. [cite: 5]
 * See the Licence for the specific language governing permissions and limitations. [cite: 6]
 */
use crate::EnvVar::*;
use crate::errors::LuminaError::{self};
use crate::helpers::events::EventLogger;
use crate::timeline;
use crate::{info_elog, success_elog, warn_elog};
use bb8::Pool;
use bb8_redis::RedisConnectionManager;
use cynthia_con::{CynthiaColors, CynthiaStyles};
use sqlx::Postgres;
use sqlx::postgres::PgPool;
use std::time::Duration;

struct DatabaseConfig {
    postgres_username: String,
    postgres_password: Option<String>,
    postgres_host: String,
    postgres_port: u16,
    postgres_dbname: String,
}

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
        let uri = if let Ok(uri) = std::env::var("DATABASE_URL") {
            info_elog!(
                ev_log,
                "DATABASE_URL set, using that to connect to Postgres",
            );
            uri
        } else {
            let pg_config: DatabaseConfig = {
                let mut uuu = (
                    "unspecified database".to_string(),
                    "unspecified host".to_string(),
                    "unknown port".to_string(),
                );
                let mut pg_config = DatabaseConfig {
                    postgres_username: std::env::var("LUMINA_POSTGRES_USERNAME")
                        .unwrap_or("lumina".to_string()),
                    postgres_password: std::env::var("LUMINA_POSTGRES_PASSWORD").ok(),
                    postgres_host: std::env::var("LUMINA_POSTGRES_HOST")
                        .unwrap_or("localhost".to_string()),
                    postgres_port: std::env::var("LUMINA_POSTGRES_PORT")
                        .ok()
                        .and_then(|p| p.parse::<u16>().ok())
                        .unwrap_or(5432),
                    postgres_dbname: std::env::var("LUMINA_POSTGRES_DATABASE")
                        .unwrap_or("lumina_config".to_string()),
                };
                pg_config.postgres_username =
                    std::env::var("LUMINA_POSTGRES_USERNAME").unwrap_or("lumina".to_string());
                let dbname = std::env::var("LUMINA_POSTGRES_DATABASE")
                    .unwrap_or("lumina_config".to_string());
                uuu.0 = dbname.clone();
                pg_config.postgres_dbname = dbname;
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
                pg_config.postgres_port = port
                    .parse::<u16>()
                    .map_err(|_| LuminaError::ConfInvalid(LUMINA_POSTGRES_PORT))?;
                match std::env::var("LUMINA_POSTGRES_HOST") {
                    Ok(val) => {
                        uuu.1 = val.clone();
                        pg_config.postgres_host = val;
                    }
                    Err(_) => {
                        warn_elog!(
                            ev_log,
                            "No Postgres database host provided under environment variable 'LUMINA_POSTGRES_HOST'. Using default value 'localhost'."
                        );
                        // Default to localhost if not set
                        uuu.1 = "localhost".to_string();
                        pg_config.postgres_host = "localhost".to_string();
                    }
                };
                match std::env::var("LUMINA_POSTGRES_PASSWORD") {
                    Ok(val) => {
                        pg_config.postgres_password = Some(val);
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
            format!(
                "postgres://{}{}@{}:{}/{}",
                pg_config.postgres_username,
                pg_config
                    .postgres_password
                    .as_deref()
                    .map(|a| format!(":{}", a))
                    .unwrap_or_default(),
                pg_config.postgres_host,
                pg_config.postgres_port,
                pg_config.postgres_dbname
            )
        };
        let pg_pool: sqlx::Pool<Postgres> = PgPool::connect(uri.as_str()).await?;
        {
            // This is where previously the database schema was created if it did not exist, but now
            // we use sqlx and let it do that :)
            // pg_conn
            //     .batch_execute(include_str!("../../SQL/create_pg.sql"))
            //     .await?;
            // Populate bloom filters
            let mut redis_conn = redis_pool.get().await?;
            let email_key = "bloom:email";
            let username_key = "bloom:username";

            // (email, username)
            let users_and_emails = operations::list_users_and_emails(&pg_pool).await?;
            for (email, username) in users_and_emails {
                let _: () = redis::cmd("BF.ADD")
                    .arg(email_key)
                    .arg(email)
                    .query_async(&mut *redis_conn)
                    .await?;
                let _: () = redis::cmd("BF.ADD")
                    .arg(username_key)
                    .arg(username)
                    .query_async(&mut *redis_conn)
                    .await?;
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
    PgsqlConnection(PgPool, Pool<RedisConnectionManager>),
}

pub(crate) trait DatabaseConnections {
    /// Get a reference to the redis pool
    /// This is useful for functions that need to access redis but not the main database
    /// such as timeline cache management
    /// This returns a clone of the pool without recreating it entirely, so it is cheap to call
    fn get_redis_pool(&self) -> Pool<RedisConnectionManager>;

    /// Get a reference to the Postgres pool
    /// This returns a clone of the pool without recreating it entirely, so it is cheap to call
    fn get_postgres_pool(&self) -> PgPool;

    /// Recreate the database connection.
    async fn recreate(&self) -> PgConn
    where
        Self: Sized;
}

impl DatabaseConnections for DbConn {
    fn get_redis_pool(&self) -> Pool<RedisConnectionManager> {
        match self {
            DbConn::PgsqlConnection(_, redis_pool) => redis_pool.clone(),
        }
    }

    fn get_postgres_pool(&self) -> PgPool {
        match self {
            DbConn::PgsqlConnection(pg_pool, _) => pg_pool.clone(),
        }
    }
    /// Recreate the database connection.
    /// This clones the pools - bb8 pools are cheap to clone as they share the underlying connections.
    // This function converts a generic DbConn to the more concrete PgConn type.
    async fn recreate(&self) -> PgConn {
        PgConn {
            postgres_pool: self.get_postgres_pool(),
            redis_pool: self.get_redis_pool(),
        }
    }
}

impl DatabaseConnections for PgConn {
    fn get_redis_pool(&self) -> Pool<RedisConnectionManager> {
        self.redis_pool.clone()
    }

    fn get_postgres_pool(&self) -> PgPool {
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
    pub(crate) postgres_pool: PgPool,
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
            let mut session_interval = tokio::time::interval(Duration::from_secs(60));
            let mut cache_interval = tokio::time::interval(Duration::from_secs(300)); // 5 minutes

            loop {
                tokio::select! {
                    _ = session_interval.tick() => {
                        // Delete any sessions older than 20 days
                        match sqlx::query!("DELETE FROM sessions WHERE created_at < NOW() - INTERVAL '20 days'").execute(&pg_pool).await {
                            Ok(_) => (),
                            Err(err) => {
                                error!("Failed to delete session: {}", err);
                            }
                        };

                    }
                    _ = cache_interval.tick() => {
                        // Clean up expired timeline caches and manage cache invalidation
                        if let Ok(mut redis_conn) = redis_pool.get().await {
                            let _ = cleanup_timeline_caches(&mut redis_conn).await;

                                let _ = check_timeline_invalidations(&mut redis_conn, &pg_pool).await;
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
            .await?;

        cursor = result.0;
        let keys = result.1;

        let mut expired_keys = Vec::new();

        for key in keys {
            // Check TTL, if -1 or 0, it should be cleaned up
            let ttl: i64 = redis::cmd("TTL")
                .arg(&key)
                .query_async(&mut **redis_conn)
                .await?;
            if ttl == -1 || ttl == 0 {
                expired_keys.push(key);
            }
        }

        if !expired_keys.is_empty() {
            let _: () = redis::cmd("DEL")
                .arg(&expired_keys)
                .query_async(&mut **redis_conn)
                .await?;
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
    pg_pool: &PgPool,
) -> Result<(), LuminaError> {
    // Get the last check timestamp
    let last_check = redis::cmd("GET")
        .arg("timeline_cache_last_check")
        .query_async(&mut **redis_conn)
        .await
        .unwrap_or(None)
        .map(|a: String| {
            time::OffsetDateTime::parse(a.as_str(), &time::format_description::well_known::Rfc3339)
        });

    let query = if let Some(Ok(timestamp)) = last_check {
        sqlx::query!(
            "SELECT DISTINCT tlid FROM timelines WHERE timestamp > $1",
            timestamp
        )
        .fetch_all(pg_pool)
        .await
    } else if let Some(Err(_)) = last_check {
        panic!(
            "timeline_cache_last_check returned an error, this means there's probably been tampering with the Redis DB."
        );
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
            .await?;
        return Ok(());
    };

    match query {
        Ok(timelines) => {
            for timeline in timelines {
                let _ = timeline::invalidate_timeline_cache(redis_conn, timeline.tlid).await;
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
                .await?;
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
                .await?;
        }
    }

    Ok(())
}

pub(crate) mod operations {

    use std::str::FromStr;

    use anyhow::bail;
    use time::OffsetDateTime;
    use uuid::Uuid;

    use crate::timeline::GLOBAL_TIMELINE_ID;

    use super::*;
    /// List all users and their emails from the database, used for populating bloom filters on
    ///startup
    ///
    /// Returns a vector of tuples containing the email and username of each user in the database:
    /// ```rust
    /// Vec<(String, String)> // (email, username)
    /// ```
    pub async fn list_users_and_emails(
        pool: &PgPool,
    ) -> Result<Vec<(String, String)>, sqlx::Error> {
        let recs = sqlx::query!(
            r#"
SELECT email, username
FROM users
"#
        )
        .fetch_all(pool)
        .await?;
        let mut res = vec![];
        for rec in recs {
            res.push((rec.email, rec.username));
        }
        Ok(res)
    }
    /// Returns a post if it is on any public timeline, including bubble timelines but excluding DM timelines.
    // (This because all bubble timelines are also published to the global timeline, for now)
    /// The answer from this is not necessarily safe for public API's, though it is yet unspecified how public API's would handle single postrequests.
    pub(crate) async fn get_public_timelineitem(
        pool: &PgPool,
        postid: Uuid,
    ) -> anyhow::Result<typedreturns::PostItem> {
        let gltl = Uuid::from_str(GLOBAL_TIMELINE_ID)?;
        let timeline_lookup = sqlx::query!(
            "SELECT * FROM timelines WHERE item_id = $1 AND tlid = $2",
            postid,
            gltl
        )
        .fetch_optional(pool)
        .await?;
        let _ = if let None = timeline_lookup {
            bail!("No post was found on global timeline")
        };
        let type_lookup = sqlx::query!("SELECT * FROM itemtypes WHERE item_id = $1", postid,)
            .fetch_one(pool)
            .await?;
        match type_lookup.itemtype.as_str() {
            "text" => {
                let post = sqlx::query!("SELECT * FROM post_text WHERE id = $1", postid,)
                    .fetch_one(pool)
                    .await?;
                let location = match (post.foreign_instance_id, post.foreign_post_id) {
                    (Some(pid), Some(iid)) => (Uuid::from_str(pid.as_str())?, iid),
                    _ => (postid, String::from("local")),
                };
                anyhow::Ok(typedreturns::PostItem::TextPost {
                    post_id: postid,
                    source_instance: location.1,
                    content: post.content,
                    timestamp: post.created_at,
                })
            }
            "media" => {
                todo!("Media post fetching not yet implemented.");
            }
            "article" => {
                todo!("Article post fetching not yet implemented.");
            }
            _ => {
                bail!("Unsupported post for the global timeline, something got mixed up here.")
            }
        }
    }
}

pub(crate) mod typedreturns {
    use time::OffsetDateTime;
    use uuid::Uuid;

    pub(crate) enum TimelineItem {
        Post(PostItem),
    }
    pub(crate) enum PostItem {
        ArticlePost {
            post_id: Uuid,
            /// Source instance. 'local' by default, hostname if external.
            source_instance: String,
            title: String,
            content: String,
            /// Timestamp of the moment of posting
            timestamp: OffsetDateTime,
            /// User id of poster, which is why the source_instance matters.
            /// This means that client will do a lookup and stores the user once it gets it.
            author_id: String,
        },
        MediaPost {
            post_id: Uuid,
            /// Source instance. 'local' by default, hostname if external.
            source_instance: String,
            /// Media description
            description: String,
            /// Base64 encoded media strings, either webp or mp4.
            medias: Vec<String>,
            /// Timestamp of the moment of posting
            timestamp: OffsetDateTime,
        },
        TextPost {
            post_id: Uuid,
            /// Source instance. 'local' by default, hostname (IID) if external.
            source_instance: String,
            /// Markdown content.
            content: String,
            /// Timestamp of the moment of posting
            timestamp: OffsetDateTime,
        },
    }
}
