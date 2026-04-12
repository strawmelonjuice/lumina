## LuminaError
- Defined in `server/src/errors.rs`.
- Key variants: `DbError(LuminaDbError)`, `Bb8RunErrorPg(bb8::RunError<postgres::Error>)`, `Bb8RunErrorRedis(bb8::RunError<redis::RedisError>)`, auth/registration errors, `SerializationError(String)`, `RocketFaillure(Box<rocket::Error>)`.
- Conversions implemented for Rocket, Postgres, Redis, and bb8 run errors.
- Guidance: propagate the source error (`?`) to keep context; avoid lossy `to_string()` unless necessary.

## Logging
- Event logging macros `info_elog!`, `warn_elog!`, `error_elog!`, `success_elog!` are used across DB/timeline flows.
- `EventLogger` can log to stdout and (optionally) Postgres `logs` table (see `helpers/events.rs`).
- When logging DB failures, prefer structured context (timeline id, page, user) to aid diagnosis.

## Failure-handling patterns
- Pool acquisition: use `?` so `.get()` maps to `LuminaError::Bb8RunErrorPg/Redis`; avoid panics.
- Redis is non-authoritative: on Redis errors, proceed with Postgres path to avoid request failure where possible.
- Bloom filters: treat `BF.EXISTS` positives as hints; always confirm with Postgres.
- Timeline cache: cache misses/failures should fall back to DB fetch; invalidation is best-effort.

## Operational notes
- If Rocket state is missing (e.g., limiter), guards fail-open; verify state wiring at startup.
- Add tracing/metrics around pool usage and cache hit/miss for production readiness.
