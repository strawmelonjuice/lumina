## Overview
- PostgreSQL and Redis are pooled with `bb8` (see `server/src/database.rs`).
- Redis is used only for performance: bloom filters and timeline caches; PostgreSQL remains source of truth.
- Background maintainer (`database::maintain`) periodically deletes old sessions and prunes timeline caches.

## PostgreSQL pool (bb8-postgres)
- Built from `tokio_postgres::Config` with `NoTls`.
- Pools are cloned everywhere via `DatabaseConnections::get_postgres_pool` to keep acquisition cheap.
- Avoid `unwrap()` on `.get()`; surface bb8 run errors via `LuminaError::Bb8RunErrorPg`.

Example (simplified):
```rust
let pg_pool = PgConn { postgres_pool, redis_pool };
let client = pg_pool.postgres_pool.get().await?; // ? maps to LuminaError::Bb8RunErrorPg
```

## Redis pool (bb8-redis)
- Configured pool builder (currently max_size 50, 5s timeout, 5m idle timeout).
- Connection type is `MultiplexedConnection`; use `redis::cmd(...).query_async(&mut **conn)`. Pool errors surface as `LuminaError::Bb8RunErrorRedis`.

### Bloom filters
- Keys: `bloom:email`, `bloom:username`.
- Populated at startup from Postgres (`database::setup`).
- Checked in `user::register_validitycheck` before DB uniqueness queries.

Example add/check:
```rust
let mut conn = redis_pool.get().await?;
redis::cmd("BF.ADD").arg("bloom:email").arg(email).query_async(&mut *conn).await?;
let exists: bool = redis::cmd("BF.EXISTS").arg("bloom:email").arg(email).query_async(&mut *conn).await?;
```

### Timeline cache
- Cache keys: `timeline_cache:{tlid}:page:{page}`; metadata key: `timeline_cache:{tlid}:meta`.
- Cache TTL: 3600s; high-traffic threshold: 100 lookups (global always high-traffic).
- Write path (`cache_timeline_page`) stores page JSON and total count; read path (`get_cached_timeline_page`) returns `CachedTimelinePage`.
- Invalidation: `invalidate_timeline_cache` SCANs matching keys and DELs; called after timeline writes and from the maintainer loop when timelines change.
- Background invalidation cursor uses `timeline_cache_last_check` stored in Redis.

Example invalidate:
```rust
let mut conn = redis_pool.get().await?;
timeline::invalidate_timeline_cache(&mut conn, tlid).await?;
```

## Background maintainer
- `database::maintain` (spawned at setup) runs two intervals:
  - Every 60s: delete sessions older than 20 days.
  - Every 300s: prune expired timeline cache entries; check timeline invalidations based on latest timestamps.

## Tests
- `src/tests.rs` covers: pool setup, bloom filter add/exists, timeline cache invalidation.

## Operational cautions
- Pool exhaustion: handle `.get()` errors; avoid panics from `unwrap()`.
- Redis is non-authoritative; always fall back to Postgres on cache miss or bloom filter hit.
- Keep TTLs and thresholds in sync if tuning (`timeline.rs` constants).
