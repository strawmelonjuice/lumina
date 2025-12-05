use crate::database::{self, DatabaseConnections};
use crate::timeline;

#[tokio::test]
async fn test_database_setup() {
    let result = database::setup().await;
    assert!(result.is_ok(), "Database setup should succeed");
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
