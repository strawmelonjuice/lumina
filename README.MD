# Lumina(/peonies) server

## Currently behind:
As Lumina is a monorepo with pluggable parts, some of them sometimes lag behind and are broken by the latest changes. The current state of the project is:
### Up to date
- Server (Rust)

### behind
- Server (Gleam) (changes in Gleam client)
- Client (TypeScript) (changes in Rust server)
- Client (Gleam) (in progress)

## Requirements
- [The Gleam compiler, `Erlang` and `rebar3`](https://gleam.run/getting-started/installing/)
- A [PostGres](https://www.postgresql.org/) database (or just set up an SQLite one if you want to be QD!)
- The [Bun](https://bun.sh/) TypeScript ecosystem

## Running Lumina

#### Clone it!

```shell
git clone https://github.com/strawmelonjuice/lumina.git
```

#### Run it!

Warning ya -- Lumina loads and logs in `$HOME/.luminainstance/` unless specified otherwise as argument. If you'd like to keep it in the
workspace, use:

```bash
bun run dev start-in ./
```

otherwise, just use `bun run dev` or `bun run build && gleam start` and have Lumina start in its default.


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
