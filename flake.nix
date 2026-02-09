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
        # Define the Rust toolchain using Fenix
        rustToolchain = fenix.packages.${system}.stable.withComponents [
          "cargo"
          "rustc"
          "rustfmt"
          "clippy"
          "rust-analyzer"
          "rust-src"
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Language tool chains: Rust, Gleam
            rustToolchain
            gleam
            bun
            # For tidying and typing
            # nodePackages.prettier

            # Helpers on OS level
            pkg-config
            dbus

            # Podman
            podman

            # Runners
            watchexec
            just
          ];

          shellHook = ''
                        export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:$LD_LIBRARY_PATH"
                        bun i --cwd=client/
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
