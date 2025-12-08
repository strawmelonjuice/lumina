## Overview
- Token-bucket limiter in `server/src/rate_limiter.rs` using in-memory `HashMap` protected by `tokio::sync::Mutex`.
- Rocket request guard `RateLimit` pulls `State<GeneralRateLimiter>`; missing state = allow (fail-open).
- Separate wrapper types: `GeneralRateLimiter` and `AuthRateLimiter` so Rocket can manage both independently.

## Defaults / Tuning
- Constructor requires `refill_per_second` and `capacity`; no hardcoded defaults. Decide per endpoint.
- In-memory only: resets on process restart; not distributed. For multi-node, replace with shared store (e.g., Redis token bucket) or IP hash partitioning.
- Keyed by client IP (`Request::client_ip()`); missing IP maps to key "unknown".

## Usage pattern
```rust
// Configure and mount in Rocket managed state
let limiter = GeneralRateLimiter::new(refill_per_second, capacity);
rocket::build().manage(limiter);

// Handler signature adds guard
#[get("/protected")]
async fn protected(_rate: RateLimit) -> &'static str {
    "ok"
}
```

## Gotchas
- Fail-open if the guard cannot fetch state; ensure the limiter is registered in Rocket.
- No per-route tuning baked in; provide distinct limiters via type wrappers if needed.
- Single-threaded bottleneck: Mutex over HashMap is fine for moderate QPS; consider sharding or lock-free structure if contention grows.
