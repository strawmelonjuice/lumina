# Lumina(/peonies) server

## -> Rewrite '25'

> Completely rewriting this project. I am relatively new
> to Lustre and to websockets and to Rocket, but wanna try
> all of them out and make them succeed in this rewrite.


### Environment variables

Part of the configuration is loaded from the database, part of it in environment variables.
Environment variables can be set in the _environment_ before run, but Lumina prefers them to be loaded from `$LUMINAFOLDER/.env`.

| NAME                                | DEFAULT                                     | FOR                                                          |
| ----------------------------------- | ------------------------------------------- | ------------------------------------------------------------ |
| `LUMINA_DB_TYPE`                  | `"sqlite"` (not recommended for production) | The kind of database to use. Options are `postgres` or `sqlite`.<br /><br /><br />**OPTIONS:**<br />_With SQLite:_<br />- `LUMINA_SQLITE_FILE`    `"instance.sqlite"`    SQLite file to connect to. Always a relative path from the instance folder.<br /><br />_With PostGres DB:_<br />- `LUMINA_POSTGRES_PORT`  `"5432"`  The port to contact the database on. <br>- `LUMINA_POSTGRES_HOST`    `"localhost"`    The address to contact the database on.<br>- `LUMINA_POSTGRES_USERNAME`    `"lumina"`    The username to log in to the database with.<br>- `LUMINA_POSTGRES_PASSWORD`    (none)    The password to log in to the database with. If not set, Lumina will try without.<br>- `LUMINA_POSTGRES_DATABASE` `"lumina_config"` The database to use. <br> |
| `LUMINA_DB_SALT`                  | `"sal"`                                     | The salting to use for some data on the database.            |
| `LUMINA_SERVER_PORT`              | `"8085"`                                    | Port for Lumina to accept HTTP requests on.                  |
| `LUMINA_SERVER_ADDR`              | `"localhost"`                               | Address for Lumina to accept HTTP requests on.               |
| `LUMINA_SERVER_HTTPS`             | `"false"`                                   | Wether to use 'https' rather than 'http' in links, etc. (please do!) |
| `LUMINA_SYNCHRONISATION_IID`      | `"localhost"`                               | A name Lumina uses when communicating with other instances, must be equal to where it's http is facing the public internet |
| `LUMINA_SYNCHRONISATION_INTERVAL` | `"30"`                                      | Specifies the interval between syncs. Minimum is 30.         |
