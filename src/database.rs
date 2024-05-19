/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */

use std::io::{Error, ErrorKind};
use std::process;

use rusqlite::Connection;
use serde::{Deserialize, Serialize};

use crate::LuminaConfig;

/// Basic exchangable user information.
#[derive(Debug, Serialize, Deserialize)]
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

#[derive(Debug, Serialize, Deserialize)]
pub struct PostInfo {
    /// Local Post ID
    pub lpid: i64,
    /// Post ID
    pub pid: i64,
    /// Instance ID - Might not be necessary on local posts. Hence being Option<>;
    pub instance: Option<String>,
    /// Author ID
    pub author_id: i64,
    /// Timestamp (UNIX)
    pub timestamp: i64,
    /// Content type
    // 1: Textual post (json<content: text/plain>)
    // 2: Article textual post (json<header: text/plain, body: text/markdown>)
    // 3: Media post (json<caption: text/markdown, media-id: integer[]>)
    // 4: Repost (json<repost-id: integer, source-instance: text>)
    pub content_type: i32,
    /// Content in JSON, deserialised depending on content_type.
    pub content: String,
    /// Tags
    tags: String, // Json<Vec<String>>
}
use handlebars::*;

use crate::assets::STR_ASSETS_POST_RENDERS_HANDLEBARS;

#[derive(Debug, Serialize, Deserialize)]
pub struct PostPreRenderData {
    pub(crate) posttype: i32,
    pub(crate) author: IIExchangedUserInfo,
    pub(crate) content: String,
    pub(crate) timestamp: i64,
    pub(crate) title: Option<String>,
    pub(crate) embeds: Option<Vec<String>>,
    pub(crate) tags: Vec<String>,
    pub(crate) local: bool,
}

impl PostPreRenderData {
    pub fn to_html(&self) -> String {
        let mut handlebars = Handlebars::new();
        handlebars_helper!(num_is_equal: |x: u64, y: u64| x == y);
        handlebars.register_helper("numequal", Box::new(num_is_equal));

        match handlebars.render_template(STR_ASSETS_POST_RENDERS_HANDLEBARS, self) {
            Ok(html) => html,
            Err(e) => {
                eprintln!("Error rendering post: {}", e);
                String::from("Error rendering post.")
            }
        }
    }
}

impl PostInfo {
    pub fn to_formatted(&self, config: &LuminaConfig) -> PostPreRenderData {
        let author_u: BasicUserInfo = serde_json::from_str::<BasicUserInfo>(
            &fetch(
                &config,
                String::from("Users"),
                "id",
                self.author_id.to_string(),
            )
            .unwrap()
            .unwrap(),
        )
        .unwrap();

        let author = IIExchangedUserInfo {
            id: self.author_id,
            username: author_u.username,
            instance: self
                .instance
                .clone()
                .unwrap_or(config.interinstance.iid.clone()),
        };
        let content;

        let mut embeds = None;

        let mut title = None;

        match self.content_type {
            1 => {
                #[derive(Serialize, Deserialize)]
                struct TextPost {
                    content: String,
                }

                content = serde_json::from_str::<TextPost>(&self.content)
                    .unwrap()
                    .content;
            }
            2 => {
                #[derive(Serialize, Deserialize)]
                struct ArticlePost {
                    header: String,
                    body: String,
                }

                let article = serde_json::from_str::<ArticlePost>(&self.content).unwrap();
                content = markdown::to_html(&article.body);
                title = Some(article.header);
            }
            3 => {
                #[derive(Serialize, Deserialize)]
                struct MediaPost {
                    caption: String,
                    media_id: Vec<i64>,
                }

                let media = serde_json::from_str::<MediaPost>(&self.content).unwrap();
                content = markdown::to_html(&media.caption);
                embeds = Some(media.media_id.iter().map(|x| x.to_string()).collect());
            }
            4 => {
                #[derive(Serialize, Deserialize)]
                struct Repost {
                    repost_id: i64,
                    source_instance: String,
                }

                let repost = serde_json::from_str::<Repost>(&self.content).unwrap();
                content = format!(
                    "<a href=\"{}/post/{}\">Reposted from {}</a>",
                    repost.source_instance, repost.repost_id, repost.source_instance
                );
            }
            _ => {
                error!("Unknown content type!");
                panic!("Unknown content type!");
            }
        };

        let timestamp = self.timestamp;

        let tags = serde_json::from_str::<Vec<String>>(&self.tags).unwrap();

        let local = self.instance.is_none();

        PostPreRenderData {
            posttype: self.content_type,
            author,
            content,
            timestamp,
            title,
            embeds,
            tags,
            local,
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
/// # `storage::fetch()`
/// Fetches well-known data from the database.
pub fn fetch(
    config: &LuminaConfig,
    table: String,
    searchr: &str,
    searchv: String,
) -> Result<Option<String>, Error> {
    if config.database.method.as_str() == "sqlite" {
        match table.as_str() {
            "Users" | "PostsStore" => {}
            _ => {
                error!("Unknown table requisted!");
                panic!("Unknown table requisted!");
            }
        };
        let conn = create_con(config);
        dbconf(&conn);

        let mut stmt = conn
            .prepare(format!(r#"select * from {table} where {searchr} = '{searchv}'"#).trim())
            .unwrap();
        debug!("{:?}", stmt);
        let mut res = stmt
            .query_map((), |row| {
                Ok(match table.as_str() {
                    "Users" => serde_json::to_string(&BasicUserInfo {
                        id: row.get(0)?,
                        username: row.get(1)?,
                        password: row.get(2)?,
                        email: row.get(3)?,
                    })
                    .unwrap(),
                    "PostsStore" => {
                        let s = PostInfo {
                            lpid: row.get(0)?,
                            pid: row.get(1)?,
                            instance: row.get(2)?,
                            author_id: row.get(3)?,
                            timestamp: row.get(4)?,
                            content_type: row.get(5)?,
                            content: row.get(6)?,
                            tags: row.get(7)?,
                        };
                        serde_json::to_string(&s).unwrap()
                    }
                    _ => {
                        error!("Unknown table requisted!");
                        panic!("Unknown table requisted!");
                    }
                })
            })
            .unwrap();
        // println!("{:?}", res.nth(0));
        match res.next() {
            None => Ok(None),
            Some(r) => match r {
                Ok(s) => Ok(Some(s)),
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

pub(crate) mod users;
