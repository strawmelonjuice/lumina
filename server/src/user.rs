//! Lumina > Server > Users
//!
//! User management module, including user struct and database interactions.
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

use crate::{
    LuminaError,
    database::DbConn,
    helpers::{events::EventLogger},
    info_elog,
};
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
            DbConn::PgsqlConnection((client, _), _) => {
                let row = client
                    .query_one("SELECT password FROM users WHERE id = $1", &[&self.id])
                    .await
                    .map_err(LuminaError::Postgres)?;
                let password: String = row.get(0);
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
            DbConn::PgsqlConnection((client, _), _) => {
                // Some username and email validation should be done here
                // Check if the email is already in use
                let email_exists = client
                    .query("SELECT * FROM users WHERE email = $1", &[&email])
                    .await
                    .map_err(LuminaError::Postgres)?;
                if !email_exists.is_empty() {
                    return Err(LuminaError::RegisterEmailInUse);
                }
                // Check if the username is already in use
                let username_exists = client
                    .query("SELECT * FROM users WHERE username = $1", &[&username])
                    .await
                    .map_err(LuminaError::Postgres)?;
                if !username_exists.is_empty() {
                    return Err(LuminaError::RegisterUsernameInUse);
                }

                let id = client
					.query_one("INSERT INTO users (email, username, password) VALUES ($1, $2, $3) RETURNING id", &[&email, &username, &password])
					.await
					.map_err(LuminaError::Postgres)?;
                Ok(User {
                    id: id.get(0),
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
        let identifyer_type = if identifier.contains('@') {
            "email"
        } else {
            "username"
        };
        match db {
            DbConn::PgsqlConnection((client, _), _) => {
                let user = client
					.query_one(
						&format!("SELECT id, email, username, COALESCE(foreign_instance_id, '') FROM users WHERE {} = $1", identifyer_type),
						&[&identifier],
					)
					.await
					.map_err(LuminaError::Postgres)?;
                Ok(User {
                    id: user.get(0),
                    email: user.get(1),
                    username: user.get(2),
                    foreign_instance_id: user.get(3),
                })
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
            DbConn::PgsqlConnection((client, _), _) => {
                let session_key = Uuid::new_v4().to_string();
                let id = client
                    .query_one(
                        "INSERT INTO sessions (user_id, session_key) VALUES ($1, $2) RETURNING id",
                        &[&user_id, &session_key],
                    )
                    .await
                    .map_err(LuminaError::Postgres)?;
                info_elog!(
                    ev_log,
                    "New session created by {}",
                    user.clone().username.color_bright_cyan()
                );
                let session_id = id.get(0);
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
            DbConn::PgsqlConnection((client, _), _) => {
                let user = client
					.query_one("SELECT users.id, users.email, users.username FROM users JOIN sessions ON users.id = sessions.user_id WHERE sessions.session_key = $1", &[&token])
					.await
					.map_err(LuminaError::Postgres)?;
                Ok(User {
                    id: user.get(0),
                    email: user.get(1),
                    username: user.get(2),
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
            DbConn::PgsqlConnection((client, _), redis_pool) => {
                let mut redis_conn = redis_pool.get().map_err(LuminaError::R2D2Pool)?;
                // fastbloom_rs expects bytes, so we use the string as bytes
                let email_key = String::from("bloom:email");
                let username_key = String::from("bloom:username");
                let email_exists: bool = redis::cmd("BF.EXISTS")
                    .arg(&email_key)
                    .arg(&email)
                    .query(&mut *redis_conn)
                    .unwrap_or(false);
                if email_exists {
                    // Fallback to DB check if in bloom filter
                    let email_db = client
                        .query("SELECT * FROM users WHERE email = $1", &[&email])
                        .await
                        .map_err(LuminaError::Postgres)?;
                    if !email_db.is_empty() {
                        return Err(LuminaError::RegisterEmailInUse);
                    }
                }
                let username_exists: bool = redis::cmd("BF.EXISTS")
                    .arg(&username_key)
                    .arg(&username)
                    .query(&mut *redis_conn)
                    .unwrap_or(false);
                if username_exists {
                    // Fallback to DB check if in bloom filter
                    let username_db = client
                        .query("SELECT * FROM users WHERE username = $1", &[&username])
                        .await
                        .map_err(LuminaError::Postgres)?;
                    if !username_db.is_empty() {
                        return Err(LuminaError::RegisterUsernameInUse);
                    }
                }
                // Fallback to DB check if not in bloom filter
                let email_db = client
                    .query("SELECT * FROM users WHERE email = $1", &[&email])
                    .await
                    .map_err(LuminaError::Postgres)?;
                if !email_db.is_empty() {
                    // Update bloom filter after DB check
                    let _: () = redis::cmd("BF.ADD")
                        .arg(&email_key)
                        .arg(&email)
                        .query(&mut *redis_conn)
                        .unwrap_or(());
                    return Err(LuminaError::RegisterEmailInUse);
                }
                let username_db = client
                    .query("SELECT * FROM users WHERE username = $1", &[&username])
                    .await
                    .map_err(LuminaError::Postgres)?;
                if !username_db.is_empty() {
                    let _: () = redis::cmd("BF.ADD")
                        .arg(&username_key)
                        .arg(&username)
                        .query(&mut *redis_conn)
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
        .map_err(|_| {LuminaError::RegexError})?;
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
                "Invalid characters in username".to_string(),
            ));
        }
        // Check if the username is too long
        if username.len() > 20 {
            return Err(LuminaError::RegisterUsernameInvalid(
                "Username too long".to_string(),
            ));
        }
        // Check if the username is too short
        if username.len() < 4 {
            return Err(LuminaError::RegisterUsernameInvalid(
                "Username too short".to_string(),
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
                "Password too short".to_string(),
            ));
        }
        if password.len() > 100 {
            return Err(LuminaError::RegisterPasswordNotValid(
                "Password too long".to_string(),
            ));
        }
        if !password.chars().any(char::is_uppercase) {
            return Err(LuminaError::RegisterPasswordNotValid(
                "Password must contain at least one uppercase letter".to_string(),
            ));
        }
        if !password.chars().any(char::is_lowercase) {
            return Err(LuminaError::RegisterPasswordNotValid(
                "Password must contain at least one lowercase letter".to_string(),
            ));
        }
        if !password.chars().any(char::is_numeric) {
            return Err(LuminaError::RegisterPasswordNotValid(
                "Password must contain at least one number".to_string(),
            ));
        }
    }
    Ok(())
}
