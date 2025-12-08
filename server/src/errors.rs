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
    DbError(LuminaDbError),
    Bb8RunErrorPg(bb8::RunError<crate::postgres::Error>),
    Bb8RunErrorRedis(bb8::RunError<redis::RedisError>),
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
    SerializationError(String),
    JoinFaillure,
}

impl From<LuminaDbError> for LuminaError {
    fn from(v: LuminaDbError) -> Self {
        Self::DbError(v)
    }
}

#[derive(Debug)]
pub(crate) enum LuminaDbError {
    Redis(redis::RedisError),
    Postgres(crate::postgres::Error),
}

impl From<rocket::Error> for LuminaError {
    fn from(err: rocket::Error) -> Self {
        LuminaError::RocketFaillure(Box::new(err))
    }
}

impl From<crate::postgres::Error> for LuminaError {
    fn from(err: crate::postgres::Error) -> Self {
        LuminaError::DbError(LuminaDbError::Postgres(err))
    }
}

impl From<redis::RedisError> for LuminaError {
    fn from(err: redis::RedisError) -> Self {
        LuminaError::DbError(LuminaDbError::Redis(err))
    }
}
impl From<bb8::RunError<crate::postgres::Error>> for LuminaError {
    fn from(err: bb8::RunError<crate::postgres::Error>) -> Self {
        LuminaError::Bb8RunErrorPg(err)
    }
}
impl From<bb8::RunError<redis::RedisError>> for LuminaError {
    fn from(err: bb8::RunError<redis::RedisError>) -> Self {
        LuminaError::Bb8RunErrorRedis(err)
    }
}
impl ToString for LuminaError {
    fn to_string(&self) -> String {
        match self {
            LuminaError::ConfInvalid(s) => format!("Configuration invalid: {}", s),
            LuminaError::DbError(e) => match e {
                LuminaDbError::Redis(re) => format!("Redis error: {}", re),
                LuminaDbError::Postgres(pe) => format!("Postgres error: {}", pe),
            },
            LuminaError::Bb8RunErrorPg(e) => format!("Postgres connection pool error: {}", e),
            LuminaError::Bb8RunErrorRedis(e) => format!("Redis connection pool error: {}", e),
            LuminaError::RocketFaillure(e) => format!("Rocket error: {}", e),
            LuminaError::BcryptError => "Bcrypt error".to_string(),
            LuminaError::RegisterEmailInUse => "Email already in use".to_string(),
            LuminaError::RegisterUsernameInUse => "Username already in use".to_string(),
            LuminaError::RegisterEmailNotValid => "Email not valid".to_string(),
            LuminaError::RegisterUsernameInvalid(s) => format!("Username invalid: {}", s),
            LuminaError::RegisterPasswordNotValid(s) => format!("Password not valid: {}", s),
            LuminaError::AuthenticationWrongPassword => "Wrong password".to_string(),
            LuminaError::UUidError => "UUID error".to_string(),
            LuminaError::RegexError => "Regex error".to_string(),
            LuminaError::SerializationError(s) => format!("Serialization error: {}", s),
            LuminaError::JoinFaillure => "Process join failure".to_string(),
            LuminaError::Unknown => "Unknown error".to_string(),
        }
    }
}