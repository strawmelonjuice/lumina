mod client_communication;
pub mod errors;
mod staticroutes;

mod database;
mod tests;

#[macro_use]
extern crate rocket;
use std::{
    net::{IpAddr, Ipv4Addr, Ipv6Addr},
    process,
    sync::Arc,
};
use tokio::sync::Mutex;
mod user;
use r2d2_sqlite::rusqlite as sqlite;
use tokio_postgres as postgres;
struct AppState(Arc<(ServerConfig, Mutex<DbConn>)>);

use database::DbConn;

#[derive(Debug, Clone)]
struct ServerConfig {
    port: u16,
    host: IpAddr,
}

extern crate dotenv;

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
        let s = std::env::var("LUMINA_SERVER_PORT").unwrap_or(String::from("8080"));
        s.parse::<u16>()
            .map_err(|_| LuminaError::ConfInvalid("LUMINA_SERVER_PORT".to_string()))?
    };
    Ok(ServerConfig { port, host: addr })
}

#[rocket::main]
async fn main() {
    dotenv().ok();

    match config_get() {
        Ok(config) => {
            let db = match database::setup(config.clone()).await {
                Ok(db) => db,
                Err(LuminaError::ConfMissing(a)) => {
                    eprintln!(
                        "{} Missing environment variable {}, which is required to continue. Please make sure it is set, or change other variables to make it redundant, if possible.",
                        "[ERROR]".color_error_red().style_bold(),
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
                Err(LuminaError::Sqlite(a)) => {
                    eprintln!("{} While opening sqlite database: {}", "[ERROR]".color_error_red().style_bold(),a);
                    process::exit(1);
                }
                Err(LuminaError::Postgres(a)) => {
                    eprintln!("{} While connecting to postgres database: {}", "[ERROR]".color_error_red().style_bold(), a);
                    process::exit(1);
                }
                Err(_) => {
                    eprintln!("{} Unknown error: could not setup database connection.", "[ERROR]".color_error_red().style_bold());
                    process::exit(1);
                }
            };
            let appstate = AppState(Arc::from((config.clone(), Mutex::from(db))));
            let def = rocket::Config {
                port: config.port,
                address: config.host,
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
                    eprintln!("{} Error starting server: {:?}", "[ERROR]".color_error_red().style_bold(), e);
                }
                Err(_) => {
                    eprintln!("{} Unknown error starting server.", "[ERROR]".color_error_red().style_bold());
                }
            }
        }
        Err(LuminaError::ConfMissing(a)) => {
            eprintln!(
                "{} Missing environment variable {}, which is required to continue. Please make sure it is set, or change other variables to make it redundant, if possible.",
            "[ERROR]".color_error_red().style_bold()
                ,
                a.color_bright_orange()
            );
            process::exit(1);
        }
        Err(LuminaError::ConfInvalid(a)) => {
            eprintln!("{} Invalid environment variable: {}", "[ERROR]".color_error_red().style_bold(),a.color_bright_orange());
            process::exit(1);
        }
        Err(_) => {
            eprintln!("{} Unknown error: could not setup server configuration.", "[ERROR]".color_error_red().style_bold());
            process::exit(1);
        }
    };
}
