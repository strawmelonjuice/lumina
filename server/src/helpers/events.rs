use crate::database::DbConn;
use crate::helpers::message_prefixes;
use crate::{LuminaError, database};
use chrono::Utc;
use cynthia_con::{CynthiaColors, CynthiaStyles};

/// Levels of logging supported by the Logger.
#[derive(Debug)]
pub enum EventType {
    Info,
    Warn,
    Error,
    Success,
    Failure,
    Log,
    Incoming,
    RegistrationError,
    SoftError,
    HTTPCode(u16),
}

/// A reusable logger that logs messages to stdout with colored prefixes
/// and, when available, also logs entries into the database.
///
/// The database log entry is simple, with the log type, the message, and a timestamp.
pub enum EventLogger {
    /// Variant created when logger has a database, and the database nor environment have any settings blocking database logging.
    WithDatabase { db: DbConn },
    /// Only log to stdout
    OnlyStdout,
}

impl EventLogger {
    /// Creates a new logger instance.
    /// The `db` parameter can be `None` if the database isn't connected.
    pub async fn new(db: &Option<DbConn>) -> Self {
        // For quick implementation we'll just check if not none and that's all.
        match db {
            Some(d) => Self::from_db(d).await,
            None => Self::OnlyStdout,
        }
    }

    pub async fn from_db(db: &DbConn) -> Self {
        match db {
            DbConn::PgsqlConnection(_, pg_config) => {
                match pg_config
                    .connect(tokio_postgres::tls::NoTls)
                    .await
                    .map_err(LuminaError::Postgres)
                {
                    Ok((client, _)) => {
                        let new_dbconn =
                            database::DbConn::PgsqlConnection(client, pg_config.clone());
                        Self::WithDatabase { db: new_dbconn }
                    }

                    Err(error) => {
                        let n = Self::OnlyStdout;
                        n.error(
                            format!("Could not connect the logger to the database! {:?}", error)
                                .as_str(),
                        )
                        .await;
                        n
                    }
                }
            }
            DbConn::SqliteConnectionPool(pool) => {
                let new_dbconn = database::DbConn::SqliteConnectionPool(pool.clone());
                Self::WithDatabase { db: new_dbconn }
            }
        }
    }

    pub async fn clone(&self) -> Self {
        match self {
            EventLogger::WithDatabase { db } => Self::from_db(db).await,
            EventLogger::OnlyStdout => Self::OnlyStdout,
        }
    }

    /// Logs a message with the specified log level.
    /// This method prints to stdout with a colored prefix and, if a database connection is available,
    /// asynchronously inserts a log entry in the logs table.
    pub async fn log(&self, level: EventType, message: &str) {
        // Get the current timestamp.
        let now = Utc::now();

        // Determine the appropriate prefix for stdout.
        let (info, warn, error, success, failure, log, incoming, registrationerror) =
            message_prefixes();
        let (prefix, use_eprintln) = match level {
            EventType::Info => (info, false),
            EventType::Warn => (warn, false),
            EventType::Error => (error, true),
            EventType::SoftError => (error, false),
            EventType::Success => (success, false),
            EventType::Failure => (failure, false),
            EventType::Log => (log, false),
            EventType::Incoming => (incoming, false),
            EventType::RegistrationError => (registrationerror, true),
            EventType::HTTPCode(code) => {
                let codestring = match code {
                    101 => format!("[HTTP/{} (Switching Protocols)]", code)
                        .color_blue()
                        .style_bold(),
                    200..=299 => format!("[HTTP/{} (OK)]", code)
                        .color_ok_green()
                        .style_bold(),
                    400..=499 => format!("[HTTP/{} (Client Error)]", code)
                        .color_yellow()
                        .style_bold(),

                    500..=599 => format!("[HTTP/{} (Server Error)]", code)
                        .color_error_red()
                        .style_bold(),
                    _ => format!("[HTTP/{}]", code).color_blue().style_bold(),
                };
                match code {
                    200..=499 => (codestring, false),
                    500..=599 => (codestring, true),
                    _ => (codestring, false),
                }
            }
        };

        let stdoutmsg =
            format!("{prefix} {message}").replace("\n", format!("\n{prefix} ").as_str());

        // Log to the database if a connection is available.
        match self {
            EventLogger::WithDatabase { db: db_conn } => {
                // Log to stdout with the prefix.
                if use_eprintln {
                    eprintln!("{stdoutmsg}");
                } else {
                    println!("{stdoutmsg}");
                }
                // Prepare the basic values for the log entry.
                let level_str = match level {
                    EventType::Info => String::from("INFO"),
                    EventType::Warn => String::from("WARN"),
                    EventType::SoftError | EventType::Error => String::from("ERROR"),
                    EventType::Success => String::from("SUCCESS"),
                    EventType::Failure => String::from("FAILURE"),
                    EventType::Log => String::from("LOG"),
                    EventType::Incoming => String::from("INCOMING"),
                    EventType::RegistrationError => String::from("REGISTRATION_ERROR"),
                    EventType::HTTPCode(code) => format!("HTTP/{}", code),
                };
                let ansi_regex = regex::Regex::new(r"\x1B\[[0-?]*[ -/]*[@-~]").unwrap();

                let message_db: String = ansi_regex
                    .replace_all(message, "")
                    .to_string()
                    .chars()
                    .filter(|c| c.is_alphanumeric() || c.is_whitespace())
                    .collect();
                let ts = now.to_rfc3339();

                match db_conn {
                    crate::database::DbConn::PgsqlConnection(client, _) => {
                        let _ = client
                            .execute(
                                "INSERT INTO logs (type, message, timestamp) VALUES ($1, $2, $3)",
                                &[&level_str, &message_db, &ts],
                            )
                            .await;
                    }
                    crate::database::DbConn::SqliteConnectionPool(pool) => {
                        if let Ok(conn) = pool.get() {
                            let _ = conn.execute(
                                "INSERT INTO logs (type, message, timestamp) VALUES (?1, ?2, ?3)",
                                r2d2_sqlite::rusqlite::params![level_str, message_db, ts],
                            );
                        }
                    }
                }
            }
            EventLogger::OnlyStdout { .. } => {
                // Log to stdout with the prefix.
                if use_eprintln {
                    eprintln!("{stdoutmsg}");
                } else {
                    println!("{stdoutmsg}");
                }
            }
        }
    }

