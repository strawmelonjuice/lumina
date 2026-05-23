[private]
default:
    @just --list

[doc("Build the styles for Lumina client")]
[group('building')]
build-styles:

[doc("Build the server-side of Lumina into a Podman image, from the Flake! This builds most of Lumina inside your worktree, albeit not tracked.")]
[group('building')]
build-server-flake: build-client
    cd server; \
    gleam export erlang-shipment
    git add -N ./server/build/erlang-shipment/* -f
    nix build  ".#container" || { \
        if [[ -d .jj ]]; then git rm ./server/build/erlang-shipment -r; jj file untrack ./server/build/erlang-shipment; >/dev/null 2>&1; \
        else git rm ./server/build/erlang-shipment -r >/dev/null 2>&1; fi; \
        exit 1; \
    }
    @if [[ -d .jj ]]; then git rm ./server/build/erlang-shipment -r; jj file untrack ./server/build/erlang-shipment/*;  else git rm ./server/build/erlang-shipment -r >/dev/null 2>&1; fi

    @echo "Loading into Podman ..."
    @podman load < result && echo -e "Podman image \033[1;35mluminapeonies:latest\033[0m built!"
    @rm result

[doc("Build the server-side of Lumina from the Containerfile")]
[group('building')]
build-server:
    podman build . --tag luminapeonies

[doc("Build the client-side of Lumina and it's styles")]
[group('building')]
build-client:
    cd ./web/ &&\
    tailwindcss -i ./app.css -o ../server/priv/static/lumina_client.css && \
    gleam build --target javascript &&\
    find ./src/ -type f -print0 | xargs -0 sha256sum | sha256sum | awk '{print $1}' > "../server/priv/static/lumina_client_rev.hash" &&\
    echo 'import { main } from "./lumina_client.mjs";document.addEventListener("DOMContentLoaded", main())' > "./build/dev/javascript/lumina_client/lumina_client.ts" &&\
    deno bundle ./build/dev/javascript/lumina_client/lumina_client.ts --minify --outfile ../server/priv/static/lumina_client.min.mjs --platform browser &&\
    deno bundle ./build/dev/javascript/lumina_client/lumina_client.ts --outfile ../server/priv/static/lumina_client.mjs --platform browser

[doc("Prefetch Gleam dependencies to speed up future builds")]
[group('prepare')]
prefetch-gleam-deps:
    cd ./web && gleam deps download

[doc("Install NPM dependencies")]
[group('prepare')]
deno-install:
    cd ./web && deno install

[group('prepare')]
create-data-dirs:
    mkdir -p ./data/configvars/
    chmod 777 data -fR || true

[doc("Clean all build artifacts")]
clean-all:
    rm -rf ./web/node_modules
    cd client && gleam clean
    cd server && gleam clean
    rm -rf ./web/build/dev/javascript/lumina_client/lumina_client.mjs
    rm -rf ./web/build/dev/javascript/lumina_client/lumina_client.ts
    rm -rf ./server/priv/static/lumina_client.min.mjs
    rm -rf ./server/priv/static/lumina_client.css

[doc("Prepares database")]
[group("local-devel")]
local-devel-prep: create-data-dirs
    dbmate up
    # I don't know if I want to build for the devmode script?
    # May also make the user from the app, if debug mode is detected.
    touch data/configvars/debug

[doc("Alias for run")]
[private]
local-devel: run

[doc("Run the server in development mode")]
[group("local-devel")]
run: local-devel-prep build-server
    podman run --replace --name lumina-local-devel -v ./data/:/data -p 3000:3000 localhost/luminapeonies:latest

[doc("Run the server in development mode with file watching")]
[group("local-devel")]
local-devel-watch:
    watchexec --restart -I -c --debounce=10s --stop-timeout=0 --shell=sh -e rs,gleam,toml,css,ts,json --print-events -- just local-devel

[doc("Runs the commands from local-devel automatically, watches")]
[group("local-devel")]
dev:
    @just local-devel-prep
    @just local-devel-watch

[doc("Run pgweb (8081) and redis-commander (8082) for local development")]
[group("local-devel")]
local-devel-dataexplorer: local-devel-prep
    @echo "This script needs to be rewritten for the gleam branch you are on."
    @exit 1

[group("development")]
parrot:
    cd server && gleam run -m parrot -- --sqlite ../data/instance.db
