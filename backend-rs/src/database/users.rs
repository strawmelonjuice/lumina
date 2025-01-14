/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */

use std::io::{Error, ErrorKind};

use magic_crypt::{new_magic_crypt, MagicCryptTrait};
use serde::{Deserialize, Serialize};
use crate::{database, LuminaConfig};

use super::{DatabaseItem, IIExchangedUserInfo};
/// The minimum length of a username.
pub const MINIMUM_USERNAME_LENGTH: usize = 3;

/// Checks if a username contains valid characters.
///
/// # Arguments
///
/// * `username` - A string slice that holds the username.
///
/// # Returns
///
/// * `bool` - Returns true if the username contains invalid characters, false otherwise.
pub(crate) fn char_check_username(username: String) -> bool {
    username.chars().any(|c| {
        match c {
            ' ' | '\\' | '/' | '@' | '\n' | '\r' | '\t' | '\x0b' | '\'' | '"' | '(' | ')' | '`'
            | '%' | '?' | '!' => true,
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
                        || !(vec_split_username[1].len() == 5 || vec_split_username[1].len() == 7)
                }
            )(),
            _ => false,
        }
    }) || !username
        .replace(['_', '-', '.'], "")
        .replacen('#', "", 1)
        .chars()
        .all(char::is_alphanumeric)
}

/// Adds a new user to the database.
///
/// # Arguments
///
/// * `username` - A string slice that holds the username.
/// * `email` - A string slice that holds the email.
/// * `password` - A string slice that holds the password.
/// * `config` - A reference to the LuminaConfig struct.
///
/// # Returns
///
/// * `Result<i64, Error>` - Returns the user id if the user is successfully added, otherwise returns an error.
pub(crate) fn add(
    username: String,
    email: String,
    password: String,
    config: &LuminaConfig,
) -> Result<i64, Error> {
    if char_check_username(username.clone()) {
        return Err(Error::new(
            ErrorKind::Other,
            "Invalid characters in username!",
        ));
    }
    if username.len() < MINIMUM_USERNAME_LENGTH {
        return Err(Error::new(ErrorKind::Other, "Username is too short."));
    }
    use regex::Regex;
    let email_regex = Regex::new(
        r"^([a-z0-9_+]([a-z0-9_+.]*[a-z0-9_+])?)@([a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,6})",
    )
    .unwrap();
    if !email_regex.is_match(&email) {
        return Err(Error::new(ErrorKind::Other, "Email is invalid."));
    };
    if password.len() < 8 {
        return Err(Error::new(ErrorKind::Other, "Password is too short."));
    }
    let mcrypt = new_magic_crypt!(config.clone().db_custom_salt, 256);
    let conn = &config.clone();
    let onusername = database::fetch::user(&config.clone(), UserDataDiscriminator::Username(username.clone()))?;
    let onemail = database::fetch::user(&config.clone(), UserDataDiscriminator::Email( email.clone()))?;
    let res: Option<User> = match onusername {
        Some(s) => Some(s),
        None => onemail,
    };
    let password_encrypted = mcrypt.encrypt_str_to_base64(password);
    match res {
        Some(_) => Err(Error::new(ErrorKind::Other, "User already exists!")),
        None => {
            match conn.db_connect().execute3(
                "INSERT INTO `users` (username, password, email) VALUES (?1,?2,?3)",
                (username.clone(), password_encrypted, email),
            ) {
                Ok(_) => {
                    match database::fetch::user(&config.clone(), UserDataDiscriminator::Username(username.clone()))? {
                        Some(q) => Ok(q.id),
                        None => Err(Error::new(
                            ErrorKind::Other,
                            "Unknown database check error.",
                        )),
                    }
                }
                Err(_) => {
                    error!("Unknown database write error!");
                    Err(Error::new(
                        ErrorKind::Other,
                        "Unknown database write error.",
                    ))
                }
            }
        }
    }
}

pub(crate) mod auth {
    use crate::database::users::User;
    use crate::ServerVars;
    use actix_web::web::Data;
    use colored::Colorize;
    use magic_crypt::{new_magic_crypt, MagicCryptTrait};
    use tokio::sync::Mutex;

    /// # AuthResponse
    /// Tells the server what the database knows of a user. If it exists, and if the password provided was correct.
    pub enum AuthResponse {
        Success(i64),
        UserNoneExistant,
        Fail(FailReason),
    }
    /// # FailReason
    /// The reason why the authentication failed.
    pub enum FailReason {
        Unspecified,
        PasswordIncorrect,
        InvalidUsername,
    }

    /// # `storage::users::auth::check()`
    /// Authenticates a user by plain username/email and password.
    pub(crate) async fn check(
        identifyer: String,
        password: String,
        server_vars_mutex: &Data<Mutex<ServerVars>>,
    ) -> AuthResponse {
        let server_vars = ServerVars::grab(server_vars_mutex).await;
        if identifyer.chars().any(|c| {
            matches!(
                c,
                ' ' | '\\' | '/' | '\n' | '\r' | '\t' | '\x0b' | '\'' | '"' | '(' | ')' | '`'
            )
        }) {
            // Invalid characters in username.
            return AuthResponse::Fail(FailReason::InvalidUsername);
        }
        let config: crate::LuminaConfig = server_vars.clone().config.clone();
        let mcrypt = new_magic_crypt!(config.clone().db_custom_salt, 256);
        let errorresponse = |e| {
            error!("{}: \n\t\tRan into an error:\n {}", "Auth".purple(), e);
            AuthResponse::Fail(FailReason::Unspecified)
        };
        let onusername =
            match super::database::fetch::user(&config.clone(), UserDataDiscriminator::Username(identifyer.clone())) {
                Ok(a) => a,
                Err(e) => return errorresponse(e),
            };
        let onemail =
            match super::database::fetch::user(&config.clone(), UserDataDiscriminator::Email( identifyer.clone())) {
                Ok(a) => a,
                Err(e) => return errorresponse(e),
            };
        let a_some: Option<User> = match onusername {
            Some(s) => Some(s),
            None => onemail,
        };
        match a_some {
            Some(u) => {
                if u.password == mcrypt.encrypt_str_to_base64(password) {
                    server_vars.tell(format!(
                        "{}\t\t\t{}",
                        "Auth".purple(),
                        format!("User {} successfully authorised.", u.username.blue()).green()
                    ));
                    AuthResponse::Success(u.id)
                } else {
                    server_vars.tell(format!(
                        "{}\t\t\t{}",
                        "Auth".purple(),
                        format!("User {}: Wrong password entered.", identifyer.blue()).bright_red()
                    ));
                    AuthResponse::Fail(FailReason::PasswordIncorrect)
                }
            }
            None => {
                server_vars.tell(format!(
                    "{}\t\t\t{}",
                    "Auth".purple(),
                    format!("User {} does not exist.", identifyer.blue()).bright_yellow()
                ));
                AuthResponse::UserNoneExistant
            }
        }
    }
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct SafeUser {
    pub id: i64,
    pub username: String,
    pub email: String,
}

/// Basic user-identifying information.
#[derive(Debug, Serialize, Deserialize)]
pub struct User {
    /// User ID
    pub(crate) id: i64,
    /// Known username
    pub(crate) username: String,
    /// Hashed password
    pub(crate) password: String,
    /// Given email
    pub(crate) email: String,
}

impl User {
    pub fn to_exchangable(&self, config: &LuminaConfig) -> IIExchangedUserInfo {
        IIExchangedUserInfo {
            id: self.id,
            username: self.username.clone(),
            instance: config.lumina_synchronisation_iid.clone(),
        }
    }
}

impl DatabaseItem for User {}