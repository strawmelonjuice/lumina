/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */

use rusqlite::Connection;
use std::fs;
use std::fs::File;
use std::io::Write;
use std::io::{Error, ErrorKind};
use std::path::Path;

use serde::{Deserialize, Serialize};

use crate::Config;

#[derive(Debug, Serialize, Deserialize)]
struct TableUsers {
    id: i64,
    username: String,
    password: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct PostInfo {
    // Local Post ID
    lpid: i64,
    // Post ID
    pid: i64,
    // Instance ID - Might not be necessary on local posts. Hence being Option<>;
    instance: Option<String>,
    // Author ID
    author_id: i64,
    // Timestamp (UNIX)
    timestamp: i64,
    // Content type
    content_type: String,
    // Content in JSON, deserialised depending on content_type.
    content: String,
}

pub fn fetch(
    config: &Config,
    table: String,
    searchr: &str,
    searchv: String,
) -> Result<Option<String>, Error> {
    if config.database.method.as_str() == "sqlite" {
        let conn = match Connection::open(config.clone().database.sqlite.unwrap().file) {
            Ok(d) => d,
            Err(_e) => {
                error!("Could not create a database connection!");
                std::process::exit(1);
            }
        };
        dbconf(&conn);
        let mut stmt = conn
            .prepare(format!("SELECT * FROM `{table}` WHERE `{searchr}` IS `{searchv}`").as_str())
            .unwrap();
        let mut res = stmt.query_map([], |row| {
            Ok(match table.as_str() {
                "users" => {
                    serde_json::to_string(&TableUsers {
                        id: row.get(0)?,
                        username: row.get(1)?,
                        password: row.get(2)?,
                    }).unwrap()
                },
                "postinfo" => {
                    serde_json::to_string(&PostInfo {
                        pid: row.get(0)?,
                        instance: row.get(1)?,
                        author_id: row.get(2)?,
                        timestamp: row.get(3)?,
                        content_type: row.get(4)?,
                        content: row.get(5)?,
                        lpid: row.get(6)?,
                    }).unwrap()
                },
                _ => {
                    error!("Unknown table requisted!");
                    panic!("Unknown table requisted!");
                }
            })
        }).unwrap();
        return match res.next() {
            None => Ok(None),
            Some(r) => match r {
                Ok(s) => Ok(Some(s)),
                _ => Err(Error::new(ErrorKind::Other, "Unparseable data.")),
            }
        };
    }
    match table.as_str() {
        "users" => {
            let mut userlist: Vec<TableUsers> = Vec::new();
            match config.database.method.as_str() {
                "csv" => {
                    if !Path::new("./data").exists() {
                        fs::create_dir_all("./data")?;
                    }
                    if !Path::new("./data/users.csv").exists() {
                        File::create("./data/users.csv")
                            .and_then(|mut d| writeln!(d, "id,username,password"))?;
                    }
                    let mut rdr = csv::Reader::from_path("./data/users.csv")?;
                    for x in rdr.records() {
                        let a = x.unwrap();
                        let d = TableUsers {
                            id: a.get(0).unwrap().parse().unwrap(),
                            username: a.get(1).unwrap().parse().unwrap(),
                            password: a.get(2).unwrap().parse().unwrap(),
                        };
                        userlist.push(d);
                    }
                }
                _ => {
                    return Err(Error::new(
                        ErrorKind::InvalidData,
                        "Unknown database method!",
                    ))
                }
            };
            // This can be done better, by calling it in SQL. But I think I might be a little lazy. (plus CSV support!)
            // Update: SQLITE now returns early.
            for user in userlist {
                match searchr {
                    "username" => {
                        if user.username == searchv {
                            return Ok(Some(serde_json::to_string(&user)?));
                        }
                    }
                    "password" => {
                        if user.password == searchv {
                            return Ok(Some(serde_json::to_string(&user)?));
                        }
                    }
                    "id" => {
                        if user.id.to_string() == searchv {
                            return Ok(Some(serde_json::to_string(&user)?));
                        }
                    }
                    _ => return Err(Error::new(ErrorKind::InvalidData, "Unknown search method!")),
                }
            }
        }
        _ => return Err(Error::new(ErrorKind::InvalidData, "Unknown table!")),
    };
    Ok(None)
}
fn dbconf(conn: &Connection) {
    let emergencyabort = || {
        error!("Could not configure the database correctly!");
        std::process::exit(1);
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
        Ok(_) => {},
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
        Ok(_) => {},
        Err(_e) => emergencyabort(),
    }
}
