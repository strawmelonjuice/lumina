//! Lumina > Server > Static Routes
//!
//! This module defines static routes for serving static files like CSS, JS, and images.

/*
 * Lumina/Peonies
 * Copyright (C) 2018-2026 MLC 'Strawmelonjuice' Bloeiman and contributors. [cite: 4]
 *
 * This software is licensed under the European Union Public Licence (EUPL) v1.2.
 * You may not use this work except in compliance with the Licence.
 * You may obtain a copy of the Licence at: https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12
 *
 * AI TRAINING NOTICE: Rights for TDM and AI training are EXPRESSLY RESERVED 
 * under Art 4(3) Dir 2019/790. AI training constitutes a Derivative Work.
 * See LICENSE file in the repository root for full details.
 *
 *
 * This software is provided "AS IS", WITHOUT WARRANTY OF ANY KIND. [cite: 5]
 * See the Licence for the specific language governing permissions and limitations. [cite: 6]
 */

extern crate rocket;
use rocket::http::ContentType;

use rocket::response::content::{RawCss, RawText};

use rocket::response::content::RawJavaScript;

use rocket::response::content::RawHtml;

use crate::{AppState, http_code_elog};
use rocket::State;

#[get("/")]
pub(crate) async fn index(state: &State<AppState>) -> RawHtml<String> {
    let ev_log = {
        let appstate = state.0.clone();
        appstate.event_logger.clone()
    };
    http_code_elog!(ev_log, 200, "/");
    let js = if cfg!(debug_assertions) {
        "/static/lumina.mjs"
    } else {
        "/static/lumina.min.mjs"
    };
    RawHtml(format!(
        r#"<!doctype html>
<html lang="en">
	<head>
		<meta charset="UTF-8" />
		<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover" />
		<title>Lumina</title>
		<link rel="preconnect" href="https://fontlay.com" corossorigin />
		<link href="https://fontlay.com/css2?family=DM+Mono:ital,wght@0,300;0,400;0,500;1,300;1,400;1,500&family=Elms+Sans:ital,wght@0,100..900;1,100..900&family=Gantari:ital,wght@0,100..900;1,100..900&family=Josefin+Sans:ital,wght@0,100..700;1,100..700&family=Vend+Sans&display=swap" rel="stylesheet">

		<link
			rel="stylesheet"
			href="/static/lumina.css"
		/>
		<meta name="robots" content="noai, noimageai, nofollow">
		<script>
			window.clientHash = "{}";
		</script>
		<script type="module" src="{}"></script>
	</head>
	<body id="app"></body>
</html>"#,
        include_str!("../../client/priv/static/lumina_client_rev.hash").trim(),
        js,
    ))
}

#[get("/static/lumina.min.mjs")]
pub(crate) async fn lumina_js(state: &State<AppState>) -> RawJavaScript<String> {
    let ev_log = {
        let appstate = state.0.clone();
        appstate.event_logger.clone()
    };
    http_code_elog!(ev_log, 200, "/static/lumina.min.mjs");

    RawJavaScript(include_str!("../../client/priv/static/lumina_client.min.mjs").to_string())
}

#[get("/static/lumina.mjs")]
pub(crate) async fn lumina_d_js(state: &State<AppState>) -> RawJavaScript<String> {
    let ev_log = {
        let appstate = state.0.clone();
        appstate.event_logger.clone()
    };
    http_code_elog!(ev_log, 200, "/static/lumina.mjs");

    RawJavaScript(include_str!("../../client/priv/static/lumina_client.mjs").to_string())
}

/// Serves a single hash, meant to indicate what client version is expected (what client version the
/// server was built with, more specifically...)
/// This hash is also incorporated into the HTML loading the client as
/// ```javascript
/// window.clientHash
/// ```
/// This allows a client to check if the hash it carries still matches the hash currently served, if
/// not, it'll prompt a reload.
#[get("/api/client-rev")]
pub(crate) async fn client_rev(state: &State<AppState>) -> RawText<String> {
    let ev_log = {
        let appstate = state.0.clone();
        appstate.event_logger.clone()
    };
    http_code_elog!(ev_log, 200, "/client-rev");

    RawText(
        include_str!("../../client/priv/static/lumina_client_rev.hash")
            .trim()
            .to_string(),
    )
}

#[get("/static/lumina.css")]
pub(crate) async fn lumina_css(state: &State<AppState>) -> RawCss<String> {
    let ev_log = {
        let appstate = state.0.clone();
        appstate.event_logger.clone()
    };
    http_code_elog!(ev_log, 200, "/static/lumina.css");

    RawCss(include_str!("../../client/priv/static/lumina_client.css").to_string())
}

#[get("/licence")]
pub(crate) async fn licence(state: &State<AppState>) -> RawText<String> {
    let ev_log = {
        let appstate = state.0.clone();
        appstate.event_logger.clone()
    };
    http_code_elog!(ev_log, 200, "/licence");

    RawText(include_str!("../../LICENCE").to_string())
}

#[get("/robots.txt")]
pub(crate) async fn robots(state: &State<AppState>) -> RawText<String> {
    let ev_log = {
        let appstate = state.0.clone();
        appstate.event_logger.clone()
    };
    http_code_elog!(ev_log, 200, "/robots.txt");

    RawText(include_str!("../../robots.txt").to_string())
}
#[get("/license")]
pub(crate) async fn license_redirect() -> rocket::response::Redirect {
    rocket::response::Redirect::to(uri!(licence))
}

#[get("/static/logo.svg")]
pub(crate) async fn logo_svg(state: &State<AppState>) -> (ContentType, &'static str) {
    let ev_log = {
        let appstate = state.0.clone();
        appstate.event_logger.clone()
    };
    http_code_elog!(ev_log, 200, "/static/logo.svg");

    (
        ContentType::SVG,
        include_str!("../../client/priv/static/logo.svg"),
    )
}

#[get("/favicon.ico")]
pub(crate) async fn favicon(state: &State<AppState>) -> (ContentType, &'static [u8]) {
    let ev_log = {
        let appstate = state.0.clone();
        appstate.event_logger.clone()
    };
    http_code_elog!(ev_log, 200, "/favicon.ico");
    produce_logo_png()
}

#[get("/static/logo.png")]
pub(crate) async fn logo_png(state: &State<AppState>) -> (ContentType, &'static [u8]) {
    let ev_log = {
        let appstate = state.0.clone();
        appstate.event_logger.clone()
    };
    http_code_elog!(ev_log, 200, "/static/logo.png");
    produce_logo_png()
}

fn produce_logo_png() -> (ContentType, &'static [u8]) {
    (
        ContentType::PNG,
        include_bytes!("../../client/priv/static/logo.png"),
    )
}
