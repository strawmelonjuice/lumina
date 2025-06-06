extern crate dotenv;
#[macro_use]
extern crate rocket;
mod client_communication;
pub mod errors;
mod staticroutes;

mod database;
mod tests;

use std::io::ErrorKind;
use std::{net::IpAddr, process, sync::Arc};
use tokio::sync::Mutex;
mod user;
use tokio_postgres as postgres;
struct AppState(Arc<(ServerConfig, Mutex<DbConn>)>);

use database::DbConn;

#[derive(Debug, Clone)]
struct ServerConfig {
    port: u16,
    host: IpAddr,
}

use crate::errors::LuminaError;
use cynthia_con::{CynthiaColors, CynthiaStyles};
use dotenv::dotenv;

fn config_get() -> Result<ServerConfig, LuminaError> {
    let addr = {
        let s = std::env::var("LUMINA_SERVER_ADDR").unwrap_or(String::from("127.0.0.1"));
        s.parse::<IpAddr>()
            .map_err(|_| LuminaError::ConfInvalid("LUMINA_SERVER_ADDR".to_string()))?
    };
    let port = {
        let s = std::env::var("LUMINA_SERVER_PORT").unwrap_or(String::from("8085"));
        s.parse::<u16>()
            .map_err(|_| LuminaError::ConfInvalid("LUMINA_SERVER_PORT".to_string()))?
    };
    Ok(ServerConfig { port, host: addr })
}

