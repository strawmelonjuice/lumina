# Lumina(/peonies) server

## -> Rewrite '25'

> Completely rewriting this project. I am relatively new
> to Lustre and to websockets and to Axum, but wanna try
> all of them out and make them succeed in this rewrite.


### Environment variables

Part of the configuration is loaded from the database, part of it in environment variables.
Environment variables can be set in the _environment_ before run, but Lumina prefers them to be loaded from `$LUMINAFOLDER/.env`.

| NAME                                | DEFAULT                                     | FOR                                                          |
| ----------------------------------- | ------------------------------------------- | ------------------------------------------------------------ |
| `_LUMINA_DB_TYPE_`                  | `"sqlite"` (not recommended for production) | The kind of database to use. Options are `postgres` or `sqlite`.<br /><br /><br />**OPTIONS:**<br />_With SQLite:_<br />- `_LUMINA_SQLITE_FILE_`    `"instance.sqlite"`    SQLite file to connect to. Always a relative path from the instance folder.<br /><br />_With PostGres DB:_<br />- `_LUMINA_POSTGRES_PORT_`  `"5432"`  The port to contact the database on. <br>- `_LUMINA_POSTGRES_HOST_`    `"localhost"`    The address to contact the database on.<br>- `_LUMINA_POSTGRES_USERNAME_`    `"lumina"`    The username to log in to the database with.<br>- `_LUMINA_POSTGRES_PASSWORD_`    (none)    The password to log in to the database with. If not set, Lumina will try without.<br>- `_LUMINA_POSTGRES_DATABASE_` `"lumina_config"` The database to use. <br> |
| `_LUMINA_DB_SALT_`                  | `"sal"`                                     | The salting to use for some data on the database.            |
| `_LUMINA_SERVER_PORT_`              | `"8085"`                                    | Port for Lumina to accept HTTP requests on.                  |
| `_LUMINA_SERVER_ADDR_`              | `"localhost"`                               | Address for Lumina to accept HTTP requests on.               |
| `_LUMINA_SERVER_HTTPS_`             | `"false"`                                   | Wether to use 'https' rather than 'http' in links, etc. (please do!) |
| `_LUMINA_SYNCHRONISATION_IID_`      | `"localhost"`                               | A name Lumina uses when communicating with other instances, must be equal to where it's http is facing the public internet |
| `_LUMINA_SYNCHRONISATION_INTERVAL_` | `"30"`                                      | Specifies the interval between syncs. Minimum is 30.         |
