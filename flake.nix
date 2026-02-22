{
  description = "Lumina Development Environment";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      utils,
      fenix,
      ...
    }:
    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        rustToolchain = fenix.packages.${system}.stable.withComponents [
          "cargo"
          "rustc"
          "rustfmt"
          "clippy"
          "rust-analyzer"
          "rust-src"
        ];
        # Define libraries in one place to avoid repetition
        libraries = with pkgs; [
          stdenv.cc.cc
          glib
          dbus
          curl
          openssl
        ];

        packages = with pkgs; [

          # Language tool chains: Rust, Gleam
          rustToolchain
          gleam
          bun
          # For tidying and typing
          # nodePackages.prettier
          sqlx-cli

          # Pkg config
          pkg-config-unwrapped

          # Podman
          podman

          # Runners
          watchexec
          just
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          # Tools go here
          nativeBuildInputs = [ pkgs.pkg-config ];

          # Libraries go here
          buildInputs = packages ++ libraries;

          shellHook = ''
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath libraries}:$LD_LIBRARY_PATH"

                        bun install --cwd=client/ --silent --only-missing
                        echo "❄️ dev environment loaded"
                        just --list
            			echo "use just to run them."
            			mise tasks
            			echo "use mise run to run them."
          '';
        };
      }
    );

}
