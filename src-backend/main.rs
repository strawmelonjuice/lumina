/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */
const CURRENT_CONFIG_VERSION: &str = "0.3-a";
#[macro_use]
extern crate build_const;
#[macro_use]
extern crate log;
extern crate simplelog;
// use console::Term;

use std::fmt::Debug;
use std::fs::File;
use std::io::Write;
use std::path::PathBuf;
use std::{env, fs, path::Path, process};

use actix_session::storage::CookieSessionStore;
use actix_session::{Session, SessionMiddleware};
use actix_web::cookie::Key;
use actix_web::{get, HttpRequest, HttpResponse};
use actix_web::{
    web::{self, Data},
    App, HttpServer,
};
use colored::Colorize;
use rand::prelude::*;
use serde::{Deserialize, Serialize};
use simplelog::*;
use tokio::sync::{Mutex, MutexGuard};

use crate::serve::notfound;
use assets::{
    fonts, vec_string_assets_anons_svg, STR_CLEAN_CONFIG_TOML, STR_CLEAN_CUSTOMSTYLES_CSS,
};

/// ## API's to the front-end.
mod api_fe;
/// # Inter-instance API's
mod api_ii;
/// ## Definition of assets, so file paths refactoring goes easier.
pub mod assets;
/// # Actions on the database
mod database;
/// # Actions on posts
mod post;
/// # Actions for gentle logging ("telling")
/// Logging doesn't need this, but for prettyness these are added as implementations on ServerVars.
mod tell;

