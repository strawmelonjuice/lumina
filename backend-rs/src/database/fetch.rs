/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */

use crate::database::{LuminaDBConnection};
use crate::post::PostInfo;
use crate::{database, LuminaConfig};
use std::io::{Error, ErrorKind};
use crate::database::users::User;

pub enum UserDataDiscriminator {
    ID(String),
    Username(String),
    Email(String),
}
impl UserDataDiscriminator {
    pub fn from_str(a: (impl AsRef<str>, impl AsRef<str>)) -> Self {
        match a.0.as_ref() {
            "id" => UserDataDiscriminator::ID(a.1.as_ref().to_string()),
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
    let (discriminator_col, discriminator_1) = match discriminator {
        UserDataDiscriminator::ID(id) => ("id", id),
        UserDataDiscriminator::Username(username) => ("username", username),
        UserDataDiscriminator::Email(email) => ("email", email),
    };
    match config.db_connect() {
        LuminaDBConnection::SQLite(conn) => {
            let mut stmt = conn
                .prepare(

                        r#"SELECT * FROM Users WHERE ? = '?'"#,
                    )

                .unwrap()
                ;
            debug!("{:?}", stmt);
            let mut res = stmt
                .query_map((discriminator_col,discriminator_1.as_str()), |row| {
                    Ok({
                        serde_json::to_string(&User {
                            id: row.get(0)?,
                            username: row.get(1)?,
                            password: row.get(2)?,
                            email: row.get(3)?,
                        })
                        .unwrap()
                    })
                })
                .unwrap();
            // println!("{:?}", res.nth(0));
            match res.next() {
                None => Ok(None),
                Some(r) => match r {
                    Ok(s) => {
                        let res: User = serde_json::from_str(&s).unwrap();
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

/// Fetches post from database
pub fn post(
    config: &LuminaConfig,
    id: u128,
) -> Result<Option<PostInfo>, Error> {
    match config.db_connect() {
        LuminaDBConnection::SQLite(conn) => {
            let mut stmt = conn
                .prepare(

                        r#"SELECT * FROM posts_pool WHERE `postid` = ?"#,

                    
                )
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
