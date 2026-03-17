//! Lumina > Server > Users
//!
//! User management module, including user struct and database interactions.
/*
 * Lumina/Peonies
 * Copyright (C) 2018-2026 MLC 'Strawmelonjuice' Bloeiman and contributors. [cite: 4]
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
 * This software is provided "AS IS", WITHOUT WARRANTY OF ANY KIND. [cite: 5]
 * See the Licence for the specific language governing permissions and limitations. [cite: 6]
 */

use crate::{LuminaError, database::DbConn, helpers::events::EventLogger, info_elog};
use cynthia_con::CynthiaColors;
use uuid::Uuid;

#[derive(Debug, Clone)]
pub struct User {
    pub id: Uuid,
    pub email: String,
    pub username: String,
    #[expect(dead_code, reason = "Will be used for federated posts in the future")]
    pub foreign_instance_id: String, // Added to handle foreign_instance_id
}

#[derive(Debug, Clone)]
pub struct SessionReference {
    pub session_id: Uuid,
    pub token: String,
}

impl User {
    pub async fn authenticate(
        email_username: String,
        password: String,
        db: &DbConn,
        ev_log: EventLogger,
    ) -> Result<(SessionReference, User), LuminaError> {
        let user = match User::get_user_by_identifier(email_username, db).await {
            // Replace some errors

            // Pass through other errors
            Ok(user) => Ok(user),
            Err(e) => Err(e),
        }?;
        let hashed_password = user.clone().get_hashed_password(db).await?;
        if bcrypt::verify(password, &hashed_password).map_err(|_| LuminaError::BcryptError)? {
            user.create_session(db, ev_log).await
        } else {
            Err(LuminaError::AuthenticationWrongPassword)
        }
    }
    async fn get_hashed_password(self, database: &DbConn) -> Result<String, LuminaError> {
        match database {
            DbConn::PgsqlConnection(pg_pool, _) => {
                let row = sqlx::query!("SELECT password FROM users WHERE id = $1", &self.id)
                    .fetch_one(pg_pool)
                    .await?;
                let password: String = row.password;
                Ok(password)
            }
        }
    }
    pub async fn create_user(
        email: String,
        username: String,
        password: String,
        db: &DbConn,
    ) -> Result<User, LuminaError> {
        register_validitycheck(email.clone(), username.clone(), password.clone(), db).await?;
        // hash the password
        let password =
            bcrypt::hash(password, bcrypt::DEFAULT_COST).map_err(|_| LuminaError::BcryptError)?;
        match db {
            DbConn::PgsqlConnection(pg_pool, _) => {
                // Some username and email validation should be done here
                // Check if the email is already in use
                let email_exists = sqlx::query!("SELECT * FROM users WHERE email = $1", &email)
                    .fetch_optional(pg_pool)
                    .await?;
                if !email_exists.is_none() {
                    return Err(LuminaError::RegisterEmailInUse);
                }
                // Check if the username is already in use
                let username_exists =
                    sqlx::query!("SELECT * FROM users WHERE username = $1", &username)
                        .fetch_optional(pg_pool)
                        .await?;
                if !username_exists.is_none() {
                    return Err(LuminaError::RegisterUsernameInUse);
                }

                let id = sqlx::query!("INSERT INTO users (email, username, password) VALUES ($1, $2, $3) RETURNING id", &email, &username, &password)
                    .fetch_one(pg_pool)
					.await
					?;
                Ok(User {
                    id: id.id,
                    email,
                    username,
                    foreign_instance_id: "".to_string(), // Default value for new users
                })
            }
        }
    }
    pub async fn get_user_by_identifier(
        identifier: String,
        db: &DbConn,
    ) -> Result<User, LuminaError> {
        let DbConn::PgsqlConnection(pg_pool, _) = db;
        // todo: Find a way to not repeat here, without it 'never matching' (which is what happens if you
        // parameterise the left side of the WHERE...)
        if identifier.contains('@') {
            match sqlx::query!("SELECT id, email, username, coalesce(foreign_instance_id, '') as foreign_instance_id FROM users WHERE email = $1", &identifier).fetch_optional(pg_pool).await?
				{
                    None => Err(LuminaError::AuthenticationNoSuchUser),
                    Some(user) => Ok(
                        User {
                            id: user.id,
                            email: user.email,
                            username: user.username,
                            foreign_instance_id: user.foreign_instance_id.unwrap_or("".to_string()),
                        }
                    ),
                }
        } else {
            match sqlx::query!("SELECT id, email, username, coalesce(foreign_instance_id, '') as foreign_instance_id FROM users WHERE username = $1", &identifier).fetch_optional(pg_pool).await?
				{
					None => Err(LuminaError::AuthenticationNoSuchUser),
					Some(user) => Ok(
						User {
							id: user.id,
							email: user.email,
							username: user.username,
							foreign_instance_id: user.foreign_instance_id.unwrap_or("".to_string()),
						}
					)
				}
        }
    }

