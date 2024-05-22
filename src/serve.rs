/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */

use crate::database::{BasicUserInfo, IIExchangedUserInfo};
use crate::{LuminaConfig, ServerVars};
use actix_session::Session;
use actix_web::http::header::LOCATION;
use actix_web::http::StatusCode;
use actix_web::web::Data;
use actix_web::{HttpRequest, HttpResponse, Responder};
use colored::Colorize;
use tokio::sync::{Mutex, MutexGuard};

pub(super) async fn notfound(
    server_z: Data<Mutex<ServerVars>>,
    req: HttpRequest,
    session: Session,
) -> HttpResponse {
    let server_y = server_z.lock().await;
    let _server_p: ServerVars = server_y.clone();
    let username_ = session.get::<String>("username");
    let username = username_.unwrap_or(None).unwrap_or(String::from(""));
    let username_b = if username != *"" {
        format!("/{}", username.green())
    } else {
        String::from("")
    };
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");

    warn!(
        "{}\t{:>45.47}\t\t{}{:<26}",
        "Request/404".bright_red(),
        req.path().red(),
        ip.yellow(),
        username_b
    );
    HttpResponse::NotFound().body("")
}

pub(super) async fn root(server_z: Data<Mutex<ServerVars>>, req: HttpRequest) -> HttpResponse {
    let server_y = server_z.lock().await;
    let server_p: ServerVars = server_y.clone();
    drop(server_y);
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    (server_p.tell)(format!(
        "{2}\t{:>45.47}\t\t{}",
        "/".bright_magenta(),
        ip.yellow(),
        "Request/200".bright_green()
    ));

    HttpResponse::build(StatusCode::OK)
        .content_type("text/html; charset=utf-8")
        .body(
            crate::assets::STR_ASSETS_INDEX_HTML
                .replace(
                    "{{iid}}",
                    &server_p.clone().config.interinstance.iid.clone(),
                )
                .clone(),
        )
}

pub(super) async fn login(server_z: Data<Mutex<ServerVars>>, req: HttpRequest) -> HttpResponse {
    let server_y = server_z.lock().await;
    let server_p: ServerVars = server_y.clone();
    drop(server_y);
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    (server_p.tell)(format!(
        "{2}\t{:>45.47}\t\t{}",
        "/login".bright_magenta(),
        ip.yellow(),
        "Request/200".bright_green()
    ));

    HttpResponse::build(StatusCode::OK)
        .content_type("text/html; charset=utf-8")
        .body(
            crate::assets::STR_ASSETS_LOGIN_HTML
                .replace(
                    "{{iid}}",
                    &server_p.clone().config.interinstance.iid.clone(),
                )
                .clone(),
        )
}

pub(super) async fn signup(server_z: Data<Mutex<ServerVars>>, req: HttpRequest) -> HttpResponse {
    let server_y = server_z.lock().await;
    let server_p: ServerVars = server_y.clone();
    drop(server_y);
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    (server_p.tell)(format!(
        "{2}\t{:>45.47}\t\t{}",
        "/signup".bright_magenta(),
        ip.yellow(),
        "Request/200".bright_green()
    ));

    HttpResponse::build(StatusCode::OK)
        .content_type("text/html; charset=utf-8")
        .body(
            crate::assets::STR_ASSETS_SIGNUP_HTML
                .replace(
                    "{{iid}}",
                    &server_p.clone().config.interinstance.iid.clone(),
                )
                .clone(),
        )
}

pub(super) async fn prefetch_js(
    server_z: Data<Mutex<ServerVars>>,
    req: HttpRequest,
) -> HttpResponse {
    let server_y: MutexGuard<ServerVars> = server_z.lock().await;
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    (server_y.tell)(format!(
        "{2}\t{:>45.47}\t\t{}",
        "/prefetch.js".magenta(),
        ip.yellow(),
        "Request/200".bright_green()
    ));
    let js = format!(
        r#"/*
* Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
*
* Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
*/

{}"#,
        crate::assets::STR_ASSETS_PREFETCH_JS
    );
    HttpResponse::build(StatusCode::OK)
        .content_type("text/javascript; charset=utf-8")
        .body(js)
}

