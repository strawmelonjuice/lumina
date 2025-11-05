extern crate dotenv;
#[macro_use]
extern crate rocket;
mod client_communication;
mod database;
pub mod errors;
pub mod helpers;
mod staticroutes;
mod tests;
mod timeline;
use helpers::events::EventLogger;
use helpers::message_prefixes;
use rocket::config::LogLevel;
use std::io::ErrorKind;
use std::{net::IpAddr, process, sync::Arc};
use tokio::sync::Mutex;
use uuid::Uuid;
mod user;
use tokio_postgres as postgres;
struct AppState(Arc<(ServerConfig, Mutex<DbConn>, EventLogger)>);
mod rate_limiter;
use database::DbConn;
use rate_limiter::{AuthRateLimiter, GeneralRateLimiter};
#[derive(Debug, Clone)]
struct ServerConfig {
    port: u16,
    host: IpAddr,
}

use crate::errors::LuminaError;
use cynthia_con::{CynthiaColors, CynthiaStyles};
use dotenv::dotenv;
use rocket::futures::TryFutureExt;

fn config_get() -> Result<ServerConfig, LuminaError> {
    let addr = {
        let s = std::env::var("LUMINA_SERVER_ADDR").unwrap_or(String::from("127.0.0.1"));
        s.parse::<IpAddr>()
            .map_err(|_| LuminaError::ConfInvalid("LUMINA_SERVER_ADDR".to_string()))?
    };
    let port = {
        let s = std::env::var("LUMINA_SERVER_PORT").unwrap_or(String::from("8085"));
        s.parse::<u16>()
            .map_err(|_| LuminaError::ConfInvalid("LUMINA_SERVER_PORT".to_string()))?
    };
    Ok(ServerConfig { port, host: addr })
}

