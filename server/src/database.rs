use crate::errors::LuminaError::{self, ConfMissing};
use tokio_postgres as postgres;
use tokio_postgres::tls::NoTlsStream;
use tokio_postgres::{Client, Connection, Socket};
use tokio_sqlite as sqlite;

pub(crate) async fn setup(config: crate::ServerConfig) -> Result<DbConn, LuminaError> {
    // match (env::var("LUMINA_DB_TYPE").map_err(|_| ConfMissing("LUMINA_DB_TYPE".to_string()))?)
    //     .as_str()
    // {
    //     "sqlite" => {
    //         let db_path = env::var("LUMINA_DB_PATH").unwrap_or("instance.sqlite".to_string());
    //         let conn = sqlite::Connection::open(db_path)
    //             .await
    //             .map_err(LuminaError::Sqlite)?;
    //         Ok(DbConn::SqliteConnection(conn))
    //     }
    //     "postgres" => {
    let pg_config = {
        let mut pg_config = postgres::Config::new();
        pg_config.user(&{
            std::env::var("_LUMINA_POSTGRES_USERNAME_")
                .map_err(|_| ConfMissing("_LUMINA_POSTGRES_USERNAME_".to_string()))?
        });
        pg_config.dbname(&{
            std::env::var("_LUMINA_POSTGRES_DATABASE_")
                .map_err(|_| ConfMissing("_LUMINA_POSTGRES_DATABASE_".to_string()))?
        });
        pg_config.port(std::env::var("_LUMINA_POSTGRES_PORT_").unwrap_or_else(|_| {
                    warn!("No Postgres database port provided under environment variable '_LUMINA_POSTGRES_PORT_'. Using default value '5432'.");
                    "5432".to_string()
                }).parse::<u16>().map_err(|_| { LuminaError::ConfInvalid("_LUMINA_POSTGRES_PORT_ is not a valid integer number".to_string()) })?);
        match std::env::var("_LUMINA_POSTGRES_HOST_") {
            Ok(val) => {
                pg_config.host(&val);
            }
            Err(_) => {
                warn!(
                    "No Postgres database host provided under environment variable '_LUMINA_POSTGRES_HOST_'. Using default value 'localhost'."
                );
                pg_config.host("localhost");
            }
        };
        match std::env::var("_LUMINA_POSTGRES_PASSWORD_") {
            Ok(val) => {
                pg_config.password(&val);
            }
            Err(_) => {
                info!(
                    "No Postgres database password provided under environment variable '_LUMINA_POSTGRES_PASSWORD_'. Trying passwordless authentication."
                );
            }
        };
        pg_config
    };
    let conn: (Client, Connection<Socket, NoTlsStream>) = pg_config
        .connect(postgres::tls::NoTls)
        .await
        .map_err(LuminaError::Postgres)?;
    let _ = tokio::spawn(conn.1);
    {
        // Set up the database
        let _ = conn
            .0
            .execute(
                "CREATE TABLE IF NOT EXISTS users (
						id UUID DEFAULT gen_random_uuid (),
						email VARCHAR NOT NULL,
						username VARCHAR NOT NULL UNIQUE,
						password VARCHAR NOT NULL
					)",
                &[],
            )
            .await
            .map_err(LuminaError::Postgres)?;
    }
    Ok(DbConn::PgsqlConnection(conn.0))
    //     }
    //     _ => {
    //         Err(LuminaError::ConfInvalid(
    //             // "LUMINA_DB_TYPE does not contain a valid value, only 'sqlite' or 'postgres' are allowed.".to_string()
    //             "LUMINA_DB_TYPE does not contain a valid value, only 'postgres' is allowed."
    //                 .to_string(),
    //         ))
    //     }
    // }
}

// This will be an enum containing either a pgsql connection or a sqlite connection
#[derive()]
pub enum DbConn {
    PgsqlConnection(postgres::Client),
    SqliteConnection(()),
}
