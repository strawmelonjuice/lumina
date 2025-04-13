use crate::user::User;
use crate::{AppState, LuminaError, database};
use cynthia_con::{CynthiaColors, CynthiaStyles};
extern crate rocket;
use rocket::State;

#[get("/connection")]
pub(crate) fn wsconnection<'k>(ws: ws::WebSocket, state: &'k State<AppState>) -> ws::Channel<'k> {
    use rocket::futures::{SinkExt, StreamExt};
    // Just a few log prefixes
    let info = "[INFO]".color_green().style_bold();
    let incoming = "[INCOMING]".color_lilac().style_bold();
    let registrationerror = "[RegistrationError]".color_bright_red().style_bold();
    // End of log prefixes
    ws.channel(move |mut stream| {
        Box::pin(async move {
            let mut client_session_data: SessionData = SessionData {
                client_type: None,
                user: None,
            };
            while let Some(message) = stream.next().await {
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
                                    println!(
                                        "{incoming} Register request: {} {}",
                                        email.clone().color_orange(),
                                        username.clone().color_bright_cyan()
                                    );

                                    // register the user
                                    {
                                        let appstate = state.0.clone();
                                        let db = &appstate.1.lock().await;
                                        match User::create_user(email.clone(), username.clone(), password, db).await
                                        {
                                            Ok(user) => {
                                                println!(
                                                    "{info} User created: {}",
                                                    user.clone().username.color_bright_cyan()
                                                );
                                                match User::create_session_token(user, db).await {
                                                    Ok((token, user)) => {
                                                        client_session_data.user =
                                                            Some(user.clone());
														println!(
															"{incoming} User {} authenticated",
															user.clone().username.color_bright_cyan()
														);
                                                        let _ = stream
                                                            .send(ws::Message::from(msgtojson(
                                                                Message::AuthSuccess {
                                                                    token,
                                                                    username: user.username,
                                                                },
                                                            )))
                                                            .await;
                                                    }
                                                    Err(e) => {
                                                    	match e {
                                                     				LuminaError::Postgres(e) =>
													                              			error!("Error creating session token: {:?}", e),
                            																LuminaError::SqlitePool(e) =>
                            																	warn!("Error creating session token: {:?}", e),
																_ => {}
                                                     }
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

                                            Err(e) => {
                                                match e {
                                                    LuminaError::RegisterUsernameInUse => {
                                                        println!(
                                                            "{registrationerror} User {} already exists",
                                                            username.clone().color_bright_cyan()
                                                        );
                                                    }
                                                    LuminaError::RegisterEmailNotValid => {
                                                        println!(
                                                            "{registrationerror} Email {} is not valid",
                                                            email.clone().color_bright_cyan()
                                                        );
                                                    }
                                                    LuminaError::RegisterUsernameInvalid(why) => {
                                                        println!(
                                                            "{registrationerror} Username '{}' is not valid: {}",
                                                            username.clone().color_bright_cyan(),
                                                            why
                                                        );
                                                    }
                                                    LuminaError::RegisterPasswordNotValid(why) => {
														println!(
															"{registrationerror} Password is not valid: {}",
															why
														);
													}
                                                    e => {
														println!(
															"{registrationerror} Error creating user: {:?}",
															e
														);
													}
                                                }

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
                                Ok(Message::RegisterPrecheck { email, username, password }) => {
                                    let appstate = state.0.clone();
                                    let db = &appstate.1.lock().await;
                                    match crate::user::register_validitycheck(email, username, password, db).await {
                                        Err(LuminaError::RegisterEmailInUse) => {
                                            let _ = stream.send(ws::Message::from(msgtojson(Message::RegisterPrecheckResponse {
                                                ok: false,
                                                why: "Email already in use".to_string(),
                                            }))).await;
                                        }
                                        Err(LuminaError::RegisterUsernameInUse) => {
                                            let _ = stream.send(ws::Message::from(msgtojson(Message::RegisterPrecheckResponse {
                                                ok: false,
                                                why: "Username already in use".to_string(),
                                            }))).await;
                                        }
                                        Err(LuminaError::RegisterEmailNotValid) => {
                                            let _ = stream.send(ws::Message::from(msgtojson(Message::RegisterPrecheckResponse {
                                                ok: false,
                                                why: "Email not valid".to_string(),
                                            }))).await;
                                        }
                                        Err(LuminaError::RegisterUsernameInvalid(why)) => {
                                            let _ = stream.send(ws::Message::from(msgtojson(Message::RegisterPrecheckResponse {
                                                ok: false,
                                                why: format!("Username invalid: {}", why),
                                            }))).await;
                                        }
                                        Err(LuminaError::RegisterPasswordNotValid(why)) => {
                                            let _ = stream.send(ws::Message::from(msgtojson(Message::RegisterPrecheckResponse {
                                                ok: false,
                                                why: format!("Password invalid: {}", why),
                                            }))).await;
                                        }
                                        Ok(_) => {
                                            let _ = stream.send(ws::Message::from(msgtojson(Message::RegisterPrecheckResponse {
                                                ok: true,
                                                why: "".to_string(),
                                            }))).await;
                                        }
                                        _ => {}
                                    }
                                }
                                Ok(Message::LoginAuthenticationRequest { email_username, password }) =>
                                {
									let appstate = state.0.clone();
                                        let db = &appstate.1.lock().await;
										let msgback = match User::authenticate(email_username.clone(), password, db).await {
                                    Ok((token, user)) => {
										println!("{incoming} User {} authenticated", user.clone().id.to_string().color_bright_cyan());
										client_session_data.user =
                                                            Some(user.clone());
										client_session_data.user = Some(user.clone());
										Message::AuthSuccess { token, username: user.username }
									}
								,
                                    Err(s) => {
										match s {
											LuminaError::AuthenticationWrongPassword => {
												println!("{registrationerror} User {} {} authenticated: Incorrect credentials", email_username.clone().color_bright_cyan(), "not".color_red());
											}
											LuminaError::AuthenticationUserNotFound => {
												println!("{registrationerror} User {} {} authenticated: User not found", email_username.clone().color_bright_cyan(), "not".color_red());
											}
											_ => {
												println!("{registrationerror} User {} {} authenticated: {:?}", email_username.clone().color_bright_cyan(), "not".color_red(), s);
											}
										}
										Message::AuthFailure

									},
                                };
									let _ = stream.send(ws::Message::from(msgtojson(msgback))).await;
                                }
                                Ok(jsonmsg) => {
                                    panic!("Unhandled message: {:?}", jsonmsg);
                                }
                                Err(e) => {
                                    error!("Error deserialising message: {:?}", e);
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
    #[serde(rename = "register_precheck")]
    RegisterPrecheck {
        email: String,
        username: String,
        password: String,
    },
    #[serde(rename = "register_precheck_response")]
    RegisterPrecheckResponse { ok: bool, why: String },
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
