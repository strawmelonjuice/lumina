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
            # Env should be at the same level as Cmd
            Env = [
              "PATH=${pkgs.jre21_minimal}/bin:${pkgs.rcon-cli}/bin:/usr/bin:/bin"
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
            # Build image and run development pg using:
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
