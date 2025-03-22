use crate::{LuminaError, database::DbConn};
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
        if {
            let mut check_results = vec![];
            {
                check_results.push(username.len() > 4);
                check_results.push(username.len() < 20);
                check_results.push(username.chars().all(char::is_alphanumeric));
                check_results.push(username.chars().all(char::is_lowercase));
            }
            check_results.contains(&false)
        } {
            return Err(LuminaError::RegisterUsernameInvalid);
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
            return Err(LuminaError::EmailNotValid);
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
            DbConn::SqliteConnectionPool(_) => {
                todo!()
            }
        }
    }
    pub async fn create_session_token(
        user: User,
        db: &DbConn,
    ) -> Result<(String, User), LuminaError> {
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
                Ok((session_key, user))
            }
            DbConn::SqliteConnectionPool(_) => {
                todo!()
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
            DbConn::SqliteConnectionPool(_) => {
                todo!()
            }
        }
    }
}
