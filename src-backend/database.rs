/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */
#![allow(dead_code)]

use std::any::type_name;
use std::io::Error;
use std::process;

use rusqlite::{params, Connection};
use serde::{Deserialize, Serialize};

use crate::post::PostInfo;
use crate::LuminaConfig;

/// Basic exchangable user information.
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct IIExchangedUserInfo {
    /// User ID
    pub(crate) id: i64,
    /// Known username
    pub(crate) username: String,
    /// Instance ID
    pub(crate) instance: String,
}

/// Basic user-identifying information.
#[derive(Debug, Serialize, Deserialize)]
pub struct BasicUserInfo {
    /// User ID
    pub(crate) id: i64,
    /// Known username
    pub(crate) username: String,
    /// Hashed password
    pub(crate) password: String,
    /// Given email
    pub(crate) email: String,
}
impl BasicUserInfo {
    pub fn to_exchangable(&self, config: &LuminaConfig) -> IIExchangedUserInfo {
        IIExchangedUserInfo {
            id: self.id,
            username: self.username.clone(),
            instance: config.interinstance.iid.clone(),
        }
    }
}

/// Create a database connection
pub(crate) fn create_con(config: &LuminaConfig) -> Connection {
    match Connection::open(
        config
            .clone()
            .run
            .cd
            .join(config.clone().database.sqlite.unwrap().file),
    ) {
        Ok(d) => d,
        Err(_e) => {
            error!("Could not create a database connection!");
            process::exit(1);
        }
    }
}

pub trait DatabaseItem {}
impl DatabaseItem for PostInfo {}
impl DatabaseItem for BasicUserInfo {}

pub enum UniversalFetchAnswer {
    Post(PostInfo),
    User(BasicUserInfo),
    None,
    Err(Error),
}
impl UniversalFetchAnswer {
    /// Unwraps a post from a fetch answer.
    /// # Panics
    /// Panics if the fetch answer is not a post.
    /// # Returns
    /// * `PostInfo` - The post metadata.
    pub fn unwrap_post(self) -> PostInfo {
        match self {
            UniversalFetchAnswer::Post(s) => s,
            UniversalFetchAnswer::None => {
                panic!("Attempted to unwrap a post from a None value!");
            }
            UniversalFetchAnswer::Err(_) => {
                panic!("Attempted to unwrap a post from an error!");
            }
            _ => {
                panic!("Attempted to unwrap a post from a different type of fetch!");
            }
        }
    }
    /// Unwraps a user from a fetch answer.
    /// # Panics
    /// Panics if the fetch answer is not a user.
    /// # Returns
    /// * `BasicUserInfo` - The user metadata.
    pub fn unwrap_user(self) -> BasicUserInfo {
        match self {
            UniversalFetchAnswer::User(s) => s,
            UniversalFetchAnswer::None => {
                panic!("Attempted to unwrap a user from a None value!");
            }
            UniversalFetchAnswer::Err(_) => {
                panic!("Attempted to unwrap a user from an error!");
            }
            _ => {
                panic!("Attempted to unwrap a user from a different type of fetch!");
            }
        }
    }
}

/// # `storage::unifetch<>()`
/// Fetches well-known data types from the database.
/// # Arguments
/// * `config` - A reference to the LuminaConfig struct.
/// * `discriminator` - A tuple containing the discriminator and the value to search for.
/// # Returns
/// * `UniversalFetchAnswer` - The fetched data. Wrapped in an enum that can be unwrapped to the specific type.
/// # Panics
/// Panics if the database type is not supported.
/// # Note
/// **Discouraged: Use the specific fetch functions instead.**
/// # Example
/// ```rust
/// let config = LuminaConfig::default();
/// let discriminator = ("username", "admin");
/// let user = storage::unifetch::<BasicUserInfo>(&config, discriminator).unwrap_user();
/// ```
pub fn unifetch<T: DatabaseItem>(
    config: &LuminaConfig,
    discriminator: (impl AsRef<str>, impl AsRef<str>),
) -> UniversalFetchAnswer {
    if type_name::<T>() == type_name::<PostInfo>() {
        let sres = fetch::post(config, discriminator);
        let res = match sres {
            Ok(s) => s,
            Err(e) => return UniversalFetchAnswer::Err(e),
        };
        match res {
            Some(s) => UniversalFetchAnswer::Post(s),
            None => UniversalFetchAnswer::None,
        }
    } else if type_name::<T>() == type_name::<BasicUserInfo>() {
        let sres = fetch::user(config, discriminator);
        let res = match sres {
            Ok(s) => s,
            Err(e) => return UniversalFetchAnswer::Err(e),
        };
        match res {
            Some(s) => UniversalFetchAnswer::User(s),
            None => UniversalFetchAnswer::None,
        }
    } else {
        error!("Unknown or unsupported database type! Only SQLITE is supported as of now.");
        process::exit(1);
    }
}
fn dbconf(conn: &Connection) {
    fn emergencyabort() {
        error!("Could not configure the database correctly!");
        process::exit(1);
    }

    match conn.execute(
        "
CREATE TABLE if not exists Users (
    id    INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE,
    username  TEXT NOT NULL,
    password  TEXT NOT NULL,
    email     TEXT NOT NULL
)
",
        (),
    ) {
        Ok(_) => {}
        Err(_e) => emergencyabort(),
    };
    match conn.execute(
        "
CREATE TABLE if not exists PostsStore (
    lpid            INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE,
    pid             INTEGER,
    instance        TEXT,
    author_id      INTEGER NOT NULL,
    timestamp      INTEGER NOT NULL,
    content_type    INTEGER NOT NULL,
    content        TEXT NOT NULL,
    tags            TEXT NOT NULL
)
",
        (),
    ) {
        Ok(_) => {}
        Err(_e) => emergencyabort(),
    }
}

pub fn fetch_posts_in_range(
    config: &LuminaConfig,
    start: i64,
    end: i64,
) -> Result<Vec<PostInfo>, Error> {
    if config.database.method.as_str() != "sqlite" {
        error!("Unknown or unsupported database type! Only SQLITE is supported as of now.");
        process::exit(1);
    }

    let conn = create_con(config);
    dbconf(&conn);

    let mut stmt = conn
        .prepare("SELECT * FROM PostsStore WHERE timestamp BETWEEN ?1 AND ?2")
        .unwrap();

    let post_rows = stmt
        .query_map(params![start, end], |row| Ok(row_to_post_info(row)))
        .unwrap();

    let mut posts = Vec::new();
    for post_row in post_rows {
        posts.push(post_row.unwrap());
    }

    Ok(posts)
}

fn row_to_post_info(row: &rusqlite::Row) -> PostInfo {
    PostInfo {
        lpid: row.get(0).unwrap(),
        pid: row.get(1).unwrap(),
        instance: row.get(2).unwrap(),
        author_id: row.get(3).unwrap(),
        timestamp: row.get(4).unwrap(),
        content_type: row.get(5).unwrap(),
        content: row.get(6).unwrap(),
        tags: row.get(7).unwrap(),
    }
}

pub(crate) mod fetch;
pub(crate) mod users;
