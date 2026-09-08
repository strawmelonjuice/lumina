let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-26.05";
  pkgs = import nixpkgs {
    config = { };
    overlays = [ ];
  };
  gleam = pkgs.rustPlatform.buildRustPackage rec {
    pname = "gleam";
    version = "1.18.1";

    src = pkgs.fetchFromGitHub {
      owner = "gleam-lang";
      repo = "gleam";
      rev = "19bf207ebb7d953ea1391f041da48c214ee1440a";
      hash = "sha256-974B+22Lvd7KB9M0yuuxkolLtRmg42NrAX5CIrIc3Ac=";
    };

    cargoLock = {
      lockFile = "${src}/Cargo.lock";
    };

    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.dbus ];

    doCheck = false;
    dontCargoInstallPostBuildHook = true;

    installPhase = ''
      mkdir -p $out/bin
      find . -name gleam -type f -executable -exec cp {} $out/bin/gleam \;
    '';
  };
in
{
  shell = pkgs.mkShellNoCC {
    packages = with pkgs; [
      gleam
      beam29Packages.erlang
      beam29Packages.rebar3
      erlang-language-platform
      clang
      deno
      just
      watchexec
      postgresql_18
      dbmate
    ];

    shellHook = ''
      export LUMINA_DEBUG='1'
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
