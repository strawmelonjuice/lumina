use axum::{
    routing::{get, post},
    http::StatusCode,
    Json, Router,
	response::{Html, IntoResponse},
};
use axum::http::header;
use serde::{Deserialize, Serialize};

#[tokio::main]
async fn main() {
    // initialize tracing
    tracing_subscriber::fmt::init();

    // build our application with a route
    let app = Router::new()
        // `GET /` goes to `root`
        .route("/", get(|| async { Html(include_str!("../../client/index.html")) }))
        .route("/static/lumina.min.mjs", get(|| async { ([(header::CONTENT_TYPE, "text/javascript")], include_str!("../../client/priv/static/lumina_client.min.mjs")) }))
		.route("/static/lumina.css", get(|| async { ([(header::CONTENT_TYPE, "text/css")], include_str!("../../client/priv/static/lumina_client.min.css")) }));

    // run our app with hyper, listening globally on port 3000
	println!("Listening on http://localhost:3000");
    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
