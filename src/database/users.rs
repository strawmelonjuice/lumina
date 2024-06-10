/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */

use std::io::{Error, ErrorKind};

use magic_crypt::{new_magic_crypt, MagicCryptTrait};
use serde_json::from_str;

use crate::LuminaConfig;

use super::{create_con, fetch, BasicUserInfo};
pub const MINIMUM_USERNAME_LENGTH: usize = 3;
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

/// # `storage::users::add()`
/// Add data for a new user to the database.
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
    let mcrypt = new_magic_crypt!(config.clone().database.key, 256);
    let conn = create_con(&config.clone());
    let onusername = fetch(
        &config.clone(),
        String::from("Users"),
        "username",
        username.clone(),
    )?;
    let onemail = fetch(
        &config.clone(),
        String::from("Users"),
        "email",
        email.clone(),
    )?;
    let res: Option<String> = match onusername {
        Some(s) => Some(s),
        None => onemail,
    };
    let password_encrypted = mcrypt.encrypt_str_to_base64(password);
    match res {
        Some(_) => Err(Error::new(ErrorKind::Other, "User already exists!")),
        None => {
            match conn.execute(
                "INSERT INTO `users` (username, password, email) VALUES (?1,?2,?3)",
                (username.clone(), password_encrypted, email),
            ) {
                Ok(_) => {
                    match fetch(
                        &config.clone(),
                        String::from("Users"),
                        "username",
                        username.clone(),
                    )? {
                        Some(q) => {
                            let o: BasicUserInfo = from_str(&q)?;
                            Ok(o.id)
                        }
                        None => Err(Error::new(
                            ErrorKind::Other,
                            "Unknown database check error.",
                        )),
                    }
                }
                Err(e) => {
                    error!("Unknown database write error: {}", e);
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
    use std::io::{Error, ErrorKind};

    use colored::Colorize;
    use magic_crypt::{new_magic_crypt, MagicCryptTrait};
    use serde_json::from_str;

    /// I first chose `Result<Option<>>`, but decided a struct which would just hold the options as bools would work as well.
    /// # AuthResponse
    /// Tells the server what the database knows of a user. If it exists, and if the password provided was correct.
    pub(crate) struct AuthResponse {
        pub(crate) success: bool,
        pub(crate) user_exists: bool,
        pub(crate) password_correct: bool,
        pub(crate) user_id: Option<i64>,
    }
    impl AuthResponse {
        /// Wraps the AuthResponse struct into a Result<Option<i64>, Error>, as originally intended.
        #[allow(unused)]
        pub(crate) fn wrap(self) -> Result<Option<i64>, Error> {
            if self.success && self.user_exists && self.password_correct {
                // Password is correct, user exists, return the user_id
                Ok(Some(self.user_id.unwrap()))
            } else if !self.success {
                // Unknown error, not important here, but there was an error causing an unknown outcome.
                Err(Error::new(ErrorKind::Other, "Unknown error."))
            } else if !self.user_exists {
                // User does not exist
                Ok(None)
            } else {
                // Password incorrect
                Ok(None)
            }
        }
    }

    /// # `storage::users::auth::check()`
    /// Authenticates a user by plain username/email and password.
    pub(crate) fn check(
        identifyer: String,
        password: String,
        server_vars: &crate::ServerVars,
    ) -> AuthResponse {
        if identifyer.chars().any(|c| match c {
            ' ' | '\\' | '/' | '\n' | '\r' | '\t' | '\x0b' | '\'' | '"' | '(' | ')' | '`' => true,
            _ => false,
        }) {
            return AuthResponse {
                success: false,
                user_exists: false,
                password_correct: false,
                user_id: None,
            };
        }
        let config: crate::LuminaConfig = server_vars.config.clone();
        let mcrypt = new_magic_crypt!(config.clone().database.key, 256);
        let errorresponse = |e| {
            error!("Auth: \n\t\tRan into an error:\n {}", e);
            AuthResponse {
                success: false,
                user_exists: false,
                password_correct: false,
                user_id: None,
            }
        };
        let onusername = match super::fetch(
            &config.clone(),
            String::from("Users"),
            "username",
            identifyer.clone(),
        ) {
            Ok(a) => a,
            Err(e) => return errorresponse(e),
        };
        let onemail = match super::fetch(
            &config.clone(),
            String::from("Users"),
            "email",
            identifyer.clone(),
        ) {
            Ok(a) => a,
            Err(e) => return errorresponse(e),
        };
        let asome: Option<String> = match onusername {
            Some(s) => Some(s),
            None => onemail,
        };
        match asome {
            Some(d) => {
                let u: super::BasicUserInfo = from_str(&d).unwrap();
                if u.password == mcrypt.encrypt_str_to_base64(password) {
                    (server_vars.tell)(format!(
                        "Auth\t\t\t{}",
                        format!("User {} successfully authorised.", u.username.blue()).green()
                    ));
                    AuthResponse {
                        success: true,
                        user_exists: true,
                        password_correct: true,
                        user_id: Some(u.id),
                    }
                } else {
                    (server_vars.tell)(format!(
                        "Auth\t\t\t{}",
                        format!("User {}: Wrong password entered.", identifyer.blue()).bright_red()
                    ));
                    AuthResponse {
                        success: true,
                        user_exists: true,
                        password_correct: false,
                        user_id: None,
                    }
                }
            }
            None => {
                (server_vars.tell)(format!(
                    "Auth\t\t\t{}",
                    format!("User {} does not exist.", identifyer.blue()).bright_yellow()
                ));
                AuthResponse {
                    success: true,
                    user_exists: false,
                    password_correct: false,
                    user_id: None,
                }
            }
        }
    }
}
