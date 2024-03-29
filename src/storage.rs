use std::{fs, path, process};
use std::fs::File;
use std::io::{Error, ErrorKind};
use std::path::Path;
use actix_web::web::patch;
use crate::Config;
use std::io::Write;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
struct TableUsers {
    id: i64,
    username: String,
    password: String,
}

pub fn fetch(config: &Config, table: String, searchr: String, searchv: String) -> Result<Option<String>, Error> {
    let it = match table.as_str() {
        "users" => match config.database.method.as_str() {
            "sqlite" => todo!(),
            "csv" => {
                if !path::Path::new("./data/users.csv").exists() {
                    File::create("./data/users.csv").and_then(|mut d| write!(d, "id, username, password\n"))?; }
                let mut rdr = csv::Reader::from_path("./data/users.csv")?;
                for x in rdr.records() {
                    let a= x.unwrap();
                    let d = TableUsers {
                        id: a.get(0).unwrap().parse().unwrap(),
                        username: a.get(1).unwrap().parse().unwrap(),
                        password: a.get(2).unwrap().parse().unwrap(),
                    };
                    return Ok(Some(serde_json::to_string(&d).unwrap()));
                }
            }
            _ => return Err((Error::new(ErrorKind::InvalidData, ("Unknown database method!"))))
        },
        _ => return Err((Error::new(ErrorKind::InvalidData, ("Unknown table!"))))
    };
    Ok(None)
}