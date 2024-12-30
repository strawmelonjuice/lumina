/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */

use crate::database::BasicUserInfo;
use crate::post::PostInfo;
use crate::{database, LuminaConfig};
use std::io::{Error, ErrorKind};
use std::process;

/// Fetches user from database
pub fn user(
    config: &LuminaConfig,
    discriminator: (impl AsRef<str>, impl AsRef<str>),
) -> Result<Option<BasicUserInfo>, Error> {
    if config.database.method.as_str() == "sqlite" {
        let conn = database::create_con(config);
        database::dbconf(&conn);

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
                    serde_json::to_string(&BasicUserInfo {
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
                    let res: BasicUserInfo = serde_json::from_str(&s).unwrap();
                    Ok(Some(res))
                }
                Err(f) => {
                    eprintln!("{:?}", f);
                    Err(Error::new(ErrorKind::Other, "Unparseable data."))
                }
            },
        }
    } else {
        error!("Unknown or unsupported database type! Only SQLITE is supported as of now.");
        process::exit(1);
    }
}

/// Fetches post from database
pub fn post(
    config: &LuminaConfig,
    discriminator: (impl AsRef<str>, impl AsRef<str>),
) -> Result<Option<PostInfo>, Error> {
    if config.database.method.as_str() == "sqlite" {
        let conn = database::create_con(config);
        database::dbconf(&conn);

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
                    let res: PostInfo = serde_json::from_str(&s).unwrap();
                    Ok(Some(res))
                }
                Err(f) => {
                    eprintln!("{:?}", f);
                    Err(Error::new(ErrorKind::Other, "Unparseable data."))
                }
            },
        }
    } else {
        error!("Unknown or unsupported database type! Only SQLITE is supported as of now.");
        process::exit(1);
    }
}