#[derive(Clone)]
struct ServerVars {
    config: LuminaConfig,
    // console: Term,
}
impl ServerVars {
    /// This function grabs the server variables from the provided mutex.
    ///
    /// # Arguments
    ///
    /// * `server_vars_mutex` - A reference to a `Data<Mutex<ServerVars>>` containing the server variables.
    ///
    /// # Returns
    ///
    /// * `ServerVars` - A clone of the server variables stored in the mutex. These are cloned so that the mutex can be unlocked without having to wait for the calling function to finish.
    ///
    /// # Errors
    ///
    /// This function does not return any errors.
    ///
    /// # Panics
    ///
    /// This function does not panic.
    ///
    /// # Examples
    ///
    /// ```
    /// // This is the shield function from 'api_fe', it implements grab in the simplest way.
    /// async fn shield(
    ///     session: Session,
    ///     server_vars_mutex: &Data<Mutex<ServerVars>>,
    ///     halt: HttpResponse,
    /// ) -> Option<HttpResponse> {
    ///     let server_vars = ServerVars::grab(server_vars_mutex).await;
    ///     let config = server_vars.clone().config;
    /// ...
    /// ```
    pub(crate) async fn grab(server_vars_mutex: &Data<Mutex<ServerVars>>) -> ServerVars {
        let vars: MutexGuard<ServerVars> = server_vars_mutex.lock().await;
        vars.clone()
    }
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
struct PrePreConfig {
    version: Option<String>,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PreConfig {
    pub version: String,
    pub server: Server,
    pub interinstance: InterInstance,
    pub database: Database,
    pub logging: Option<Logging>,
}
#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct LuminaConfig {
    pub version: String,
    pub server: Server,
    pub interinstance: InterInstance,
    pub database: Database,
    pub logging: Option<Logging>,
    pub run: ERun,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ERun {
    pub cd: PathBuf,
    pub customcss: String,
    pub session_valid: i64,
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

fn default_as_true() -> bool {
    true
}

#[derive(Default, Clone, PartialEq, Serialize, Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
pub struct Server {
    pub port: u16,
    pub adress: String,
    #[serde(alias = "cookiekey")]
    pub cookie_key: String,
    #[serde(default = "default_as_true")]
    pub secure: bool,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct InterInstance {
    pub iid: String,
    pub synclist: Vec<SynclistItem>,
    pub ignorelist: Vec<String>,
    pub syncing: Syncing,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct SynclistItem {
    pub name: String, // The name of the instance to sync with, equal to the domain name it is public on.
    pub level: String, // The level of syncing to do. "full" is the only one being implemented right now.
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Syncing {
    pub syncintervall: u64,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Database {
    pub method: String,
    pub sqlite: Option<SQLite>,
    #[serde(alias = "cryptkey")]
    pub key: String,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SQLite {
    pub file: String,
}

#[tokio::main]
async fn main() {
    let v = (|| {
        if env::args().nth(1).unwrap_or(String::from("")) != *"" {
            return PathBuf::from(env::args().nth(1).unwrap());
        };
        match home::home_dir() {
            Some(path) => path.join(".luminainstance/"),
            None => PathBuf::from(Path::new(".")),
        }
    })();
    let vs = v
        .canonicalize()
        .unwrap_or(v.to_path_buf())
        .to_string_lossy()
        .replace("\\\\?\\", "")
        .to_string();
    if !v.exists() {
        match fs::create_dir_all(v.clone()) {
            Ok(_) => {}
            Err(e) => {
                eprintln!(
                    "Could not write necessary files! Error: {}",
                    e.to_string().bright_red()
                );
                process::exit(1);
            }
        }
    }
    if !v.is_dir() {
        eprintln!(
            "Unable to load or write config! Error: {}",
            format!("`{}` is not a directory.", vs).bright_red()
        );
        process::exit(1);
    }
    let config: LuminaConfig = {
        println!("Loading configuration from {}", vs);
        let va = v.clone().join("./config.toml");
        let confp = Path::new(&va);
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
        let sty_f = v.clone().join("./custom-styles.css");
        if (!sty_f.is_file()) || (!sty_f.exists()) {
            let mut output = match File::create(sty_f.clone()) {
                Ok(p) => p,
                Err(a) => {
                    eprintln!(
                        "Error: Could not create blank style customisation file. The system returned: {}",
                        a
                    );
                    process::exit(1);
                }
            };

            match write!(output, "{}", STR_CLEAN_CUSTOMSTYLES_CSS) {
                Ok(p) => p,
                Err(a) => {
                    eprintln!(
                        "Error: Could not create blank style customisation file. The system returned: {}",
                        a
                    );
                    process::exit(1);
                }
            };
        }
        let o = v.clone();
        let config_version_up_to_date: bool = match fs::read_to_string(confp) {
            Ok(g) => match toml::from_str(&g) {
                Ok(p) => {
                    let p: PrePreConfig = p;
                    p.version.unwrap_or(String::from("Unset")) == *CURRENT_CONFIG_VERSION
                }
                _ => false,
            },
            _ => false,
        };
        if !config_version_up_to_date {
            eprintln!("ERROR! The config file Lumina tried to load, doesn't match the configuration version Lumina supports. (Expected: {})", CURRENT_CONFIG_VERSION);
            process::exit(1);
        };

        match fs::read_to_string(confp) {
            Ok(g) => match toml::from_str(&g) {
                Ok(p) => {
                    let mut rng = thread_rng();
                    let p: PreConfig = p;
                    LuminaConfig {
                        version: p.version,
                        server: p.server,
                        interinstance: p.interinstance,
                        database: p.database,
                        logging: p.logging,
                        run: ERun {
                            cd: o,
                            customcss: fs::read_to_string(sty_f)
                                .unwrap_or(String::from(r"/* Failed loading custom css */")),
                            session_valid: rng.gen_range(1..=900000),
                        },
                    }
                }
                Err(e) => {
                    eprintln!(
                        "ERROR: Could not interpret server configuration at `{}`!\n\n\t{}",
                        confp
                            .canonicalize()
                            .unwrap_or(confp.to_path_buf())
                            .to_string_lossy()
                            .replace("\\\\?\\", ""),
                        e.message()
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
    let logsets: LogSets = {
        fn matchlogmode(o: u8) -> LevelFilter {
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
        match config.clone().logging {
            None => LogSets {
                file_loglevel: LevelFilter::Info,
                term_loglevel: LevelFilter::Warn,
                logfile: config.run.cd.join("./instance.log"),
            },
            Some(d) => LogSets {
                file_loglevel: match d.file_loglevel {
                    Some(l) => matchlogmode(l),
                    None => LevelFilter::Info,
                },
                term_loglevel: match d.term_loglevel {
                    Some(l) => matchlogmode(l),
                    None => LevelFilter::Warn,
                },
                logfile: match d.logfile {
                    Some(s) => config.run.cd.join(s.as_str()),
                    None => config.run.cd.join("./instance.log"),
                },
            },
        }
    };
    CombinedLogger::init(vec![
        TermLogger::new(
            logsets.term_loglevel,
            Config::default(),
            TerminalMode::Mixed,
            ColorChoice::Auto,
        ),
        WriteLogger::new(
            logsets.file_loglevel,
            Config::default(),
            File::create(&logsets.logfile).unwrap(),
        ),
    ])
    .unwrap();
    let server_p: ServerVars = ServerVars {
        config: config.clone(),
        // console: Term::stdout(),
    };
    let server_q: Data<Mutex<ServerVars>> = Data::new(Mutex::new(server_p.clone()));
    server_p.tell(format!(
        "Logging to {}",
        logsets
            .logfile
            .canonicalize()
            .unwrap()
            .to_string_lossy()
            .replace("\\\\?\\", "")
    ));
    let keydouble = config.server.cookie_key.repeat(2);
    let keybytes = keydouble.as_bytes();
    if keybytes.len() < 32 {
        error!(
            "Error: Cookie key must be at least 32 (doubled) bytes long. \"{}\" yields only {} bytes.",
            config.server.cookie_key.blue(),
            format!("{}",keybytes.len()).blue()
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
            .default_service(web::to(notfound))
            .route("/", web::get().to(serve::root))
            .route("/home", web::get().to(serve::homepage))
            .route("/login", web::get().to(serve::login))
            .route("/signup", web::get().to(serve::signup))
            .route("/session/logout", web::get().to(serve::logout))
            .route("/home/", web::get().to(serve::homepage))
            .route("/login/", web::get().to(serve::login))
            .route("/signup/", web::get().to(serve::signup))
            .route("/session/logout/", web::get().to(serve::logout))
            .route("/app.js", web::get().to(serve::appjs))
            .route("/app.js.map", web::get().to(serve::appjsmap))

            .route(
                "/api/fe/fetch-page",
                web::post().to(api_fe::pageservresponder),
            )
            .route(
                "/api/fe/editor_fetch_markdownpreview",
                web::post().to(api_fe::render_editor_articlepost),
            )
            .route("/api/fe/update", web::get().to(api_fe::update))
            .route("/api/fe/auth", web::post().to(api_fe::auth))
            .route("/api/fe/auth-create", web::post().to(api_fe::newaccount))
            .route(
                "/api/fe/auth-create/check-username",
                web::post().to(api_fe::check_username),
            )
            .route("/red-cross.svg", web::get().to(serve::red_cross_svg))
            .route("/spinner.svg", web::get().to(serve::spinner_svg))
            .route("/green-check.svg", web::get().to(serve::green_check_svg))
            .route("/logo.svg", web::get().to(serve::logo_svg))
            .route("/favicon.ico", web::get().to(serve::logo_png))
            .route("/logo.png", web::get().to(serve::logo_png))

            .service(avatar)
            .service(serve_fonts)
            .app_data(web::Data::clone(&server_q))
    })
    .bind((config.server.adress.clone(), config.server.port))
    {
        Ok(o) => {
            server_p.tell(format!(
                "Running on {0}:{1}, which should be bound to {2}://{3}",
                config.server.adress,
                config.server.port,
                if config.server.secure {
                    "https"
                } else {
                    "http"
                },
                config.interinstance.iid
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
    let _ = futures::join!(api_ii::main(server_p.clone()), main_server, close());
}

async fn close() {
    // This function is uh, pruned mostly, because it affected others.
    let _ = tokio::signal::ctrl_c().await;
    println!("\n\n\nBye!\n");
    process::exit(0);
    // let msg = format!("Type [{}] and then [{}] to exit or use '{}' to show more available Lumina server runtime commands.", "q".blue(), "return".bright_magenta(), "help".bright_blue()).bright_yellow();
    // println!("{}", msg);
    // let mut input = String::new();
    // let mut waiting = true;
    // while waiting {
    //     input.clear();
    //     let _ = std::io::stdout().flush();
    //     std::io::stdin()
    //         .read_line(&mut input)
    //         .expect("Failed to read input");
    //     if input == *"\r\n" {
    //         waiting = false;
    //     }
    //     input = input.replace(['\n', '\r'], "");
    //     let split_input = input.as_str().split(' ').collect::<Vec<&str>>();
    //     match split_input[0].to_lowercase().as_str() {
    //         "q" | "x" | "exit" => {
    //             println!("Bye!");
    //             process::exit(0);
    //         }
    //         "au" | "adduser" => {
    //             if split_input.len() < 2 {
    //                 println!("Usage: adduser <username> <password> <email>");
    //             } else {
    //                 match database::users::add(
    //                     split_input[1].to_string(),
    //                     split_input[2].to_string(),
    //                     split_input[3].to_string(),
    //                     &config.clone(),
    //                 ) {
    //                     Ok(o) => println!(
    //                         "{}",
    //                         format!(
    //                             "Added user {} with password {} and ID {}.",
    //                             split_input[1].bright_magenta(),
    //                             split_input[2].bright_magenta(),
    //                             o.to_string().bright_magenta(),
    //                         )
    //                             .green()
    //                     ),
    //                     Err(e) => println!(
    //                         "{}",
    //                         format!(
    //                             "Could not add user {} with password {}: {}",
    //                             split_input[1],
    //                             split_input[2],
    //                             e
    //                         )
    //                             .red()
    //                     ),
    //                 }
    //             }
    //         }
    //         "h" | "help" => println!(
    //             "\n{}\n\t{} {}{}{} {}{}{} {}{}{}{}",
    //             "Lumina server runtime command line - Help\n".bright_yellow(),
    //             "au | adduser".white(),
    //             "<".red(), "username".bright_yellow().on_red(), ">".red(),
    //             "<".red(), "password".bright_yellow().on_red(), ">".red(),
    //             "<".red(), "email".bright_yellow().on_red(), ">".red(),
    //             format!("\n\t\tAdds a new user to the database.\n\t{}\n\t\tDisplays this help message.\n\t{}\n\t\tShut down the server.", "h | help".white(), "q | x | exit".white()).green()
    //         ),
    //         _ => println!("{}", msg),
    //     }
    // }
}

mod serve;

#[doc = r"Font file server"]
#[get("/fonts/{a:.*}")]
pub(crate) async fn serve_fonts(
    req: HttpRequest,
    server_vars_mutex: Data<Mutex<ServerVars>>,
    session: Session,
) -> HttpResponse {
    // let reqx = req.clone();
    let fnt: String = req.match_info().get("a").unwrap().parse().unwrap();
    let fonts = fonts();
    let fontbytes: &[u8] = match fnt.as_str() {
        "Josefin_Sans/JosefinSans-VariableFont_wght.ttf" => fonts.josefin_sans,
        "Fira_Sans/FiraSans-Regular.ttf" => fonts.fira_sans,
        "Gantari/Gantari-VariableFont_wght.ttf" => fonts.gantari,
        "Syne/Syne-VariableFont_wght.ttf" => fonts.syne,
        _ => {
            return notfound(server_vars_mutex, req, session).await;
        }
    };
    let server_vars = ServerVars::grab(&server_vars_mutex).await;
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    server_vars.tell(format!(
        "{2}\t{:>45.47}\t\t{}",
        format!("/fonts/{}", fnt).magenta(),
        ip.yellow(),
        "Request/200".bright_green()
    ));
    HttpResponse::Ok()
        .append_header(("Accept-Charset", "UTF-8"))
        .content_type("font/ttf")
        .body(fontbytes)
}

#[get("/user/avatar/{a:.*}")]
pub(crate) async fn avatar(
    req: HttpRequest,
    server_vars_mutex: Data<Mutex<ServerVars>>,
    session: Session,
) -> HttpResponse {
    let server_vars = ServerVars::grab(&server_vars_mutex).await;
    let user: String = req.match_info().get("a").unwrap().parse().unwrap();

    // For now unused. Will be used once users can have avatars.
    let _ = (user, session);
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    server_vars.tell(format!(
        "{2}\t{:>45.47}\t\t{}",
        req.path().magenta(),
        ip.yellow(),
        "Request/200".bright_green()
    ));
    let index: usize = Rng::gen_range(&mut thread_rng(), 0..=5);
    let cont: String = {
        let oo = &vec_string_assets_anons_svg()[index];

        oo.clone().to_string()
    };
    HttpResponse::Ok()
        .append_header(("Accept-Charset", "UTF-8"))
        .content_type("image/svg+xml")
        .body(cont)
}
