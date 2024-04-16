/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */
#[macro_use]
extern crate log;
extern crate simplelog;

use std::fmt::Debug;
use std::fs::File;
use std::io::Write;
use std::path::PathBuf;
use std::{fs, path::Path, process};

use actix_session::storage::CookieSessionStore;
use actix_session::{Session, SessionMiddleware};
use actix_web::cookie::Key;
use actix_web::http::StatusCode;
use actix_web::HttpResponse;
use actix_web::{web::{self, Data},
    App, HttpServer, Responder,
};
use colored::Colorize;
use serde::{Deserialize, Serialize};
use simplelog::*;
use tokio::sync::{Mutex, MutexGuard};

use tell::tellgen;

use crate::assets::{
    STR_ASSETS_INDEX_HTML, STR_ASSETS_MAIN_MIN_JS, STR_CLEAN_CONFIG_TOML,
    STR_GENERATED_MAIN_MIN_CSS,
};

const DEFAULT_JS_JSON: &str = r#"const ephewvar = {"config":{"interinstance":{"iid":"example.com"}}}; // Default config's JSON, to allow editor type chekcking."#;
const DEFAULT_JS_MIN_JSON: &str = r#"{config:{interinstance:{iid:"example.com"}}}"#;

mod assets;
mod instance_poller;
mod storage;
mod tell;

#[derive(Clone)]
struct ServerP {
    config: Config,
    tell: fn(String) -> (),
}
#[derive(Default, Debug, Clone, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
struct JSClientData {
    config: JSClientConfig,
}
#[derive(Default, Debug, Clone, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
struct JSClientConfig {
    interinstance: JSClientConfigInterInstance,
}
#[derive(Default, Debug, Clone, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
struct JSClientConfigInterInstance {
    iid: String,
}
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

#[derive(Default, Clone, PartialEq, Serialize, Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
pub struct Server {
    pub port: u16,
    pub adress: String,
    #[serde(alias = "cookiekey")]
    pub cookie_key: String,
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

#[tokio::main]
async fn main() {
    let config: Config = {
        let confp = Path::new("./config.toml");
        if (!confp.is_file()) || (!confp.exists()) {
            let mut output = match File::create(confp) {
                Ok(p) => p,
                Err(a) => {
                    eprintln!(
                        "Error: Could not create blank config file. The system returned: {}",
                        a
                    );
                    process::exit(1);
                }
            };

            match write!(output, "{}", STR_CLEAN_CONFIG_TOML) {
                Ok(p) => p,
                Err(a) => {
                    eprintln!(
                        "Error: Could not create blank config file. The system returned: {}",
                        a
                    );
                    process::exit(1);
                }
            };
        }
        match fs::read_to_string(confp) {
            Ok(g) => match toml::from_str(&g) {
                Ok(p) => p,
                Err(_e) => {
                    eprintln!(
                        "Error: Could not interpret server configuration at `{}`!",
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
                eprintln!(
                    "Error: Could not read server configuration at `{}`!",
                    confp
                        .canonicalize()
                        .unwrap_or(confp.to_path_buf())
                        .to_string_lossy()
                        .replace("\\\\?\\", "")
                );
                process::exit(1);
            }
        }
    };
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
    let server_p: ServerP = ServerP {
        config: config.clone(),
        tell: tell.clone(),
    };
    let server_q: Data<Mutex<ServerP>> = Data::new(Mutex::new(server_p));
    tell(format!(
        "Logging to {}",
        logsets
            .logfile
            .canonicalize()
            .unwrap()
            .to_string_lossy()
            .replace("\\\\?\\", "")
    ));
    // testing
    println!(
        "{}",
        storage::fetch(
            &config.clone(),
            "users".to_string(),
            "password",
            "password".to_string()
        )
        .unwrap()
        .unwrap_or("no such user".parse().unwrap())
    );
    let keydouble = config.server.cookie_key.repeat(2);
    let keybytes = keydouble.as_bytes();
    if keybytes.len() < 32 {
        error!(
            "Error: Cookie key must be at least 32 (doubled) bytes long. \"{}\" gives us {} bytes.",
            config.server.cookie_key,
            keybytes.len()
        );
        process::exit(1);
    }
    let secret_key: Key = Key::from(keybytes);
    let main_server = match HttpServer::new(move || {
        App::new()
            .wrap(SessionMiddleware::new(
                CookieSessionStore::default(),
                secret_key.clone(),
            ))
            .default_service(web::to(|| HttpResponse::Ok()))
            .route("/", web::get().to(root))
            .route("/home", web::get().to(timelines))
            .route("/site.js", web::get().to(site_js))
            .route("/site.css", web::get().to(site_css))
            .app_data(web::Data::clone(&server_q))
    })
    .bind((config.server.adress.clone(), config.server.port.clone()))
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
    let _ = futures::join!(instance_poller::main(config.clone(), tell), main_server);
}

async fn timelines(server_z: Data<Mutex<ServerP>>, _session: Session) -> impl Responder {
    let server_y = server_z.lock().await;
    let server_p: ServerP = server_y.clone();
    drop(server_y);
    let username_ = _session.get::<String>("username");
    (server_p.tell)(format!(
        "Request/200\t\t{} (@{})",
        "/home".green(),
        username_
            .unwrap_or(Option::from(String::from("unknown")))
            .unwrap_or(String::from("unknown"))
    ));
    let cont = "";
    HttpResponse::build(StatusCode::OK)
        .content_type("text/html; charset=utf-8")
        .body(cont)
}

async fn root(server_z: Data<Mutex<ServerP>>) -> HttpResponse {
    let server_y = server_z.lock().await;
    let server_p: ServerP = server_y.clone();
    drop(server_y);
    (server_p.tell)(format!("Request/200\t\t{}", "/".green()));
    // Contains a simple replacer, not meant for templating. Implemented using Extension, which I am kinda experimenting with.

    HttpResponse::build(StatusCode::OK)
        .content_type("text/html; charset=utf-8")
        .body(
            STR_ASSETS_INDEX_HTML
                .replace(
                    "{{iid}}",
                    &server_p.clone().config.interinstance.iid.clone(),
                )
                .clone(),
        )
}

async fn site_js(server_z: Data<Mutex<ServerP>>) -> HttpResponse {
    let server_y: MutexGuard<ServerP> = server_z.lock().await;
    let config: Config = server_y.clone().config;
    let jsonm = serde_json::to_string(&JSClientData {
        config: JSClientConfig {
            interinstance: JSClientConfigInterInstance {
                iid: config.interinstance.iid.clone().to_string(),
            },
        },
    })
    .unwrap();

    HttpResponse::build(StatusCode::OK)
        .content_type("text/javascript; charset=utf-8")
        .body(
            STR_ASSETS_MAIN_MIN_JS
                .replace(
                    DEFAULT_JS_JSON,
                    format!("const ephewvar = {};", jsonm.clone()).as_str(),
                )
                .replace(DEFAULT_JS_MIN_JSON, jsonm.clone().as_str()),
        )
}

async fn site_css() -> HttpResponse {
    HttpResponse::build(StatusCode::OK)
        .content_type("text/css; charset=utf-8")
        .body(STR_GENERATED_MAIN_MIN_CSS)
}