    pub async fn create_session(
        self,
        db: &DbConn,
        ev_log: EventLogger,
    ) -> Result<(SessionReference, User), LuminaError> {
        let user = self;
        let user_id = user.id;
        match db {
            DbConn::PgsqlConnection(pg_pool, _) => {
                let session_key = Uuid::new_v4().to_string();
                let id = sqlx::query!(
                    "INSERT INTO sessions (user_id, session_key) VALUES ($1, $2) RETURNING id",
                    &user_id,
                    &session_key,
                )
                .fetch_one(pg_pool)
                .await?;
                info_elog!(
                    ev_log,
                    "New session created by {}",
                    user.clone().username.color_bright_cyan()
                );
                let session_id = id.id;
                Ok((
                    SessionReference {
                        session_id,
                        token: session_key,
                    },
                    user,
                ))
            }
        }
    }
    pub async fn revive_session_from_token(
        token: String,
        db: &DbConn,
    ) -> Result<User, LuminaError> {
        match db {
            DbConn::PgsqlConnection(pg_pool, _) => {
                let user = sqlx::query!("SELECT users.id, users.email, users.username FROM users JOIN sessions ON users.id = sessions.user_id WHERE sessions.session_key = $1", &token)
                    .fetch_one(pg_pool)
					.await
					?;
                Ok(User {
                    id: user.id,
                    email: user.email,
                    username: user.username,
                    foreign_instance_id: "".to_string(), // Default value for revived sessions
                })
            }
        }
    }
}

