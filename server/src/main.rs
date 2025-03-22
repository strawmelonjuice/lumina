mod client_communication;
pub mod errors;
mod staticroutes;

mod database;
mod tests;

#[macro_use]
extern crate rocket;
use std::sync::Arc;
use tokio::sync::Mutex;
mod user;
use tokio_postgres as postgres;
use tokio_sqlite as sqlite;
struct AppState(Arc<(ServerConfig, Mutex<DbConn>)>);

use database::DbConn;
use rocket::request::FromRequest;

#[derive(Debug, Clone)]
struct ServerConfig {
    port: u16,
    host: String,
}

extern crate dotenv;

use crate::errors::LuminaError;
use cynthia_con::CynthiaColors;
use dotenv::dotenv;

#[rocket::main]
async fn main() {
    dotenv().ok();

    let config = ServerConfig {
        port: 8000,
        host: "localhost".to_string(),
    };
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
        Err(LuminaError::Postgres(a)) => panic!("Error connecting to postgres database: {}", a),
        Err(_) => panic!("Unknown error: could not setup database connection."),
    };
    let appstate = AppState(Arc::from((config, Mutex::from(db))));
    let should_start_server = true;
    if should_start_server {
        let result = rocket::build()
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
    } else {
        // do something else
    }
}
