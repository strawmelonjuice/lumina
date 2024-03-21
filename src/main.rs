use std::io::Write;
use std::{fs, path::Path, process};

use actix_web::{get, post, web, App, HttpResponse, HttpServer, Responder};
use serde::{Deserialize, Serialize};

use log::error;

use crate::log::info;

mod instance_poller;
mod log;

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Config {
    pub server: Server,
    pub interinstance: InterInstance,
    pub database: Database,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Server {
    pub port: u16,
    pub adress: String,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct InterInstance {
    pub synclist: Vec<String>,
    pub ignorelist: Vec<String>,
    pub polling: Polling,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Polling {
    pub pollintervall: u64,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Database {
    pub method: String,
    pub sqlite: SQLite,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SQLite {
    pub file: String,
}



#[actix_web::main]
async fn main() {
    let config: Config = (|| {
        let confp = Path::new("./env.toml");
        if (!confp.is_file()) || (!confp.exists()) {
            let mut output = match fs::File::create(confp) {
                Ok(p) => p,
                Err(a) => {
                    error(format!(
                        "Could not create blank config file. The system returned: {}",
                        a
                    ));
                    process::exit(1);
                }
            };

            match write!(
                output,
                r#"[server]
# What port to bind to (the server is designed with apache2 reverse-proxy in mind, so 80 is not necesarily default.)
port = 8085
# What adress to bind to? Usually, this is 127.0.0.1 for dev, and 0.0.0.0 for prod.
adress = "0.0.0.0"

[interinstance]
# Specifies instances to send sync requests to. Note that these are only answered if both servers have each other listed. If not, the admin's will get a request to add them, but don't necessarily have to.
synclist = []
# Ignored instances are no longer allowed to send requests to join this instance's synclist.
ignorelist = [
"example.com"
]
[interinstance.polling]
# Specifies the interval between polls. Minimum is 30.
pollintervall = 120

[database]
# What kind of database to use, currently only supporting "sqlite". 
method = "sqlite"
[database.sqlite]
# The database file to use for sqlite.
file = "instance-db.sqlite"
"#
            ) {
                Ok(p) => p,
                Err(a) => {
                    error(format!(
                        "Could not create blank config file. The system returned: {}",
                        a
                    ));
                    process::exit(1);
                }
            };
        }
        return match fs::read_to_string(Path::new("./env.toml")) {
            Ok(g) => match toml::from_str(&g) {
                Ok(p) => p,
                Err(_e) => {
                    error(format!(
                        "Could not interpret server configuration at `{}`!",
                        confp
                            .canonicalize()
                            .unwrap_or(confp.to_path_buf())
                            .to_string_lossy()
                            .replace("\\\\?\\", "")
                    ));
                    process::exit(1);
                }
            },
            Err(_) => {
                error(format!(
                    "Could not interpret server configuration at `{}`!",
                    confp
                        .canonicalize()
                        .unwrap_or(confp.to_path_buf())
                        .to_string_lossy()
                        .replace("\\\\?\\", "")
                ));
                process::exit(1);
            }
        };
    })();
    let main_server = match HttpServer::new(|| {
        App::new()
            .service(api)
            .service(echo)
            .route("/", web::get().to(root))
    })
    .bind((config.server.adress.clone(), config.server.port))
    {
        Ok(o) => {
            info(format!(
                "Running on http://{0}:{1}/",
                config.server.adress, config.server.port
            ));
            o
        }
        Err(s) => {
            error(format!(
                "Could not bind to {}:{}, error message: {}",
                config.server.adress, config.server.port, s
            ));
            process::exit(1);
        }
    }
    .run();
    let _ = test(config.clone());
    let _ = futures::join!(
        instance_poller::main(config.interinstance.polling.pollintervall),
        main_server
    );
}

use rusqlite::{Connection, Result};

#[derive(Debug)]
struct Person {
    id: i32,
    name: String,
    data: Option<Vec<u8>>,
}

// Using the sqlite example to remind myself how to use it. (I normally go with mysql, can you imagine?)
fn test(config: Config) -> Result<()> {
    let conn = Connection::open(config.database.sqlite.file)?;

    conn.execute(
        "CREATE TABLE person (
            id    INTEGER PRIMARY KEY,
            name  TEXT NOT NULL,
            data  BLOB
        )",
        (), // empty list of parameters.
    )?;
    let me = Person {
        id: 0,
        name: "Steven".to_string(),
        data: None,
    };
    conn.execute(
        "INSERT INTO person (name, data) VALUES (?1, ?2)",
        (&me.name, &me.data),
    )?;

    let mut stmt = conn.prepare("SELECT id, name, data FROM person")?;
    let person_iter = stmt.query_map([], |row| {
        Ok(Person {
            id: row.get(0)?,
            name: row.get(1)?,
            data: row.get(2)?,
        })
    })?;

    for person in person_iter {
        println!("Found person {:?}", person.unwrap());
    }
    Ok(())
}
#[post("/api")]
async fn api(req_body: String) -> impl Responder {
    HttpResponse::Ok().body(req_body)
}

#[get("/echo")]
async fn echo(req_body: String) -> impl Responder {
    HttpResponse::Ok().body(req_body)
}

async fn root() -> impl Responder {
    HttpResponse::Ok().body("Hey there!")
}
