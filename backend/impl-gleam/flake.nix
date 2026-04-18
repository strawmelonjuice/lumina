{
  description = "Lumina Development Environment";

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

        myImage = pkgs.dockerTools.buildLayeredImage {
          name = "luminapeonies";
          tag = "latest";
          contents = [
            pkgs.bash
            pkgs.coreutils
            pkgs.erlang_28
          ];
          config = {
            Cmd = [
              "/app/entrypoint.sh"
              "run"
            ];
            WorkingDir = "/data";
            Env = [
              "PATH=/usr/bin:/bin"
              "PORT=3000"
            ];
          };
          # Volumes = {
          #   "/data" = { };
          # };
          extraCommands = ''
            mkdir -p app
            cp -r ${./server/build/erlang-shipment}/* app/
            chmod +x app/entrypoint.sh
          '';
        };
      in
      {
        packages.container = myImage;

        devShells.default = pkgs.mkShell {
          shellHook = ''
            echo "❄️ dev environment loaded, use 'just dev' next, or use 'just --list' for recipies."
          '';
          buildInputs = with pkgs; [
            # Gleam application
            gleam
            erlang_28
            rebar3
            bun
            tailwindcss_4
            # Task runner
            watchexec
            just
            # Migrations
            dbmate
            sqlite
            # Containerisation
            podman
          ];
        };
      }
    )
    // {
      nixosModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          virtualisation.oci-containers.containers."strawmelonjuice-lumina" = {
            # image = "strawmelonjuice/luminapeonies:latest";
            image = "luminapeonies:latest";
            ports = [
              "3000:3000"
            ];
            volumes = [
              "/var/lib/lumina-peonies:/data"
            ];
            extraOptions = [ "--network=slirp4netns" ];
          };
        };
    };
}
