use rocket::http::ContentType;

use rocket::response::content::RawCss;

use rocket::response::content::RawJavaScript;

use rocket::response::content::RawHtml;

#[get("/")]
pub(crate) async fn index() -> RawHtml<String> {
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

<body>
<div id="app"></div>
</body>
</html>"#
            .to_string(),
    )
}

#[get("/static/lumina.min.mjs")]
pub(crate) async fn lumina_js() -> RawJavaScript<String> {
    RawJavaScript(include_str!("../../client/priv/static/lumina_client.min.mjs").to_string())
}

#[get("/static/lumina.css")]
pub(crate) async fn lumina_css() -> RawCss<String> {
    RawCss(include_str!("../../client/priv/static/lumina_client.css").to_string())
}

#[get("/static/logo.svg")]
pub(crate) async fn logo_svg() -> (ContentType, &'static str) {
    (
        ContentType::SVG,
        include_str!("../../client/priv/static/logo.svg"),
    )
}

#[get("/favicon.ico")]
pub(crate) async fn favicon() -> (ContentType, &'static [u8]) {
    logo_png().await
}

#[get("/static/logo.png")]
pub(crate) async fn logo_png() -> (ContentType, &'static [u8]) {
    (
        ContentType::PNG,
        include_bytes!("../../client/priv/static/logo.png"),
    )
}
