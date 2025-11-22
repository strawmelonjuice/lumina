//// Lumina > Server > Static Routes
//// This module defines static routes for serving static files like CSS, JS, and images.

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
use rocket::http::ContentType;

use rocket::response::content::{RawCss, RawText};

use rocket::response::content::RawJavaScript;

use rocket::response::content::RawHtml;

use crate::{AppState, http_code_elog};
use rocket::State;

#[get("/")]
pub(crate) async fn index<'k>(state: &'k State<AppState>) -> RawHtml<String> {
    let ev_log = {
        let appstate = state.0.clone();
        appstate.2.clone().await
    };
    http_code_elog!(ev_log, 200, "/");

    RawHtml(
        r#"<!doctype html>
<html lang="en">
<head>
	<meta charset="UTF-8" />
	<meta name="viewport" content="width=device-width, initial-scale=1.0" />

	<title>Lumina</title>

	<link
		rel="stylesheet"
		href="/static/lumina.css"
	/>
	<script type="module" src="/static/lumina.min.mjs"></script>
</head>

<body id="app">
</body>
</html>"#
            .to_string(),
    )
}

#[get("/static/lumina.min.mjs")]
pub(crate) async fn lumina_js<'k>(state: &'k State<AppState>) -> RawJavaScript<String> {
    let ev_log = {
        let appstate = state.0.clone();
        appstate.2.clone().await
    };
    http_code_elog!(ev_log, 200, "/static/lumina.min.mjs");

    RawJavaScript(include_str!("../../client/priv/static/lumina_client.min.mjs").to_string())
}

#[get("/static/lumina.css")]
pub(crate) async fn lumina_css<'k>(state: &'k State<AppState>) -> RawCss<String> {
    let ev_log = {
        let appstate = state.0.clone();
        appstate.2.clone().await
    };
    http_code_elog!(ev_log, 200, "/static/lumina.css");

    RawCss(include_str!("../../client/priv/static/lumina_client.css").to_string())
}

#[get("/licence")]
pub(crate) async fn licence<'k>(state: &'k State<AppState>) -> RawText<String> {
    let ev_log = {
        let appstate = state.0.clone();
        appstate.2.clone().await
    };
    http_code_elog!(ev_log, 200, "/licence");

    RawText(include_str!("../../COPYING").to_string())
}
#[get("/license")]
pub(crate) async fn license_redirect() -> rocket::response::Redirect {
    rocket::response::Redirect::to(uri!(licence))
}

#[get("/static/logo.svg")]
pub(crate) async fn logo_svg<'k>(state: &'k State<AppState>) -> (ContentType, &'static str) {
    let ev_log = {
        let appstate = state.0.clone();
        appstate.2.clone().await
    };
    http_code_elog!(ev_log, 200, "/static/logo.svg");

    (
        ContentType::SVG,
        include_str!("../../client/priv/static/logo.svg"),
    )
}

#[get("/favicon.ico")]
pub(crate) async fn favicon<'k>(state: &'k State<AppState>) -> (ContentType, &'static [u8]) {
    let ev_log = {
        let appstate = state.0.clone();
        appstate.2.clone().await
    };
    http_code_elog!(ev_log, 200, "/favicon.ico");
    produce_logo_png()
}

#[get("/static/logo.png")]
pub(crate) async fn logo_png<'k>(state: &'k State<AppState>) -> (ContentType, &'static [u8]) {
    let ev_log = {
        let appstate = state.0.clone();
        appstate.2.clone().await
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
