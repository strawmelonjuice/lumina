/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */
#![allow(dead_code)]

// noinspection DuplicatedCode

use crate::config::LuminaDBConnectionInfo;
use crate::post::PostInfo;
use crate::{LuminaConfig, SynclistItem};
use colored::Colorize;
use rusqlite::{params, Connection};
use serde::{Deserialize, Serialize};
use std::any::type_name;
use std::io::Error;
use std::process;
use LuminaDBConnectionInfo::{LuminaDBConnectionInfoPOSTGRES, LuminaDBConnectionInfoSQLite};
use users::User;

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

impl LuminaConfig {
    /// Create a database connection to either SQLite or POSTGRES.
    pub(crate) fn db_connect(&self) -> LuminaDBConnection {
        match self.db_connection_info.clone() {
            LuminaDBConnectionInfoSQLite(file) => match Connection::open(file.clone()) {
                Ok(d) => LuminaDBConnection::SQLite(d),
                Err(_e) => {
                    error!(
                        "Could not create a database connection to <{}>",
                        file.display().to_string().yellow()
                    );
                    process::exit(1);
                }
            },
            LuminaDBConnectionInfoPOSTGRES(pg_config) => {
                let f = pg_config.connect(postgres::tls::NoTls).unwrap();
                LuminaDBConnection::POSTGRES(f)
            }
        }
    }
}

pub enum LuminaDBConnection {
    SQLite(Connection),
    POSTGRES(postgres::Client),
}

