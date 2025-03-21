use crate::postgres;
use crate::sqlite;
pub(crate) enum LuminaError {
    ConfMissing(String),
    ConfInvalid(String),
    Sqlite(sqlite::Error),
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
}
