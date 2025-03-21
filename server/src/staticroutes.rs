use rocket::http::ContentType;

use rocket::response::content::RawCss;

use rocket::response::content::RawJavaScript;

use rocket::response::content::RawHtml;

#[get("/")]
pub(crate) async fn index() -> RawHtml<String> {
    RawHtml(include_str!("../../client/index.html").to_string())
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