impl LuminaDBConnection {
    pub(crate) fn initial_dbconf(&mut self) {
        fn emergencyabort() {
            error!("Could not configure the database correctly!");
            process::exit(1);
        }
        let qs = [
            "CREATE TABLE IF NOT EXISTS external_posts(
                host_id INTEGER PRIMARY KEY,
                source_id INTEGER NOT NULL,
                source_instance TEXT NOT NULL
            );",
            "CREATE TABLE IF NOT EXISTS interinstance_relations(
                instance_id TEXT PRIMARY KEY,
                synclevel TEXT NOT NULL,
                last_contact INTEGER NOT NULL
            );",
            "CREATE TABLE IF NOT EXISTS local_posts(
                host_id INTEGER PRIMARY KEY,
                user_id INTEGER NOT NULL,
                privacy INTEGER NOT NULL
            );",
            "CREATE TABLE IF NOT EXISTS posts_pool(
                postid INTEGER PRIMARY KEY,
                kind TEXT NOT NULL,
                content TEXT NOT NULL,
                from_local INTEGER NOT NULL
            );",
            "CREATE TABLE IF NOT EXISTS users(
                id INTEGER PRIMARY KEY,
                username TEXT NOT NULL,
                password TEXT NOT NULL,
                email TEXT NOT NULL
            );",
        ];

        for query in qs {
            match self.execute0(query) {
                Ok(_) => {}
                Err(_e) => emergencyabort(),
            }
        }
    }
    pub(crate) fn execute0(&mut self, query: &str) -> Result<(), ()> {
        match self {
            LuminaDBConnection::SQLite(conn) => {
                conn.execute(query, ()).map(|_r| ()).map_err(|_e| ())
            }
            LuminaDBConnection::POSTGRES(client) => {
                client.execute(query, &[]).map(|_r| ()).map_err(|_e| ())
            }
        }
    }
    pub(crate) fn execute1(&mut self, query: &str, param: impl AsRef<str>) -> Result<(), ()> {
        match self {
            LuminaDBConnection::SQLite(conn) => conn
                .execute(query, &[&param.as_ref()])
                .map(|_r| ())
                .map_err(|_e| ()),
            LuminaDBConnection::POSTGRES(client) => client
                .execute(query, &[&param.as_ref()])
                .map(|_r| ())
                .map_err(|_e| ()),
        }
    }
    pub(crate) fn execute2(
        &mut self,
        query: &str,
        params: (impl AsRef<str>, impl AsRef<str>),
    ) -> Result<(), ()> {
        match self {
            LuminaDBConnection::SQLite(conn) => conn
                .execute(query, &[&params.0.as_ref(), &params.1.as_ref()])
                .map(|_r| ())
                .map_err(|_e| ()),
            LuminaDBConnection::POSTGRES(client) => client
                .execute(query, &[&params.0.as_ref(), &params.1.as_ref()])
                .map(|_r| ())
                .map_err(|_e| ()),
        }
    }
    pub(crate) fn execute3(
        &mut self,
        query: &str,
        params: (impl AsRef<str>, impl AsRef<str>, impl AsRef<str>),
    ) -> Result<(), ()> {
        match self {
            LuminaDBConnection::SQLite(conn) => conn
                .execute(
                    query,
                    &[
                        &(params.0.as_ref()),
                        &(params.1.as_ref()),
                        &(params.2.as_ref()),
                    ],
                )
                .map(|_r| ())
                .map_err(|_e| ()),
            LuminaDBConnection::POSTGRES(client) => client
                .execute(
                    query,
                    &[
                        &(params.0.as_ref()),
                        &(params.1.as_ref()),
                        &(params.2.as_ref()),
                    ],
                )
                .map(|_r| ())
                .map_err(|_e| ()),
        }
    }
    pub(crate) fn execute4(
        &mut self,
        query: &str,
        params: (
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
        ),
    ) -> Result<(), ()> {
        match self {
            LuminaDBConnection::SQLite(conn) => conn
                .execute(
                    query,
                    &[
                        &(params.0.as_ref()),
                        &(params.1.as_ref()),
                        &(params.2.as_ref()),
                        &(params.3.as_ref()),
                    ],
                )
                .map(|_r| ())
                .map_err(|_e| ()),
            LuminaDBConnection::POSTGRES(client) => client
                .execute(
                    query,
                    &[
                        &(params.0.as_ref()),
                        &(params.1.as_ref()),
                        &(params.2.as_ref()),
                        &(params.3.as_ref()),
                    ],
                )
                .map(|_r| ())
                .map_err(|_e| ()),
        }
    }
    pub(crate) fn execute5(
        &mut self,
        query: &str,
        params: (
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
        ),
    ) -> Result<(), ()> {
        match self {
            LuminaDBConnection::SQLite(conn) => conn
                .execute(
                    query,
                    &[
                        &(params.0.as_ref()),
                        &(params.1.as_ref()),
                        &(params.2.as_ref()),
                        &(params.3.as_ref()),
                        &(params.4.as_ref()),
                    ],
                )
                .map(|_r| ())
                .map_err(|_e| ()),
            LuminaDBConnection::POSTGRES(client) => client
                .execute(
                    query,
                    &[
                        &(params.0.as_ref()),
                        &(params.1.as_ref()),
                        &(params.2.as_ref()),
                        &(params.3.as_ref()),
                        &(params.4.as_ref()),
                    ],
                )
                .map(|_r| ())
                .map_err(|_e| ()),
        }
    }
    pub fn execute6(
        &mut self,
        query: &str,
        params: (
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
        ),
    ) -> Result<(), ()> {
        match self {
            LuminaDBConnection::SQLite(conn) => conn
                .execute(
                    query,
                    &[
                        &(params.0.as_ref()),
                        &(params.1.as_ref()),
                        &(params.2.as_ref()),
                        &(params.3.as_ref()),
                        &(params.4.as_ref()),
                        &(params.5.as_ref()),
                    ],
                )
                .map(|_r| ())
                .map_err(|_e| ()),
            LuminaDBConnection::POSTGRES(client) => client
                .execute(
                    query,
                    &[
                        &(params.0.as_ref()),
                        &(params.1.as_ref()),
                        &(params.2.as_ref()),
                        &(params.3.as_ref()),
                        &(params.4.as_ref()),
                        &(params.5.as_ref()),
                    ],
                )
                .map(|_r| ())
                .map_err(|_e| ()),
        }
    }

    pub fn execute7(
        &mut self,
        query: &str,
        params: (
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
        ),
    ) -> Result<(), ()> {
        match self {
            LuminaDBConnection::SQLite(conn) => conn
                .execute(
                    query,
                    &[
                        &(params.0.as_ref()),
                        &(params.1.as_ref()),
                        &(params.2.as_ref()),
                        &(params.3.as_ref()),
                        &(params.4.as_ref()),
                        &(params.5.as_ref()),
                        &(params.6.as_ref()),
                    ],
                )
                .map(|_r| ())
                .map_err(|_e| ()),
            LuminaDBConnection::POSTGRES(client) => client
                .execute(
                    query,
                    &[
                        &(params.0.as_ref()),
                        &(params.1.as_ref()),
                        &(params.2.as_ref()),
                        &(params.3.as_ref()),
                        &(params.4.as_ref()),
                        &(params.5.as_ref()),
                        &(params.6.as_ref()),
                    ],
                )
                .map(|_r| ())
                .map_err(|_e| ()),
        }
    }
    //noinspection DuplicatedCode
    //noinspection DuplicatedCode
    pub fn execute8(
        &mut self,
        query: &str,
        params: (
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
        ),
    ) -> Result<(), ()> {
        match self {
            LuminaDBConnection::SQLite(conn) => conn
                .execute(
                    query,
                    &[
                        &(params.0.as_ref()),
                        &(params.1.as_ref()),
                        &(params.2.as_ref()),
                        &(params.3.as_ref()),
                        &(params.4.as_ref()),
                        &(params.5.as_ref()),
                        &(params.6.as_ref()),
                        &(params.7.as_ref()),
                    ],
                )
                .map(|_r| ())
                .map_err(|_e| ()),
            LuminaDBConnection::POSTGRES(client) => client
                .execute(
                    query,
                    &[
                        &(params.0.as_ref()),
                        &(params.1.as_ref()),
                        &(params.2.as_ref()),
                        &(params.3.as_ref()),
                        &(params.4.as_ref()),
                        &(params.5.as_ref()),
                        &(params.6.as_ref()),
                        &(params.7.as_ref()),
                    ],
                )
                .map(|_r| ())
                .map_err(|_e| ()),
        }
    }
    //noinspection ALL
    pub fn execute9(
        &mut self,
        query: &str,
        params: (
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
        ),
    ) -> Result<(), ()> {
        match self {
            LuminaDBConnection::SQLite(conn) => conn
                .execute(
                    query,
                    &[
                        &(params.0.as_ref()),
                        &(params.1.as_ref()),
                        &(params.2.as_ref()),
                        &(params.3.as_ref()),
                        &(params.4.as_ref()),
                        &(params.5.as_ref()),
                        &(params.6.as_ref()),
                        &(params.7.as_ref()),
                        &(params.8.as_ref()),
                    ],
                )
                .map(|_r| ())
                .map_err(|_e| ()),
            LuminaDBConnection::POSTGRES(client) => client
                .execute(
                    query,
                    &[
                        &(params.0.as_ref()),
                        &(params.1.as_ref()),
                        &(params.2.as_ref()),
                        &(params.3.as_ref()),
                        &(params.4.as_ref()),
                        &(params.5.as_ref()),
                        &(params.6.as_ref()),
                        &(params.7.as_ref()),
                        &(params.8.as_ref()),
                    ],
                )
                .map(|_r| ())
                .map_err(|_e| ()),
        }
    }
    //noinspection DuplicatedCode
    //noinspection DuplicatedCode
    pub fn execute10(
        &mut self,
        query: &str,
        params: (
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
            impl AsRef<str>,
        ),
    ) -> Result<(), ()> {
        match self {
            LuminaDBConnection::SQLite(conn) => conn
                .execute(
                    query,
                    &[
                        &(params.0.as_ref()),
                        &(params.1.as_ref()),
                        &(params.2.as_ref()),
                        &(params.3.as_ref()),
                        &(params.4.as_ref()),
                        &(params.5.as_ref()),
                        &(params.6.as_ref()),
                        &(params.7.as_ref()),
                        &(params.8.as_ref()),
                        &(params.9.as_ref()),
                    ],
                )
                .map(|_r| ())
                .map_err(|_e| ()),
            LuminaDBConnection::POSTGRES(client) => client
                .execute(
                    query,
                    &[
                        &(params.0.as_ref()),
                        &(params.1.as_ref()),
                        &(params.2.as_ref()),
                        &(params.3.as_ref()),
                        &(params.4.as_ref()),
                        &(params.5.as_ref()),
                        &(params.6.as_ref()),
                        &(params.7.as_ref()),
                        &(params.8.as_ref()),
                        &(params.9.as_ref()),
                    ],
                )
                .map(|_r| ())
                .map_err(|_e| ()),
        }
    }
}

