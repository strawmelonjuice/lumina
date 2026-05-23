//! Lumina > Server > Errors
//!
//! This module defines custom error types used throughout the server.

/*
 * Lumina/Peonies
 * Copyright (C) 2018-2026 MLC 'Strawmelonjuice' Bloeiman and contributors.
 *
 * This software is licensed under the European Union Public Licence (EUPL) v1.2.
 * You may not use this work except in compliance with the Licence.
 * You may obtain a copy of the Licence at: https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12
 *
 * AI TRAINING NOTICE: Rights for TDM and AI training are EXPRESSLY RESERVED
 * under Art 4(3) Dir 2019/790. AI training constitutes a Derivative Work.
 * See LICENSE file in the repository root for full details.
 *
 *
 * This software is provided "AS IS", WITHOUT WARRANTY OF ANY KIND.
 * See the Licence for the specific language governing permissions and limitations.
 */

#[derive(Debug)]
pub(crate) enum LuminaError {
    ConfInvalid(crate::EnvVar),
    DbError(LuminaDbError),
    Bb8RunErrorRedis(Box<bb8::RunError<redis::RedisError>>),
    Unknown,
    RocketFaillure(Box<rocket::Error>),
    BcryptError,
    RegisterEmailInUse,
    RegisterUsernameInUse,
    RegisterEmailNotValid,
    RegisterUsernameInvalid(crate::user::OnRegisterUsernameInvalid),
    RegisterPasswordNotValid(crate::user::OnRegisterPasswordNotValid),
    AuthenticationWrongPassword,
    UUidError,
    RegexError,
    SerializationError(serde_json::Error),
    JoinFaillure,
    AuthenticationNoSuchUser,
}

impl From<LuminaDbError> for LuminaError {
    fn from(v: LuminaDbError) -> Self {
        Self::DbError(v)
    }
}

#[derive(Debug)]
pub(crate) enum LuminaDbError {
    Redis(Box<redis::RedisError>),
    Postgres(sqlx::Error),
}

impl From<rocket::Error> for LuminaError {
    fn from(err: rocket::Error) -> Self {
        LuminaError::RocketFaillure(Box::new(err))
    }
}

impl From<serde_json::Error> for LuminaError {
    fn from(err: serde_json::Error) -> Self {
        LuminaError::SerializationError(err)
    }
}

impl From<sqlx::Error> for LuminaError {
    fn from(err: sqlx::Error) -> Self {
        LuminaError::DbError(LuminaDbError::Postgres(err))
    }
}

impl From<redis::RedisError> for LuminaError {
    fn from(err: redis::RedisError) -> Self {
        LuminaError::DbError(LuminaDbError::Redis(Box::new(err)))
    }
}

impl From<bb8::RunError<redis::RedisError>> for LuminaError {
    fn from(err: bb8::RunError<redis::RedisError>) -> Self {
        LuminaError::Bb8RunErrorRedis(Box::new(err))
    }
}

impl std::fmt::Display for LuminaError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "{}",
            match self {
                LuminaError::ConfInvalid(s) => match s {
                    crate::EnvVar::LUMINA_SERVER_ADDR =>
                        "LUMINA_SERVER_ADDR is an invalid address".to_string(),
                    crate::EnvVar::LUMINA_SERVER_PORT =>
                        "LUMINA_SERVER_PORT is not a valid port number".to_string(),
                    crate::EnvVar::LUMINA_POSTGRES_PORT =>
                        "LUMINA_POSTGRES_PORT is not a valid port number".to_string(),
                },

                LuminaError::DbError(e) => match e {
                    LuminaDbError::Redis(re) => format!("Redis error: {}", re),
                    LuminaDbError::Postgres(pe) => format!("Postgres error: {}", pe),
                },
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
                LuminaError::AuthenticationNoSuchUser => "No such user".to_string(),
                LuminaError::Unknown => "Unknown error".to_string(),
            }
        )
    }
}