pub(super) async fn login_js(server_z: Data<Mutex<ServerVars>>, req: HttpRequest) -> HttpResponse {
    let server_y: MutexGuard<ServerVars> = server_z.lock().await;
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    (server_y.tell)(format!(
        "{2}\t{:>45.47}\t\t{}",
        "/login.js".magenta(),
        ip.yellow(),
        "Request/200".bright_green()
    ));
    let js = format!(
        r#"/*
* Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
*
* Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
*/

{}"#,
        crate::assets::STR_ASSETS_LOGIN_JS
    );
    HttpResponse::build(StatusCode::OK)
        .content_type("text/javascript; charset=utf-8")
        .body(js)
}

pub(super) async fn index_js(server_z: Data<Mutex<ServerVars>>, req: HttpRequest) -> HttpResponse {
    let server_y: MutexGuard<ServerVars> = server_z.lock().await;
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    (server_y.tell)(format!(
        "{2}\t{:>45.47}\t\t{}",
        "/login.js".magenta(),
        ip.yellow(),
        "Request/200".bright_green()
    ));
    let js = format!(
        r#"/*
* Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
*
* Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
*/

{}"#,
        crate::assets::STR_ASSETS_INDEX_JS
    );
    HttpResponse::build(StatusCode::OK)
        .content_type("text/javascript; charset=utf-8")
        .body(js)
}

pub(super) async fn home_js(server_z: Data<Mutex<ServerVars>>, req: HttpRequest) -> HttpResponse {
    let server_y: MutexGuard<ServerVars> = server_z.lock().await;
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    (server_y.tell)(format!(
        "{2}\t{:>45.47}\t\t{}",
        "/site-home.js".magenta(),
        ip.yellow(),
        "Request/200".bright_green()
    ));
    let js = format!(
        r#"/*
* Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
*
* Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
*/

{}"#,
        crate::assets::STR_ASSETS_HOME_JS
    );
    HttpResponse::build(StatusCode::OK)
        .content_type("text/javascript; charset=utf-8")
        .body(js)
}

pub(super) async fn signup_js(server_z: Data<Mutex<ServerVars>>, req: HttpRequest) -> HttpResponse {
    let server_y: MutexGuard<ServerVars> = server_z.lock().await;
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    (server_y.tell)(format!(
        "{2}\t{:>45.47}\t\t{}",
        "/login.js".magenta(),
        ip.yellow(),
        "Request/200".bright_green()
    ));
    let js = format!(
        r#"/*
* Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
*
* Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
*/

{}"#,
        crate::assets::STR_ASSETS_SIGNUP_JS
    );
    HttpResponse::build(StatusCode::OK)
        .content_type("text/javascript; charset=utf-8")
        .body(js)
}

pub(super) async fn site_c_css(
    server_z: Data<Mutex<ServerVars>>,
    req: HttpRequest,
) -> HttpResponse {
    let server_y: MutexGuard<ServerVars> = server_z.lock().await;
    let config: LuminaConfig = server_y.clone().config;
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    (server_y.tell)(format!(
        "{2}\t{:>45.47}\t\t{}",
        "/custom.css".magenta(),
        ip.yellow(),
        "Request/200".bright_green()
    ));
    HttpResponse::build(StatusCode::OK)
        .content_type("text/css; charset=utf-8")
        .body(config.run.customcss)
}

pub(super) async fn site_css(server_z: Data<Mutex<ServerVars>>, req: HttpRequest) -> HttpResponse {
    let server_y: MutexGuard<ServerVars> = server_z.lock().await;
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    (server_y.tell)(format!(
        "{2}\t{:>45.47}\t\t{}",
        "/site.css".magenta(),
        ip.yellow(),
        "Request/200".bright_green()
    ));
    HttpResponse::build(StatusCode::OK)
        .content_type("text/css; charset=utf-8")
        .body(crate::assets::STR_GENERATED_MAIN_MIN_CSS)
}

