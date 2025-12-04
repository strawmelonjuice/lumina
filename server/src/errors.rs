//! Lumina > Server > Errors
//!
//! This module defines custom error types used throughout the server.

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

#[derive(Debug)]
pub(crate) enum LuminaError {
    ConfInvalid(String),
    R2D2Pool(r2d2::Error),
    Postgres(crate::postgres::Error),
    Unknown,
    /// Rocket failure wrapper, due to size, we only store the error source here. Construct with:
    /// ```rust
    /// (LuminaError::RocketFaillure, Some<rocket::Error>)
    /// ```
    RocketFaillure,
    BcryptError,
    RegisterEmailInUse,
    RegisterUsernameInUse,
    RegisterEmailNotValid,
    RegisterUsernameInvalid(String),
    RegisterPasswordNotValid(String),
    AuthenticationWrongPassword,
    UUidError,
    RegexError,
    Redis(redis::RedisError),
    SerializationError(String),
    JoinFaillure,
}
