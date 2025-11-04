extern crate rocket;
use rocket::http::ContentType;

use rocket::response::content::RawCss;

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