#[rocket::main]
async fn main() {
    let me = format!("Lumina Server, version {}", env!("CARGO_PKG_VERSION"));
    let ev_log: EventLogger = EventLogger::new(&None).await;
    let args: Vec<String> = std::env::args().skip(1).collect();
    match (
        args.is_empty(),
        args.first().unwrap_or(&String::new()).as_str(),
    ) {
        (true, _) | (false, "start") | (false, "") => {
            dotenv().ok();
            info_elog!(ev_log, "Starting {}.", me.clone().color_lightblue());
            println!(
                "{} {} and contributors, licenced under {}.",
                message_prefixes().0,
                "MLC Bloeiman".color_pink(),
                "BSD-3".color_blue()
            );
            println!("{}", cynthia_con::horizline());
            warn_elog!(
                ev_log,
                "Lumina is still in early development, and should not be used in production in any way. Please use at your own risk."
            );
            match config_get() {
                Ok(config) => {
                    let mut interval =
                        tokio::time::interval(std::time::Duration::from_millis(3000));
                    let mut db_mut: Option<DbConn> = None;
                    let mut ev_log: EventLogger = EventLogger::new(&db_mut).await;

                    let mut db_tries: usize = 0;
                    while db_mut.is_none() {
                        interval.tick().await;
                        db_mut = match database::setup().await {
                            Ok(db) => Some(db),
                            Err(LuminaError::ConfMissing(a)) => {
                                error_elog!(
                                    ev_log,
                                    "Missing environment variable {}, which is required to continue. Please make sure it is set, or change other variables to make it redundant, if possible.",
                                    a.color_bright_orange()
                                );
                                None
                            }
                            Err(LuminaError::ConfInvalid(a)) => {
                                error_elog!(
                                    ev_log,
                                    "Invalid environment variable: {}",
                                    a.color_bright_orange()
                                );
                                None
                            }

                            Err(LuminaError::Postgres(a)) => {
                                error_elog!(ev_log, "While connecting to postgres database: {}", a);
                                None
                            }
                            Err(LuminaError::R2D2Pool(a)) => {
                                error_elog!(ev_log, "While setting up database pool: {}", a);
                                None
                            }
                            Err(LuminaError::Redis(a)) => {
                                error_elog!(ev_log, "While connecting to Redis: {}", a);
                                None
                            }
                            Err(_) => {
                                error_elog!(
                                    ev_log,
                                    "Unknown error: could not setup database connection.",
                                );
                                None
                            }
                        };
                        if db_mut.is_none() {
                            if db_tries < 4 {
                                db_tries += 1;
                                warn_elog!(
                                    ev_log,
                                    "Retrying database connection in 3 seconds. (try {})",
                                    db_tries
                                )
                            } else {
                                error_elog!(
                                    ev_log,
                                    "Failed to connect to database four times, not retrying."
                                );
                                process::exit(1);
                            }
                        } else {
                            // update ev_log, since clearly, it's no longer a question
                            ev_log = EventLogger::new(&db_mut).await;

                            success_elog!(ev_log, "Database connected.")
                        }
                    }
                    let ev_log = EventLogger::new(&db_mut).await;
                    let db = db_mut.unwrap();

                    if cfg!(debug_assertions) {
                        let mut redis_conn = db.get_redis_pool().get().unwrap();
                        timeline::invalidate_timeline_cache(
                            &mut redis_conn,
                            "00000000-0000-0000-0000-000000000000",
                        )
                        .await
                        .unwrap();
                        let global = timeline::fetch_timeline_post_ids(
                            ev_log.clone().await,
                            &db,
                            "00000000-0000-0000-0000-000000000000",
                            None,
                        )
                        .await
                        .unwrap_or_default();
                        if global.1 == 0 {
                            println!(
                                "Debug mode: Inserting Hello World post and two test users if not exists."
                            );

                            let generated_uuid = Uuid::new_v4();
                            let hello_content = "Hello world";

                            match db.recreate().await.unwrap() {
                                DbConn::PgsqlConnection((client, _), _) => {
                                    // Insert Hello World post and timeline entry if not exists
                                    let user_1_: Result<user::User, LuminaError> =
                                        match user::User::create_user(
                                            String::from("test@lumina123.co"),
                                            String::from("testuser1"),
                                            String::from("MyTestPassw9292!"),
                                            &db,
                                        )
                                        .await
                                        {
                                            Ok(a) => Ok(a),
                                            // But if a user exists, we just pass the user.
                                            Err(LuminaError::RegisterUsernameInUse)
                                            | Err(LuminaError::RegisterEmailInUse) => {
                                                user::User::get_user_by_identifier(
                                                    String::from("testuser1"),
                                                    &db,
                                                )
                                                .await
                                            }
                                            Err(e) => Err(e),
                                        };

                                    let user_2_ = match user::User::create_user(
                                        String::from("test@lumina234.co"),
                                        String::from("testuser2"),
                                        String::from("MyTestPassw9292!"),
                                        &db,
                                    )
                                    .await
                                    {
                                        Ok(a) => Ok(a),
                                        // But if a user exists, we just pass the user.
                                        Err(LuminaError::RegisterUsernameInUse)
                                        | Err(LuminaError::RegisterEmailInUse) => {
                                            user::User::get_user_by_identifier(
                                                String::from("testuser2"),
                                                &db,
                                            )
                                            .await
                                        }
                                        Err(e) => Err(e),
                                    };

                                    match (user_1_, user_2_) {
                                        (Ok(user_1), Ok(user_2)) => {
                                            println!(
                                                "Created two users with password 'MyTestPassw9292!' and usernames 'testuser1' and 'testuser2'."
                                            );
                                            let _ = client
												.execute(
													"INSERT INTO post_text (id, author_id, content, created_at) VALUES ($1, $2, $3, CURRENT_TIMESTAMP) ON CONFLICT (id) DO NOTHING",
													&[&generated_uuid, &user_1.id, &hello_content],
												)
												.await;
                                            let add_clone = ev_log.clone().await;
                                            timeline::add_to_timeline(
                                                add_clone,
                                                &db,
                                                "00000000-0000-0000-0000-000000000000",
                                                &generated_uuid.to_string().as_str(),
                                            )
                                            .await
                                            .unwrap_or(());
                                            ()
                                        }
                                        z => {
                                            println!(
                                                "Ran into some issues: user 1: {:?}, user 2: {:?} ",
                                                z.0, z.1
                                            );
                                            ()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    let appstate = AppState(Arc::from((
                        config.clone(),
                        Mutex::from(db),
                        ev_log.clone().await,
                    )));

                    // Create a simple in-memory IP-based rate limiter.
                    // Default: allow 5 events per 10 seconds (0.5 tokens/sec) with capacity 10.
                    let rate_limiter = GeneralRateLimiter::new(0.5, 10.0);

                    // Dedicated, stricter limiter for authentication attempts (helps stop brute-force):
                    // e.g. allow 2 attempts per 10 seconds (0.2 tokens/sec) with capacity 4.
                    let auth_rate_limiter = AuthRateLimiter::new(0.2, 4.0);

                    let def = rocket::Config {
                        port: config.port,
                        address: config.host,
                        // TODO: Use Lumina's logging instead, no logging is bad practise.
                        // Technically, we currently do this by just shipping it into each http
                        // route. HOWEVER, we don't have a 404 route!
                        log_level: LogLevel::Critical,
                        ..rocket::Config::default()
                    };

                    let result = rocket::build()
                        .configure(def)
                        .mount(
                            "/",
                            routes![
                                staticroutes::index,
                                staticroutes::lumina_js,
                                staticroutes::lumina_css,
                                client_communication::wsconnection,
                                staticroutes::logo_svg,
                                staticroutes::logo_png,
                                staticroutes::favicon,
                            ],
                        )
                        .manage(appstate)
                        .manage(rate_limiter)
                        .manage(auth_rate_limiter)
                        .launch()
                        .await
                        .map_err(LuminaError::RocketFaillure);
                    match result {
                        Ok(_) => {}
                        Err(LuminaError::RocketFaillure(e)) => {
                            // This handling should slowly expand as I run into newer ones, the 'defh' (default handling) is good enough, but for the most-bumped into errors, I'd like to give more human responses.
                            let defh =
                                async || error_elog!(ev_log, "Error starting server: {:?}", e);
                            match e.kind() {
                                rocket::error::ErrorKind::Bind(e) => match e.kind() {
                                    ErrorKind::AddrInUse => {
                                        error_elog!(
                                            ev_log,
                                            "Another program or instance is running on this port or adress."
                                        );
                                        soft_error_elog!(
                                            ev_log,
                                            "Make sure you have not double-started Lumina, or have a different program serving on this port!"
                                        );
                                        soft_error_elog!(
                                            ev_log,
                                            "{}",
                                            format!("Technical explanation: {}", e).style_dim()
                                        );
                                    }
                                    _ => defh().await,
                                },
                                _ => defh().await,
                            }
                            process::exit(1);
                        }
                        Err(_) => {
                            error_elog!(ev_log, "Unknown error starting server.",);
                        }
                    }
                }
                Err(LuminaError::ConfMissing(a)) => {
                    error_elog!(
                        ev_log,
                        "Missing environment variable {}, which is required to continue. Please make sure it is set, or change other variables to make it redundant, if possible.",
                        a.color_bright_orange()
                    );
                    process::exit(1);
                }
                Err(LuminaError::ConfInvalid(a)) => {
                    error_elog!(
                        ev_log,
                        "Invalid environment variable: {}",
                        a.color_bright_orange()
                    );
                    process::exit(1);
                }
                Err(_) => {
                    error_elog!(
                        ev_log,
                        "Unknown error: could not setup server configuration.",
                    );
                    process::exit(1);
                }
            };
        }
        (false, "licence") | (false, "license") => {
            println!(
                "Licence for {} and its {}.",
                me.color_lightblue().style_italic(),
                "Lumina Client".color_yellow().style_italic()
            );
            println!("MLC Bloeiman and contributors.");
            println!("{}", cynthia_con::horizline());
            println!("{}", include_str!("../../LICENSE"));
        }
        (false, "help") | (false, "man") => {
            fn table_to_centered_string(a: &mut tabled::Table) -> String {
                let s: Vec<String> = a
                    .to_string()
                    .split("\n")
                    .map(|s| s.style_centered())
                    .collect();
                let d = s.join("\n");
                d
            }
            println!("{}", me);
            {
                println!("{}", "Subcommands".style_centered().style_bold());
                println!();
                println!(
                    "\t\t{}|{}\tShow this help",
                    "help".color_lightblue().style_italic(),
                    "man".color_lightblue().style_italic()
                );
                println!(
                    "\t\t{}\t\tShow version and exit",
                    "version".color_lightblue().style_italic()
                );
                println!(
                    "\t\t{}\t\tShow licence and exit",
                    "licence".color_lightblue().style_italic()
                );
                println!(
                    "\t\t{}\t\tStart Lumina server",
                    "start".color_lightblue().style_italic()
                );
            }
            println!();
            {
                println!("{}", "Environment variables".style_centered().style_bold());
                println!();
                let mut builder = tabled::builder::Builder::new();
                builder.push_record(["Name", "Default value", "Description"]);
                builder.push_record(["LUMINA_DB_TYPE", r#"sqlite"#, r#"The kind of database to use. Options are 'postgres' (recommended) or 'sqlite'."#]);
                builder.push_record([
                    "LUMINA_REDIS_URL",
                    r#"redis://127.0.0.1/"#,
                    r#"The URL for the Redis server."#,
                ]);
                builder.push_record([
                    "LUMINA_DB_SALT",
                    r#"sal"#,
                    r#"The salting to use for some data on the database."#,
                ]);
                builder.push_record([
                    "LUMINA_SERVER_PORT",
                    r#"8085"#,
                    r#"Port for Lumina to accept HTTP requests on."#,
                ]);
                builder.push_record(["LUMINA_SERVER_ADDR", r#"127.0.0.1"#, "Address for Lumina to accept HTTP requests on. (usually '127.0.0.1' or '0.0.0.0')"]);
                builder.push_record(["LUMINA_SERVER_HTTPS", r#"false"#, "Wether to use 'https' rather than 'http' in links, etc. Recommendation is to set to true."]);
                builder.push_record([
                    "LUMINA_SYNC_IID",
                    r#"localhost"#,
                    "Broadcasted domain name, should be equal to public domain name.",
                ]);
                builder.push_record([
                    "LUMINA_SYNC_INTERVAL",
                    r#"30"#,
                    "Specifies the interval between syncs. Minimum is 30.",
                ]);
                println!(
                    "{}",
                    table_to_centered_string(
                        builder.build().with(tabled::settings::Style::modern())
                    )
                    .style_dim()
                );
                println!();
                println!(
                    "{}",
                    format!(
                        r#"When having "LUMINA_DB_TYPE" set to '{}': (recommended)"#,
                        "postgres".color_lilac().style_bold()
                    )
                    .style_centered()
                    .style_italic()
                );
                let mut builder = tabled::builder::Builder::new();
                builder.push_record(["Name", "Default value", "Description"]);
                builder.push_record([
                    "LUMINA_POSTGRES_PORT",
                    r#"5432"#,
                    r#"The port to contact the database on."#,
                ]);
                builder.push_record([
                    "LUMINA_POSTGRES_HOST",
                    r#"localhost"#,
                    r#"The address to contact the database on."#,
                ]);
                builder.push_record([
                    "LUMINA_POSTGRES_USERNAME",
                    r#""#,
                    r#"The username to log in to the database with."#,
                ]);
                builder.push_record(["LUMINA_POSTGRES_PASSWORD", r#""#, r#"The password to log in to the database with. If not set, Lumina will try without."#]);
                builder.push_record([
                    "LUMINA_POSTGRES_DATABASE",
                    r#""#,
                    r#"The name of the database to use."#,
                ]);
                println!(
                    "{}",
                    table_to_centered_string(
                        builder.build().with(tabled::settings::Style::modern())
                    )
                    .color_lilac()
                    .style_dim()
                );

                println!();
                println!(
                    "{}",
                    format!(
                        r#"When having "LUMINA_DB_TYPE" set to '{}':"#,
                        "sqlite".color_bright_orange().style_bold()
                    )
                    .style_centered()
                    .style_italic()
                );
                let mut builder = tabled::builder::Builder::new();
                builder.push_record(["Name", "Default value", "Description"]);

                builder.push_record([
                    "LUMINA_SQLITE_FILE",
                    r#"instance.sqlite"#,
                    "SQLite file to connect to. Always a relative path from the instance folder.",
                ]);
                println!(
                    "{}",
                    table_to_centered_string(
                        builder.build().with(tabled::settings::Style::modern())
                    )
                    .color_bright_orange()
                    .style_dim()
                )
            }
        }
        (false, unknown) => {
            soft_error_elog!(
                ev_log,
                "Unknown subcommand, '{}', use '{}' for available commands.'",
                unknown.color_blue().style_italic(),
                "help".color_lightblue().style_italic()
            )
        }
    }
}
