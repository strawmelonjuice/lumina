//// This module contains the code to run the sql queries defined in
//// `./src/lumina_server/data/sql`.
//// > 🐿️ This module was generated automatically using v4.7.0 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/option.{type Option}
import pog
import youid/uuid.{type Uuid}

/// A row you get from running the `consume_invite` query
/// defined in `./src/lumina_server/data/sql/consume_invite.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ConsumeInviteRow {
  ConsumeInviteRow(username: String, email: Option(String))
}

/// If invite code is valid, use it, assigning it to a new user id and invalidating it.
///
/// This query has a lot of parameters! So here's a short list:
/// 1. The new user's generated ID (public key)
/// 2. The used invite code
/// 3. The new user's email
/// 4. The new user's displayname
/// 5. The new user's username
/// 6. The new user's password
/// 7. The new user's generated private key
/// 8. The session ID to log in to this new account
/// 9. Newly assigned usersession id.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn consume_invite(
  db: pog.Connection,
  arg_1: BitArray,
  arg_2: String,
  arg_3: String,
  arg_4: String,
  arg_5: String,
  arg_6: String,
  arg_7: BitArray,
  arg_8: Uuid,
  arg_9: BitArray,
) -> Result(pog.Returned(ConsumeInviteRow), pog.QueryError) {
  let decoder = {
    use username <- decode.field(0, decode.string)
    use email <- decode.field(1, decode.optional(decode.string))
    decode.success(ConsumeInviteRow(username:, email:))
  }

  "-- If invite code is valid, use it, assigning it to a new user id and invalidating it.
--
-- This query has a lot of parameters! So here's a short list:
-- 1. The new user's generated ID (public key)
-- 2. The used invite code
-- 3. The new user's email
-- 4. The new user's displayname
-- 5. The new user's username
-- 6. The new user's password
-- 7. The new user's generated private key
-- 8. The session ID to log in to this new account
-- 9. Newly assigned usersession id.

WITH data(user_id, invite_code, email, displayname, username, password, private_key, session_id, usersession_id) AS (
	VALUES
	($1::bytea, $2, $3, $4, $5, $6, $7::bytea, $8::uuid, $9::bytea)
), check_invite AS (
	SELECT invite_code
		FROM invites
		WHERE valid = TRUE
		AND invite_code = (SELECT invite_code FROM data)
),      user_insert AS (
         INSERT
             INTO users (id, private_key, instance_id, email, displayname, username, password)

                 VALUES (
					(SELECT user_id FROM data), -- id (pubkey)
                         (SELECT private_key FROM data), -- private key
                         uuid_nil(), -- instance id
                    	(SELECT email FROM data), -- email
                         (SELECT displayname FROM data), -- displayname
                         (SELECT username FROM data), -- username
                    	(SELECT password FROM data) -- password
                        )
                 RETURNING id, username, email),
invite_consume AS (
    UPDATE invites
        SET valid = FALSE,
            used_by = (SELECT user_id FROM data)
        WHERE invite_code = (SELECT invite_code FROM check_invite)
	),

     session_insert AS (
         INSERT
             INTO usersessions (id, user_id, session_key)
                 VALUES ((SELECT session_id FROM data), -- Session ID
                         (SELECT user_id FROM data), -- User ID
                         (SELECT usersession_id FROM data) -- Usersession key
                        )
                 RETURNING 1)

SELECT username, email
	FROM user_insert
	WHERE EXISTS (SELECT 1 FROM session_insert)
LIMIT 1;
"
  |> pog.query
  |> pog.parameter(pog.bytea(arg_1))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(pog.text(arg_4))
  |> pog.parameter(pog.text(arg_5))
  |> pog.parameter(pog.text(arg_6))
  |> pog.parameter(pog.bytea(arg_7))
  |> pog.parameter(pog.text(uuid.to_string(arg_8)))
  |> pog.parameter(pog.bytea(arg_9))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

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

/// Writes a new user account, does not check for invites, does not create a session.
///
/// This query has a lot of parameters! So here's a short list:
/// 1. The new user's generated ID (public key)
/// 2. The new user's email
/// 3. The new user's displayname
/// 4. The new user's username
/// 5. The new user's password
/// 6. The new user's generated private key
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn insert_user(
  db: pog.Connection,
  arg_1: BitArray,
  arg_2: String,
  arg_3: String,
  arg_4: String,
  arg_5: String,
  arg_6: BitArray,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "-- Writes a new user account, does not check for invites, does not create a session.
--
-- This query has a lot of parameters! So here's a short list:
-- 1. The new user's generated ID (public key)
-- 2. The new user's email
-- 3. The new user's displayname
-- 4. The new user's username
-- 5. The new user's password
-- 6. The new user's generated private key

INSERT
	INTO users
		(id, private_key, instance_id, email, displayname, username, password)
	VALUES
		($1, $6, uuid_nil(), $2, $3, $4, $5);
"
  |> pog.query
  |> pog.parameter(pog.bytea(arg_1))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(pog.text(arg_4))
  |> pog.parameter(pog.text(arg_5))
  |> pog.parameter(pog.bytea(arg_6))
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
