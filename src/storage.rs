/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */

use std::io::{Error, ErrorKind};
use std::process;

use rusqlite::Connection;
use serde::{Deserialize, Serialize};

use crate::Config;

#[derive(Debug, Serialize, Deserialize)]
pub struct TableUsers {
    /// User ID
    pub(crate) id: i64,
    /// Known username
    pub(crate) username: String,
    /// Hashed password
    pub(crate) password: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PostInfo {
    /// Local Post ID
    lpid: i64,
    /// Post ID
    pid: i64,
    /// Instance ID - Might not be necessary on local posts. Hence being Option<>;
    instance: Option<String>,
    /// Author ID
    author_id: i64,
    /// Timestamp (UNIX)
    timestamp: i64,
    /// Content type
    content_type: String,
    /// Content in JSON, deserialised depending on content_type.
    content: String,
}

pub fn fetch(
    config: &Config,
    table: String,
    searchr: &str,
    searchv: String,
) -> Result<Option<String>, Error> {
    if config.database.method.as_str() == "sqlite" {
        match table.as_str() {
            "users" | "postinfo" => {}
            _ => {
                error!("Unknown table requisted!");
                panic!("Unknown table requisted!");
            }
        };
        let conn = match Connection::open(
            config
                .clone()
                .session
                .cd
                .join(config.clone().database.sqlite.unwrap().file),
        ) {
            Ok(d) => d,
            Err(_e) => {
                error!("Could not create a database connection!");
                process::exit(1);
            }
        };
        dbconf(&conn);

        let mut stmt =
            // match
        conn
            .prepare(
                format!("SELECT * FROM `{table}` WHERE ?1 IS ?2").as_str(),
            )
            .unwrap();
        // {
        //     Ok(d) => d,
        //     Err(e) => return Err(Error::new(ErrorKind::Other, e)),
        // };
        let mut res = stmt
            .query_map((searchr, searchv.as_str()), |row| {
                Ok(match table.as_str() {
                    "users" => serde_json::to_string(&TableUsers {
                        id: row.get(0)?,
                        username: row.get(1)?,
                        password: row.get(2)?,
                    })
                    .unwrap(),
                    "postinfo" => serde_json::to_string(&PostInfo {
                        pid: row.get(0)?,
                        instance: row.get(1)?,
                        author_id: row.get(2)?,
                        timestamp: row.get(3)?,
                        content_type: row.get(4)?,
                        content: row.get(5)?,
                        lpid: row.get(6)?,
                    })
                    .unwrap(),
                    _ => {
                        error!("Unknown table requisted!");
                        panic!("Unknown table requisted!");
                    }
                })
            })
            .unwrap();
        match res.next() {
            None => Ok(None),
            Some(r) => match r {
                Ok(s) => Ok(Some(s)),
                _ => Err(Error::new(ErrorKind::Other, "Unparseable data.")),
            },
        }
    } else {
        error!("Unknown or unsupported database type! Only SQLITE is supported as of now.");
        process::exit(1);
    }
}
fn dbconf(conn: &Connection) {
    let emergencyabort = || {
        error!("Could not configure the database correctly!");
        process::exit(1);
    };

    match conn.execute(
        "
CREATE TABLE if not exists Users (
    id    INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE,
    username  TEXT NOT NULL,
    password  TEXT NOT NULL
)
",
        (), // empty list of parameters.
    ) {
        Ok(_) => {}
        Err(_e) => emergencyabort(),
    };
    match conn.execute(
        "
CREATE TABLE if not exists TimeLinePostPool (
    lpid            INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE,
    pid             INTEGER,
    instance        TEXT,
    author_id      TEXT NOT NULL,
    timestamp      INTEGER NOT NULL,
    content_type    TEXT NOT NULL,
    content        TEXT NOT NULL
)
",
        (), // empty list of parameters.
    ) {
        Ok(_) => {}
        Err(_e) => emergencyabort(),
    }
}

pub(crate) mod users {
    pub(crate) mod auth {
        /// I first chose `Result<Option<>>`, but decided a struct which would just hold the options as bools would work as well.
        /// # AuthResponse
        /// Tells the server what the database knows of a user. If it exists, and if the password provided was correct.
        pub(crate) struct AuthResponse {
            success: bool,
            user_exists: bool,
            password_correct: bool,
            user_id: Option<i64>,
        }
        impl AuthResponse {
            /// Wraps the AuthResponse struct into a Result<Option<i64>, Error>, as originally intended.
            pub(crate) fn wrap(self) -> Result<Option<i64>, Error> {
                if self.success && self.user_exists && self.password_correct {
                    // Password is correct, user exists, return the user_id
                    Ok(Some(self.user_id.unwrap()))
                } else {
                    if !self.success {
                        // Unknown error, not important here, but there was an error causing an unknown outcome.
                        Err(Error::new(ErrorKind::Other, "Unknown error."))
                    } else {
                        if !self.user_exists {
                            // User does not exist
                            Ok(None)
                        } else {
                            // Password incorrect
                            Ok(None)
                        }
                    }
                }
            }
        }

        use colored::Colorize;
        use magic_crypt::{new_magic_crypt, MagicCryptTrait};
        use std::io::{Error, ErrorKind};

        /// # `auth_check`
        /// Authenticates a user by plain username and password.
        pub(crate) fn check(
            username: String,
            password: String,
            server_vars: &crate::ServerP,
        ) -> AuthResponse {
            let config: crate::Config = server_vars.config.clone();
            let mcrypt = new_magic_crypt!(config.clone().database.key, 256);
            match super::super::fetch(
                &config.clone(),
                "users".to_string(),
                "username",
                username.clone(),
            ) {
                Ok(a) => match a {
                    Some(d) => {
                        let u: super::super::TableUsers = serde_json::from_str(&*d).unwrap();
                        if u.password == mcrypt.encrypt_str_to_base64(password) {
                            (server_vars.tell)(format!(
                                "Auth\t\t\t{}",
                                format!("User {} successfully authorised.", u.username.blue())
                                    .green()
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
                                format!("User {}: Wrong password entered.", username.blue())
                                    .bright_red()
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
                            format!("User {} does not exist.", username.blue()).bright_yellow()
                        ));
                        AuthResponse {
                            success: true,
                            user_exists: false,
                            password_correct: false,
                            user_id: None,
                        }
                    }
                },
                Err(e) => {
                    error!("Auth: \n\t\tRan into an error:\n {}", e);
                    AuthResponse {
                        success: false,
                        user_exists: false,
                        password_correct: false,
                        user_id: None,
                    }
                }
            }
        }
    }
}
