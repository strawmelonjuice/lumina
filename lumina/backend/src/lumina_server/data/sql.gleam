//// This module contains the code to run the sql queries defined in
//// `./src/lumina_server/data/sql`.
//// > 🐿️ This module was generated automatically using v4.7.0 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/option.{type Option}
import pog
import youid/uuid.{type Uuid}

/// A row you get from running the `create_authenticated_usersession` query
/// defined in `./src/lumina_server/data/sql/create_authenticated_usersession.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateAuthenticatedUsersessionRow {
  CreateAuthenticatedUsersessionRow(username: String, email: Option(String))
}

/// Creates an authenticated session from a session id, and a user id.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_authenticated_usersession(
  db: pog.Connection,
  arg_1: Uuid,
  id: BitArray,
  arg_3: BitArray,
) -> Result(pog.Returned(CreateAuthenticatedUsersessionRow), pog.QueryError) {
  let decoder = {
    use username <- decode.field(0, decode.string)
    use email <- decode.field(1, decode.optional(decode.string))
    decode.success(CreateAuthenticatedUsersessionRow(username:, email:))
  }

  "-- Creates an authenticated session from a session id, and a user id.



WITH inserted AS (
	INSERT
		INTO usersessions (id, user_id, session_key)
		VALUES ($1, $2, $3)
		RETURNING 1
)
SELECT username,email
	FROM users
	WHERE instance_id = '00000000-0000-0000-0000-000000000000'
	AND id = $2
	AND EXISTS (SELECT 1 FROM inserted)
	LIMIT 1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.bytea(id))
  |> pog.parameter(pog.bytea(arg_3))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_self_instance` query
/// defined in `./src/lumina_server/data/sql/get_self_instance.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetSelfInstanceRow {
  GetSelfInstanceRow(name: String)
}

/// Returns the instances' own entry in the instances table. This is usually a check: It's there to make sure the entry
/// exists, before we can create users based on it.
///
/// Once this returns an instance name, none will be written to the database again, even after it changing in the
/// configuration.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_self_instance(
  db: pog.Connection,
) -> Result(pog.Returned(GetSelfInstanceRow), pog.QueryError) {
  let decoder = {
    use name <- decode.field(0, decode.string)
    decode.success(GetSelfInstanceRow(name:))
  }

  "-- Returns the instances' own entry in the instances table. This is usually a check: It's there to make sure the entry
-- exists, before we can create users based on it.
--
-- Once this returns an instance name, none will be written to the database again, even after it changing in the
-- configuration.
SELECT name
	FROM instances
	WHERE id = '00000000-0000-0000-0000-000000000000'
	LIMIT 1;
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_valid_invites` query
/// defined in `./src/lumina_server/data/sql/get_valid_invites.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetValidInvitesRow {
  GetValidInvitesRow(invite_code: String)
}

/// Gets the list of instance invite codes for which `valid` is `True`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_valid_invites(
  db: pog.Connection,
) -> Result(pog.Returned(GetValidInvitesRow), pog.QueryError) {
  let decoder = {
    use invite_code <- decode.field(0, decode.string)
    decode.success(GetValidInvitesRow(invite_code:))
  }

  "-- Gets the list of instance invite codes for which `valid` is `True`.

SELECT invite_code
	FROM invites
	WHERE valid = TRUE;
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `local_user_id_by_email` query
/// defined in `./src/lumina_server/data/sql/local_user_id_by_email.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type LocalUserIdByEmailRow {
  LocalUserIdByEmailRow(id: BitArray)
}

/// Gets a local user's id (publickey) from the database based on the email they use.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn local_user_id_by_email(
  db: pog.Connection,
  email: String,
) -> Result(pog.Returned(LocalUserIdByEmailRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.bit_array)
    decode.success(LocalUserIdByEmailRow(id:))
  }

  "-- Gets a local user's id (publickey) from the database based on the email they use.

SELECT id
	FROM users
	WHERE instance_id = '00000000-0000-0000-0000-000000000000'
	AND email = $1
	LIMIT 1;
"
  |> pog.query
  |> pog.parameter(pog.text(email))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `local_user_id_by_username` query
/// defined in `./src/lumina_server/data/sql/local_user_id_by_username.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type LocalUserIdByUsernameRow {
  LocalUserIdByUsernameRow(id: BitArray)
}

/// Gets a local user's id (publickey) from the database based on the username they use.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn local_user_id_by_username(
  db: pog.Connection,
  username: String,
) -> Result(pog.Returned(LocalUserIdByUsernameRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.bit_array)
    decode.success(LocalUserIdByUsernameRow(id:))
  }

  "-- Gets a local user's id (publickey) from the database based on the username they use.

SELECT id
	FROM users
	WHERE instance_id = '00000000-0000-0000-0000-000000000000'
	AND username = $1
	LIMIT 1;
"
  |> pog.query
  |> pog.parameter(pog.text(username))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `password_hash_for_userid` query
/// defined in `./src/lumina_server/data/sql/password_hash_for_userid.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type PasswordHashForUseridRow {
  PasswordHashForUseridRow(password: Option(String))
}

/// Gets a local user's password hash from the database for their id (publickey).
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn password_hash_for_userid(
  db: pog.Connection,
  id: BitArray,
) -> Result(pog.Returned(PasswordHashForUseridRow), pog.QueryError) {
  let decoder = {
    use password <- decode.field(0, decode.optional(decode.string))
    decode.success(PasswordHashForUseridRow(password:))
  }

  "-- Gets a local user's password hash from the database for their id (publickey).

SELECT password
	FROM users
	WHERE instance_id = '00000000-0000-0000-0000-000000000000'
	AND id = $1
	LIMIT 1;
"
  |> pog.query
  |> pog.parameter(pog.bytea(id))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Sets the instance name and creates the id for the local instance, this is required for a lot of things and shouldn't
/// change afterwards! After this, a first (admin) user should be created!
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn set_self_instance(
  db: pog.Connection,
  arg_1: String,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "-- Sets the instance name and creates the id for the local instance, this is required for a lot of things and shouldn't
-- change afterwards! After this, a first (admin) user should be created!
INSERT
	INTO instances (id, name)
	VALUES (uuid_nil(), $1);
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}
