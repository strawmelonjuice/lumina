/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */
const SPECIALDATES: &str = r#"
.monthclass-6 .contentkeeper::before {
    margin-top: .8em;
    margin-bottom: .8em;
    content: "Happy Pride Month!";
    justify-content: center;
    align-items: center;
    height: 2.4em;
    color: black;
    width: 100%;
    display: inline-flex;
    background-image: linear-gradient(to right, rgb(237, 34, 36), rgb(243, 91, 34), rgb(249, 150, 33), rgb(245, 193, 30), rgb(241, 235, 27) 27%, rgb(241, 235, 27), rgb(241, 235, 27) 33%, rgb(99, 199, 32), rgb(12, 155, 73), rgb(33, 135, 141), rgb(57, 84, 165), rgb(97, 55, 155), rgb(147, 40, 142))
}
.dayclass-29.monthclass-2 .contentkeeper::before {
    margin-top: .8em;
    margin-bottom: .8em;
    content: "[This day does not exist]";
    justify-content: center;
    align-items: center;
    height: 2.4em;
    flex: none;
    color: yellow;
    width: 100%;
    display: inline-flex;
    background-color: black;
    text-shadow: 22px 4px 2px rgba(255,255,0,0.6);
    box-shadow: 2px 2px 10px 8px #3d3a3a;
    animation-name: glitched;
    animation-duration: 3s;
    animation-iteration-count: infinite;
    animation-timing-function: linear;
    animation-direction: alternate;
}
@keyframes glitched {
    0% {
        transform: skew(-20deg);
        left: -4px;
    }
    10% {
        transform: skew(-20deg);
        left: -4px;
    }
    11% {
        transform: skew(0deg);
        left: 2px;
    }
    50% {
        transform: skew(0deg);
    }
    51% {
        transform: skew(10deg);
    }
    59% {
        transform: skew(10deg);
    }
    60% {
        transform: skew(0deg);
    }
    100% {
        transform: skew(0deg);
    }
}"#;

use actix_session::Session;
use actix_web::http::header::LOCATION;
use actix_web::http::StatusCode;
use actix_web::web::Data;
use actix_web::{HttpRequest, HttpResponse, Responder};
use colored::Colorize;
use tokio::sync::{Mutex, MutexGuard};

use crate::database::{BasicUserInfo, IIExchangedUserInfo};
use crate::{LuminaConfig, ServerVars};
use chrono::Datelike;

