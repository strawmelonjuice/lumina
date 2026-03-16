# Lumina(/peonies) server

> Notice:
> This project lives on [Tangled](https://tangled.org/strawmelonjuice.com/Lumina), it is mirrored to Codeberg and a few
> other places, but the main development happens on Tangled.
> Please report issues and contribute on Tangled.

### Environment variables

Part of the configuration is loaded from the database, part of it in environment variables.
Environment variables can be set in the _environment_ before run, but Lumina prefers them to be loaded from
`$LUMINAFOLDER/.env`.

| NAME                       | DEFAULT                                                                                | FOR                                                                                                                        |
| -------------------------- | -------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `DATABASE_URL`             | Development: `postgres://lumina:lumina_pw@localhost:5432/lumina_config`, production: - | The Postgres database url to connect to. Overrides all `LUMINA_POSTGRES_*` values.                                         |
| `LUMINA_POSTGRES_PORT`     | `5432`                                                                                 | The port to contact the database on.                                                                                       |
| `LUMINA_POSTGRES_HOST`     | `localhost`                                                                            | The address to contact the database on.                                                                                    |
| `LUMINA_POSTGRES_USERNAME` | `lumina`                                                                               | The username to log in to the database with.                                                                               |
| `LUMINA_POSTGRES_PASSWORD` | -                                                                                      | The password to log in to the database with. If not set, Lumina will try without.                                          |
| `LUMINA_POSTGRES_DATABASE` | `lumina_config`                                                                        | The database to use.                                                                                                       |
| `LUMINA_REDIS_URL`         | `redis://127.0.0.1/`                                                                   | Redis URL to connect to.                                                                                                   |
| `LUMINA_DB_SALT`           | `sal`                                                                                  | The salting to use for some data on the database.                                                                          |
| `LUMINA_SERVER_PORT`       | `8085`                                                                                 | Port for Lumina to accept HTTP requests on.                                                                                |
| `LUMINA_SERVER_ADDR`       | `127.0.0.1`                                                                            | Address for Lumina to accept HTTP requests on. (usually `127.0.0.1` or `0.0.0.0`)                                          |
| `LUMINA_SERVER_HTTPS`      | `false`                                                                                | Whether to use 'https' rather than 'http' in links, etc. (please do!)                                                      |
| `LUMINA_SYNC_IID`          | `localhost`                                                                            | A name Lumina uses when communicating with other instances, must be equal to where it's http is facing the public internet |
| `LUMINA_SYNC_INTERVAL`     | `30`                                                                                   | Specifies the interval between syncs. Minimum is 30.                                                                       |

## Development

### With Nix (preffered)

Use `flake.nix`, either using `direnv` (there's an `.envrc` file to do this!) or with `nix develop`.
This gets you all the dependencies, including Just.

```sh
just dev # Prepares your enviroment and builds/runs the server with file watching.
```

### Without Nix

Make sure you have [mise-en-place](https://mise.jdx.dev/) and [Just](https://just.systems/) preinstalled.

```sh
mise install # Installs mise deps
just dev # Prepares your enviroment and builds/runs the server with file watching.
```

When running Lumina server in development mode, it automatically creates two accounts for you and one of those has an attached
post on the global timeline.

| Username  | Email             | Password         |
| --------- | ----------------- | ---------------- |
| testuser1 | test@lumina123.co | MyTestPassw9292! |
| testuser2 | test@lumina234.co | MyTestPassw9292! |
