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

/// Fetches user from database
pub fn user(
    config: &LuminaConfig,
    discriminator: (impl AsRef<str>, impl AsRef<str>),
) -> Result<Option<User>, Error> {
    match config.db_connect() {
        LuminaDBConnection::SQLite(conn) => {
            let mut stmt = conn
                .prepare(
                    format!(
                        r#"select * from Users where {0} = '{1}'"#,
                        discriminator.0.as_ref(),
                        discriminator.1.as_ref()
                    )
                    .trim(),
                )
                .unwrap();
            debug!("{:?}", stmt);
            let mut res = stmt
                .query_map((), |row| {
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
    discriminator: (impl AsRef<str>, impl AsRef<str>),
) -> Result<Option<PostInfo>, Error> {
    match config.db_connect() {
        LuminaDBConnection::SQLite(conn) => {
            

            let mut stmt = conn
                .prepare(
                    format!(
                        r#"select * from PostsStore where {0} = '{1}'"#,
                        discriminator.0.as_ref(),
                        discriminator.1.as_ref()
                    )
                    .trim(),
                )
                .unwrap();
            debug!("{:?}", stmt);
            let mut res = stmt
                .query_map((), |row| {
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
