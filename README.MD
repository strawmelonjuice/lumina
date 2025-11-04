# Lumina(/peonies) server

> Notice:
> This repo is edited on [My personal forge](https://git.strawmelonjuice.com/strawmelonjuice/lumina) and mirrorred
> on [codeberg](https://codeberg.org/strawmelonjuice/lumina) and [GitHub](https://github.com/strawmelonjuice/lumina). But
> you can still send in a PR!
> See [CONTRIBUTING.md](CONTRIBUTING.md) for more information.

## -> Rewrite '25'

> Completely rewriting this project. I am relatively new
> to Lustre and to websockets and to Rocket, but wanna try
> all of them out and make them succeed in this rewrite.

### Environment variables

Part of the configuration is loaded from the database, part of it in environment variables.
Environment variables can be set in the _environment_ before run, but Lumina prefers them to be loaded from
`$LUMINAFOLDER/.env`.

| NAME                       | DEFAULT              | FOR                                                                                                                        |
| -------------------------- | -------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `LUMINA_POSTGRES_PORT`     | `5432`               | The port to contact the database on.                                                                                       |
| `LUMINA_POSTGRES_HOST`     | `localhost`          | The address to contact the database on.                                                                                    |
| `LUMINA_POSTGRES_USERNAME` | `lumina`             | The username to log in to the database with.                                                                               |
| `LUMINA_POSTGRES_PASSWORD` | -                    | The password to log in to the database with. If not set, Lumina will try without.                                          |
| `LUMINA_POSTGRES_DATABASE` | `lumina_config`      | The database to use.                                                                                                       |
| `LUMINA_REDIS_URL`         | `redis://127.0.0.1/` | Redis URL to connect to.                                                                                                   |
| `LUMINA_DB_SALT`           | `sal`                | The salting to use for some data on the database.                                                                          |
| `LUMINA_SERVER_PORT`       | `8085`               | Port for Lumina to accept HTTP requests on.                                                                                |
| `LUMINA_SERVER_ADDR`       | `127.0.0.1`          | Address for Lumina to accept HTTP requests on. (usually `127.0.0.1` or `0.0.0.0`)                                          |
| `LUMINA_SERVER_HTTPS`      | `false`              | Whether to use 'https' rather than 'http' in links, etc. (please do!)                                                      |
| `LUMINA_SYNC_IID`          | `localhost`          | A name Lumina uses when communicating with other instances, must be equal to where it's http is facing the public internet |
| `LUMINA_SYNC_INTERVAL`     | `30`                 | Specifies the interval between syncs. Minimum is 30.                                                                       |

## Development

During development, I use the following:

```sh
mise install # Installs mise deps
mise run local-devel-prep # Because you'll need a database running somewhere.
mise run local-devel-watch
```

I might just specify it a bit further sometime in the future.
