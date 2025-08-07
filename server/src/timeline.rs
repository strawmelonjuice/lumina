use crate::errors::LuminaError;
use crate::helpers::events::EventLogger;
use crate::{DbConn, error_elog, user};
use redis::Commands;
use uuid::Uuid;

/// The UUID for the global timeline (all zeroes)
pub const GLOBAL_TIMELINE_ID: &str = "00000000-0000-0000-0000-000000000000";

/// Fetch a list of post IDs for a given timeline.
/// For now, only supports the global timeline.
pub async fn fetch_timeline_post_ids(
    event_logger: EventLogger,
    db: &DbConn,
    timeline_id: &str,
) -> Result<Vec<String>, LuminaError> {
    // Log the requested timeline id for caching
    match db {
        DbConn::PgsqlConnection((client, _pg_config), redis_pool) => {
            let mut redis_conn = redis_pool.get().map_err(LuminaError::R2D2Pool)?;
            let _: () = redis_conn
                .incr(format!("timeline_lookup:{}", timeline_id), 1)
                .map_err(LuminaError::Redis)?;
            if timeline_id == GLOBAL_TIMELINE_ID {
                // Query for post IDs in the global timeline
                let rows = client
                    .query(
                        "SELECT item_id FROM timelines WHERE tlid = $1 ORDER BY timestamp DESC",
                        &[&timeline_id],
                    )
                    .await
                    .map_err(LuminaError::Postgres)?;
                let post_ids = rows
                    .into_iter()
                    .map(|row| row.get::<_, String>(0))
                    .collect();
                Ok(post_ids)
            } else {
                // Only global supported for now
                Ok(vec![])
            }
        }
        DbConn::SqliteConnectionPool(pool, redis_pool) => {
            let mut redis_conn = redis_pool.get().map_err(LuminaError::R2D2Pool)?;
            let _: () = redis_conn
                .incr(format!("timeline_lookup:{}", timeline_id), 1)
                .map_err(LuminaError::Redis)?;
            if timeline_id == GLOBAL_TIMELINE_ID {
                let conn = pool.get().map_err(LuminaError::R2D2Pool)?;
                let mut stmt = conn
                    .prepare("SELECT item_id FROM timelines WHERE tlid = ? ORDER BY timestamp DESC")
                    .map_err(LuminaError::Sqlite)?;
                let mut rows = stmt.query([timeline_id]).map_err(LuminaError::Sqlite)?;
                let mut post_ids = Vec::new();
                while let Some(row) = rows.next().map_err(LuminaError::Sqlite)? {
                    post_ids.push(row.get(0).map_err(LuminaError::Sqlite)?);
                }
                Ok(post_ids)
            } else {
                Ok(vec![])
            }
        }
    }
}
/// Fetch post IDs for a timeline by its name. Also returns the UUID of the timeline.
/// Needs to know the user to check for permissions or for example for the 'following' timeline.
pub async fn fetch_timeline_post_ids_by_timeline_name(
    event_logger: EventLogger,
    db: &DbConn,
    timeline_name: &str,
    user: user::User,
) -> Result<(uuid::Uuid, Vec<String>), LuminaError> {
    // For now, only global timeline is supported.
    if timeline_name == "global" {
        Uuid::parse_str(GLOBAL_TIMELINE_ID).map_err(LuminaError::UUidError)?;
        fetch_timeline_post_ids(event_logger, db, GLOBAL_TIMELINE_ID)
            .await
            .map(|post_ids| (Uuid::parse_str(GLOBAL_TIMELINE_ID).unwrap(), post_ids))
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
