/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */

//! ## API's to the front-end.
//! This module contains the API endpoints for the frontend, most of them being Actix request factories.

use actix_session::Session;
use actix_web::http::header::{CacheControl, CacheDirective};
use actix_web::http::StatusCode;
use actix_web::web::Data;
use actix_web::{HttpRequest, HttpResponse};
use colored::Colorize;
use serde::{Deserialize, Serialize};
use tokio::sync::{Mutex, MutexGuard};

use crate::database::fetch::user_by_id;
use crate::database::users::auth::{check, AuthResponse};
use crate::database::users::{add, SafeUser};
use crate::database::{self};
use crate::{LuminaConfig, ServerVars};

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
struct FEJSonObj {
    // pub pulled: i128,
    pub instance: FEJsonObjInstanceInfo,
    pub user: SafeUser,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
struct FEJsonObjInstanceInfo {
    pub iid: String,
    pub last_sync: i64,
}

pub enum ShieldValue {
    Notsafe(HttpResponse),
    Safe,
}
async fn shield(
    session: Session,
    server_vars_mutex: &Data<Mutex<ServerVars>>,
    halt: HttpResponse,
) -> ShieldValue {
    let server_vars = ServerVars::grab(server_vars_mutex).await;
    let config = server_vars.clone().config;
    let id_ = session.get::<i64>("userid").unwrap_or(None);
    let id = id_.unwrap_or(-100);
    let safe = checksessionvalidity(id, &session, &config);
    if !safe {
        session.purge();
        ShieldValue::Notsafe(halt)
    } else {
        ShieldValue::Safe
    }
}

pub(crate) fn checksessionvalidity(id: i64, session: &Session, config: &LuminaConfig) -> bool {
    match id {
        -100 => false,
        _ => match session.get::<i64>("validity") {
            Ok(s) => matches!(s, Some(a) if a == config.clone().erun.session_valid),
            Err(_) => false,
        },
    }
}

pub(crate) async fn update(
    server_vars_mutex: Data<Mutex<ServerVars>>,
    session: Session,
    req: HttpRequest,
) -> HttpResponse {
    let server_vars: ServerVars = ServerVars::grab(&server_vars_mutex).await;
    let config: LuminaConfig = server_vars.clone().config;
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    let username_a = session.get::<String>("username");
    let username_b = username_a.unwrap_or(None).unwrap_or(String::from(""));
    let username_c = if username_b != *"" {
        format!("/{}", username_b.green())
    } else {
        String::from("")
    };
    info!(
        "{}\t{:>45.47}\t\t{}{:<26}",
        "Request/200".bright_green(),
        "/api/fe/update".magenta(),
        ip.yellow(),
        username_c
    );
    let mut d: FEJSonObj = FEJSonObj {
        // pulled: -1,
        instance: FEJsonObjInstanceInfo {
            iid: config.lumina_synchronisation_iid.clone(),
            last_sync: -1,
        },
        user: SafeUser {
            username: "unset".to_string(),
            id: -1,
            email: "unset".to_string(),
        },
    };
    let userd_maybe = database::fetch::user(
        &config,
        database::fetch::UserDataDiscriminator::Username(username_b),
    )
    .unwrap_or(None);
    if let Some(userd) = userd_maybe {
        d.user = SafeUser {
            username: userd.username,
            id: userd.id,
            email: userd.email,
        };
    };
    HttpResponse::build(StatusCode::OK)
        .insert_header(CacheControl(vec![CacheDirective::NoCache]))
        .content_type("text/json; charset=utf-8")
        .body(serde_json::to_string(&d).unwrap())
}
#[derive(Deserialize)]
pub(super) struct AuthReqData {
    username: String,
    password: String,
}

pub(crate) async fn auth(
    server_vars_mutex: Data<Mutex<ServerVars>>,
    session: Session,
    req: HttpRequest,
    data: actix_web::web::Json<AuthReqData>,
) -> HttpResponse {
    let server_vars = ServerVars::grab(&server_vars_mutex).await;
    let config = server_vars.clone().config;
    server_vars.tell("Auth request received.");
    let result = check(
        data.username.clone(),
        data.password.clone(),
        &server_vars_mutex,
    )
    .await;
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    match result {
        AuthResponse::Success(user_id) => {
            let user = user_by_id(&config, user_id).unwrap();
            let username = user.username;
            info!("User '{0}' logged in succesfully from {1}", username, ip);
            session.insert("userid", user.id).unwrap();
            session.insert("username", username).unwrap();
            session
                .insert("validity", config.clone().erun.session_valid)
                .unwrap();
            HttpResponse::build(StatusCode::OK)
                .insert_header(CacheControl(vec![CacheDirective::NoCache]))
                .content_type("text/json; charset=utf-8")
                .body(r#"{"Ok": true, "Errorvalue": ""}"#)
        }
        _ => HttpResponse::build(StatusCode::UNAUTHORIZED)
            .insert_header(CacheControl(vec![CacheDirective::NoCache]))
            .content_type("text/json; charset=utf-8")
            .body(r#"{"Ok": false}"#),
    }
}

#[derive(Deserialize)]
pub(super) struct AuthCreateUserReqData {
    username: String,
    email: String,
    password: String,
}
pub(crate) async fn newaccount(
    server_vars_mutex: Data<Mutex<ServerVars>>,
    session: Session,
    req: HttpRequest,
    data: actix_web::web::Json<AuthCreateUserReqData>,
) -> HttpResponse {
    let server_vars = ServerVars::grab(&server_vars_mutex).await;
    let config = server_vars.clone().config;
    server_vars.tell("User creation request: received.");
    let result = add(
        data.username.clone(),
        data.email.clone(),
        data.password.clone(),
        &config.clone(),
    );
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    match result {
        Ok(user_id) => {
            let user = database::fetch::user_by_id(&config, user_id).unwrap();
            let username = user.username;
            session.insert("userid", user.id).unwrap();
            session.insert("username", username).unwrap();
            session
                .insert("validity", config.clone().erun.session_valid)
                .unwrap();
            server_vars.tell(format!(
                "User creation request: approved for {} @ {}",
                user.id, ip
            ));
            HttpResponse::build(StatusCode::OK)
                .insert_header(CacheControl(vec![CacheDirective::NoCache]))
                .content_type("text/json; charset=utf-8")
                .body(r#"{"Ok": true}"#)
        }
        Err(e) => {
            server_vars.tell(format!("User creation request:  denied - {e}"));
            HttpResponse::build(StatusCode::EXPECTATION_FAILED)
                .insert_header(CacheControl(vec![CacheDirective::NoCache]))
                .content_type("text/json; charset=utf-8")
                .body(format!(r#"{{"Ok": false, "Errorvalue": "{}"}}"#, e))
        }
    }
}
#[derive(Deserialize)]
pub struct FEPageServeRequest {
    location: String,
}
#[derive(Serialize)]
struct FEPageServeResponse {
    main: String,
    side: String,
    /*
     * Message Numbers and Corresponding Messages:
     *
     * 1: "It seems your session has expired."
     * 2: "This page does not exist according to the instance server."
     * 33: "Notification centre - special page."
     * 34: Content from `STR_ASSETS_EDITOR_WINDOW_HTML`
     *
     * 9** messages notify the client to use certain templates to parse the data in. These are always
     * accompanied by a 899 code.
     * 901: "Homepage/timelines left+right"
     * 909: "Notification centre"
     */
    message: Vec<i64>,
}
pub(crate) async fn pageservresponder(
    server_vars_mutex: Data<Mutex<ServerVars>>,
    session: Session,
    _req: HttpRequest,
    data: actix_web::web::Json<FEPageServeRequest>,
) -> HttpResponse {
    match shield(
        session.clone(),
        &server_vars_mutex,
        HttpResponse::build(StatusCode::OK)
            .insert_header(CacheControl(vec![CacheDirective::NoCache]))
            .content_type("text/json; charset=utf-8")
            .body(
                serde_json::to_string(&FEPageServeResponse {
                    main: String::from("It seems your session has expired."),
                    side: String::new(),
                    message: vec![1],
                })
                .unwrap(),
            ),
    )
    .await
    {
        ShieldValue::Notsafe(o) => o,
        ShieldValue::Safe => {
            let config = {
                let server_vars: MutexGuard<ServerVars> = server_vars_mutex.lock().await;
                server_vars.clone().config.clone()
            };
            // These three WILL be used in the future, when pages actually get dynamic.
            let location = data.location.clone();
            let id_ = session.get::<i64>("userid").unwrap_or(Some(-100));
            let id = id_.unwrap_or(-100);
            let user: database::users::User = database::fetch::user_by_id(&config, id).unwrap();
            let server_vars = server_vars_mutex.lock().await.clone();
            let config: LuminaConfig = server_vars.clone().config;
            let o: FEPageServeResponse = match location.as_str() {
                "home" => FEPageServeResponse {
                    main: serde_json::to_string(&subpagedata::HomePageData {
                        username: user.username,
                        instance_name: config.lumina_synchronisation_iid,
                    })
                    .unwrap(),
                    side: String::new(),
                    message: vec![899, 901],
                },
                "test" => FEPageServeResponse {
                    message: vec![],
                    side: String::new(),
                    main: {
                        let mut s = format!(
                            "<h1>Post fetched from DB (dynamically rendered using HandleBars)</h1>\n{}\n",
                            &database::fetch::post(&config, 1)
                                .unwrap()
                                .unwrap()
                                .to_formatted(&config)
                                .to_html()
                        );
                        s.push_str(include_str!("../frontend_assets/html/examplepost.html"));
                        s
                    },
                },
                "notifications-centre" => FEPageServeResponse {
                    main: String::from("Notifications should show up here!"),
                    side: String::from(""),
                    message: vec![33],
                },
                "editor" => FEPageServeResponse {
                    main: String::from(crate::assets::STR_ASSETS_EDITOR_WINDOW_HTML),
                    side: String::from(""),
                    message: vec![34],
                },

                _ => {
                    return HttpResponse::build(StatusCode::OK)
                        .insert_header(CacheControl(vec![CacheDirective::NoCache]))
                        .content_type("text/json; charset=utf-8")
                        .body(
                            serde_json::to_string(&FEPageServeResponse {
                                main: String::from(
                                    "This page does not exist according to the instance server.",
                                ),
                                side: String::new(),
                                message: vec![2],
                            })
                            .unwrap(),
                        )
                }
            };
            HttpResponse::build(StatusCode::OK)
                .content_type("text/json; charset=utf-8")
                .insert_header(CacheControl(vec![CacheDirective::NoCache]))
                .body(serde_json::to_string(&o).unwrap())
        }
    }
}
#[derive(Deserialize)]
pub struct FEUsernameCheckRequest {
    u: String,
}

pub(crate) async fn check_username(
    server_vars_mutex: Data<Mutex<ServerVars>>,
    data: actix_web::web::Json<FEUsernameCheckRequest>,
) -> HttpResponse {
    let server_vars = ServerVars::grab(&server_vars_mutex).await;
    let config = server_vars.clone().config;
    let username = data.u.clone();
    if database::users::char_check_username(username.clone()) {
        return HttpResponse::build(StatusCode::OK)
            .content_type("text/json; charset=utf-8")
            .insert_header(CacheControl(vec![CacheDirective::NoCache]))
            .body(r#"{"Ok": false, "Why": "InvalidChars"}"#.to_string());
    }
    if username.len() < 4 {
        return HttpResponse::build(StatusCode::OK)
            .content_type("text/json; charset=utf-8")
            .insert_header(CacheControl(vec![CacheDirective::NoCache]))
            .body(r#"{"Ok": false, "Why": "TooShort"}"#.to_string());
    }
    if database::fetch::user(
        &config.clone(),
        database::fetch::UserDataDiscriminator::Username(username.clone()),
    )
    .unwrap_or(None)
    .is_some()
    {
        return HttpResponse::build(StatusCode::OK)
            .content_type("text/json; charset=utf-8")
            .insert_header(CacheControl(vec![CacheDirective::NoCache]))
            .body(r#"{"Ok": false, "Why": "userExists"}"#.to_string());
    };
    HttpResponse::build(StatusCode::OK)
        .content_type("text/json; charset=utf-8")
        .insert_header(CacheControl(vec![CacheDirective::NoCache]))
        .body(r#"{"Ok": true}"#)
}

#[derive(Deserialize)]
pub struct EditorContent {
    a: String,
}
#[derive(Serialize, Deserialize)]
struct EditorResponse {
    #[serde(rename = "Ok")]
    ok: bool,
    #[serde(rename = "htmlContent")]
    html_content: String,
}
pub(crate) async fn render_editor_articlepost(
    server_vars_mutex: Data<Mutex<ServerVars>>,
    data: actix_web::web::Json<EditorContent>,
) -> HttpResponse {
    let server_vars = ServerVars::grab(&server_vars_mutex).await;
    let _config = server_vars.clone().config;
    let unprocessed_md = data.a.clone();

    let processed_md =
        match markdown::to_html_with_options(unprocessed_md.as_str(), &markdown::Options::gfm()) {
            Ok(html) => html,
            Err(_) => {
                return HttpResponse::build(StatusCode::OK)
                    .content_type("text/json; charset=utf-8")
                    .insert_header(CacheControl(vec![CacheDirective::NoCache]))
                    .body(
                        serde_json::to_string(&EditorResponse {
                            ok: false,
                            html_content: String::from("Markdown processing failed."),
                        })
                        .unwrap(),
                    );
            }
        };
    let readied_html = processed_md
        .replace(r#"<img "#, r#"<img class="max-w-9/12" "#)
        .replace(r#"<a "#, r#"<a class="text-blue-400" "#)
        .replace(r#"<code>"#, r#"<code class="m-1 text-stone-500 bg-slate-200 dark:text-stone-200 dark:bg-slate-600">"#)
        .replace(r#"<blockquote>"#, r#"<blockquote class="p-0 [&>*]:pl-2 ml-3 mr-3 border-gray-300 border-s-4 bg-gray-50 dark:border-gray-500 dark:bg-gray-800">"#);
    HttpResponse::build(StatusCode::OK)
        .insert_header(CacheControl(vec![CacheDirective::NoCache]))
        .content_type("text/json; charset=utf-8")
        .body(
            serde_json::to_string(&EditorResponse {
                ok: true,
                html_content: readied_html,
            })
            .unwrap(),
        )
}

mod subpagedata {
    use serde::Serialize;

    #[derive(Serialize)]
    #[serde(rename_all = "snake_case")]
    pub(super) struct HomePageData {
        pub(super) username: String,
        pub(super) instance_name: String,
    }
}

mod media;