pub(crate) async fn register_validitycheck(
    email: String,
    username: String,
    password: String,
    db: &DbConn,
) -> Result<(), LuminaError> {
    {
        // Check if the email or username is already in use using fastbloom algorithm with Redis, and fallback to DB check if not found. If not in either, we can go on.
        match db {
            DbConn::PgsqlConnection(pg_pool, redis_pool) => {
                let mut redis_conn = redis_pool.get().await?;
                // fastbloom_rs expects bytes, so we use the string as bytes
                let email_key = String::from("bloom:email");
                let username_key = String::from("bloom:username");
                let email_exists: bool = redis::cmd("BF.EXISTS")
                    .arg(&email_key)
                    .arg(&email)
                    .query_async(&mut *redis_conn)
                    .await
                    .unwrap_or(false);
                if email_exists {
                    // Fallback to DB check if in bloom filter
                    let email_db = sqlx::query!("SELECT * FROM users WHERE email = $1", &email)
                        .fetch_optional(pg_pool)
                        .await?;
                    if !email_db.is_none() {
                        return Err(LuminaError::RegisterEmailInUse);
                    }
                }
                let username_exists: bool = redis::cmd("BF.EXISTS")
                    .arg(&username_key)
                    .arg(&username)
                    .query_async(&mut *redis_conn)
                    .await
                    .unwrap_or(false);
                if username_exists {
                    // Fallback to DB check if in bloom filter
                    let username_db =
                        sqlx::query!("SELECT * FROM users WHERE username = $1", &username)
                            .fetch_optional(pg_pool)
                            .await?;
                    if !username_db.is_none() {
                        return Err(LuminaError::RegisterUsernameInUse);
                    }
                }
                // Fallback to DB check if not in bloom filter
                let email_db = sqlx::query!("SELECT * FROM users WHERE email = $1", &email)
                    .fetch_optional(pg_pool)
                    .await?;
                if !email_db.is_none() {
                    // Update bloom filter after DB check
                    let _: () = redis::cmd("BF.ADD")
                        .arg(&email_key)
                        .arg(&email)
                        .query_async(&mut *redis_conn)
                        .await
                        .unwrap_or(());
                    return Err(LuminaError::RegisterEmailInUse);
                }
                let username_db =
                    sqlx::query!("SELECT * FROM users WHERE username = $1", &username)
                        .fetch_optional(pg_pool)
                        .await?;
                if !username_db.is_none() {
                    let _: () = redis::cmd("BF.ADD")
                        .arg(&username_key)
                        .arg(&username)
                        .query_async(&mut *redis_conn)
                        .await
                        .unwrap_or(());
                    return Err(LuminaError::RegisterUsernameInUse);
                }
            }
        }
    }

    //
    //
    // Email checks
    //
    {
        let email_regex = regex::Regex::new(
            r"^([a-z0-9_+]([a-z0-9_+.]*[a-z0-9_+])?)@([a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{1,6})",
        )
        .map_err(|_| LuminaError::RegexError)?;
        if !email_regex.is_match(&email) {
            return Err(LuminaError::RegisterEmailNotValid);
        };
    }

    //
    //
    // Username checks
    //
    {
        // Check if username is valid
        if username.chars().any(|c| {
            match c {
                ' ' | '\\' | '/' | '@' | '\n' | '\r' | '\t' | '\x0b' | '\'' | '"' | '(' | ')'
                | '`' | '%' | '?' | '!' => true,
                '#' => (
                    // Make sure, if a # is in the username, only 4 numbers may follow it.
                    || {
                        let split_username = username.split('#');
                        let array_split_username: Vec<&str> = split_username.collect();
                        let lastbit = username.replacen(array_split_username[0], "", 1);
                        let firstbit = username.replacen(&*lastbit, "", 1);
                        let vec_split_username: Vec<&str> = vec![&*firstbit, &*lastbit];
                        // println!("array: {:?}", array_split_username);
                        // println!("vec: {:?}", vec_split_username);
                        if vec_split_username.is_empty() || array_split_username[1].is_empty() {
                            return true;
                        };
                        (!array_split_username[1].chars().all(char::is_numeric))
                            || !(vec_split_username[1].len() == 5
                                || vec_split_username[1].len() == 7)
                    }
                )(),
                _ => false,
            }
        }) || !username
            .replace(['_', '-', '.'], "")
            .replacen('#', "", 1)
            .chars()
            .all(char::is_alphanumeric)
        {
            return Err(LuminaError::RegisterUsernameInvalid(
                OnRegisterUsernameInvalid::InvalidCharacters,
            ));
        }
        // Check if the username is too long
        if username.len() > 20 {
            return Err(LuminaError::RegisterUsernameInvalid(
                OnRegisterUsernameInvalid::TooLong,
            ));
        }
        // Check if the username is too short
        if username.len() < 4 {
            return Err(LuminaError::RegisterUsernameInvalid(
                OnRegisterUsernameInvalid::TooShort,
            ));
        }
    }

    //
    //
    // Password checks
    //
    {
        if password.len() < 8 {
            return Err(LuminaError::RegisterPasswordNotValid(
                OnRegisterPasswordNotValid::TooShort,
            ));
        }
        if password.len() > 100 {
            return Err(LuminaError::RegisterPasswordNotValid(
                OnRegisterPasswordNotValid::TooLong,
            ));
        }
        if !password.chars().any(char::is_uppercase) {
            return Err(LuminaError::RegisterPasswordNotValid(
                OnRegisterPasswordNotValid::MissingUppercase,
            ));
        }
        if !password.chars().any(char::is_lowercase) {
            return Err(LuminaError::RegisterPasswordNotValid(
                OnRegisterPasswordNotValid::MissingLowercase,
            ));
        }
        if !password.chars().any(char::is_numeric) {
            return Err(LuminaError::RegisterPasswordNotValid(
                OnRegisterPasswordNotValid::MissingNumber,
            ));
        }
    }
    Ok(())
}

#[derive(Debug)]
pub(crate) enum OnRegisterUsernameInvalid {
    TooLong,
    TooShort,
    InvalidCharacters,
}
impl std::fmt::Display for OnRegisterUsernameInvalid {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "{}",
            match self {
                OnRegisterUsernameInvalid::TooLong => "Username too long",
                OnRegisterUsernameInvalid::TooShort => "Username too short",
                OnRegisterUsernameInvalid::InvalidCharacters => {
                    "Username contains invalid characters"
                }
            }
        )
    }
}
#[derive(Debug)]
pub(crate) enum OnRegisterPasswordNotValid {
    TooShort,
    TooLong,
    MissingUppercase,
    MissingLowercase,
    MissingNumber,
}
impl std::fmt::Display for OnRegisterPasswordNotValid {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "{}",
            match self {
                OnRegisterPasswordNotValid::TooShort => "Password too short",
                OnRegisterPasswordNotValid::TooLong => "Password too long",
                OnRegisterPasswordNotValid::MissingUppercase => {
                    "Password must contain at least one uppercase letter"
                }
                OnRegisterPasswordNotValid::MissingLowercase => {
                    "Password must contain at least one lowercase letter"
                }
                OnRegisterPasswordNotValid::MissingNumber => {
                    "Password must contain at least one number"
                }
            }
        )
    }
}
