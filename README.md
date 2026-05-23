# Lumina(/peonies) server

> Notice:
> This project lives on [Tangled](https://tangled.org/strawmelonjuice.com/Lumina), it is mirrored to Codeberg and a few
> other places, but the main development happens on Tangled.
> Please report issues and contribute on Tangled.

Lumina is a project in development, as the short description says "Just trying out an old concept.". It is not in any
way ready for you to try. However, you are encouraged to contribute in any way!

Currently, as no stable is produced yet, code lives mainly in the `development` branch.


## Development

Use `flake.nix`, either using `direnv` (there's an `.envrc` file to do this!) or with `nix develop`.
This gets you all the dependencies, including Just.

```sh
just dev # Prepares your enviroment and builds/runs the server with file watching.
```

When running Lumina server in development mode, it automatically creates two accounts for you and one of those has an attached
post on the global timeline.

| Username  | Email             | Password         |
| --------- | ----------------- | ---------------- |
| testuser1 | test@lumina123.co | MyTestPassw9292! |
| testuser2 | test@lumina234.co | MyTestPassw9292! |
