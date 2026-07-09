//// This module contains the code to run the sql queries defined in
//// `./src/lumina_server/data/sql`.
//// > 🐿️ This module was generated automatically using v4.7.0 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import pog

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
