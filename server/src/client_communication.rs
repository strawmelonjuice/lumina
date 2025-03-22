use crate::AppState;
use crate::user::User;
use cynthia_con::CynthiaColors;
extern crate rocket;
use rocket::State;
use ws;

#[get("/connection")]
pub(crate) fn wsconnection<'k>(ws: ws::WebSocket, state: &'k State<AppState>) -> ws::Channel<'k> {
    use rocket::futures::{SinkExt, StreamExt};

    ws.channel(move |mut stream| {
        Box::pin(async move {
            let mut client_session_data: SessionData = SessionData {
                client_type: None,
                user: None,
            };
            while let Some(message) = stream.next().await {
                println!("Received message: {:?}", message);
                match message? {
                    ws::Message::Text(msg) => {
                        match msg.as_str() {
                            "ping" => {
                                let _ = stream.send(ws::Message::Text("pong".to_string())).await;
                            }
                            "client-init" => {
                                client_session_data.client_type = Some(ClientType::Web);
                                let _ = stream
                                    .send(ws::Message::from(msgtojson(Message::Greeting {
                                        greeting: "Hello from server!".to_string(),
                                    })))
                                    .await;
                            }
                            possibly_json => match serde_json::from_str::<Message>(possibly_json) {
                                Ok(Message::RegisterRequest {
                                    email,
                                    username,
                                    password,
                                }) => {
                                    // register the user
                                    {
                                        let appstate = state.0.clone();
                                        let db = &appstate.1.lock().await;
                                        match User::create_user(email, username, password, db).await
                                        {
                                            Ok(user) => {
                                                match User::create_session_token(user, db).await {
                                                    Ok((token, user)) => {
                                                        client_session_data.user =
                                                            Some(user.clone());
                                                        let _ = stream
                                                            .send(ws::Message::from(msgtojson(
                                                                Message::AuthSuccess {
                                                                    token,
                                                                    username: user.username,
                                                                },
                                                            )))
                                                            .await;
                                                    }
                                                    Err(_e) => {
                                                        // I would return a more specific error message
                                                        // to the client here, but if the server knows the
                                                        // error, the client should know the error twice as
                                                        // well.

                                                        let _ = stream
                                                            .send(ws::Message::from(msgtojson(
                                                                Message::AuthFailure,
                                                            )))
                                                            .await;
                                                    }
                                                }
                                            }

                                            Err(_e) => {
                                                // I would return a more specific error message
                                                // to the client here, but if the server knows the
                                                // error, the client should know the error twice as
                                                // well.

                                                let _ = stream
                                                    .send(ws::Message::from(msgtojson(
                                                        Message::AuthFailure,
                                                    )))
                                                    .await;
                                            }
                                        }
                                    }
                                    let _ = stream.send(ws::Message::from("unknown")).await;
                                }
                                Ok(jsonmsg) => {
                                    let _ = stream.send(ws::Message::from("unknown")).await;
                                    eprintln!(
                                        "todo: {}",
                                        format!("Handle message: {:?}", jsonmsg).color_error_red()
                                    );
                                }
                                Err(_e) => {
                                    let _ = stream.send(ws::Message::from("unknown")).await;
                                }
                            },
                        }
                    }
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

#[derive(serde::Serialize, serde::Deserialize, Debug, Clone)]
#[serde(tag = "type", rename_all = "snake_case")]
// An example of a JSON message that the client might send to the server:
// {"type": "client-init", "data": "hi"}
pub(crate) enum Message {
    #[serde(rename = "client-init")]
    ClientInit { data: String },
    #[serde(rename = "greeting")]
    Greeting { greeting: String },
    #[serde(rename = "serialisation_error")]
    SerialisationError { error: String },
    #[serde(rename = "login_authentication_request")]
    LoginAuthenticationRequest {
        email_username: String,
        password: String,
    },
    #[serde(rename = "register_request")]
    RegisterRequest {
        email: String,
        username: String,
        password: String,
    },
    #[serde(rename = "auth_success")]
    AuthSuccess { token: String, username: String },
    #[serde(rename = "auth_failure")]
    AuthFailure,
    #[serde(rename = "unknown")]
    Unknown,
}

pub(crate) fn msgtojson(msg: Message) -> String {
    serde_json::to_string(&msg).unwrap_or_else(|e| -> String {
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

pub(crate) struct SessionData {
    pub(crate) client_type: Option<ClientType>,
    pub(crate) user: Option<User>,
}

pub enum ClientType {
    Web,
    NativeApp,
}
