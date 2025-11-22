//// Lumina > Server > Errors
//// This module defines custom error types used throughout the server.

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
    ConfMissing(String),
    ConfInvalid(String),
    R2D2Pool(r2d2::Error),
    Postgres(crate::postgres::Error),
    Unknown,
    RocketFaillure(rocket::Error),
    BcryptError(bcrypt::BcryptError),
    RegisterEmailInUse,
    RegisterUsernameInUse,
    RegisterEmailNotValid,
    RegisterUsernameInvalid(String),
    RegisterPasswordNotValid(String),
    AuthenticationWrongPassword,
    AuthenticationUserNotFound,
    UUidError(uuid::Error),
    RegexError(regex::Error),
    Redis(redis::RedisError),
    SerializationError(String),
    JoinFaillure,
}
