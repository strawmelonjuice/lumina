use crate::postgres;
use crate::sqlite;
use r2d2_sqlite::rusqlite;
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
    EmailNotValid,
    RegisterUsernameInvalid,
    PasswordNotValid,
    LoginInvalid,
    UUidError(uuid::Error),
}
