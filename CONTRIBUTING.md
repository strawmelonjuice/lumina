# Contributing to Lumina

> IMPORTANT
>
> This project is not hosted on GitHub or Codeberg. However, you can contribute by sending pull requests to the project's repository or any of it's official mirrors. I'll be happy to review and merge your contributions to the main repository.
>
> If you turn into a frequent contributor, you may contact me to gain a <https://git.strawmelonjuice.com/> account to contribute on the main repository.

Thank you for your interest in contributing! This document outlines how to set up your environment, follow the style, and submit changes.

---

## Where to contribute

- Main repository (primary): <https://git.strawmelonjuice.com/strawmelonjuice/lumina>
- Official mirrors: <https://codeberg.org/strawmelonjuice/lumina>, <https://github.com/strawmelonjuice/lumina>
- Note about GitHub: Any changes made on GitHub will be overwritten by automated force-pushes from strawmelonjuiceforge and may not be reviewed.

Please open issues and submit pull requests (PRs) on the main repository or an official mirror.

Frequent contributors may request an account on the main forge to collaborate more directly: <https://git.strawmelonjuice.com/>.

---

## Code of Conduct

- Be respectful and constructive.
- Assume good intent and seek clarity.
- Harassment, discrimination, and personal attacks are not tolerated.

If you experience or witness unacceptable behavior, contact the maintainer via the main forge.

---

## Project layout

- `server/` — Rust (Rocket) server application.
- `client/` — Gleam application targeting JavaScript (bundled to browser).
- `mise/` — Task definitions for development flows.
- `data/` — Local runtime data directory (created by tasks).
- Root files — Workspace-level configuration, license, docs, and Docker-related files.

---

## Prerequisites

- Rust toolchain (latest stable) with `rustfmt` and (optionally) `clippy`.
- Gleam.
- Bun.
- Node is not required when using Bun.
- Redis/Postgres if you want to test those backends, otherwise SQLite is the default for development.
- Optional: Watchexec (installed automatically via tasks), Taplo, Prettier (run via tasks).

This repository uses `mise` to manage tools and developer tasks:
- Install mise: https://mise.jdx.dev/
- Then install toolchain/tool deps used by the project and tasks:
  ```sh
  mise install
  ```

---

## Local setup

Environment is configured via environment variables. For development, the server prefers a `.env` file in your instance folder: `$LUMINAFOLDER/.env`.

Key variables (defaults exist for development):
- `LUMINA_DB_TYPE` — `sqlite` or `postgres` (default: `sqlite`)
- `LUMINA_REDIS_URL` — `redis://127.0.0.1/`
- `LUMINA_SERVER_ADDR` — `127.0.0.1`
- `LUMINA_SERVER_PORT` — `8085`
- And others described in `README.MD`

First-time setup:
```sh
# From repo root
mise install
mise run build-server
```

Development run options:
```sh
# Fast development with auto-restart on changes
mise run development-run-watch # add -podman to run in podman, since otherwise you'll need to run a Redis server and a PostgreSQL server locally.

# Or run once (debug)
mise run development-run # add -podman to run in podman, since otherwise you'll need to run a Redis server and a PostgreSQL server locally.

# Or an optimized (release) development run
mise run optimised-development-run # You need to have a Redis server and a PostgreSQL server running locally.
```

There are more variations. Run `mise run` and type 'development' in the task finder to list all of them.

The build pipeline (mise) takes care of client (Gleam) compilation and styles, and it will create necessary data directories.

---

## Formatting, checks, and quality

Before pushing or opening a PR, run:
```sh
# Format Rust, Gleam, and meta files
mise run format

# Basic checks (Rust and Gleam)
mise run check

# Build to ensure it compiles
mise run build-server

# Optionally: There are some watching tasks and tasks to run Lumina niet development mode
mise run check-watch
mise run development-run-watch-podman
# ..etc.
```

Conventions:
- Rust code is formatted with `rustfmt`.
- Gleam code is formatted with `gleam format`.
- Meta files are formatted via Prettier and Taplo.
- Prefer clear, explicit error handling and logs over silent failures.
- Keep modules cohesive and prefer small, testable units.

---

## Branching and commit messages

- Create feature branches from the default branch (typically `main`).
  - Suggested naming: `feat/<short-name>`, `fix/<short-name>`, `docs/<short-name>`, `chore/<short-name>`.
- Commit messages:
  - Be concise and descriptive.
  - Prefer Conventional Commits style when possible:
    - `feat: add user session cleanup job`
    - `fix(server): handle empty redis url`
    - `docs: improve contributing guide`

---

## Pull requests

PR checklist:
- Code is formatted and builds locally.
- `mise run check` passes.
- Include tests when adding logic or fixing bugs (Rust: `cargo test`; Gleam: `gleam test`).
- Update docs (README/WHY/ABOUT) where relevant.
- Keep PRs focused. Large refactors should be split or well-justified.

Review expectations:
- Be prepared to discuss design decisions and trade-offs.
- Address review comments via additional commits (avoid force-push unless asked).
- Squash commits at merge time if appropriate.

---

## Reporting bugs

When filing a bug report:
- Describe what you expected to happen and what actually happened.
- Include steps to reproduce.
- Provide version info (commit hash) and environment (OS, DB type, Redis/Postgres versions).
- Include relevant logs or stack traces when possible.

---

## Feature requests

When proposing a feature:
- Explain the problem it solves and the target use-cases.
- Consider alternatives and why this approach is preferred.
- If possible, include a small design sketch (API, data flow, or UI).
- Prototype branches are welcome if they help the discussion.

---

## Security

If you discover a security issue:
- Do not open a public issue with sensitive details.
- Contact me privately via the email on my main forge.
- Provide clear reproduction steps and affected versions.
- A fix or mitigation plan will be discussed before public disclosure.

---

## Tests

- Rust: place tests alongside modules or in `server/` integration tests, use `cargo test`.
- Gleam: use `gleam test` for client-side logic where applicable.
- Prefer deterministic tests; avoid timing-based flakes.
- Add tests for new behavior and regression tests for fixed bugs.

---

## License and contributor terms

By contributing, you agree that your contributions are licensed under the BSD 3-Clause License of this repository, unless explicitly stated otherwise in writing.

See `LICENSE` at the repository root.

---

## Thank you

Your time and effort are appreciated. Whether you’re reporting a bug, improving docs, or adding features—every contribution helps make Lumina better.
