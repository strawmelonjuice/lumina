//! Lumina > Server > Posts > Timeline
//!
//! Timeline management module for posts.

/*
 * Lumina/Peonies
 * Copyright (C) 2018-2026 MLC 'Strawmelonjuice' Bloeiman and contributors.
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
 * This software is provided "AS IS", WITHOUT WARRANTY OF ANY KIND.
 * See the Licence for the specific language governing permissions and limitations.
 */

use crate::errors::{LuminaDbError, LuminaError};
use crate::helpers::events::EventLogger;
use crate::{DbConn, error_elog, info_elog, user};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// The UUID for the global timeline (all zeroes)
pub const GLOBAL_TIMELINE_ID: &str = "00000000-0000-0000-0000-000000000000";

/// Maximum number of results per page
pub const TIMELINE_PAGE_SIZE: usize = 40;

/// Minimum lookup count to consider a timeline high-traffic (excluding global)
pub const HIGH_TRAFFIC_THRESHOLD: i64 = 100;

/// Cache TTL in seconds (1 hour)
pub const CACHE_TTL: usize = 3600;

#[derive(Serialize, Deserialize)]
struct CachedTimelinePage {
    post_ids: Vec<String>,
    total_count: usize,
    page: usize,
    cached_at: i64,
}

/// Check if a timeline should be cached based on traffic
async fn is_high_traffic_timeline(
    redis_conn: &mut bb8::PooledConnection<'_, bb8_redis::RedisConnectionManager>,
    timeline_id: &str,
) -> Result<bool, LuminaError> {
    // Global timeline is always high traffic
    if timeline_id == GLOBAL_TIMELINE_ID {
        return Ok(true);
    }

    // Check lookup count for other timelines
    let lookup_count: i64 = redis::cmd("GET")
        .arg(format!("timeline_lookup:{}", timeline_id))
        .query_async(&mut **redis_conn)
        .await
        .unwrap_or(0);

    Ok(lookup_count >= HIGH_TRAFFIC_THRESHOLD)
}

/// Get cache key for a timeline page
fn get_cache_key(timeline_id: &str, page: usize) -> String {
    format!("timeline_cache:{}:page:{}", timeline_id, page)
}

/// Get cache metadata key
fn get_cache_meta_key(timeline_id: &str) -> String {
    format!("timeline_cache:{}:meta", timeline_id)
}

/// Store timeline page in Redis cache
async fn cache_timeline_page(
    redis_conn: &mut bb8::PooledConnection<'_, bb8_redis::RedisConnectionManager>,
    timeline_id: &str,
    page: usize,
    post_ids: &[String],
    total_count: usize,
) -> Result<(), LuminaError> {
    let cached_page = CachedTimelinePage {
        post_ids: post_ids.to_vec(),
        total_count,
        page,
        cached_at: time::OffsetDateTime::now_utc().unix_timestamp(),
    };

    let cache_key = get_cache_key(timeline_id, page);
    let serialized = serde_json::to_string(&cached_page)?;

    let _: () = redis::cmd("SETEX")
        .arg(cache_key)
        .arg(CACHE_TTL)
        .arg(serialized)
        .query_async(&mut **redis_conn)
        .await?;

    // Also cache metadata
    let meta_key = get_cache_meta_key(timeline_id);
    let _: () = redis::cmd("SETEX")
        .arg(meta_key)
        .arg(CACHE_TTL)
        .arg(total_count)
        .query_async(&mut **redis_conn)
        .await?;

    Ok(())
}

/// Retrieve timeline page from Redis cache
async fn get_cached_timeline_page(
    redis_conn: &mut bb8::PooledConnection<'_, bb8_redis::RedisConnectionManager>,
    timeline_id: &str,
    page: usize,
) -> Result<Option<CachedTimelinePage>, LuminaError> {
    let cache_key = get_cache_key(timeline_id, page);

    let cached_data: Option<String> = redis::cmd("GET")
        .arg(cache_key)
        .query_async(&mut **redis_conn)
        .await?;

    match cached_data {
        Some(data) => {
            let cached_page: CachedTimelinePage = serde_json::from_str(&data)?;
            Ok(Some(cached_page))
        }
        None => Ok(None),
    }
}