pub(super) async fn notfound(
    server_vars_mutex: Data<Mutex<ServerVars>>,
    req: HttpRequest,
    session: Session,
) -> HttpResponse {
    let _server_vars = ServerVars::grab(&server_vars_mutex).await;
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

pub(super) async fn root(
    server_vars_mutex: Data<Mutex<ServerVars>>,
    req: HttpRequest,
) -> HttpResponse {
    let server_vars: ServerVars = ServerVars::grab(&server_vars_mutex).await;
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    (server_vars.tell)(format!(
        "{2}\t{:>45.47}\t\t{}",
        "/".bright_magenta(),
        ip.yellow(),
        "Request/200".bright_green()
    ));

    HttpResponse::build(StatusCode::OK)
        .content_type("text/html; charset=utf-8")
        .body(replaceable(
            crate::assets::STR_ASSETS_INDEX_HTML,
            &server_vars,
        ))
}

fn replaceable(string: &str, server_vars: &ServerVars) -> String {
    // "Compress" that CSS too, however, be careful. Two consecutive spaces can be removed, but one on its own might mean something!
    let specialdates = SPECIALDATES.replace(['\r', '\n'], "").replace("  ", "");
    let current_date = chrono::Utc::now();
    let mut stylesheet: String = String::new();
    stylesheet.push_str("<style>");
    stylesheet.push_str("\n\n\n/* --- Main stylesheet --- */\n\n\n");
    stylesheet.push_str(crate::assets::STR_GENERATED_MAIN_MIN_CSS);
    stylesheet.push_str("\n\n\n/* --- Custom instance-specific CSS content --- */\n\n\n");
    stylesheet.push_str(&*server_vars.config.run.customcss.clone());
    stylesheet.push_str("\n\n\n/* --- CSS content for special events --- */\n\n\n");
    stylesheet.push_str(specialdates.as_str());
    stylesheet.push_str("</style>");
    let s = string
        .replace(
            "{{iid}}",
            &server_vars.clone().config.interinstance.iid.clone(),
        )
        .replace(
            "monthclass-month",
            format!("monthclass-{}", current_date.month()).as_str(),
        )
        .replace(
            "dayclass-day",
            format!("dayclass-{}", current_date.day()).as_str(),
        )
        .replace("<style></style>", &*stylesheet);
    s.clone()
}

pub(super) async fn login(
    server_vars_mutex: Data<Mutex<ServerVars>>,
    req: HttpRequest,
) -> HttpResponse {
    let server_vars: ServerVars = ServerVars::grab(&server_vars_mutex).await;
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    (server_vars.tell)(format!(
        "{2}\t{:>45.47}\t\t{}",
        "/login".bright_magenta(),
        ip.yellow(),
        "Request/200".bright_green()
    ));

    HttpResponse::build(StatusCode::OK)
        .content_type("text/html; charset=utf-8")
        .body(replaceable(
            crate::assets::STR_ASSETS_LOGIN_HTML,
            &server_vars,
        ))
}

pub(super) async fn signup(
    server_vars_mutex: Data<Mutex<ServerVars>>,
    req: HttpRequest,
) -> HttpResponse {
    let server_vars: ServerVars = ServerVars::grab(&server_vars_mutex).await;
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    (server_vars.tell)(format!(
        "{2}\t{:>45.47}\t\t{}",
        "/signup".bright_magenta(),
        ip.yellow(),
        "Request/200".bright_green()
    ));

    HttpResponse::build(StatusCode::OK)
        .content_type("text/html; charset=utf-8")
        .body(replaceable(
            crate::assets::STR_ASSETS_SIGNUP_HTML,
            &server_vars,
        ))
}

pub(super) async fn prefetch_js(
    server_vars_mutex: Data<Mutex<ServerVars>>,
    req: HttpRequest,
) -> HttpResponse {
    let server_vars = ServerVars::grab(&server_vars_mutex).await;
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    (server_vars.tell)(format!(
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

pub(super) async fn login_js(
    server_vars_mutex: Data<Mutex<ServerVars>>,
    req: HttpRequest,
) -> HttpResponse {
    let server_vars = ServerVars::grab(&server_vars_mutex).await;
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    (server_vars.tell)(format!(
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

pub(super) async fn index_js(
    server_vars_mutex: Data<Mutex<ServerVars>>,
    req: HttpRequest,
) -> HttpResponse {
    let server_vars = ServerVars::grab(&server_vars_mutex).await;
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    (server_vars.tell)(format!(
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

pub(super) async fn home_js(
    server_vars_mutex: Data<Mutex<ServerVars>>,
    req: HttpRequest,
) -> HttpResponse {
    let server_vars = ServerVars::grab(&server_vars_mutex).await;
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    (server_vars.tell)(format!(
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

pub(super) async fn signup_js(
    server_vars_mutex: Data<Mutex<ServerVars>>,
    req: HttpRequest,
) -> HttpResponse {
    let server_vars = ServerVars::grab(&server_vars_mutex).await;
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    (server_vars.tell)(format!(
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


pub(super) async fn red_cross_svg(
    server_vars_mutex: Data<Mutex<ServerVars>>,
    req: HttpRequest,
) -> HttpResponse {
    let server_vars = ServerVars::grab(&server_vars_mutex).await;
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    (server_vars.tell)(format!(
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
    server_vars_mutex: Data<Mutex<ServerVars>>,
    req: HttpRequest,
) -> HttpResponse {
    let server_vars = ServerVars::grab(&server_vars_mutex).await;
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    (server_vars.tell)(format!(
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
    server_vars_mutex: Data<Mutex<ServerVars>>,
    req: HttpRequest,
) -> HttpResponse {
    let server_vars = ServerVars::grab(&server_vars_mutex).await;
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    (server_vars.tell)(format!(
        "{2}\t{:>45.47}\t\t{}",
        "/green-check.svg".magenta(),
        ip.yellow(),
        "Request/200".bright_green()
    ));
    HttpResponse::build(StatusCode::OK)
        .content_type("image/svg+xml; charset=utf-8")
        .body(crate::assets::STR_ASSETS_GREEN_CHECK_SVG)
}

pub(super) async fn logo_svg(
    server_vars_mutex: Data<Mutex<ServerVars>>,
    req: HttpRequest,
) -> HttpResponse {
    let server_vars = ServerVars::grab(&server_vars_mutex).await;
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    (server_vars.tell)(format!(
        "{2}\t{:>45.47}\t\t{}",
        "/logo.svg".magenta(),
        ip.yellow(),
        "Request/200".bright_green()
    ));
    HttpResponse::build(StatusCode::OK)
        .content_type("image/svg+xml; charset=utf-8")
        .body(crate::assets::STR_ASSETS_LOGO_SVG)
}

pub(super) async fn logo_png(
    server_vars_mutex: Data<Mutex<ServerVars>>,
    req: HttpRequest,
) -> HttpResponse {
    let server_vars = ServerVars::grab(&server_vars_mutex).await;
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    (server_vars.tell)(format!(
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
    server_vars_mutex: Data<Mutex<ServerVars>>,
    req: HttpRequest,
) -> HttpResponse {
    let server_vars = ServerVars::grab(&server_vars_mutex).await;
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    (server_vars.tell)(format!(
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
    server_vars_mutex: Data<Mutex<ServerVars>>,
    req: HttpRequest,
) -> HttpResponse {
    let server_vars = ServerVars::grab(&server_vars_mutex).await;
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    (server_vars.tell)(format!(
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
    server_vars_mutex: Data<Mutex<ServerVars>>,
    session: Session,
    req: HttpRequest,
) -> HttpResponse {
    fence(
        session,
        server_vars_mutex,
        req,
        |_, server_vars, user, request| {
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
                .body(replaceable(
                    crate::assets::STR_ASSETS_HOME_HTML,
                    &server_vars,
                ))
        },
    )
    .await
}

pub(super) async fn logout(
    server_vars_mutex: Data<Mutex<ServerVars>>,
    session: Session,
    req: HttpRequest,
) -> impl Responder {
    let server_vars = ServerVars::grab(&server_vars_mutex).await;
    let username_ = session.get::<String>("username");
    let coninfo = req.connection_info();
    let ip = coninfo.realip_remote_addr().unwrap_or("<unknown IP>");
    match username_.unwrap_or(None) {
        Some(username) => {
            (server_vars.tell)(format!(
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
    let server_vars: MutexGuard<ServerVars> = server_vars_mutex.lock().await;
    let config = server_vars.clone().config;
    let id_ = session.get::<i64>("userid").unwrap_or(Some(-100));
    let id = id_.unwrap_or(-100);
    debug!("Session validity: {:?}", session.get::<i64>("validity"));
    debug!("Session contents: {:?}", session.entries());
    debug!("User ID: {:?}", id);

    let safe = match id {
        -100 => false,
        _ => match session.get::<i64>("validity") {
            Ok(s) => matches!(s, Some(a) if a == config.clone().run.session_valid),
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
            server_vars.clone().to_owned(),
            user.to_exchangable(&config),
            req,
        )
    }
}