pub trait DatabaseItem {}
impl DatabaseItem for PostInfo {}

pub enum UniversalFetchAnswer {
    Post(PostInfo),
    User(User),
    None,
    Err(Error),
}
impl UniversalFetchAnswer {
    /// Unwraps a post from a fetch answer.
    /// # Panics
    /// Will panic if the fetch answer is not a post.
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
    /// Unwraps a user from an unifetch answer.
    /// # Panics
    /// Will panic when the fetch answer is not a user.
    /// # Returns
    /// * `BasicUserInfo` - The user metadata.
    pub fn unwrap_user(self) -> User {
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
/// Prefer using the specific fetch functions instead.
/// # Arguments
/// * `config` - A reference to the LuminaConfig struct.
/// * `discriminator` - A tuple containing the discriminator and the value to search for.
/// # Returns
/// * `UniversalFetchAnswer` - The fetched data. Wrapped in an enum that can be unwrapped to the specific type.
/// # Panics
/// Will panic if the database type is not supported.
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
        let f= format!("{}", discriminator.1.as_ref());
        let sres = fetch::post(config, f.parse().unwrap());
        let res = match sres {
            Ok(s) => s,
            Err(e) => return UniversalFetchAnswer::Err(e),
        };
        match res {
            Some(s) => UniversalFetchAnswer::Post(s),
            None => UniversalFetchAnswer::None,
        }
    } else if type_name::<T>() == type_name::<User>() {
        let sres = fetch::user(config, fetch::UserDataDiscriminator::from_str(discriminator));
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

pub fn fetch_posts_in_range(
    config: &LuminaConfig,
    start: i64,
    end: i64,
) -> Result<Vec<PostInfo>, Error> {
    match config.db_connect() {
        LuminaDBConnection::SQLite(conn) => {
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
        LuminaDBConnection::POSTGRES(_) => {
            todo!("Postgres not implemented yet.");
        }
    }
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

pub fn get_instance_sync_list(config: &LuminaConfig) -> Result<Vec<SynclistItem>, Error> {
    match config.db_connect() {
        LuminaDBConnection::SQLite(conn) => {
            let mut stmt = conn
                .prepare("SELECT * FROM interinstance_relations")
                .unwrap();

            let sync_list_rows = stmt
                .query_map((), |row| {
                    Ok(SynclistItem {
                        name: row.get(0).unwrap(),
                        level: row.get(1).unwrap(),
                        last_contact: row.get(2).unwrap(),
                    })
                })
                .unwrap();

            let mut sync_list = Vec::new();
            for sync_list_row in sync_list_rows {
                sync_list.push(sync_list_row.unwrap());
            }

            Ok(sync_list)
        }
        LuminaDBConnection::POSTGRES(mut client) => {
            let rows = client
                .query("SELECT * FROM interinstance_relations", &[])
                .unwrap();

            let mut sync_list = Vec::new();
            for row in rows {
                sync_list.push(SynclistItem {
                    name:  row.get(0),
                    level: row.get(1),
                    last_contact: row.get(2),
                });
            }
            Ok(sync_list)
        }
    }
}