/// Invalidate all cache entries for a timeline
pub async fn invalidate_timeline_cache(
    redis_conn: &mut bb8::PooledConnection<'_, bb8_redis::RedisConnectionManager>,
    timeline_id: Uuid,
) -> Result<(), LuminaError> {
    let timeline_id_string = Uuid::to_string(&timeline_id);
    // Use SCAN to find all cache keys for this timeline
    let pattern = format!("timeline_cache:{}:*", timeline_id_string);

    let mut cursor = 0;
    loop {
        let result: (u64, Vec<String>) = redis::cmd("SCAN")
            .cursor_arg(cursor)
            .arg("MATCH")
            .arg(&pattern)
            .query_async(&mut **redis_conn)
            .await?;

        cursor = result.0;
        let keys = result.1;

        if !keys.is_empty() {
            let _: () = redis::cmd("DEL")
                .arg(&keys)
                .query_async(&mut **redis_conn)
                .await?;
        }

        if cursor == 0 {
            break;
        }
    }

    Ok(())
}

/// Fetch total count for a timeline from database
async fn fetch_timeline_total_count(db: &DbConn, timeline_id: &str) -> Result<usize, LuminaError> {
    match db {
        DbConn::PgsqlConnection(pg_pool, _redis_pool) => {
            let timeline_uuid = Uuid::parse_str(timeline_id).map_err(|_| LuminaError::UUidError)?;
            let row = sqlx::query!(
                "SELECT COUNT(*) AS count FROM timelines WHERE tlid = $1",
                &timeline_uuid
            )
            .fetch_one(pg_pool)
            .await?;

            let count: i64 = row.count.unwrap_or(0);
            Ok(count as usize)
        }
    }
}

/// Fetch timeline post IDs from database with pagination
async fn fetch_timeline_from_db(
    db: &DbConn,
    timeline_id: &str,
    offset: usize,
    limit: usize,
) -> Result<Vec<String>, LuminaError> {
    match db {
        DbConn::PgsqlConnection(pg_pool, _redis_pool) => {
            let timeline_uuid = Uuid::parse_str(timeline_id).map_err(|_| LuminaError::UUidError)?;
            let rows =
				sqlx::query!(
					"SELECT item_id FROM timelines WHERE tlid = $1 ORDER BY timestamp DESC LIMIT $2 OFFSET $3",
					&timeline_uuid, &(limit as i64), &(offset as i64),
				)
				.fetch_all(pg_pool)
				.await
				?;

            let post_ids = rows
                .into_iter()
                .map(|row| row.item_id.to_string())
                .collect();
            Ok(post_ids)
        }
    }
}

/// Fetch a paginated list of post IDs for a given timeline.
/// Returns (post_ids, total_count, has_more_pages)
pub async fn fetch_timeline_post_ids(
    event_logger: EventLogger,
    db: &DbConn,
    timeline: &Uuid,
    page: Option<usize>,
) -> Result<(Vec<String>, usize, bool), LuminaError> {
    let timeline_id = timeline.to_string();
    let page = page.unwrap_or(0);
    let offset = page * TIMELINE_PAGE_SIZE;

    // Get Redis connection
    let mut redis_conn = match db {
        DbConn::PgsqlConnection(_, redis_pool) => redis_pool.get().await?,
    };

    // Log the requested timeline id for tracking
    let _: () = redis::cmd("INCR")
        .arg(format!("timeline_lookup:{}", timeline_id))
        .query_async(&mut *redis_conn)
        .await?;

    // Check if this timeline should be cached
    let should_cache = is_high_traffic_timeline(&mut redis_conn, &timeline_id).await?;

    // Try to get from cache if it's a high-traffic timeline
    if should_cache
        && let Some(cached_page) =
            get_cached_timeline_page(&mut redis_conn, &timeline_id, page).await?
    {
        let has_more = (page + 1) * TIMELINE_PAGE_SIZE < cached_page.total_count;
        return Ok((cached_page.post_ids, cached_page.total_count, has_more));
    }

    // Cache miss or low-traffic timeline - fetch from database
    if timeline_id == GLOBAL_TIMELINE_ID || should_cache {
        // Get total count
        let total_count = fetch_timeline_total_count(db, &timeline_id).await?;

        // Get page data
        let post_ids = fetch_timeline_from_db(db, &timeline_id, offset, TIMELINE_PAGE_SIZE).await?;

        // Cache the result if it's high-traffic
        if should_cache {
            match cache_timeline_page(&mut redis_conn, &timeline_id, page, &post_ids, total_count)
                .await
            {
                Ok(_) => info_elog!(
                    event_logger,
                    "Cached timeline {} page {} with {} posts",
                    timeline_id,
                    page,
                    post_ids.len()
                ),
                Err(e) => match e {
                    LuminaError::SerializationError(s) => error_elog!(
                        event_logger,
                        "Failed to serialize timeline {} page {} for caching: {}",
                        timeline_id,
                        page,
                        s
                    ),
                    LuminaError::DbError(LuminaDbError::Redis(redis_err)) => error_elog!(
                        event_logger,
                        "Failed to cache timeline {} page {}: {:?}",
                        timeline_id,
                        page,
                        redis_err
                    ),
                    _ => error_elog!(
                        event_logger,
                        "Unexpected error while caching timeline {} page {}: {:?}",
                        timeline_id,
                        page,
                        e
                    ),
                },
            };
        }

        let has_more = (page + 1) * TIMELINE_PAGE_SIZE < total_count;
        Ok((post_ids, total_count, has_more))
    } else {
        // Non-global, low-traffic timeline - return empty for now
        Ok((vec![], 0, false))
    }
}

