use std::io::Write;
use std::{fs, process, path::Path};

use actix_web::{get, post, web, App, HttpResponse, HttpServer, Responder};
use serde::{Deserialize, Serialize};

use log::error;

use crate::log::info;

mod instance_poller;
mod log;

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Config {
    pub server: Server,
    pub interinstance: Interinstance,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Server {
    pub port: u16,
    pub adress: String,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Interinstance {
    pub synclist: Vec<String>,
    pub ignorelist: Vec<String>,
    pub polling: Polling,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Polling {
    pub pollintervall: u64,
}


#[actix_web::main]
async fn main() {
    let config: Config = (|| {
        let confp = Path::new("./env.toml");
    if (!confp.is_file()) || (!confp.exists()) {
        let mut output = match fs::File::create(confp) {
            Ok(p) => p,
            Err(a) => {
                error(format!("Could not create blank config file. The system returned: {}", a));
                process::exit(1);
            }
        };

        match write!(output, r#"[server]
# What port to bind to (the server is designed with apache2 reverse-proxy in mind, so 80 is not necesarily default.)
port = 8085
# What adress to bind to? Usually, this is 127.0.0.1 for dev, and 0.0.0.0 for prod.
adress = "0.0.0.0"

[interinstance]
# Specifies instances to send sync requests to. Note that these are only answered if both servers have each other listed. If not, the admin's will get a request to add them, but don't necessarily have to.
synclist = []
# Ignored instances are no longer allowed to send requests to join this instance's synclist.
ignorelist = []
[interinstance.polling]
# Specifies the interval between polls. Minimum is 30.
pollintervall = 120
"#) {
            Ok(p) => p,
            Err(a) => {
                error(format!("Could not create blank config file. The system returned: {}", a));
                process::exit(1);
            }
        };
    }
       return match fs::read_to_string(Path::new("./env.toml")) {
        Ok(g) => match toml::from_str(&g) {
            Ok(p) => p,
            Err(_e) => {
                error(format!("Could not interpret server configuration at `{}`!", confp.canonicalize().unwrap_or(confp.to_path_buf()).to_string_lossy().replace("\\\\?\\","")));
                process::exit(1);
            }
        },
        Err(_) => {
            error(format!("Could not interpret server configuration at `{}`!", confp.canonicalize().unwrap_or(confp.to_path_buf()).to_string_lossy().replace("\\\\?\\","")));
            process::exit(1);
        }
    }})();
    let main_server = match HttpServer::new(|| {
        App::new()
            .service(api)
            .service(echo)
            .route("/", web::get().to(root))
    })
    .bind((config.server.adress.clone(), config.server.port))
    {
        Ok(o) => {
            info(format!(
                "Running on http://{0}:{1}/",
                config.server.adress, config.server.port
            ));
            o
        }
        Err(s) => {
            error(format!(
                "Could not bind to {}:{}, error message: {}",
                config.server.adress,
                config.server.port,
                s
            ));
            process::exit(1);
        }
    }
    .run();
    let _ = futures::join!(instance_poller::main(config.interinstance.polling.pollintervall), main_server);
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
