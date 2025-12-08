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

use std::mem;
use crate::database::{self, DatabaseConnections};
use crate::timeline;
use crate::errors::LuminaError;

#[tokio::test]
async fn test_database_setup() {
    let result = database::setup().await.expect("Database setup should succeed.");
    assert!(result.get_postgres_pool().get().await.is_ok(), "Should get Postgres connection");
    assert!(result.get_redis_pool().get().await.is_ok(), "Should get Redis connection");
}

#[tokio::test]
async fn test_redis_bloom_filter() {
    let db = database::setup().await.expect("DB setup");
    let redis_pool = db.get_redis_pool();
    let mut conn = redis_pool.get().await.expect("Redis conn");
    let email_key = "test_bloom:email";
    let test_email = "testuser@example.com";

    // Add to bloom filter
    let _: () = redis::cmd("BF.ADD")
        .arg(email_key)
        .arg(test_email)
        .query_async(&mut *conn)
        .await
        .expect("BF.ADD");

    // Check if exists
    let exists: bool = redis::cmd("BF.EXISTS")
        .arg(email_key)
        .arg(test_email)
        .query_async(&mut *conn)
        .await
        .expect("BF.EXISTS");

    assert!(exists, "Bloom filter should contain the test email");

    // Clean up
    let _: () = redis::cmd("DEL")
        .arg(email_key)
        .query_async(&mut *conn)
        .await
        .unwrap_or(());
}

#[tokio::test]
async fn test_timeline_invalidation() {
    let db = database::setup().await.expect("DB setup");
    let redis_pool = db.get_redis_pool();
    let mut conn = redis_pool.get().await.expect("Redis conn");
    let timeline_id = "test-timeline-invalidation";

    // Set a test cache key
    let cache_key = format!("timeline_cache:{}:page:0", timeline_id);
    let _: () = redis::cmd("SET")
        .arg(&cache_key)
        .arg("test_data")
        .query_async(&mut *conn)
        .await
        .expect("SET");

    // Invalidate the timeline
    timeline::invalidate_timeline_cache(&mut conn, timeline_id)
        .await
        .expect("Invalidate cache");

    // Verify cache was cleared
    let result: Option<String> = redis::cmd("GET")
        .arg(&cache_key)
        .query_async(&mut *conn)
        .await
        .unwrap_or(None);

    assert!(result.is_none(), "Cache should be invalidated");
}


#[test]
fn print_sizes() {
    println!("Size of LuminaError: {} bytes", mem::size_of::<LuminaError>());
    println!("Size of errors::LuminaDbError: {} bytes", mem::size_of::<crate::errors::LuminaDbError>());
    println!("Size of EnvVar: {} bytes", mem::size_of::<crate::EnvVar>());
    println!("Size of InnerAppState: {} bytes", mem::size_of::<crate::InnerAppState>());
}

#[test]
fn test_error_sizes() {
    // We want to keep our error types small to minimize overhead when passing them around.
    assert!(mem::size_of::<LuminaError>() <= 16, "LuminaError should be 16 bytes or less");
    assert!(mem::size_of::<crate::errors::LuminaDbError>() <= 16, "LuminaDbError should be 16 bytes or less");
}

#[test]
fn test_appstate_size() {
    // Appstate is moved around a lot, so we want to keep it small, which is pretty easy since it just holds a single Arc pointer to a InnerAppState.
    assert!(mem::size_of::<crate::AppState>() <= 8, "AppState should be 8 bytes or less");
    // This constraint should lower over time as we optimize InnerAppState
    assert!(mem::size_of::<crate::InnerAppState>() <= 88, "InnerAppState should be 88 bytes or less");
}