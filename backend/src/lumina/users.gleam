//// User management module

// Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
// Licensed under the BSD 3-Clause License. See the LICENSE file for more info.

const minimum_username_length = 3

const minimum_password_length = 8

import argus
import gleam/bool
import gleam/dynamic
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/regex
import gleam/result
import gleam/string
import gmysql
import lumina/data/context.{type Context}
import lumina/database
import lumina/shared/shared_users
import pog
import sqlight
import wisp

pub type SafeUser =
  shared_users.SafeUser

pub type User {
  User(id: Int, username: String, password: String, email: String)
}

pub fn to_safe_user(user: User) -> SafeUser {
  shared_users.SafeUser(id: user.id, username: user.username, email: user.email)
}

/// Fetches a user from the database by id
pub fn fetch(ctx: Context, uid: Int) -> Option(User) {
  let decoder =
    dynamic.tuple4(dynamic.int, dynamic.string, dynamic.string, dynamic.string)

  case
    case ctx.db {
      database.POSTGRESConnection(con) -> {
        pog.query("SELECT * FROM users WHERE id = $1")
        |> pog.returning(decoder)
        |> pog.parameter(pog.int(uid))
        |> pog.execute(con)
        |> database.pogerror_to_string
        |> result.map(fn(a) {
          case a {
            pog.Returned(_, i) -> i
          }
        })
      }
      database.SQLiteConnection(con) -> {
        use conn <- sqlight.with_connection(con)
        sqlight.query(
          "SELECT * FROM `users` WHERE `id` = ?",
          conn,
          [sqlight.int(uid)],
          decoder,
        )
        |> result.map_error(string.inspect)
      }
    }
  {
    Ok([values]) -> {
      Some(User(values.0, values.1, values.2, values.3))
    }
    Error(e) -> {
      let errormsg =
        "An error occurred while fetching the user from the database: " <> e
      wisp.log_emergency(errormsg)
      panic
    }
    _ -> None
  }
}

/// Fetches a user from the database by username
fn fetch_username(ctx: Context, username: String) -> Option(User) {
  let decoder =
    dynamic.tuple4(dynamic.int, dynamic.string, dynamic.string, dynamic.string)

  case
    case ctx.db {
      database.POSTGRESConnection(con) -> {
        pog.query("SELECT * FROM users WHERE username = $1")
        |> pog.parameter(pog.text(username))
        |> pog.returning(decoder)
        |> pog.execute(con)
        |> database.pogerror_to_string
        |> result.map(fn(a) {
          case a {
            pog.Returned(_, i) -> i
          }
        })
      }
      database.SQLiteConnection(con) -> {
        use conn <- sqlight.with_connection(con)
        sqlight.query(
          "SELECT * FROM `users` WHERE `username` = ?",
          conn,
          [sqlight.text(username)],
          decoder,
        )
        |> result.map_error(string.inspect)
      }
    }
  {
    Ok([values]) -> {
      Some(User(values.0, values.1, values.2, values.3))
    }
    Error(e) -> {
      let errormsg =
        "An error occurred while fetching the user from the database: " <> e
      wisp.log_emergency(errormsg)
      panic
    }
    Ok([]) -> None
    _ -> panic
  }
}

/// Fetches a user from the database by username
fn fetch_email(ctx: Context, email: String) -> Option(User) {
  let decoder =
    dynamic.tuple4(dynamic.int, dynamic.string, dynamic.string, dynamic.string)

  case
    case ctx.db {
      database.POSTGRESConnection(con) -> {
        pog.query("SELECT * FROM users WHERE email = $1")
        |> pog.returning(decoder)
        |> pog.parameter(pog.text(email))
        |> pog.execute(con)
        |> result.map_error(string.inspect)
        |> result.map(fn(a) {
          case a {
            pog.Returned(_, i) -> i
          }
        })
      }
      database.SQLiteConnection(con) -> {
        use conn <- sqlight.with_connection(con)
        sqlight.query(
          "SELECT * FROM `users` WHERE `email` = ?",
          conn,
          [sqlight.text(email)],
          decoder,
        )
        |> result.map_error(string.inspect)
      }
    }
  {
    Ok([values]) -> {
      Some(User(values.0, values.1, values.2, values.3))
    }
    Error(e) -> {
      let errormsg =
        "An error occurred while fetching the user from the database: " <> e
      wisp.log_emergency(errormsg)
      panic
    }
    _ -> None
  }
}

pub type UserAdditionError {
  // 4** errors
  UsernameCharacters
  UsernameTooShort
  InvalidEmail
  PasswordTooShort
  // 5** errors
  RegexError(regex.CompileError)
  EncryptError
  DatabaseError(String)
  ReturnError
}

