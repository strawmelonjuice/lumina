pub mod errors;

#[macro_use]
extern crate rocket;
use rocket::response;
use rocket::response::content::{RawCss, RawHtml, RawJavaScript};
use std::path::{Path, PathBuf};
use ws;

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
    RawCss(include_str!("../../client/priv/static/lumina_client.css").to_string())
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
                        "client-init" => {
                            let _ = stream
                                .send(ws::Message::from(msgtojson(Message::Greeting {
                                    greeting: "Hello from server!".to_string(),
                                })))
                                .await;
                        }
                        possibly_json => match serde_json::from_str::<Message>(possibly_json) {
                            Ok(jsonmsg) => {
                                todo!("Handle message: {:?}", jsonmsg);
                            }
                            Err(e) => {
                                let _ = stream.send(ws::Message::from("unknown")).await;
                            }
                        },
                    },
                    ws::Message::Close(_) => {
                        let _ = stream.send(ws::Message::Close(None)).await;
                        break;
                    }
                    _ => {
                        let _ = stream.send(ws::Message::from("unknown")).await;
                    }
                }
            }

            Ok(())
        })
    })
}

#[derive(serde::Serialize, serde::Deserialize, Debug)]
#[serde(tag = "type", rename_all = "snake_case")]
// An example of a JSON message that the client might send to the server:
// {"type": "client-init", "data": "hi"}
enum Message {
    #[serde(rename = "client-init")]
    ClientInit { data: String },
    #[serde(rename = "greeting")]
    Greeting { greeting: String },
    #[serde(rename = "serialisation_error")]
    SerialisationError { error: String },
    #[serde(rename = "unknown")]
    Unknown,
}
fn msgtojson(msg: Message) -> String {
    serde_json::to_string(&msg).unwrap_or_else(|e| {
        serde_json::to_string(&Message::SerialisationError {
            error: format!("{:?}", e),
        })
        .unwrap_or_else(|e| {
            format!(
                "{{\"type\": \"serialisation_error\", \"error\": \"{}\"}}",
                e
            )
        })
    })
}
