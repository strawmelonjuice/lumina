/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */
#[macro_use]
extern crate log;
extern crate simplelog;
use rand::prelude::*;
#[macro_use]
extern crate build_const;

use actix_session::storage::CookieSessionStore;
use actix_session::{Session, SessionMiddleware};
use actix_web::cookie::Key;
use actix_web::{get, HttpRequest, HttpResponse};
use actix_web::{
    web::{self, Data},
    App, HttpServer,
};
use colored::Colorize;
use serde::{Deserialize, Serialize};
use simplelog::*;
use std::fmt::Debug;
use std::fs::File;
use std::io::Write;
use std::path::PathBuf;
use std::{env, fs, path::Path, process};
use tokio::sync::{Mutex, MutexGuard};

use tell::tellgen;

use crate::assets::{fonts, STR_CLEAN_CONFIG_TOML, STR_CLEAN_CUSTOMSTYLES_CSS};
use crate::serve::notfound;

mod api_fe;
mod assets;
mod instance_poller;
mod storage;
mod tell;

#[derive(Clone)]
struct ServerVars {
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
pub struct PreConfig {
    pub server: Server,
    pub interinstance: InterInstance,
    pub database: Database,
    pub logging: Option<Logging>,
}
#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Config {
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
            Some(path) => path.join(".ephewinstance/"),
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
    let config: Config = {
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
        match fs::read_to_string(confp) {
            Ok(g) => match toml::from_str(&g) {
                Ok(p) => {
                    let mut rng = thread_rng();
                    let p: PreConfig = p;
                    Config {
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
        match config.clone().logging {
            None => LogSets {
                file_loglevel: LevelFilter::Info,
                term_loglevel: LevelFilter::Warn,
                logfile: config.run.cd.join("./instance.log"),
            },
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
                    Some(s) => config.run.cd.join(s.as_str()),
                    None => config.run.cd.join("./instance.log"),
                },
            },
        }
    };
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
    let server_p: ServerVars = ServerVars {
        config: config.clone(),
        tell,
    };
    let server_q: Data<Mutex<ServerVars>> = Data::new(Mutex::new(server_p.clone()));
    tell(format!(
        "Logging to {}",
        logsets
            .logfile
            .canonicalize()
            .unwrap()
            .to_string_lossy()
            .replace("\\\\?\\", "")
    ));
    // some tests
    // Ran successfully
    //         println!("\n\n\n Creating a user named 'davemustaine' with password 'Polarbear':\n{:?}", storage::users::add("davemustaine".to_string(), "Polarbear".to_string(), &config.clone()));
    //
    // Ran successfully
    //         println!(
    //             " Checking for a user named 'gerardway' with password 'password'? {} \n\n\n",
    //             match storage::users::auth::check(
    //                 "gerardway".to_string(),
    //                 "password".to_string(),
    //                 &(server_p)
    //             )
    //             .wrap()
    //             .unwrap_or(None)
    //             {
    //                 Some(a) => a.to_string(),
    //                 None => "No such user.".to_string(),
    //             }
    //             .yellow()
    //             .on_bright_green()
    //         );
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
            .route("/logout", web::get().to(serve::logout))
            .route("/prefetch.js", web::get().to(serve::prefetch_js))
            .route("/login.js", web::get().to(serve::login_js))
            .route("/api/fe/update", web::get().to(api_fe::update))
            .route("/api/fe/auth", web::post().to(api_fe::auth))
            .route("/site.css", web::get().to(serve::site_css))
            .route("/custom.css", web::get().to(serve::site_c_css))
            .route("/red-cross.svg", web::get().to(serve::red_cross_svg))
            .route("/spinner.svg", web::get().to(serve::spinner_svg))
            .route("/green-check.svg", web::get().to(serve::green_check_svg))
            .route("/logo.svg", web::get().to(serve::logo_svg))
            .route("/favicon.ico", web::get().to(serve::logo_png))
            .route("/logo.png", web::get().to(serve::logo_png))
            .route("/axios/axios.min.js", web::get().to(serve::node_axios))
            .route(
                "/axios/axios.min.js.map",
                web::get().to(serve::node_axios_map),
            )
            .service(serve_fonts)
            .app_data(web::Data::clone(&server_q))
    })
    .bind((config.server.adress.clone(), config.server.port))
    {
        Ok(o) => {
            tell(format!(
                "Running on {0}:{1} (http://127.0.0.1:{1}/)",
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
    let _ = futures::join!(
        instance_poller::main(config.clone(), tell),
        main_server,
        close(config.clone())
    );
}

async fn close(config: Config) {
    let msg = format!("Type [{}] and then [{}] to exit or use '{}' to show more available Ephew server runtime commands.","X".blue(), "return".bright_magenta(), "help".bright_blue()).bright_yellow();
    println!("{}", msg);
    let mut input = String::new();
    let mut waiting = true;
    while waiting {
        input.clear();
        let _ = std::io::stdout().flush();
        std::io::stdin()
            .read_line(&mut input)
            .expect("Failed to read line");
        if input == *"\r\n" {
            waiting = false;
        }
        input = input.replace(['\n', '\r'], "");
        let split_input = input.as_str().split(' ').collect::<Vec<&str>>();
        match split_input[0].to_lowercase().as_str() {
            "c" | "x" | "exit" => {
                println!("Bye!");
                process::exit(0);
            }
            "au" | "adduser" => {
                if split_input.len() < 2 {
                    println!("Usage: adduser <username> <password>");
                } else {
                    match storage::users::add(
                        split_input[1].to_string(),
                        split_input[2].to_string(),
                        &config.clone(),
                    ) {
                        Ok(o) => println!(
                            "{}",
                            format!(
                                "Added user {} with password {} and ID {}.",
                                split_input[1].bright_magenta(),
                                split_input[2].bright_magenta(),
                                o.to_string().bright_magenta(),
                            )
                            .green()
                        ),
                        Err(e) => println!(
                            "{}",
                            format!(
                                "Could not add user {} with password {}: {}",
                                split_input[1],
                                split_input[2],
                                e
                            )
                            .red()
                        ),
                    }
                }
            }
            "h" | "help" => println!(
                "\n{}{}{}",
                "Ephew server runtime command line - Help\n".bright_yellow(),
                format!("\n\tau | adduser {}{}",
                        format!("{}{}{}", "<".red(), "username".bright_yellow(), ">".red()),
                        format!("{}{}{}", "<".red(), "password".bright_yellow(), ">".red())
                ),
                        "\n\t\tAdds a new user to the database.\n\th | help\n\t\tDisplays this help message.\n\tc | x | exit\n\t\tShut down the server.".green()
            ),
            _ => println!("{}", msg),
        }
    }
}

mod serve {
    use actix_session::Session;
    use actix_web::http::header::LOCATION;
    use actix_web::http::StatusCode;
    use actix_web::web::Data;
    use actix_web::{HttpRequest, HttpResponse, Responder};
    use colored::Colorize;
    use tokio::sync::{Mutex, MutexGuard};

    use crate::assets::{
        BYTES_ASSETS_LOGO_PNG, STR_ASSETS_GREEN_CHECK_SVG, STR_ASSETS_INDEX_HTML,
        STR_ASSETS_LOGIN_HTML, STR_ASSETS_LOGIN_JS, STR_ASSETS_LOGO_SVG, STR_ASSETS_PREFETCH_JS,
        STR_ASSETS_RED_CROSS_SVG, STR_ASSETS_SIGNUP_HTML, STR_ASSETS_SPINNER_SVG,
        STR_GENERATED_MAIN_MIN_CSS, STR_NODE_MOD_AXIOS_MIN_JS, STR_NODE_MOD_AXIOS_MIN_JS_MAP,
    };
    use crate::storage::BasicUserInfo;
    use crate::{Config, ServerVars};

    pub(super) async fn notfound(
        server_z: Data<Mutex<ServerVars>>,
        req: HttpRequest,
        session: Session,
    ) -> HttpResponse {
        let server_y = server_z.lock().await;
        let _server_p: ServerVars = server_y.clone();
        let username_ = session.get::<String>("username");
        let username = username_.unwrap_or(None).unwrap_or(String::from(""));
        let username_b = if username != *"" {
            format!("/{}", username.green())
        } else {
            String::from("")
        };
        let coninfo = req.connection_info();
        let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");

        warn!(
            "{}\t{:>45.47}\t\t{}{:<26}",
            "Request/404".bright_red(),
            req.path().red(),
            ip.yellow(),
            username_b
        );
        HttpResponse::NotFound().body("")
    }
    pub(super) async fn root(server_z: Data<Mutex<ServerVars>>, req: HttpRequest) -> HttpResponse {
        let server_y = server_z.lock().await;
        let server_p: ServerVars = server_y.clone();
        drop(server_y);
        let coninfo = req.connection_info();
        let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
        (server_p.tell)(format!(
            "{2}\t{:>45.47}\t\t{}",
            "/".bright_magenta(),
            ip.yellow(),
            "Request/200".bright_green()
        ));

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

    pub(super) async fn login(server_z: Data<Mutex<ServerVars>>, req: HttpRequest) -> HttpResponse {
        let server_y = server_z.lock().await;
        let server_p: ServerVars = server_y.clone();
        drop(server_y);
        let coninfo = req.connection_info();
        let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
        (server_p.tell)(format!(
            "{2}\t{:>45.47}\t\t{}",
            "/login".bright_magenta(),
            ip.yellow(),
            "Request/200".bright_green()
        ));

        HttpResponse::build(StatusCode::OK)
            .content_type("text/html; charset=utf-8")
            .body(
                STR_ASSETS_LOGIN_HTML
                    .replace(
                        "{{iid}}",
                        &server_p.clone().config.interinstance.iid.clone(),
                    )
                    .clone(),
            )
    }
    pub(super) async fn signup(
        server_z: Data<Mutex<ServerVars>>,
        req: HttpRequest,
    ) -> HttpResponse {
        let server_y = server_z.lock().await;
        let server_p: ServerVars = server_y.clone();
        drop(server_y);
        let coninfo = req.connection_info();
        let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
        (server_p.tell)(format!(
            "{2}\t{:>45.47}\t\t{}",
            "/signup".bright_magenta(),
            ip.yellow(),
            "Request/200".bright_green()
        ));

        HttpResponse::build(StatusCode::OK)
            .content_type("text/html; charset=utf-8")
            .body(
                STR_ASSETS_SIGNUP_HTML
                    .replace(
                        "{{iid}}",
                        &server_p.clone().config.interinstance.iid.clone(),
                    )
                    .clone(),
            )
    }
    pub(super) async fn prefetch_js(
        server_z: Data<Mutex<ServerVars>>,
        req: HttpRequest,
    ) -> HttpResponse {
        let server_y: MutexGuard<ServerVars> = server_z.lock().await;
        let coninfo = req.connection_info();
        let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
        (server_y.tell)(format!(
            "{2}\t{:>45.47}\t\t{}",
            "/prefetch.js".magenta(),
            ip.yellow(),
            "Request/200".bright_green()
        ));
        let js = format!(
            r#"/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */

 {}"#,
            STR_ASSETS_PREFETCH_JS
        );
        HttpResponse::build(StatusCode::OK)
            .content_type("text/javascript; charset=utf-8")
            .body(js)
    }

    pub(super) async fn login_js(
        server_z: Data<Mutex<ServerVars>>,
        req: HttpRequest,
    ) -> HttpResponse {
        let server_y: MutexGuard<ServerVars> = server_z.lock().await;
        let coninfo = req.connection_info();
        let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
        (server_y.tell)(format!(
            "{2}\t{:>45.47}\t\t{}",
            "/login.js".magenta(),
            ip.yellow(),
            "Request/200".bright_green()
        ));
        let js = format!(
            r#"/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */

 {}"#,
            STR_ASSETS_LOGIN_JS
        );
        HttpResponse::build(StatusCode::OK)
            .content_type("text/javascript; charset=utf-8")
            .body(js)
    }

    pub(super) async fn site_c_css(
        server_z: Data<Mutex<ServerVars>>,
        req: HttpRequest,
    ) -> HttpResponse {
        let server_y: MutexGuard<ServerVars> = server_z.lock().await;
        let config: Config = server_y.clone().config;
        let coninfo = req.connection_info();
        let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
        (server_y.tell)(format!(
            "{2}\t{:>45.47}\t\t{}",
            "/custom.css".magenta(),
            ip.yellow(),
            "Request/200".bright_green()
        ));
        HttpResponse::build(StatusCode::OK)
            .content_type("text/css; charset=utf-8")
            .body(config.run.customcss)
    }

    pub(super) async fn site_css(
        server_z: Data<Mutex<ServerVars>>,
        req: HttpRequest,
    ) -> HttpResponse {
        let server_y: MutexGuard<ServerVars> = server_z.lock().await;
        let coninfo = req.connection_info();
        let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
        (server_y.tell)(format!(
            "{2}\t{:>45.47}\t\t{}",
            "/site.css".magenta(),
            ip.yellow(),
            "Request/200".bright_green()
        ));
        HttpResponse::build(StatusCode::OK)
            .content_type("text/css; charset=utf-8")
            .body(STR_GENERATED_MAIN_MIN_CSS)
    }
    pub(super) async fn red_cross_svg(
        server_z: Data<Mutex<ServerVars>>,
        req: HttpRequest,
    ) -> HttpResponse {
        let server_y: MutexGuard<ServerVars> = server_z.lock().await;
        let coninfo = req.connection_info();
        let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
        (server_y.tell)(format!(
            "{2}\t{:>45.47}\t\t{}",
            "/red-cross.svg".magenta(),
            ip.yellow(),
            "Request/200".bright_green()
        ));
        HttpResponse::build(StatusCode::OK)
            .content_type("image/svg+xml; charset=utf-8")
            .body(STR_ASSETS_RED_CROSS_SVG)
    }
    pub(super) async fn spinner_svg(
        server_z: Data<Mutex<ServerVars>>,
        req: HttpRequest,
    ) -> HttpResponse {
        let server_y: MutexGuard<ServerVars> = server_z.lock().await;
        let coninfo = req.connection_info();
        let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
        (server_y.tell)(format!(
            "{2}\t{:>45.47}\t\t{}",
            "/spinner.svg".magenta(),
            ip.yellow(),
            "Request/200".bright_green()
        ));
        HttpResponse::build(StatusCode::OK)
            .content_type("image/svg+xml; charset=utf-8")
            .body(STR_ASSETS_SPINNER_SVG)
    }
    pub(super) async fn green_check_svg(
        server_z: Data<Mutex<ServerVars>>,
        req: HttpRequest,
    ) -> HttpResponse {
        let server_y: MutexGuard<ServerVars> = server_z.lock().await;
        let coninfo = req.connection_info();
        let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
        (server_y.tell)(format!(
            "{2}\t{:>45.47}\t\t{}",
            "/green-check.svg".magenta(),
            ip.yellow(),
            "Request/200".bright_green()
        ));
        HttpResponse::build(StatusCode::OK)
            .content_type("image/svg+xml; charset=utf-8")
            .body(STR_ASSETS_GREEN_CHECK_SVG)
    }
    pub(super) async fn logo_svg(
        server_z: Data<Mutex<ServerVars>>,
        req: HttpRequest,
    ) -> HttpResponse {
        let server_y: MutexGuard<ServerVars> = server_z.lock().await;
        let coninfo = req.connection_info();
        let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
        (server_y.tell)(format!(
            "{2}\t{:>45.47}\t\t{}",
            "/logo.svg".magenta(),
            ip.yellow(),
            "Request/200".bright_green()
        ));
        HttpResponse::build(StatusCode::OK)
            .content_type("image/svg+xml; charset=utf-8")
            .body(STR_ASSETS_LOGO_SVG)
    }

    pub(super) async fn logo_png(
        server_z: Data<Mutex<ServerVars>>,
        req: HttpRequest,
    ) -> HttpResponse {
        let server_y: MutexGuard<ServerVars> = server_z.lock().await;
        let coninfo = req.connection_info();
        let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
        (server_y.tell)(format!(
            "{2}\t{:>45.47}\t\t{}",
            "/logo.png".magenta(),
            ip.yellow(),
            "Request/200".bright_green()
        ));
        HttpResponse::build(StatusCode::OK)
            .content_type("image/png; charset=utf-8")
            .body(BYTES_ASSETS_LOGO_PNG)
    }
    pub(super) async fn node_axios_map(
        server_z: Data<Mutex<ServerVars>>,
        req: HttpRequest,
    ) -> HttpResponse {
        let server_y: MutexGuard<ServerVars> = server_z.lock().await;
        let coninfo = req.connection_info();
        let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
        (server_y.tell)(format!(
            "{2}\t{:>45.47}\t\t{}",
            "/axios/axios.min.js.map".magenta(),
            ip.yellow(),
            "Request/200".bright_green()
        ));
        HttpResponse::build(StatusCode::OK)
            .content_type("text/javascript; charset=utf-8")
            .body(STR_NODE_MOD_AXIOS_MIN_JS_MAP)
    }

    pub(super) async fn node_axios(
        server_z: Data<Mutex<ServerVars>>,
        req: HttpRequest,
    ) -> HttpResponse {
        let server_y: MutexGuard<ServerVars> = server_z.lock().await;
        let coninfo = req.connection_info();
        let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
        (server_y.tell)(format!(
            "{2}\t{:>45.47}\t\t{}",
            "/axios/axios.min.js".magenta(),
            ip.yellow(),
            "Request/200".bright_green()
        ));
        HttpResponse::build(StatusCode::OK)
            .content_type("text/javascript; charset=utf-8")
            .body(STR_NODE_MOD_AXIOS_MIN_JS)
    }
    pub(super) async fn homepage(
        server_z: Data<Mutex<ServerVars>>,
        session: Session,
        req: HttpRequest,
    ) -> HttpResponse {
        fence(
            session,
            server_z,
            req,
            |_: Config, server_vars: ServerVars, user: BasicUserInfo, request: HttpRequest| {
                let coninfo = request.connection_info();
                let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
                (server_vars.tell)(format!(
                    "{}\t{:>45.47}\t\t{}/{:<25}",
                    "Request/200".bright_green(),
                    "/home".bright_magenta(),
                    ip.yellow(),
                    user.username.green()
                ));
                let cont = "";
                HttpResponse::build(StatusCode::OK)
                    .content_type("text/html; charset=utf-8")
                    .body(cont)
            },
        )
        .await
    }

    pub(super) async fn logout(
        server_z: Data<Mutex<ServerVars>>,
        session: Session,
        req: HttpRequest,
    ) -> impl Responder {
        let server_y = server_z.lock().await;
        let server_p: ServerVars = server_y.clone();
        drop(server_y);
        let username_ = session.get::<String>("username");
        let coninfo = req.connection_info();
        let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
        match username_.unwrap_or(None) {
            Some(username) => {
                (server_p.tell)(format!(
                    "{}\t{:>45.47}\t\t{}/{:<25}",
                    "Request/200".bright_green(),
                    "/logout".bright_magenta(),
                    ip.yellow(),
                    username.green()
                ));
                session.purge();
                HttpResponse::build(StatusCode::OK)
                    .append_header((LOCATION, "/login"))
                    .finish()
            }
            None => HttpResponse::build(StatusCode::TEMPORARY_REDIRECT)
                .append_header((LOCATION, "/login"))
                .finish(),
        }
    }
    /// # `Fence()`
    /// Fence is a function serving kind of like middleware usually would. But actix middleware kinda sucks balls. So.
    pub(crate) async fn fence(
        session: Session,
        server_vars_mutex: Data<Mutex<ServerVars>>,
        req: HttpRequest,
        next: fn(
            config: Config,
            vars: ServerVars,
            user: BasicUserInfo,
            req: HttpRequest,
        ) -> HttpResponse,
    ) -> HttpResponse {
        let server_y: MutexGuard<ServerVars> = server_vars_mutex.lock().await;
        let config = server_y.clone().config;
        let id_ = session.get::<String>("userid");
        let id = id_.unwrap_or(None).unwrap_or(String::from(""));
        let safe = id != *""
            && session.get::<i64>("validity").unwrap_or(None)
                == Some(config.clone().run.session_valid);
        if !safe {
            HttpResponse::build(StatusCode::TEMPORARY_REDIRECT)
                .append_header((LOCATION, "/login"))
                .finish()
        } else {
            let user: BasicUserInfo = serde_json::from_str(
                crate::storage::fetch(&config, String::from("Users"), "id", id.to_string())
                    .unwrap()
                    .unwrap()
                    .as_str(),
            )
            .unwrap();

            next(config, server_y.clone().to_owned(), user, req)
        }
    }
}
#[doc = r"Font file server"]
#[get("/fonts/{a:.*}")]
pub(crate) async fn serve_fonts(
    req: HttpRequest,
    server_z: Data<Mutex<ServerVars>>,
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
            return notfound(server_z, req, session).await;
        }
    };
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    let server_y: MutexGuard<ServerVars> = server_z.lock().await;
    (server_y.tell)(format!(
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
