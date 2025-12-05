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
    Bb8Pool(String),
    Postgres(crate::postgres::Error),
    Unknown,
    RocketFaillure(Box<rocket::Error>),
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
impl From<rocket::Error> for LuminaError {
    fn from(err: rocket::Error) -> Self {
        LuminaError::RocketFaillure(Box::new(err))
    }
}

impl From<crate::postgres::Error> for LuminaError {
    fn from(err: crate::postgres::Error) -> Self {
        LuminaError::Postgres(err)
    }
}

impl From<redis::RedisError> for LuminaError {
    fn from(err: redis::RedisError) -> Self {
        LuminaError::Redis(err)
    }
}