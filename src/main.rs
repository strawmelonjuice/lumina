/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licenced under the BSD 3-Clause License. See the LICENCE file for more info.
 */

use serde::{Deserialize, Serialize};
use std::io::Write;
use std::{fs, path::Path, process};

use actix_web::{get, post, web, App, HttpResponse, HttpServer, Responder};

mod instance_poller;
mod storage;
mod tell;
use tell::tellgen;

#[macro_use]
extern crate log;
extern crate simplelog;

use simplelog::*;

use colored::Colorize;

use std::fs::File;
use std::path::PathBuf;

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Config {
    pub server: Server,
    pub interinstance: InterInstance,
    pub database: Database,
    pub logging: Option<Logging>,
}
#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Logging {
    #[serde(alias = "file-loglevel")]
    #[serde(alias = "file-log-level")]
    pub file_loglevel: Option<u8>,
    #[serde(alias = "term-loglevel")]
    #[serde(alias = "term-log-level")]
    #[serde(alias = "console-loglevel")]
    #[serde(alias = "console-log-level")]
    pub term_loglevel: Option<u8>,

    #[serde(alias = "file")]
    #[serde(alias = "filename")]
    pub logfile: Option<String>,
}
pub struct LogSets {
    pub file_loglevel: LevelFilter,
    pub term_loglevel: LevelFilter,
    pub logfile: PathBuf,
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
    pub iid: String,
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
    pub sqlite: Option<SQLite>,
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
            let mut output = match File::create(confp) {
                Ok(p) => p,
                Err(a) => {
                    error!(
                        "Could not create blank config file. The system returned: {}",
                        a
                    );
                    process::exit(1);
                }
            };

            match write!(
                output,
                r#"[server]
# What port to bind to (the server is designed with apache2 reverse-proxy in mind, so 80 is not necessarily default.)
port = 8085
# What adress to bind to? Usually, this is 127.0.0.1 for dev, and 0.0.0.0 for prod.
adress = "0.0.0.0"

[interinstance]
# Instance ID, equals, the domain name this instance is open on.
iid = "example.com"
# Specifies instances to send sync requests to. Note that these are only answered if both servers have each other listed. If not, the admin's will get a request to add them, but don't necessarily have to.
synclist = [
    #    Of course, by default, the home domain is included, however! You can just remove it if you want to!
    "peonies.xyz"
]
# Ignored instances are no longer allowed to send requests to join this instance's synclist.
ignorelist = [
    "example.com"
]
[interinstance.polling]
# Specifies the interval between polls. Minimum is 30.
pollintervall = 120

[database]
# What kind of database to use, currently only supporting "sqlite" (recommended), and "csv" (advised against).
method = "sqlite"
[database.sqlite]
# The database file to use for sqlite.
file = "instance-db.sqlite"

[logging]
file-loglevel = 3
console-loglevel = 2
file = "instance-logging.log"
"#
            ) {
                Ok(p) => p,
                Err(a) => {
                    error!(
                        "Could not create blank config file. The system returned: {}",
                        a
                    );
                    process::exit(1);
                }
            };
        }
        return match fs::read_to_string(Path::new("./env.toml")) {
            Ok(g) => match toml::from_str(&g) {
                Ok(p) => p,
                Err(_e) => {
                    error!(
                        "Could not interpret server configuration at `{}`!",
                        confp
                            .canonicalize()
                            .unwrap_or(confp.to_path_buf())
                            .to_string_lossy()
                            .replace("\\\\?\\", "")
                    );
                    process::exit(1);
                }
            },
            Err(_) => {
                error!(
                    "Could not interpret server configuration at `{}`!",
                    confp
                        .canonicalize()
                        .unwrap_or(confp.to_path_buf())
                        .to_string_lossy()
                        .replace("\\\\?\\", "")
                );
                process::exit(1);
            }
        };
    })();
    let logsets: LogSets = (|config: &Config| {
        // How DRY of me.
        fn asddg(o: u8) -> LevelFilter {
            match o {
                0 => LevelFilter::Off,
                1 => LevelFilter::Error,
                2 => LevelFilter::Warn,
                3 => LevelFilter::Info,
                4 => LevelFilter::Debug,
                5 => LevelFilter::Trace,
                _ => {
                    eprintln!(
                        "{} Could not set loglevel `{}`! Ranges are 0-5 (quiet to verbose)",
                        "error:".red(),
                        o
                    );
                    process::exit(1);
                }
            }
        }
        return match config.clone().logging {
            None => {
                return LogSets {
                    file_loglevel: LevelFilter::Info,
                    term_loglevel: LevelFilter::Warn,
                    logfile: PathBuf::from("./instance.log"),
                };
            }
            Some(d) => LogSets {
                file_loglevel: match d.file_loglevel {
                    Some(l) => asddg(l),
                    None => LevelFilter::Info,
                },
                term_loglevel: match d.term_loglevel {
                    Some(l) => asddg(l),
                    None => LevelFilter::Warn,
                },
                logfile: match d.logfile {
                    Some(s) => PathBuf::from(s.as_str()),
                    None => PathBuf::from("./instance.log"),
                },
            },
        };
    })(&config);
    CombinedLogger::init(vec![
        TermLogger::new(
            logsets.term_loglevel,
            simplelog::Config::default(),
            TerminalMode::Mixed,
            ColorChoice::Auto,
        ),
        WriteLogger::new(
            logsets.file_loglevel,
            simplelog::Config::default(),
            File::create(&logsets.logfile).unwrap(),
        ),
    ])
    .unwrap();
    let tell = tellgen(config.clone().logging);
    tell(format!(
        "Logging to {}",
        logsets
            .logfile
            .canonicalize()
            .unwrap()
            .to_string_lossy()
            .replace("\\\\?\\", "")
    ));
    let main_server = match HttpServer::new(|| {
        App::new()
            .service(api)
            .service(echo)
            .route("/", web::get().to(root))
    })
    .bind((config.server.adress.clone(), config.server.port))
    {
        Ok(o) => {
            tell(format!(
                "Running on http://{0}:{1}/",
                config.server.adress, config.server.port
            ));
            o
        }
        Err(s) => {
            error!(
                "Could not bind to {}:{}, error message: {}",
                config.server.adress, config.server.port, s
            );
            process::exit(1);
        }
    }
    .run();
    // testing
    println!(
        "{}",
        storage::fetch(
            &config.clone(),
            "users".to_string(),
            "password".to_string(),
            "password".to_string()
        )
        .unwrap()
        .unwrap_or("no such user".parse().unwrap())
    );
    let _ = futures::join!(
        instance_poller::main(config.interinstance.polling.pollintervall),
        main_server
    );
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