/// Fetch post IDs for a timeline by its name. Also returns the UUID of the timeline.
/// Needs to know the user to check for permissions or for example for the 'following' timeline.
/// Returns (timeline_uuid, post_ids, total_count, has_more_pages)
pub async fn fetch_timeline_post_ids_by_timeline_name(
    event_logger: EventLogger,
    db: &DbConn,
    timeline_name: &str,
    user: user::User,
    page: Option<usize>,
) -> Result<(Uuid, Vec<String>, usize, bool), LuminaError> {
    info_elog!(
        event_logger,
        "Fetching timeline '{}' for user '{}'",
        timeline_name,
        user.username
    );
    // For now, only global timeline is supported.
    if timeline_name == "global" {
        let global_timeline_uuid =
            Uuid::parse_str(GLOBAL_TIMELINE_ID).map_err(|_| LuminaError::UUidError)?;
        let (post_ids, total_count, has_more) =
            fetch_timeline_post_ids(event_logger, db, &global_timeline_uuid, page).await?;
        Ok((global_timeline_uuid, post_ids, total_count, has_more))
    } else {
        // Handle other timelines in the future
        error_elog!(
            event_logger,
            "Yet unsupported timeline name: {}",
            timeline_name
        );
        Err(LuminaError::Unknown)
    }
}

/// Add a post to a timeline and invalidate cache if necessary
pub async fn add_to_timeline(
    event_logger: EventLogger,
    db: &DbConn,
    timeline: &Uuid,
    item: &Uuid,
    item_type: ItemType,
) -> Result<(), LuminaError> {
    // Add to database
    match db {
        DbConn::PgsqlConnection(pg_pool, redis_pool) => {
            sqlx::query!(
                "INSERT INTO timelines (tlid, item_id, timestamp) VALUES ($1, $2, NOW())",
                *timeline,
                item,
            )
            .execute(pg_pool)
            .await?;

            sqlx::query!(
                "INSERT INTO itemtypes (itemtype, item_id) VALUES ($1, $2)",
                match item_type {
                    ItemType::Text => "text",
                    ItemType::Article => "article",
                    ItemType::Media => "media",
                },
                item,
            )
            .execute(pg_pool)
            .await?;

            // Invalidate cache
            let mut redis_conn = redis_pool.get().await?;
            if let Err(e) = invalidate_timeline_cache(&mut redis_conn, *timeline).await {
                error_elog!(
                    event_logger,
                    "Failed to invalidate cache for timeline {}: {:?}",
                    timeline.to_string(),
                    e
                );
            }
        }
    }

    Ok(())
}

pub(crate) enum ItemType {
    Text,
    Article,
    Media,
    // ... More
}

#[expect(dead_code, reason = "Not used yet")]
/// Remove a post from a timeline and invalidate cache if necessary
pub async fn remove_from_timeline(
    event_logger: EventLogger,
    db: &DbConn,
    timeline: &Uuid,
    item: &Uuid,
) -> Result<(), LuminaError> {
    // Remove from database
    match db {
        DbConn::PgsqlConnection(pg_pool, redis_pool) => {
            sqlx::query!(
                "DELETE FROM timelines WHERE tlid = $1 AND item_id = $2",
                &timeline,
                &item
            )
            .execute(pg_pool)
            .await?;

            // Invalidate cache
            let mut redis_conn = redis_pool.get().await?;
            if let Err(e) = invalidate_timeline_cache(&mut redis_conn, *timeline).await {
                error_elog!(
                    event_logger,
                    "Failed to invalidate cache for timeline {}: {:?}",
                    timeline.to_string(),
                    e
                );
            }
        }
    }

    Ok(())
}
