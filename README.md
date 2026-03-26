# Lumina(/peonies) server

> Notice:
> This project lives on [Tangled](https://tangled.org/strawmelonjuice.com/Lumina), it is mirrored to Codeberg and a few
> other places, but the main development happens on Tangled.
> Please report issues and contribute on Tangled.

Lumina is a project in development, as the short description says "Just trying out an old concept.". It is not in any
way ready for you to try. However, you are encouraged to contribute in any way!

## Roadmap

This roadmap is only meant to support development, not place new constraints on an already overwhelmed...me.

- [ ] Web client in Gleam+Lustre
	- [x] A DaisyUI theme and basic defined interface, previewing what Lumina/Peonies will look like.
	- [x] Login/Register UI/flow for Username-Password Authentication
	- [ ] User settings
	- [ ] Timelineview (tested mainly on `global`)
		- [ ] Post to load in timeline
	- [ ] Timelineswitch (seeing other timelines)
	- [ ] ... more to be documented
- [ ] Server backend and API's
	- [ ] Server can send timeline global paginated...
		- [x] Over authorized WS
		- [ ] Through public HTTPS GET
	- [ ] Client can request other timelines, by ID, paginated...
		- [ ] Over session-protected WS
		- [ ] 🧪 Not over unauthorized HTTPS GET
		- [ ] Over authorized HTTPS GET
	- [ ] Server can authorize session...
		- [x] ...Based on username-password over WS
		- [x] ...Based on session token over WS
		- [ ] ...Based on API token over WS
		- [ ] ...Based on API token over HTTPS POST.
		- [ ] ...Based on oauth over HTTPS get.
		- [ ] ... More?
	- [ ] A DM timeline should be available to both (or more) users in the DM.
	- [ ] ... More to be documented
- [ ] Authentication:
	- [x] Username-Password based login
	- [ ] Oauth-based OIDC/Bsky login
	- [ ] two-factor-auth
- [ ] IIC (InterInstance Communicating)
	- [ ] Redesign the IIC's ways completely, also see notes for this.
	- [ ] Investigate federating to ATProto, making any Lumina instance also a PDS. (Except Lumina data would live mostly
	off-protocol, and for example article posts would be published as Links to the Bluesky feed.)
	- [ ] ... to be documented
- [ ] ... More to be documented

This roadmap is missing a lot, but it's primary goal is to help ME find a next thing to fix.

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
