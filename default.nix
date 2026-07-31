let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-26.05";
  pkgs = import nixpkgs {
    config = { };
    overlays = [ ];
  };
in
{
  shell = pkgs.mkShellNoCC {
    packages = with pkgs; [
      gleam
      beam29Packages.erlang
      beam29Packages.rebar3
      erlang-language-platform
      deno
      just
      watchexec
      postgresql_18
      dbmate
    ];

    shellHook = ''
      just --list
      echo "Use just to run these recipes."
      if [ ! -d "$PGDATA" ]; then
          export PGDATA="$(pwd)/lumina/backend/build/data/data/.postgres"
          export PGHOST="/tmp"
          export LOG_PATH="$PGDATA/server.log"
          initdb --auth=trust -U postgres
          echo "listen_addresses = '127.0.0.1'" >> "$PGDATA/postgresql.conf"
          echo "port = 5432" >> "$PGDATA/postgresql.conf"
          echo "unix_socket_directories = '$PGHOST'" >> "$PGDATA/postgresql.conf"
      fi
    '';
  };
}
