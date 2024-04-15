/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */
use serde::{Deserialize, Serialize};
use std::io::Write;
use std::{fs, path::Path, process};

use axum::{
    routing::{get, post},
    Extension, Json, Router,
};

mod assets;
mod instance_poller;
mod storage;
mod tell;

use tell::tellgen;

#[macro_use]
extern crate log;
extern crate simplelog;

use simplelog::*;

use colored::Colorize;

use crate::assets::{STR_ASSETS_INDEX_HTML, STR_CLEAN_CONFIG_TOML};
use axum::response::Html;
use axum::serve::Serve;
use std::fs::File;
use std::path::PathBuf;

#[derive(Clone)]
struct ServerP {
    config: Config,
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

#[tokio::main]
async fn main() {
    let config: Config = {
        let confp = Path::new("./config.toml");
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

            match write!(output, "{}", STR_CLEAN_CONFIG_TOML) {
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
        match fs::read_to_string(confp) {
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
    };
    tell(format!(
        "Logging to {}",
        logsets
            .logfile
            .canonicalize()
            .unwrap()
            .to_string_lossy()
            .replace("\\\\?\\", "")
    ));
    let app = Router::new()
        .route("/", get(root))
        .route("/api/", post(api))
        .route("/home", get(root))
        .layer(Extension(server_p));
    let listener = match tokio::net::TcpListener::bind(format!(
        "{0}:{1}",
        config.server.adress, config.server.port
    ))
    .await
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
    };
    let main_server = axum::serve(listener, app);
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

    let _ = futures::join!(
        instance_poller::main(config.interinstance.polling.pollintervall, tell),
        returnmainserver(main_server)
    );
}

// Remove me whenever stable async lambdas are possible..
async fn returnmainserver(server: Serve<Router, Router>) {
    server.await.unwrap()
}

async fn api(Json(payload): Json<String>) -> &'static str {
    let _ = payload;
    "Hi?"
}

async fn root(Extension(server_p): Extension<ServerP>) -> Html<String> {
    // Contains a simple replacer, not meant for templating. Implemented using Extension, which I am kinda experimenting with.
    Html::from(
        (STR_ASSETS_INDEX_HTML.replace(
            "{{iid}}",
            &server_p.clone().config.interinstance.iid.clone(),
        ))
        .clone(),
    )
}
