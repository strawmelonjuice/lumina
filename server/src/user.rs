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
    pub async fn create_user(
        email: String,
        username: String,
        password: String,
        db: &DbConn,
    ) -> Result<User, LuminaError> {
        match {
            let mut check_results = vec![];
            {
                check_results.push((
                    username.len() > 4,
                    "Username must be at least 5 characters long",
                ));
                check_results.push((
                    username.len() < 20,
                    "Username must be less than 20 characters long",
                ));
                // Make sure the username does not contain any special characters, but underscores or dashes are allowed
                check_results.push((!username.contains('@'), "Username cannot contain '@'"));
                check_results.push((!username.contains('!'), "Username cannot contain '!'"));
                check_results.push((!username.contains('#'), "Username cannot contain '#'"));
                check_results.push((!username.contains('$'), "Username cannot contain '$'"));
                check_results.push((!username.contains('%'), "Username cannot contain '%'"));
                check_results.push((!username.contains('^'), "Username cannot contain '^'"));
                check_results.push((!username.contains('&'), "Username cannot contain '&'"));
                check_results.push((!username.contains('*'), "Username cannot contain '*'"));
                check_results.push((!username.contains('('), "Username cannot contain '('"));
                check_results.push((!username.contains(')'), "Username cannot contain ')'"));
                // check_results.push((
                //     username.chars().all(char::is_lowercase),
                //     "Username must be all lowercase",
                // ));
                // This false-positive's on the last check, so it's commented out for now, replacing it with a replacement check
                check_results.push((
                    username.chars().all(|x| {
                        // No case check on special
                        if !x.is_alphabetic() {
                            return true;
                        } else {
                            return x.is_lowercase();
                        }
                    }),
                    "Username must be alphanumeric, with underscores and dashes allowed",
                ));
            }
            check_results.iter().find(|x| x.0 == false).map(|x| x.1)
        } {
            Some(v) => {
                return Err(LuminaError::RegisterUsernameInvalid(v.to_string()));
            }
            None => {}
        }
        // Check if the email is valid
        if {
            let mut check_results = vec![];
            {
                check_results.push(email.contains('@'));
                check_results.push(email.contains('.'));
                let mut splemail = email.split("@");
                check_results.push(match splemail.nth(0) {
                    Some(v) => v.len() > 4,
                    None => false,
                });
                check_results.push(match splemail.nth(1) {
                    Some(v) => {
                        v.len() > 4
                            && v.contains('.')
                            && v.split('.').last().unwrap().len() > 1
                            && v.split('.').last().unwrap().len() < 5
                            && v == splemail.last().unwrap()
                    }
                    None => false,
                });

                check_results.push(email.len() > 8);
            }
            check_results.contains(&false)
        } {
            return Err(LuminaError::RegisterEmailNotValid);
        }
        // Now do that again but with reasons, like for username:
        match {
            let mut check_results = vec![];
            {
                check_results.push((
                    password.len() > 7,
                    "Password must be at least 8 characters long",
                ));
                check_results.push((
                    password.len() < 100,
                    "Password must be less than 100 characters long",
                ));
                check_results.push((
                    password.chars().any(char::is_uppercase),
                    "Password must contain at least one uppercase letter",
                ));
                check_results.push((
                    password.chars().any(char::is_lowercase),
                    "Password must contain at least one lowercase letter",
                ));
                check_results.push((
                    password.chars().any(char::is_numeric),
                    "Password must contain at least one number",
                ));
                check_results.push((
                    !password.chars().all(char::is_alphanumeric),
                    "Password must contain at least one special character",
                ));
            }
            check_results.iter().find(|x| x.0 == false).map(|x| x.1)
        } {
            Some(v) => {
                return Err(LuminaError::RegisterPasswordNotValid(v.to_string()));
            }
            None => {}
        }

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
