mod client_communication;
pub mod errors;
mod staticroutes;

mod database;
mod tests;

#[macro_use]
extern crate rocket;
use std::{
    net::{IpAddr, Ipv4Addr, Ipv6Addr},
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
use cynthia_con::CynthiaColors;
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
                Err(LuminaError::ConfMissing(a)) => panic!(
                    "Missing environment variable {}, which is required to continue. Please make sure it is set, or change other variables to make it redundant, if possible.",
                    a.color_bright_orange()
                ),
                Err(LuminaError::ConfInvalid(a)) => {
                    panic!("Invalid environment variable: {}", a.color_bright_orange())
                }
                Err(LuminaError::Sqlite(a)) => panic!("Error opening sqlite database: {}", a),
                Err(LuminaError::Postgres(a)) => {
                    panic!("Error connecting to postgres database: {}", a)
                }
                Err(_) => panic!("Unknown error: could not setup database connection."),
            };
            let appstate = AppState(Arc::from((config.clone(), Mutex::from(db))));
            let mut def = rocket::Config::default();
            def.port = config.port;
            def.address = config.host;
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
                    println!("Error starting server: {:?}", e);
                }
                Err(_) => {
                    println!("Unknown error starting server.");
                }
            }
        }
        Err(LuminaError::ConfMissing(a)) => panic!(
            "Missing environment variable {}, which is required to continue. Please make sure it is set, or change other variables to make it redundant, if possible.",
            a.color_bright_orange()
        ),
        Err(LuminaError::ConfInvalid(a)) => {
            panic!("Invalid environment variable: {}", a.color_bright_orange())
        }
        Err(_) => panic!("Unknown error: could not setup server configuration."),
    };
}