/// Adds a new user to the database.
///
/// ## Arguments
///
/// * `username` - A string that holds the username.
/// * `email` - A string that holds the email.
/// * `password` - A string that holds the password.
/// * `config` - A reference to the LuminaConfig struct.
///
/// ## Returns
///
/// * `Result(Int, UserAdditionError)` - Returns the user id if the user is successfully added, otherwise returns an explanative error.
pub fn add_user(
  ctx: Context,
  username: String,
  email: String,
  password: String,
) -> Result(Int, UserAdditionError) {
  // Account validation steps
  // Step 1 - Username
  use <- bool.guard(
    when: check_username(username),
    return: Error(UsernameCharacters),
  )
  use <- bool.guard(
    when: string.length(username) < minimum_username_length,
    return: Error(UsernameTooShort),
  )
  // Step 2 - Email
  let emreg =
    "^([a-z0-9_+]([a-z0-9_+.]*[a-z0-9_+])?)@([a-z0-9]+([\\-\\.]{1}[a-z0-9]+)*\\.[a-z]{2,6})"
  use emailregex <- result.try(result.map_error(
    regex.from_string(emreg),
    RegexError,
  ))
  use <- bool.guard(
    when: regex.check(emailregex, email)
      |> bool.negate(),
    return: Error(InvalidEmail),
  )
  // Step 3 - Password
  use <- bool.guard(
    when: string.length(password) < minimum_password_length,
    return: Error(PasswordTooShort),
  )

  // Password hashing

  // let hasher_result =
  //   aragorn2.hasher()
  //   |> aragorn2.hash_password(<<password:utf8>>)
  //   |> result.replace_error(EncryptError)
  // use hashed_password <- result.try(hasher_result)
  let assert Ok(hashes) =
    argus.hasher()
    |> argus.hash(password, ctx.config.db_custom_salt)
  let hashed_password = hashes.encoded_hash

  // Add user to the database and return the user is
  use r <- result.try(result.map_error(
    case ctx.db {
      database.POSTGRESConnection(con) -> {
        pog.query(
          "INSERT INTO users (username,email,password) VALUES ($1, $2, $3) RETURNING id",
        )
        |> pog.parameter(pog.text(username))
        |> pog.parameter(pog.text(email))
        |> pog.parameter(pog.text(hashed_password))
        |> pog.returning(dynamic.element(0, dynamic.int))
        |> pog.execute(con)
        |> database.pogerror_to_string
        |> result.map(fn(a) {
          case a {
            pog.Returned(_, i) -> i
          }
        })
      }
      database.SQLiteConnection(con) -> {
        use conn <- sqlight.with_connection(con)
        sqlight.query(
          "INSERT INTO `users` (`username`, `email`, `password`) VALUES (?, ?, ?) Returning `id`",
          conn,
          [
            sqlight.text(username),
            sqlight.text(email),
            sqlight.text(hashed_password),
          ],
          dynamic.element(0, dynamic.int),
        )
        |> result.map_error(string.inspect)
      }
    },
    DatabaseError,
  ))

  // Now retrieve the uid from the database
  r
  |> list.first
  |> result.replace_error(ReturnError)
}

/// Checks if a username contains valid characters.
///
/// # Arguments
///
/// * `username` - A string that holds the username.
///
/// # Returns
///
/// * `bool` - Returns true if the username contains invalid characters, false otherwise.
pub fn check_username(username: String) {
  [
    username |> string.contains(" "),
    username |> string.contains("\\"),
    username |> string.contains("/"),
    username |> string.contains("@"),
    username |> string.contains("\n"),
    username |> string.contains("\r"),
    username |> string.contains("\t"),
    username |> string.contains("\u{001b}"),
    username |> string.contains("\""),
    username |> string.contains("'"),
    username |> string.contains("("),
    username |> string.contains(")"),
    username |> string.contains("`"),
    username |> string.contains("%"),
    username |> string.contains("?"),
    username |> string.contains("!"),
    // We disallow '#' for now, but in the future we should allow '#' only if 4 numeric characters follow it.
    username |> string.contains("#"),
    // username
  //   |> string.replace(["_", "-", "."], "")
  //   |> is_alphanumeric()
  ]
  |> list.any(fn(c) { c })
}

/// Authenticates a user by plain username/email and password.
pub fn auth(identifier: String, password: String, ctx: Context) -> AuthResponse {
  // Check for invalid chars
  use <- bool.guard(
    when: [
      // ' ' | '\\' | '/' | '\n' | '\r' | '\t' | '\x0b' | '\'' | '"' | '(' | ')' | '`'
      identifier |> string.contains(" "),
      identifier |> string.contains("\\"),
      identifier |> string.contains("/"),
      identifier |> string.contains("\n"),
      identifier |> string.contains("\r"),
      identifier |> string.contains("\t"),
      identifier |> string.contains("\u{001b}"),
      identifier |> string.contains("\""),
      identifier |> string.contains("'"),
      identifier |> string.contains("("),
      identifier |> string.contains(")"),
      identifier |> string.contains("`"),
      // %, ? and ! were allowed in the Rust code that I'm porting, wondering why.
      identifier |> string.contains("%"),
      identifier |> string.contains("?"),
      identifier |> string.contains("!"),
      // We disallow '#' for now, but in the future we should allow '#' only if 4 numeric characters follow it.
      identifier |> string.contains("#"),
    ]
      |> list.any(fn(c) { c }),
    return: Error(InvalidIdentifier),
  )
  case
    case identifier |> string.contains("@") {
      True -> fetch_email(ctx, identifier)
      False -> fetch_username(ctx, identifier)
    }
  {
    None -> Error(NonexistentUser)
    Some(user) -> {
      case
        // aragorn2.verify_password(aragorn2.hasher(), <<password:utf8>>, <<user.password:utf8>>)
        argus.verify(user.password, password)
      {
        Error(e) -> Error(DecryptionError(e))
        Ok(True) -> Ok(Some(user.id))
        Ok(False) -> Error(PasswordIncorrect)
      }
    }
  }
}

pub type AuthResponse =
  Result(Option(Int), AuthResponseError)

pub type AuthResponseError {
  // 4** - User input errors
  PasswordIncorrect
  NonexistentUser
  InvalidIdentifier
  // 5** - Internal errors
  Unspecified
  DataBaseError(gmysql.Error)
  DecryptionError(argus.HashError)
}
