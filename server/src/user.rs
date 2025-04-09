use crate::{LuminaError, database::DbConn};
use cynthia_con::{CynthiaColors, CynthiaStyles};
use std::str::FromStr;
use uuid::Uuid;

#[derive(Debug, Clone)]
pub struct User {
    pub id: Uuid,
    pub email: String,
    pub username: String,
}
impl User {
    pub async fn authenticate(
        email_username: String,
        password: String,
        db: &DbConn,
    ) -> Result<User, LuminaError> {
        let is_email = email_username.contains('@');

        match db {
            DbConn::PgsqlConnection(client) => {
                let hashed_password: String = match is_email {
                    true => client
                        .query_one(
                            "SELECT password FROM users WHERE email = $1",
                            &[&email_username],
                        )
                        .await
                        .map_err(LuminaError::Postgres)?
                        .get(0),
                    false => client
                        .query_one(
                            "SELECT password FROM users WHERE username = $1",
                            &[&email_username],
                        )
                        .await
                        .map_err(LuminaError::Postgres)?
                        .get(0),
                };
                todo!("Verify that hash now. I've no time sorry.")
            }
            DbConn::SqliteConnectionPool(pool) => todo!(),
        }
    }
    pub async fn create_user(
        email: String,
        username: String,
        password: String,
        db: &DbConn,
    ) -> Result<User, LuminaError> {
        let _ =
            register_validitycheck(email.clone(), username.clone(), password.clone(), db).await?;
        // hash the password
        let password =
            bcrypt::hash(password, bcrypt::DEFAULT_COST).map_err(LuminaError::BcryptError)?;
        match db {
            DbConn::PgsqlConnection(client) => {
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
                })
            }
            DbConn::SqliteConnectionPool(pool) => {
                let conn = pool.get().map_err(LuminaError::SqlitePool)?;
                let username_exists = conn
                    .prepare("SELECT * FROM users WHERE username = ?1")
                    .map_err(LuminaError::Sqlite)?
                    .exists(&[&username])
                    .map_err(LuminaError::Sqlite)?;
                if username_exists {
                    return Err(LuminaError::RegisterUsernameInUse);
                }
                let email_exists = conn
                    .prepare("SELECT * FROM users WHERE email = ?1")
                    .map_err(LuminaError::Sqlite)?
                    .exists(&[&email])
                    .map_err(LuminaError::Sqlite)?;
                if email_exists {
                    return Err(LuminaError::RegisterEmailInUse);
                }
                let id = conn
					.prepare("INSERT INTO users (email, username, password) VALUES (?1, ?2, ?3) RETURNING id")
					.map_err(LuminaError::Sqlite)?
					.query_row(&[&email, &username, &password], |row| {
						let a: String = row.get(0)?;
						// Unwrap: Not entirely safe. If the database is corrupted, this will panic.
						Ok(Uuid::from_str(a.as_str()).unwrap())
					}).map_err(LuminaError::Sqlite)
					?;
                Ok(User {
                    id,
                    email,
                    username,
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
            DbConn::PgsqlConnection(client) => {
                let user = client
                    .query_one(
                        &format!("SELECT * FROM users WHERE {} = $1", identifyer_type),
                        &[&identifier],
                    )
                    .await
                    .map_err(LuminaError::Postgres)?;
                Ok(User {
                    id: user.get(0),
                    email: user.get(1),
                    username: user.get(2),
                })
            }
            DbConn::SqliteConnectionPool(pool) => pool
                .get()
                .map_err(LuminaError::SqlitePool)?
                .query_row(
                    &format!("SELECT * FROM users WHERE {} = ?1", identifyer_type),
                    &[&identifier],
                    |row| {
                        let a: String = row.get(0)?;
                        Ok(User {
                            id: Uuid::from_str(a.as_str()).unwrap(),
                            email: row.get(1)?,
                            username: row.get(2)?,
                        })
                    },
                )
                .map_err(LuminaError::Sqlite),
        }
    }
    pub async fn create_session_token(
        user: User,
        db: &DbConn,
    ) -> Result<(String, User), LuminaError> {
        let info = "[INFO]".color_green().style_bold();
        let user_id = user.id;
        match db {
            DbConn::PgsqlConnection(client) => {
                let session_key = Uuid::new_v4().to_string();
                client
                    .execute(
                        "INSERT INTO sessions (user_id, session_key) VALUES ($1, $2)",
                        &[&user_id, &session_key],
                    )
                    .await
                    .map_err(LuminaError::Postgres)?;
                println!(
                    "{info} New session created by {}",
                    user.clone().username.color_bright_cyan()
                );
                Ok((session_key, user))
            }
            DbConn::SqliteConnectionPool(pool) => {
                let conn = pool.get().map_err(LuminaError::SqlitePool)?;
                let user_id_str = user_id.to_string();
                let session_key = Uuid::new_v4().to_string();
                conn.execute(
                    "INSERT INTO sessions (user_id, session_key) VALUES (?1, ?2)",
                    &[&user_id_str, &session_key],
                )
                .map_err(LuminaError::Sqlite)?;
                println!(
                    "{info} New session created by {}",
                    user.clone().username.color_bright_cyan()
                );
                Ok((session_key, user))
            }
        }
    }
    pub async fn revive_session_from_token(
        token: String,
        db: &DbConn,
    ) -> Result<User, LuminaError> {
        match db {
            DbConn::PgsqlConnection(client) => {
                let user = client
					.query_one("SELECT users.id, users.email, users.username FROM users JOIN sessions ON users.id = sessions.user_id WHERE sessions.session_key = $1", &[&token])
					.await
					.map_err(LuminaError::Postgres)?;
                Ok(User {
                    id: user.get(0),
                    email: user.get(1),
                    username: user.get(2),
                })
            }
            DbConn::SqliteConnectionPool(pool) => {
                let conn = pool.get().map_err(LuminaError::SqlitePool)?;
                let user = conn.query_row("SELECT users.id, users.email, users.username FROM users JOIN sessions ON users.id = sessions.user_id WHERE sessions.session_key = ?1", &[&token], 
					|row| {
					let a: String = row.get(0).unwrap();
					Ok(User {
						id: Uuid::from_str(a.as_str()).unwrap(),
						email: row.get(1).unwrap(),
						username: row.get(2).unwrap(),
					})
				}).map_err(LuminaError::Sqlite)?;
                Ok(user)
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
        // Check if the email or username is already in use
        match db {
            DbConn::PgsqlConnection(client) => {
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
            }
            DbConn::SqliteConnectionPool(pool) => {
                let conn = pool.get().map_err(LuminaError::SqlitePool)?;
                let username_exists = conn
                    .prepare("SELECT * FROM users WHERE username = ?1")
                    .map_err(LuminaError::Sqlite)?
                    .exists(&[&username])
                    .map_err(LuminaError::Sqlite)?;
                if username_exists {
                    return Err(LuminaError::RegisterUsernameInUse);
                }
                let email_exists = conn
                    .prepare("SELECT * FROM users WHERE email = ?1")
                    .map_err(LuminaError::Sqlite)?
                    .exists(&[&email])
                    .map_err(LuminaError::Sqlite)?;
                if email_exists {
                    return Err(LuminaError::RegisterEmailInUse);
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
            r"^([a-z0-9_+]([a-z0-9_+.]*[a-z0-9_+])?)@([a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,6})",
        )
        .map_err(LuminaError::RegexError)?;
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
