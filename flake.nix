{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      utils,
    }:
    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            gleam
            beam29Packages.erlang
            beam29Packages.rebar3
            deno
            just
            watchexec
            postgresql_18
            dbmate
          ];

          shellHook = ''
            just --list
            echo "Use just to run these recipes."

            if [ -n "''${DIRENV_IN_ENVRC}" ]; then
               echo "Note: Use 'nix develop' to start the database, this doesn't work in direnv shells."
            else
               if [ ! -d "$PGDATA" ]; then
                  export PGDATA="$(pwd)/lumina/backend/build/data/data/.postgres"
                  export PGHOST="/tmp"
                  export LOG_PATH="$PGDATA/server.log"
                  initdb --auth=trust -U postgres
                  echo "listen_addresses = '127.0.0.1'" >> "$PGDATA/postgresql.conf"
                  echo "port = 5432" >> "$PGDATA/postgresql.conf"
                  echo "unix_socket_directories = '$PGHOST'" >> "$PGDATA/postgresql.conf"
               fi
               if ! pg_ctl status >/dev/null 2>&1; then
                  pg_ctl -D "$PGDATA" -l "$LOG_PATH" -o "-c listen_addresses=\"127.0.0.1\"" start
               fi
               trap 'pg_ctl stop' EXIT
               echo "Database is active and can be accessed on `just --evaluate LUMINA_DB_URL`."
            fi
          '';
        };
      }
    );
}
