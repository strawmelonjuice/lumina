/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */

use crate::database::users::User;
use crate::database::LuminaDBConnection;
use crate::post::PostInfo;
use crate::{database, LuminaConfig};
use std::io::{Error, ErrorKind};

pub enum UserDataDiscriminator {
    Id(i64),
    Username(String),
    Email(String),
}
impl UserDataDiscriminator {
    pub fn from_str(a: (impl AsRef<str>, impl AsRef<str>)) -> Self {
        match a.0.as_ref() {
            "id" => UserDataDiscriminator::Id(a.1.as_ref().parse().unwrap()),
            "username" => UserDataDiscriminator::Username(a.1.as_ref().to_string()),
            "email" => UserDataDiscriminator::Email(a.1.as_ref().to_string()),
            _ => panic!("Invalid discriminator"),
        }
    }
}

/// Fetches user from database
pub fn user(
    config: &LuminaConfig,
    discriminator: UserDataDiscriminator,
) -> Result<Option<User>, Error> {
    match discriminator {
        UserDataDiscriminator::Id(id) => Ok(user_by_id(config, id)),
        UserDataDiscriminator::Username(username) => Ok(user_by_username(config, username)),
        UserDataDiscriminator::Email(email) => Ok(user_by_email(config, email)),
    }
}

/// Fetches user from database by id
pub fn user_by_id(config: &LuminaConfig, id: i64) -> Option<User> {
    match config.db_connect() {
        LuminaDBConnection::SQLite(conn) => {
            let mut stmt = conn
                .prepare(r#"SELECT * FROM Users WHERE `id` = $1"#)
                .unwrap();
            debug!("{:?}", stmt);
            let mut res = stmt.query([id.to_string()]).unwrap();
            let res = res.next().unwrap().unwrap();
            match (|| -> Result<(i64, String, String, String), rusqlite::Error> {
                let c: i64 = res.get(0)?;
                let username = res.get(1)?;
                let password = res.get(2)?;
                let email = res.get(3)?;
                Ok((c, username, password, email))
            })() {
                Ok((a, username, password, email)) => Some(User {
                    id: a,
                    username,
                    password,
                    email,
                }),
                Err(_) => None,
            }
        }
        LuminaDBConnection::POSTGRES(mut client) => {
            match client.query(r#"SELECT * FROM Users WHERE `id` = $1"#, &[&id]) {
                Ok(res) => {
                    let res = res.get(0)?;
                    let id: i64 = res.get(0);
                    let username: String = res.get(1);
                    let password: String = res.get(2);
                    let email: String = res.get(3);
                    Some(User {
                        id,
                        username,
                        password,
                        email,
                    })
                }
                Err(_) => None,
            }
        }
    }
}

/// Fetches user from database by username
pub fn user_by_username(config: &LuminaConfig, username: String) -> Option<User> {
    match config.db_connect() {
        LuminaDBConnection::SQLite(conn) => {
            let mut stmt = conn
                .prepare(r#"SELECT * FROM Users WHERE `username` = $1"#)
                .unwrap();
            debug!("{:?}", stmt);
            let mut res = stmt.query([username]).unwrap();
            let res = match res.next() {
                Ok(d) => d?,
                Err(e) => {
                    error!("SQLite user fetch error. {:#}", e);
                    panic!("{:#}", e)
                }
            };
            match (|| -> Result<(i64, String, String, String), rusqlite::Error> {
                let id: i64 = res.get(0)?;
                let c = res.get(1)?;
                let password = res.get(2)?;
                let email = res.get(3)?;
                Ok((id, c, password, email))
            })() {
                Ok((id, a, password, email)) => Some(User {
                    id,
                    username: a,
                    password,
                    email,
                }),
                Err(_) => None,
            }
        }
        LuminaDBConnection::POSTGRES(mut client) => {
            match client.query(r#"SELECT * FROM Users WHERE `username` = $1"#, &[&username]) {
                Ok(res) => {
                    let res = res.get(0)?;
                    let id: i64 = res.get(0);
                    let username: String = res.get(1);
                    let password: String = res.get(2);
                    let email: String = res.get(3);
                    Some(User {
                        id,
                        username,
                        password,
                        email,
                    })
                }
                Err(_) => None,
            }
        }
    }
}

/// Fetches user from database by email
pub fn user_by_email(config: &LuminaConfig, email: String) -> Option<User> {
    match config.db_connect() {
        LuminaDBConnection::SQLite(conn) => {
            let mut stmt = conn
                .prepare(r#"SELECT * FROM Users WHERE `email` = $1"#)
                .unwrap();
            debug!("{:?}", stmt);
            let mut res = stmt.query([email]).unwrap();
            let res = res.next().unwrap()?;
            match (|| -> Result<(i64, String, String, String), rusqlite::Error> {
                let c: i64 = res.get(0)?;
                let username = res.get(1)?;
                let password = res.get(2)?;
                let email = res.get(3)?;
                Ok((c, username, password, email))
            })() {
                Ok((a, username, password, email)) => Some(User {
                    id: a,
                    username,
                    password,
                    email,
                }),
                Err(_) => None,
            }
        }
        LuminaDBConnection::POSTGRES(mut client) => {
            match client.query(r#"SELECT * FROM Users WHERE `id` = $1"#, &[&email]) {
                Ok(res) => {
                    let res = res.get(0)?;
                    let id: i64 = res.get(0);
                    let username: String = res.get(1);
                    let password: String = res.get(2);
                    let email: String = res.get(3);
                    Some(User {
                        id,
                        username,
                        password,
                        email,
                    })
                }
                Err(_) => None,
            }
        }
    }
}

/// Fetches post from database
pub fn post(config: &LuminaConfig, id: u128) -> Result<Option<PostInfo>, Error> {
    match config.db_connect() {
        LuminaDBConnection::SQLite(conn) => {
            let mut stmt = conn
                .prepare(r#"SELECT * FROM posts_pool WHERE `postid` = ?"#)
                .unwrap();
            debug!("{:?}", stmt);
            let mut res = stmt
                .query_map([id.to_string()], |row| {
                    Ok({
                        let s = database::row_to_post_info(row);
                        serde_json::to_string(&s).unwrap()
                    })
                })
                .unwrap();
            // println!("{:?}", res.nth(0));
            match res.next() {
                None => Ok(None),
                Some(r) => match r {
                    Ok(s) => {
                        let res: PostInfo = serde_json::from_str(&s)?;
                        Ok(Some(res))
                    }
                    Err(f) => {
                        eprintln!("{:?}", f);
                        Err(Error::new(ErrorKind::Other, "Unparseable data."))
                    }
                },
            }
        }
        LuminaDBConnection::POSTGRES(_) => {
            todo!("Postgres not implemented yet.");
        }
    }
}
