//! Lumina > Server > Client Communication
//!
//! This module handles communication between the Lumina server and its clients
//! over WebSockets. It defines the message formats, handles incoming messages,
//! and sends appropriate responses back to the clients.
//!
//! For future clients that might not be web-based, this module is designed to be
//! extensible and adaptable to different client types.
//! It might for example be expanded to also feature a REST API for clients that
//! cannot use WebSockets.

/*
 *     Lumina/Peonies
 *     Copyright (C) 2018-2026 MLC 'Strawmelonjuice'  Bloeiman and contributors.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU Affero General Public License as published
 *     by the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU Affero General Public License for more details.
 *
 *     You should have received a copy of the GNU Affero General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

extern crate rocket;
use crate::rate_limiter::RateLimit;
use crate::timeline::fetch_timeline_post_ids_by_timeline_name;
use crate::user::User;
use crate::{
    AppState, LuminaError, authentication_error_elog, error_elog, http_code_elog, incoming_elog,
    info_elog, registration_error_elog, warn_elog,
};
use base64::Engine;
use base64::engine::general_purpose::STANDARD;
use cynthia_con::{CynthiaColors, CynthiaStyles};
use rocket::State;
use std::net::IpAddr;
use uuid::Uuid;

#[get("/connection")]
pub(crate) async fn wsconnection<'k>(
    ws: ws::WebSocket,
    state: &'k State<AppState>,
    _rate_limit: RateLimit,
    _limiter: &'k State<crate::rate_limiter::GeneralRateLimiter>,
    auth_limiter: &'k State<crate::rate_limiter::AuthRateLimiter>,
    client_ip: Option<IpAddr>,
) -> ws::Channel<'k> {
    let ev_log = {
        let appstate = state.0.clone();
        appstate.event_logger.clone().await
    };
    http_code_elog!(ev_log, 200, "/connection");
    use rocket::futures::{SinkExt, StreamExt};

    ws.channel(move |mut stream| {
		Box::pin(async move {
			http_code_elog!(ev_log, 101, "/connection");
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
							possibly_json => {
								match serde_json::from_str::<Message>(possibly_json) {
									Ok(Message::Introduction { client_kind, try_revive }) => {
										match client_kind.as_str() {
											"web" => {
												client_session_data.client_type = Some(ClientType::Web)
											}
											"mobile" => todo!(),
											_ => {}
										}
										match try_revive {
											Some(token) => {
												let appstate = state.0.clone();
												let db = &appstate.db.lock().await;
												match User::revive_session_from_token(token.clone(), db).await {
													Ok(user) => {
														incoming_elog!(ev_log, "Session revived for user: {}",
				                            user.clone().username.color_bright_cyan()
			                            );
														client_session_data.user = Some(user.clone());
														let _ = stream
															.send(ws::Message::from(msgtojson(Message::AuthSuccess {
																token,
																username: user.username,
															})))
															.await;
													}
													Err(e) => {
														match e {
															LuminaError::Postgres(postgres_error) => {
																// Check if it's a "no rows returned" type error
																if postgres_error.to_string().contains("no rows") || postgres_error.to_string().contains("RowCount") {
																	info_elog!( ev_log,"Session revival failed: token not found or expired.");
																} else {
																	info_elog!(ev_log,"Session revival failed: database error: {:?}", postgres_error);
																}
															}

															_ => {
																info_elog!(ev_log,"Session revival failed: {:?}", e);
															}
														}
														let _ = stream
															.send(ws::Message::from(msgtojson(Message::AuthFailure)))
															.await;
													}
												}
											}
											None => {
												let _ = stream
													.send(ws::Message::from(msgtojson(Message::Greeting {
														greeting: "Hello from server!".to_string(),
													})))
													.await;
											}
										}
									}
									Ok(Message::RegisterRequest {
										   email,
										   username,
										   password,
									   }) => {
										incoming_elog!(
                                                                ev_log,
                                                                    "Register request: {} {}",
                                                                    email.clone().color_orange(),
                                                                    username.clone().color_bright_cyan()
                                                                );

										// register the user
										{
											let appstate = state.0.clone();
											let db = &appstate.db.lock().await;
											match User::create_user(email.clone(), username.clone(), password, db).await
											{
												Ok(user) => {
													info_elog!(
                                                                            ev_log,
                                                                                "User created: {}",
                                                                                user.clone().username.color_bright_cyan()
                                                                            );
													match User::create_session(user, db, ev_log.clone().await).await {
														Ok((session_reference, user)) => {
															client_session_data.user =
																Some(user.clone());
															incoming_elog!(ev_log,"User {} authenticated.",
                            user.clone().username.color_bright_cyan()
				                            );
															let _ = stream
																.send(ws::Message::from(msgtojson(
																	Message::AuthSuccess {
																		token: session_reference.token,
																		username: user.username,
																	},
																)))
																.await;
														}
														Err(e) => {
															match e {
																LuminaError::Postgres(e) =>
																	error_elog!(ev_log,"While creating session token: {:?}", e),
																LuminaError::R2D2Pool(e) =>
																	warn_elog!(ev_log,"There was an error creating session token: {:?}", e),
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
															registration_error_elog!(ev_log, "User {} already exists",
                                                                                        username.clone().color_bright_cyan()
                                                                                    );
														}
														LuminaError::RegisterEmailNotValid => {
															registration_error_elog!(ev_log, "Email {} is not valid",
                                                                                        email.clone().color_bright_cyan()
                                                                                    );
														}
														LuminaError::RegisterUsernameInvalid(why) => {
															registration_error_elog!(ev_log, "Username '{}' is not valid: {}",
                                                                                        username.clone().color_bright_cyan(),
                                                                                        why
                                                                                    );
														}
														LuminaError::RegisterPasswordNotValid(why) => {
															registration_error_elog!(ev_log, "Password is not valid: {}",
                            why
				                            );
														}
														e => {
															registration_error_elog!(ev_log, "Error creating user: {:?}",
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
									}
									Ok(Message::RegisterPrecheck { email, username, password }) => {
										let appstate = state.0.clone();
										let db = &appstate.db.lock().await;
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
									Ok(Message::LoginAuthenticationRequest { email_username, password }) => {
										// Quick pre-check: if the limiter says this IP is blocked, avoid DB work.
										if !auth_limiter.allow_ip(client_ip).await {
											authentication_error_elog!(ev_log, "Rate-limited authentication attempt from IP: {:?}", client_ip);
											let _ = stream.send(ws::Message::from(msgtojson(Message::AuthFailure))).await;
										} else {
											let appstate = state.0.clone();
											let db = &appstate.db.lock().await;
											let msgback = match User::authenticate(email_username.clone(), password, db, ev_log.clone().await).await {
												Ok((session_reference, user)) => {
													incoming_elog!(ev_log,"User {} authenticated to session with id {}.\n{}", user.username.clone().color_bright_cyan(), session_reference.session_id.to_string().color_pink(), format!("(User id: {})", user.id).style_dim());
													client_session_data.user = Some(user.clone());
													Message::AuthSuccess { token: session_reference.token, username: user.username }
												}
												Err(s) => {
													match s {
														LuminaError::AuthenticationWrongPassword => {
															authentication_error_elog!(ev_log,"User {} {} authenticated: Incorrect credentials", email_username.color_bright_cyan(), "not".color_red());
														}
														// LuminaError::AuthenticationUserNotFound => {
														// 	authentication_error_elog!(ev_log,"User {} {} authenticated: User not found", email_username.color_bright_cyan(), "not".color_red());
														// }
														_ => {
															authentication_error_elog!(ev_log,"User {} {} authenticated: {:?}", email_username.color_bright_cyan(), "not".color_red(), s);
														}
													}
													Message::AuthFailure
												}
											};
											let _ = stream.send(ws::Message::from(msgtojson(msgback))).await;
										}
									}
									Ok(Message::OwnUserInformationRequest) => {
										// Handle request for user's own information
										match &client_session_data.user {
											Some(user) => {
												// For now, send back basic user info as a greeting
												// This could be expanded to a proper user info response message type
												let response = Message::OwnUserInformationResponse {
													username: user.username.clone(),
													email: user.email.clone(),
													// Provide a compile-time included SVG placeholder avatar when none is available.
													// The SVG file is included as bytes and base64-encoded here.
													avatar: Some((
														"image/svg+xml".to_string(),
														// Encode the included SVG bytes as base64 at compile time.
														STANDARD.encode(include_bytes!("../../assets/svgs/dummy_user_120px.svg")),
													)),
													uuid: user.id.to_string(),
												};
												let msg_json = msgtojson(response);
												// println!("Sending own user information response: {}", msg_json);
												let _ = stream.send(ws::Message::from(msg_json)).await;
											}
											None => {
												let _ = stream.send(ws::Message::from(msgtojson(Message::AuthFailure))).await;
											}
										}
									}
									Ok(Message::TimelineRequest { by_name: name, page }) => {
										let appstate = state.0.clone();
										let db = &appstate.db.lock().await;
										// Fetch post IDs for the requested timeline
										match fetch_timeline_post_ids_by_timeline_name(
											ev_log.clone().await,
											db,
											&name,
											client_session_data.user.clone().unwrap(),
											page,
										).await {
											Ok((tlid, post_ids, total_count, has_more)) => {
												let response = Message::TimelineResponse {
													post_ids,
													timeline_name: name,
													timeline_id: tlid,
													total_count,
													page: page.unwrap_or(0),
													has_more,
												};
												let _ = stream.send(ws::Message::from(msgtojson(response))).await;
											}
											Err(e) => {
												error_elog!(ev_log, "Error fetching timeline: {:?}", e);
												let _ = stream.send(ws::Message::from(msgtojson(Message::SerialisationError {
													error: format!("{:?}", e),
												}))).await;
											}
										}
									}
									// Responding variants are not supposed to ever arrive here.
									Ok(Message::ClientInit { .. }) |
									Ok(Message::Greeting { .. }) | Ok(Message::SerialisationError { .. })
									| Ok(Message::RegisterPrecheckResponse { .. })
									| Ok(Message::AuthSuccess { .. })
									| Ok(Message::AuthFailure)
									| Ok(Message::MediaPostDataSent { .. })
									| Ok(Message::TextPostDataSent { .. })
									| Ok(Message::ArticlePostDataSent { .. })
									| Ok(Message::OwnUserInformationResponse { .. })
									| Ok(Message::TimelineResponse { .. }) => {
										panic!("These messages should never arrive here.")
									}
									// This one makes sense.
									Ok(Message::Unknown) => {
										panic!("Unknown message received?")
									}
									// And to handle straight up errors:
									Err(e) => {
										error_elog!(ev_log, "Error deserialising message: {:?}\n\n{}" , e,
                                                            format!("The message: {}", possibly_json).style_dim()
                                                            );
										let _ = stream.send(ws::Message::from("unknown")).await;
									}
								}
							}
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
    #[serde(rename = "introduction")]
    Introduction {
        client_kind: String,
        try_revive: Option<String>,
    },
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
    #[serde(rename = "data_article_post")]
    ArticlePostDataSent {
        post_id: Uuid,
        /// Source instance. 'local' by default, hostname if external.
        source_instance: String,
        title: String,
        content: String,
        /// Unix timestamp of the moment of posting
        timestamp: u64,
        /// User id of poster, which is why the source_instance matters.
        /// This means that client will do a lookup and stores the user once it gets it.
        author_id: String,
    },
    #[serde(rename = "data_embed_post")]
    MediaPostDataSent {
        post_id: Uuid,
        /// Source instance. 'local' by default, hostname if external.
        source_instance: String,
        /// Media description
        description: String,
        /// Base64 encoded media strings, either webp or mp4.
        medias: Vec<String>,
    },
    #[serde(rename = "data_textual_post")]
    TextPostDataSent {
        post_id: Uuid,
        /// Source instance. 'local' by default, hostname if external.
        source_instance: String,
        /// Markdown content.
        content: String,
    },
    #[serde(rename = "own_user_information_request")]
    /// Request for the server to send back the user's own information.
    /// This is used to get the user's own information after logging in.
    OwnUserInformationRequest,
    #[serde(rename = "own_user_information_response")]
    /// Response to the `OwnUserInformationRequest` containing the user's own information.
    OwnUserInformationResponse {
        username: String,
        email: String,
        // Optional field populated with mime type and base64 of a profile picture.
        avatar: Option<(String, String)>,
        uuid: String,
    },
    /// Requests a list of strings to represent a certain timeline or bubble timeline.
    #[serde(rename = "timeline_request")]
    TimelineRequest {
        by_name: String,
        #[serde(default)]
        page: Option<usize>,
    },
    TimelineResponse {
        timeline_name: String,
        timeline_id: Uuid,
        /// A list of post IDs for the requested timeline.
        post_ids: Vec<String>,
        /// Total number of posts in timeline
        total_count: usize,
        /// Current page number
        page: usize,
        /// Whether there are more pages available
        has_more: bool,
    },

    /// "Yeah I don't know what I'm sending either!"
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
    // NativeApp will one day mean a native application, like a mobile app.
    // For now, it is nothing.
	#[expect(dead_code, reason="Will be used when other clients are added.")]
    NativeApp,
}