    /// Convenience method to log an informational message.
    pub async fn info(&self, message: &str) {
        self.log(EventType::Info, message).await
    }

    /// Convenience method to log a warning message.
    pub async fn warn(&self, message: &str) {
        self.log(EventType::Warn, message).await
    }

    /// Convenience method to log an error message.
    pub async fn error(&self, message: &str) {
        self.log(EventType::Error, message).await
    }
    /// Convenience method to log a soft error message.
    pub async fn s_error(&self, message: &str) {
        self.log(EventType::Error, message).await
    }
    /// Convenience method to log a success message.
    pub async fn success(&self, message: &str) {
        self.log(EventType::Success, message).await
    }

    /// Convenience method to log a failure message.
    pub async fn failure(&self, message: &str) {
        self.log(EventType::Failure, message).await
    }

    /// Convenience method to log a plain message without a specific log level.
    pub async fn log_plain(&self, message: &str) {
        self.log(EventType::Log, message).await
    }

    /// Convenience method to log an incoming message.
    pub async fn incoming(&self, message: &str) {
        self.log(EventType::Incoming, message).await
    }

    /// Convenience method to log a registration error message.
    pub async fn registration_error(&self, message: &str) {
        self.log(EventType::RegistrationError, message).await
    }

    /// Convenience method to log an HTTP code message.
    pub async fn http_code(&self, code: u16, message: &str) {
        self.log(EventType::HTTPCode(code), message).await
    }
}
#[macro_export]
macro_rules! info_elog {
    ($logger:expr, $($arg:tt)*) => {
        $logger.info(&format!($($arg)*)).await
    };
}

#[macro_export]
/// Takes an event log object and then runs .warn on it, formatting using the other arguments.
macro_rules! warn_elog {
    ($logger:expr, $($arg:tt)*) => {
        $logger.warn(&format!($($arg)*)).await
    };
}

#[macro_export]
/// Takes an event log object and then runs .error on it, formatting using the other arguments.
macro_rules! error_elog {
    ($logger:expr, $($arg:tt)*) => {
        $logger.error(&format!($($arg)*)).await
    };
}

#[macro_export]
/// Takes an event log object and then runs .s_error on it, formatting using the other arguments.
macro_rules! soft_error_elog {
    ($logger:expr, $($arg:tt)*) => {
        $logger.s_error(&format!($($arg)*)).await
    };
}

#[macro_export]
/// Takes an event log object and then runs .success on it, formatting using the other arguments.
macro_rules! success_elog {
    ($logger:expr, $($arg:tt)*) => {
        $logger.success(&format!($($arg)*)).await
    };
}

/// Takes an event log object and then runs .faillure on it, formatting using the other arguments.
#[macro_export]
macro_rules! fail_elog {
    ($logger:expr, $($arg:tt)*) => {
        $logger.failure(&format!($($arg)*)).await
    };
}

/// Takes an event log object and then runs .log_plain on it, formatting using the other arguments.
#[macro_export]
macro_rules! elog {
    ($logger:expr, $($arg:tt)*) => {
        $logger.log_plain(&format!($($arg)*)).await
    };
}

#[macro_export]
/// Takes an event log object and then runs .incoming on it, formatting using the other arguments.
macro_rules! incoming_elog {
    ($logger:expr, $($arg:tt)*) => {
        $logger.incoming(&format!($($arg)*)).await
    };
}

#[macro_export]
/// Takes an event log object and then runs .registration_error on it, formatting using the other arguments.
macro_rules! registration_error_elog {
    ($logger:expr, $($arg:tt)*) => {
        $logger.registration_error(&format!($($arg)*)).await
    };
}

#[macro_export]
/// Takes an event log object and then runs .http_code on it, formatting using the other
/// arguments.
macro_rules! http_code_elog {
    ($logger:expr, $code:expr, $($arg:tt)*) =>
        {
            $logger.http_code($code, &format!($($arg)*)).await
        };
}
