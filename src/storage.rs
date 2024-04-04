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

pub fn fetch(
    config: &Config,
    table: String,
    searchr: String,
    searchv: String,
) -> Result<Option<String>, Error> {
    match table.as_str() {
        "users" => {
            let mut userlist: Vec<TableUsers> = Vec::new();
            match config.database.method.as_str() {
                "sqlite" => {
                    let conn = match Connection::open(config.clone().database.sqlite.unwrap().file)
                    {
                        Ok(d) => d,
                        Err(_e) => {
                            error!("Could not create a database connection!");
                            std::process::exit(1);
                        }
                    };
                    match conn.execute(
                        "
CREATE TABLE if not exists Users (
    id    INTEGER PRIMARY KEY,
    username  TEXT NOT NULL,
    password  TEXT NOT NULL
)
",
                        (), // empty list of parameters.
                    ) {
                        Ok(_) => {}
                        Err(_e) => {
                            error!("Could not configure the database correctly!");
                            std::process::exit(1);
                        }
                    };
                    // todo: Give these their own match error handling; They're uncompatible with the std error handling, and are therefor just unwrapped now. This is not preffered.
                    let mut stmt = conn
                        .prepare("SELECT id, username, password FROM users")
                        .unwrap();
                    let user_iter = stmt
                        .query_map([], |row| {
                            Ok(TableUsers {
                                id: row.get(0)?,
                                username: row.get(1)?,
                                password: row.get(2)?,
                            })
                        })
                        .unwrap();
                    for user in user_iter {
                        userlist.push(user.unwrap());
                    }
                }
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
            for user in userlist {
                match searchr.as_str() {
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
