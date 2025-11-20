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

use rocket::State;
use rocket::http::Status;
use rocket::request::{FromRequest, Outcome, Request};
use std::collections::HashMap;
use std::net::IpAddr;
use std::time::Instant;
use tokio::sync::Mutex;

/// A request guard that enforces the rate limit. Add as a parameter to handlers
/// (e.g. `rate: RateLimit`) to have the connection checked before the handler
/// runs. On failure Rocket will respond with 429 Too Many Requests.
pub struct RateLimit;

#[rocket::async_trait]
impl<'r> FromRequest<'r> for RateLimit {
    type Error = ();

    async fn from_request(req: &'r Request<'_>) -> Outcome<Self, Self::Error> {
        // Try to get client IP from Rocket request
        let ip = req.client_ip();

        // Get the limiter from managed state (GeneralRateLimiter wrapper)
        let limiter = match req.guard::<&State<GeneralRateLimiter>>().await {
            Outcome::Success(s) => s,
            _ => return Outcome::Success(RateLimit), // If limiter not present, allow through
        };

        let allowed = limiter.allow_ip(ip).await;
        if allowed {
            Outcome::Success(RateLimit)
        } else {
            Outcome::Error((Status::TooManyRequests, ()))
        }
    }
}

/// Simple token-bucket rate limiter keyed by string (IP address).
pub struct RateLimiter {
    inner: Mutex<HashMap<String, TokenBucket>>,
    refill_per_second: f64,
    capacity: f64,
}

struct TokenBucket {
    tokens: f64,
    last: Instant,
}

impl RateLimiter {
    /// Create a new RateLimiter.
    /// refill_per_second: how many tokens are added per second
    /// capacity: maximum number of tokens stored
    pub fn new(refill_per_second: f64, capacity: f64) -> Self {
        Self {
            inner: Mutex::new(HashMap::new()),
            refill_per_second,
            capacity,
        }
    }

    /// Allow or deny a single event for the given key (usually an IP string).
    /// Returns true if allowed (consumes one token), false if rate limited.
    pub async fn allow(&self, key: &str) -> bool {
        let mut map = self.inner.lock().await;
        let now = Instant::now();
        let bucket = map.entry(key.to_string()).or_insert(TokenBucket {
            tokens: self.capacity,
            last: now,
        });

        // refill
        let elapsed = now.duration_since(bucket.last).as_secs_f64();
        let refill = elapsed * self.refill_per_second;
        bucket.tokens = (bucket.tokens + refill).min(self.capacity);
        bucket.last = now;

        if bucket.tokens >= 1.0 {
            bucket.tokens -= 1.0;
            true
        } else {
            false
        }
    }

    /// Convenience: accept an Option<IpAddr> and use a string key.
    pub async fn allow_ip(&self, ip: Option<IpAddr>) -> bool {
        let key = match ip {
            Some(a) => a.to_string(),
            None => "unknown".to_string(),
        };
        self.allow(&key).await
    }
}

// A lightweight request-guard helper is provided in `client_communication.rs` by using
// Rocket's `State<RateLimiter>` and implementing a small guard there. The core limiter
// lives here so other code can call it directly if needed.

/// Wrapper type used to manage a separate auth-specific limiter in Rocket's state.
/// Rocket distinguishes managed state by Rust type, so we expose this new type to
/// allow both a general `RateLimiter` and a dedicated `AuthRateLimiter`.
pub struct AuthRateLimiter(pub RateLimiter);

impl AuthRateLimiter {
    /// Create a new AuthRateLimiter which internally uses a RateLimiter.
    pub fn new(refill_per_second: f64, capacity: f64) -> Self {
        AuthRateLimiter(RateLimiter::new(refill_per_second, capacity))
    }

    /// Delegate allow_ip to the inner limiter.
    pub async fn allow_ip(&self, ip: Option<IpAddr>) -> bool {
        self.0.allow_ip(ip).await
    }
}

/// Wrapper for a general-purpose limiter so Rocket can manage a distinct type.
pub struct GeneralRateLimiter(pub RateLimiter);

impl GeneralRateLimiter {
    pub fn new(refill_per_second: f64, capacity: f64) -> Self {
        GeneralRateLimiter(RateLimiter::new(refill_per_second, capacity))
    }

    pub async fn allow_ip(&self, ip: Option<IpAddr>) -> bool {
        self.0.allow_ip(ip).await
    }
}
