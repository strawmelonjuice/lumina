use crate::postgres;
use r2d2_sqlite::rusqlite;
#[derive(Debug)]
pub(crate) enum LuminaError {
    ConfMissing(String),
    ConfInvalid(String),
    Sqlite(rusqlite::Error),
    SqlitePool(r2d2::Error),
    Postgres(postgres::Error),
    Unknown,
    RocketFaillure(rocket::Error),
    UuidConversion(uuid::Error),
    BcryptError(bcrypt::BcryptError),
    RegisterEmailInUse,
    RegisterUsernameInUse,
    RegisterEmailNotValid,
    RegisterUsernameInvalid(String),
    RegisterPasswordNotValid(String),
    LoginInvalid,
    UUidError(uuid::Error),
    RegexError(regex::Error),
}
