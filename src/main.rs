use std::process;

use actix_web::{get, post, web, App, HttpResponse, HttpServer, Responder};
use serde::{Deserialize, Serialize};

use log::error;

use crate::log::info;

mod instance_poller;
mod log;

#[derive(Deserialize, Debug, Serialize)]
struct Config {
    adress: String,
    port: u16,
    pollinterval: u64,
}

#[actix_web::main]
async fn main() {
    let config = Config {
        adress: String::from("127.0.0.1"),
        port: 8080,
        pollinterval: 120,
    };
    let main_server = match HttpServer::new(|| {
        App::new()
            .service(api)
            .service(echo)
            .route("/", web::get().to(root))
    })
    .bind((config.adress.clone(), config.port))
    {
        Ok(o) => {
            info(format!(
                "Running on http://{0}:{1}/",
                config.adress, config.port
            ));
            o
        }
        Err(s) => {
            error(format!(
                "Could not bind to {}:{}, error message: {}",
                config.adress,
                config.port,
                s.to_string()
            ));
            process::exit(1);
        }
    }
    .run();
    let _ = futures::join!(instance_poller::main(config.pollinterval), main_server);
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