pub(super) async fn red_cross_svg(
    server_z: Data<Mutex<ServerVars>>,
    req: HttpRequest,
) -> HttpResponse {
    let server_y: MutexGuard<ServerVars> = server_z.lock().await;
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    (server_y.tell)(format!(
        "{2}\t{:>45.47}\t\t{}",
        "/red-cross.svg".magenta(),
        ip.yellow(),
        "Request/200".bright_green()
    ));
    HttpResponse::build(StatusCode::OK)
        .content_type("image/svg+xml; charset=utf-8")
        .body(crate::assets::STR_ASSETS_RED_CROSS_SVG)
}

pub(super) async fn spinner_svg(
    server_z: Data<Mutex<ServerVars>>,
    req: HttpRequest,
) -> HttpResponse {
    let server_y: MutexGuard<ServerVars> = server_z.lock().await;
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    (server_y.tell)(format!(
        "{2}\t{:>45.47}\t\t{}",
        "/spinner.svg".magenta(),
        ip.yellow(),
        "Request/200".bright_green()
    ));
    HttpResponse::build(StatusCode::OK)
        .content_type("image/svg+xml; charset=utf-8")
        .body(crate::assets::STR_ASSETS_SPINNER_SVG)
}

pub(super) async fn green_check_svg(
    server_z: Data<Mutex<ServerVars>>,
    req: HttpRequest,
) -> HttpResponse {
    let server_y: MutexGuard<ServerVars> = server_z.lock().await;
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    (server_y.tell)(format!(
        "{2}\t{:>45.47}\t\t{}",
        "/green-check.svg".magenta(),
        ip.yellow(),
        "Request/200".bright_green()
    ));
    HttpResponse::build(StatusCode::OK)
        .content_type("image/svg+xml; charset=utf-8")
        .body(crate::assets::STR_ASSETS_GREEN_CHECK_SVG)
}

pub(super) async fn logo_svg(server_z: Data<Mutex<ServerVars>>, req: HttpRequest) -> HttpResponse {
    let server_y: MutexGuard<ServerVars> = server_z.lock().await;
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    (server_y.tell)(format!(
        "{2}\t{:>45.47}\t\t{}",
        "/logo.svg".magenta(),
        ip.yellow(),
        "Request/200".bright_green()
    ));
    HttpResponse::build(StatusCode::OK)
        .content_type("image/svg+xml; charset=utf-8")
        .body(crate::assets::STR_ASSETS_LOGO_SVG)
}

pub(super) async fn logo_png(server_z: Data<Mutex<ServerVars>>, req: HttpRequest) -> HttpResponse {
    let server_y: MutexGuard<ServerVars> = server_z.lock().await;
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    (server_y.tell)(format!(
        "{2}\t{:>45.47}\t\t{}",
        "/logo.png".magenta(),
        ip.yellow(),
        "Request/200".bright_green()
    ));
    HttpResponse::build(StatusCode::OK)
        .content_type("image/png; charset=utf-8")
        .body(crate::assets::BYTES_ASSETS_LOGO_PNG)
}

pub(super) async fn node_axios_map(
    server_z: Data<Mutex<ServerVars>>,
    req: HttpRequest,
) -> HttpResponse {
    let server_y: MutexGuard<ServerVars> = server_z.lock().await;
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    (server_y.tell)(format!(
        "{2}\t{:>45.47}\t\t{}",
        "/axios/axios.min.js.map".magenta(),
        ip.yellow(),
        "Request/200".bright_green()
    ));
    HttpResponse::build(StatusCode::OK)
        .content_type("text/javascript; charset=utf-8")
        .body(crate::assets::STR_NODE_MOD_AXIOS_MIN_JS_MAP)
}