#[rocket::main]
async fn main() {
    // Some print prefixes
    let error = "[ERROR]".color_error_red().style_bold();
    let info = "[INFO]".color_green().style_bold();
    let warn = "[WARN]".color_yellow().style_bold();
    // End of print prefixes
    let me = format!("Lumina Server, version {}", env!("CARGO_PKG_VERSION"));
    let args: Vec<String> = std::env::args().skip(1).collect();
    match (
        args.is_empty(),
        args.first().unwrap_or(&String::new()).as_str(),
    ) {
        (true, _) | (false, "start") | (false, "") => {
            dotenv().ok();
            println!("{info} Starting {}.", me.clone().color_lightblue());
            println!(
                "{info} {} and contributors, licenced under {}.",
                "MLC Bloeiman".color_pink(),
                "BSD-3".color_blue()
            );
            println!("{}", cynthia_con::horizline());
            println!(
                "{warn} Lumina is still in early development, and should not be used in production in any way. Please use at your own risk."
            );
            match config_get() {
                Ok(config) => {
                    let db = match database::setup().await {
                        Ok(db) => db,
                        Err(LuminaError::ConfMissing(a)) => {
                            eprintln!(
                                "{error} Missing environment variable {}, which is required to continue. Please make sure it is set, or change other variables to make it redundant, if possible.",
                                a.color_bright_orange()
                            );
                            process::exit(1);
                        }
                        Err(LuminaError::ConfInvalid(a)) => {
                            eprintln!(
                                "{error} Invalid environment variable: {}",
                                a.color_bright_orange()
                            );
                            process::exit(1);
                        }
                        Err(LuminaError::Sqlite(a)) => {
                            eprintln!("{error} While opening sqlite database: {}", a);
                            process::exit(1);
                        }
                        Err(LuminaError::Postgres(a)) => {
                            eprintln!("{error} While connecting to postgres database: {}", a);
                            process::exit(1);
                        }
                        Err(_) => {
                            eprintln!(
                                "{error} Unknown error: could not setup database connection.",
                            );
                            process::exit(1);
                        }
                    };
                    let appstate = AppState(Arc::from((config.clone(), Mutex::from(db))));
                    let def = rocket::Config {
                        port: config.port,
                        address: config.host,
                        ident: rocket::config::Ident::try_new(me.clone()).unwrap_or_default(),
                        ..rocket::Config::default()
                    };
                    let result = rocket::build()
                        .configure(def)
                        .mount(
                            "/",
                            routes![
                                staticroutes::index,
                                staticroutes::lumina_js,
                                staticroutes::lumina_css,
                                client_communication::wsconnection,
                                staticroutes::logo_svg,
                                staticroutes::logo_png,
                                staticroutes::favicon,
                            ],
                        )
                        .manage(appstate)
                        .launch()
                        .await
                        .map_err(LuminaError::RocketFaillure);
                    match result {
                        Ok(_) => {}
                        Err(LuminaError::RocketFaillure(e)) => {
                            // This handling should slowly expand as I run into newer ones, the 'defh' (default handling) is good enough, but for the most-bumped into errors, I'd like to give more human responses.
                            let defh = || eprintln!("{error} Error starting server: {:?}", e);
                            match e.kind() {
                                rocket::error::ErrorKind::Bind(e) => match e.kind() {
                                    ErrorKind::AddrInUse => {
                                        println!(
                                            "{error} Another program or instance is running on this port or adress."
                                        );
                                        println!(
                                            "{error} Make sure you have not double-started Lumina, or have a different program serving on this port!"
                                        );
                                        println!(
                                            "{error} {}",
                                            format!("Technical explanation: {}", e).style_dim()
                                        );
                                    }
                                    _ => defh(),
                                },
                                _ => defh(),
                            }
                            process::exit(1);
                        }
                        Err(_) => {
                            eprintln!("{error} Unknown error starting server.",);
                        }
                    }
                }
                Err(LuminaError::ConfMissing(a)) => {
                    eprintln!(
                        "{error} Missing environment variable {}, which is required to continue. Please make sure it is set, or change other variables to make it redundant, if possible.",
                        a.color_bright_orange()
                    );
                    process::exit(1);
                }
                Err(LuminaError::ConfInvalid(a)) => {
                    eprintln!(
                        "{} Invalid environment variable: {}",
                        "[ERROR]".color_error_red().style_bold(),
                        a.color_bright_orange()
                    );
                    process::exit(1);
                }
                Err(_) => {
                    eprintln!(
                        "{} Unknown error: could not setup server configuration.",
                        "[ERROR]".color_error_red().style_bold()
                    );
                    process::exit(1);
                }
            };
        }
        (false, "licence") | (false, "license") => {
            println!(
                "Licence for {} and its {}.",
                me.color_lightblue().style_italic(),
                "Lumina Client".color_yellow().style_italic()
            );
            println!("MLC Bloeiman and contributors.");
            println!("{}", cynthia_con::horizline());
            println!("{}", include_str!("../../LICENSE"));
        }
        (false, "help") | (false, "man") => {
            fn table_to_centered_string(a: &mut tabled::Table) -> String {
                let s: Vec<String> = a
                    .to_string()
                    .split("\n")
                    .map(|s| s.style_centered())
                    .collect();
                let d = s.join("\n");
                d
            }
            println!("{}", me);
            {
                println!("{}", "Subcommands".style_centered().style_bold());
                println!();
                println!(
                    "\t\t{}|{}\tShow this help",
                    "help".color_lightblue().style_italic(),
                    "man".color_lightblue().style_italic()
                );
                println!(
                    "\t\t{}\t\tShow version and exit",
                    "version".color_lightblue().style_italic()
                );
                println!(
                    "\t\t{}\t\tShow licence and exit",
                    "licence".color_lightblue().style_italic()
                );
                println!(
                    "\t\t{}\t\tStart Lumina server",
                    "start".color_lightblue().style_italic()
                );
            }
            println!();
            {
                println!("{}", "Environment variables".style_centered().style_bold());
                println!();
                let mut builder = tabled::builder::Builder::new();
                builder.push_record(["Name", "Default value", "Description"]);
                builder.push_record(["LUMINA_DB_TYPE", r#"sqlite"#, r#"The kind of database to use. Options are 'postgres' (recommended) or 'sqlite'."#]);
                builder.push_record([
                    "LUMINA_DB_SALT",
                    r#"sal"#,
                    r#"The salting to use for some data on the database."#,
                ]);
                builder.push_record([
                    "LUMINA_SERVER_PORT",
                    r#"8085"#,
                    r#"Port for Lumina to accept HTTP requests on."#,
                ]);
                builder.push_record(["LUMINA_SERVER_ADDR", r#"127.0.0.1"#, "Address for Lumina to accept HTTP requests on. (usually '127.0.0.1' or '0.0.0.0')"]);
                builder.push_record(["LUMINA_SERVER_HTTPS", r#"false"#, "Wether to use 'https' rather than 'http' in links, etc. Recommendation is to set to true."]);
                builder.push_record([
                    "LUMINA_SYNC_IID",
                    r#"localhost"#,
                    "Broadcasted domain name, should be equal to public domain name.",
                ]);
                builder.push_record([
                    "LUMINA_SYNC_INTERVAL",
                    r#"30"#,
                    "Specifies the interval between syncs. Minimum is 30.",
                ]);
                println!(
                    "{}",
                    table_to_centered_string(
                        builder.build().with(tabled::settings::Style::modern())
                    )
                    .style_dim()
                );
                println!();
                println!(
                    "{}",
                    format!(
                        r#"When having "LUMINA_DB_TYPE" set to '{}': (recommended)"#,
                        "postgres".color_lilac().style_bold()
                    )
                    .style_centered()
                    .style_italic()
                );
                let mut builder = tabled::builder::Builder::new();
                builder.push_record(["Name", "Default value", "Description"]);
                builder.push_record([
                    "LUMINA_POSTGRES_PORT",
                    r#"5432"#,
                    r#"The port to contact the database on."#,
                ]);
                builder.push_record([
                    "LUMINA_POSTGRES_HOST",
                    r#"localhost"#,
                    r#"The address to contact the database on."#,
                ]);
                builder.push_record([
                    "LUMINA_POSTGRES_USERNAME",
                    r#""#,
                    r#"The username to log in to the database with."#,
                ]);
                builder.push_record(["LUMINA_POSTGRES_PASSWORD", r#""#, r#"The password to log in to the database with. If not set, Lumina will try without."#]);
                builder.push_record([
                    "LUMINA_POSTGRES_DATABASE",
                    r#""#,
                    r#"The name of the database to use."#,
                ]);
                println!(
                    "{}",
                    table_to_centered_string(
                        builder.build().with(tabled::settings::Style::modern())
                    )
                    .color_lilac()
                    .style_dim()
                );

                println!();
                println!(
                    "{}",
                    format!(
                        r#"When having "LUMINA_DB_TYPE" set to '{}':"#,
                        "sqlite".color_bright_orange().style_bold()
                    )
                    .style_centered()
                    .style_italic()
                );
                let mut builder = tabled::builder::Builder::new();
                builder.push_record(["Name", "Default value", "Description"]);

                builder.push_record([
                    "LUMINA_SQLITE_FILE",
                    r#"instance.sqlite"#,
                    "SQLite file to connect to. Always a relative path from the instance folder.",
                ]);
                println!(
                    "{}",
                    table_to_centered_string(
                        builder.build().with(tabled::settings::Style::modern())
                    )
                    .color_bright_orange()
                    .style_dim()
                )
            }
        }
        (false, unknown) => {
            println!(
                "{error} Unknown subcommand, '{}', use '{}' for available commands.'",
                unknown.color_blue().style_italic(),
                "help".color_lightblue().style_italic()
            )
        }
    }
}
