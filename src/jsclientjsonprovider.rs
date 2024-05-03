/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */

use actix_session::Session;
use actix_web::http::StatusCode;
use actix_web::web::Data;
use actix_web::HttpResponse;
use colored::Colorize;
use serde::{Deserialize, Serialize};
use tokio::sync::{Mutex, MutexGuard};

use crate::storage::fetch;
use crate::{Config, ServerVars};

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct JSClientData {
    pub instance: JSClientInstance,
    pub user: JSClientUser,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct JSClientInstance {
    pub config: JSClientConfig,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct JSClientConfig {
    pub interinstance: JSClientInterinstance,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct JSClientInterinstance {
    pub iid: String,
    pub lastpoll: i64,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct JSClientUser {
    pub username: String,
    pub id: i64,
}

pub(crate) async fn serves(server_z: Data<Mutex<ServerVars>>, _session: Session) -> HttpResponse {
    let server_y: MutexGuard<ServerVars> = server_z.lock().await;
    let config: Config = server_y.clone().config;
    let username_ = _session.get::<String>("username");
    (server_y.tell)(format!("Request/200\t\t{}", "/api/fe/update".green()));
    let json = serde_json::to_string(&JSClientData {
        instance: JSClientInstance {
            config: JSClientConfig {
                interinstance: JSClientInterinstance {
                    iid: "".to_string(),
                    lastpoll: 0,
                },
            },
        },
        user: JSClientUser {
            username: match username_.clone().unwrap_or(None) {
                Some(username) => username.to_string(),
                None => "unset".to_string(),
            },
            id: fetch(
                &config.clone(),
                String::from("Users"),
                "username",
                (match username_.unwrap_or(None) {
                    Some(username) => username.to_string(),
                    None => "unset".to_string(),
                }),
            )
            .unwrap()
            .unwrap()
            .parse()
            .unwrap(),
        },
    })
    .unwrap();
    HttpResponse::build(StatusCode::OK)
        .content_type("text/json; charset=utf-8")
        .body(json)
}