pub(super) async fn node_axios(
    server_z: Data<Mutex<ServerVars>>,
    req: HttpRequest,
) -> HttpResponse {
    let server_y: MutexGuard<ServerVars> = server_z.lock().await;
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    (server_y.tell)(format!(
        "{2}\t{:>45.47}\t\t{}",
        "/axios/axios.min.js".magenta(),
        ip.yellow(),
        "Request/200".bright_green()
    ));
    HttpResponse::build(StatusCode::OK)
        .content_type("text/javascript; charset=utf-8")
        .body(crate::assets::STR_NODE_MOD_AXIOS_MIN_JS)
}

pub(super) async fn homepage(
    server_z: Data<Mutex<ServerVars>>,
    session: Session,
    req: HttpRequest,
) -> HttpResponse {
    fence(session, server_z, req, |_, server_vars, user, request| {
        let coninfo = request.connection_info();
        let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
        (server_vars.tell)(format!(
            "{}\t{:>45.47}\t\t{}/{:<25}",
            "Request/200".bright_green(),
            "/home".bright_magenta(),
            ip.yellow(),
            user.username.green()
        ));
        HttpResponse::build(StatusCode::OK)
            .content_type("text/html; charset=utf-8")
            .body(
                crate::assets::STR_ASSETS_HOME_HTML
                    .replace(
                        "{{iid}}",
                        &server_vars.clone().config.interinstance.iid.clone(),
                    )
                    .clone(),
            )
    })
    .await
}

pub(super) async fn logout(
    server_z: Data<Mutex<ServerVars>>,
    session: Session,
    req: HttpRequest,
) -> impl Responder {
    let server_y = server_z.lock().await;
    let server_p: ServerVars = server_y.clone();
    drop(server_y);
    let username_ = session.get::<String>("username");
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    match username_.unwrap_or(None) {
        Some(username) => {
            (server_p.tell)(format!(
                "{}\t{:>45.47}\t\t{}/{:<25}",
                "Request/200".bright_green(),
                "/session/logout".bright_magenta(),
                ip.yellow(),
                username.green()
            ));
            session.purge();
            HttpResponse::build(StatusCode::TEMPORARY_REDIRECT)
                .append_header((LOCATION, "/login"))
                .finish()
        }
        None => HttpResponse::build(StatusCode::TEMPORARY_REDIRECT)
            .append_header((LOCATION, "/login"))
            .finish(),
    }
}

/// Fence is a function serving kind of like middleware usually would. But actix middleware kinda sucks balls. So.
pub(crate) async fn fence(
    session: Session,
    server_vars_mutex: Data<Mutex<ServerVars>>,
    req: HttpRequest,
    next: fn(
        config: LuminaConfig,
        vars: ServerVars,
        user: IIExchangedUserInfo,
        req: HttpRequest,
    ) -> HttpResponse,
) -> HttpResponse {
    let server_y: MutexGuard<ServerVars> = server_vars_mutex.lock().await;
    let config = server_y.clone().config;
    let id_ = session.get::<i64>("userid").unwrap_or(Some(-100));
    let id = id_.unwrap_or(-100);
    debug!("Session validity: {:?}", session.get::<i64>("validity"));
    debug!("Session contents: {:?}", session.entries());
    debug!("User ID: {:?}", id);

    let safe = match id {
        -100 => false,
        _ => match session.get::<i64>("validity") {
            Ok(s) => match s {
                Some(a) if a == config.clone().run.session_valid => true,
                _ => false,
            },
            Err(_) => false,
        },
    };
    if !safe {
        session.purge();
        HttpResponse::build(StatusCode::TEMPORARY_REDIRECT)
            .append_header((LOCATION, "/login"))
            .finish()
    } else {
        let user: BasicUserInfo = serde_json::from_str(
            crate::database::fetch(&config, String::from("Users"), "id", id.to_string())
                .unwrap()
                .unwrap()
                .as_str(),
        )
        .unwrap();

        next(
            config.clone(),
            server_y.clone().to_owned(),
            user.to_exchangable(&config),
            req,
        )
    }
}
