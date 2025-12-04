//! Lumina > Server > Helpers > Events
//!
//! This module provides an event logging utility that logs messages to stdout
//! with colored prefixes and optionally logs them to a database.
//!
//! This helps increase consistency in logging throughout the server codebase, centralises it, and
//! improves readability and distinctability with its colored output.
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

use crate::LuminaError;
use crate::database::{DatabaseConnections, DbConn, PgConn};
use cynthia_con::{CynthiaColors, CynthiaStyles};
use time::OffsetDateTime;

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
    AuthenticationError,
    SoftError,
    HTTPCode(u16),
}

/// A reusable logger that logs messages to stdout with colored prefixes
/// and, when available, also logs entries into the database.
///
/// The database log entry is simple, with the log type, the message, and a timestamp.
pub enum EventLogger {
    /// Variant created when logger has a database, and the database nor environment have any settings blocking database logging.
    WithDatabase(Box<PgConn>),
    /// Only log to stdout
    OnlyStdout,
}

impl EventLogger {
    /// Creates a new logger instance.
    /// The `db` parameter can be `None` if the database isn't connected.
    pub async fn new(db: &Option<PgConn>) -> Self {
        // For quick implementation we'll just check if not none and that's all.
        match db {
            Some(d) => Self::from_db(d).await,
            None => Self::OnlyStdout,
        }
    }
    pub async fn new_l(db: &Option<DbConn>) -> Self {
        // For quick implementation we'll just check if not none and that's all.
        match db {
            Some(d) => Self::from_db_l(d).await,
            None => Self::OnlyStdout,
        }
    }

    pub async fn from_db_l(db_: &DbConn) -> Self {
        match db_.recreate().await {
            Ok(db) => {
                let new_db = DbConn::to_pgconn(db);
                Self::WithDatabase(Box::new(new_db))
            }
            Err(error) => {
                let n = Self::OnlyStdout;
                n.error(
                    format!("Could not connect the logger to the database! {:?}", error).as_str(),
                )
                .await;
                n
            }
        }
    }

    pub async fn from_db(db_: &PgConn) -> Self {
        match db_.recreate().await {
            Ok(new_db) => Self::WithDatabase(Box::new(new_db)),
            Err(error) => {
                let n = Self::OnlyStdout;
                n.error(
                    format!("Could not connect the logger to the database! {:?}", error).as_str(),
                )
                .await;
                n
            }
        }
    }

    pub async fn clone(&self) -> Self {
        match self {
            EventLogger::WithDatabase(db) => Self::from_db(db).await,
            EventLogger::OnlyStdout => Self::OnlyStdout,
        }
    }

    /// Logs a message with the specified log level.
    /// This method prints to stdout with a colored prefix and, if a database connection is available,
    /// asynchronously inserts a log entry in the logs table.
    pub async fn log(&self, level: EventType, message: &str) {
        // Get the current timestamp.
        let now = OffsetDateTime::now_utc();

        // Determine the appropriate prefix for stdout.
        // These prefixes are colored and styled matching helpers::prefixes().
        let (prefix, use_eprintln) = match level {
            EventType::Info => ("[INFO]".color_green().style_bold(), false),
            EventType::Warn => ("[WARN]".color_yellow().style_bold(), false),
            EventType::Error => ("[ERROR]".color_error_red().style_bold(), true),
            EventType::SoftError => ("[ERROR]".color_error_red().style_bold(), false),
            EventType::Success => ("[✅ SUCCESS]".color_ok_green().style_bold(), false),
            EventType::Failure => ("[✖️ FAILURE]".color_error_red().style_bold(), false),
            EventType::Log => ("[LOG]".color_blue().style_bold(), false),
            EventType::Incoming => ("[INCOMING]".color_lilac().style_bold(), false),
            EventType::RegistrationError => {
                ("[RegistrationError]".color_bright_red().style_bold(), true)
            }
            EventType::AuthenticationError => (
                "[AuthenticationError]".color_bright_red().style_bold(),
                true,
            ),
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
            EventLogger::WithDatabase(db_conn) => {
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
                    EventType::AuthenticationError => String::from("AUTHENTICATION_ERROR"),
                    EventType::HTTPCode(code) => format!("HTTP/{}", code),
                };
                let ansi_regex = regex::Regex::new(r"\x1B\[[0-?]*[ -/]*[@-~]")
                    .map_err(|_| LuminaError::RegexError)
                    .unwrap();

                let message_db: String = ansi_regex
                    .replace_all(message, "")
                    .to_string()
                    .chars()
                    .filter(|c| !c.is_control() || c.is_whitespace())
                    .collect();
                let ts = now
                    .format(&time::format_description::well_known::Rfc3339)
                    .unwrap();

                let _ = db_conn
                    .postgres
                    .execute(
                        "INSERT INTO logs (type, message, timestamp) VALUES ($1, $2, $3)",
                        &[&level_str, &message_db, &ts],
                    )
                    .await;
            } 
            EventLogger::OnlyStdout => {
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
    /// Convenience method to log a registration error message.
    pub async fn authentication_error(&self, message: &str) {
        self.log(EventType::AuthenticationError, message).await
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
/// Takes an event log object and then runs .authentication_error on it, formatting using the other
/// arguments.
macro_rules! authentication_error_elog {
    ($logger:expr, $($arg:tt)*) => {
        $logger.authentication_error(&format!($($arg)*)).await
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
