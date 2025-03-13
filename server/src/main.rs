#[macro_use]
extern crate rocket;
use rocket::response;
use rocket::response::content::{RawCss, RawHtml, RawJavaScript};
use std::path::{Path, PathBuf};
use ws::Message;

#[get("/")]
async fn index() -> RawHtml<String> {
    RawHtml(include_str!("../../client/index.html").to_string())
}

#[get("/static/lumina.min.mjs")]
async fn lumina_js() -> RawJavaScript<String> {
    RawJavaScript(include_str!("../../client/priv/static/lumina_client.min.mjs").to_string())
}

#[get("/static/lumina.css")]
async fn lumina_css() -> RawCss<String> {
    RawCss(include_str!("../../client/priv/static/lumina_client.min.css").to_string())
}

#[rocket::main]
async fn main() {
    let should_start_server = true; // for now
    if should_start_server {
        let result = rocket::build()
            .mount("/", routes![index, lumina_js, lumina_css, wsconnection])
            .launch()
            .await;
        match result {
            Ok(_) => {}
            Err(e) => {
                println!("Error starting server: {:?}", e);
            }
        }
    } else {
        // do something else
    }
}

#[get("/connection")]
fn wsconnection(ws: ws::WebSocket) -> ws::Channel<'static> {
    use rocket::futures::{SinkExt, StreamExt};

    ws.channel(move |mut stream| {
        Box::pin(async move {
            while let Some(message) = stream.next().await {
                println!("Received message: {:?}", message);
                match message? {
                    ws::Message::Text(msg) => match msg.as_str() {
                        "ping" => {
                            let _ = stream.send(ws::Message::Text("pong".to_string())).await;
                        }
                        "close" => {
                            break;
                        }
                        "client-init" => {
                            let _ = stream.send(Message::from("client-init")).await;
                        }
                        _ => {
                            let _ = stream.send(Message::from("unknown")).await;
                        }
                    },
                    _ => {
                        let _ = stream.send(Message::from("unknown")).await;
                    }
                }
            }

            Ok(())
        })
    })
}
