[private]
default:
    @just --list

[doc("Build the styles for Lumina client")]
[group('building')]
build-styles:
    cd ./client/ && bun x @tailwindcss/cli@4.1.18 -i ./app.css -o ./priv/static/lumina_client.css

[doc("Build the server-side of Lumina")]
[group('building')]
build-server: build-client
    cargo build

[doc("Build the server-side of Lumina optimised for release")]
[group('building')]
build-server-release: build-client
    cargo build --release

[doc("Build the client-side of Lumina and it's styles")]
[group('building')]
build-client: build-styles
    cd ./client/ &&\
    gleam build --target javascript &&\
    find ./client/src/ -type f -print0 | xargs -0 sha256sum | sha256sum | awk '{print $1}' > "./priv/static/lumina_client_rev.hash" &&\
    echo 'import { main } from "./lumina_client.mjs";document.addEventListener("DOMContentLoaded", main())' > "./build/dev/javascript/lumina_client/lumina_client.ts" &&\
    bun build ./build/dev/javascript/lumina_client/lumina_client.ts --minify --outfile ./priv/static/lumina_client.min.mjs --target=browser &&\
    bun build ./build/dev/javascript/lumina_client/lumina_client.ts --outfile ./priv/static/lumina_client.mjs --target=browser

[doc("Prefetch Gleam dependencies to speed up future builds")]
[group('prepare')]
prefetch-gleam-deps:
    cd ./client && gleam deps download

[doc("Install Bun dependencies")]
[group('prepare')]
bun-install:
    cd ./client && bun i

[group('prepare')]
create-data-dirs:
    mkdir -p ./data
    mkdir -p ./data/postgres
    mkdir -p ./data/redis

[doc("Clean all build artifacts")]
clean-all:
    cargo clean
    rm -rf ./client/node_modules
    rm -rf ./client/build
    rm -rf ./client/build/dev/javascript/lumina_client/lumina_client.mjs
    rm -rf ./client/build/dev/javascript/lumina_client/lumina_client.ts
    rm -rf ./client/priv/static/lumina_client.min.mjs
    rm -rf ./client/priv/static/lumina_client.css

[doc("Just runs the Podman image for a Redis and Postgres server for local development run to connect to.")]
[group("local-devel")]
local-devel-prep: create-data-dirs
   # The redis container can be replaced if it already exists, but the postgres container needs to be checked, due to
   # sqlx needing to connect to it to create the database and run the migrations, so if it is restarted, it may not be
   # ready by the time sqlx tries to connect.
   podman run --replace --name lumina-redis -p 6379:6379 -v ./data/redis:/data -d docker.io/redis/redis-stack:7.2.0-v18
   @podman inspect -f '{{{{.State.Running}}}}' luminadb 2>/dev/null | grep -q 'true' \
        && echo "luminadb is already running." \
        || podman run -d -p 5432:5432 \
           --name luminadb \
           -e POSTGRES_USER=lumina \
           -e POSTGRES_PASSWORD=lumina_pw \
           -e POSTGRES_DB=lumina_config \
           -v ./data/postgres:/var/lib/postgresql/data:Z \
           docker.io/library/postgres:17-alpine3.22
   sqlx db create
   sqlx migrate run
   echo "Postgres database created and migrations ran"


[doc("Run the server in development mode")]
[group("local-devel")]
local-devel $LUMINA_POSTGRES_PASSWORD="lumina_pw": build-server
    ./target/debug/lumina-server

[doc("Run the server in development mode with file watching")]
[group("local-devel")]
local-devel-watch:
    watchexec --restart --stop-timeout=0 --shell=sh -e rs,gleam,toml,css,ts,json -- just local-devel

[doc("Runs the commands from local-devel automatically, watches")]
[group("local-devel")]
dev:
    @just local-devel-prep
    @just local-devel-watch

[group("local-devel")]
[doc("Run pgweb (8081) and redis-commander (8082) for local development")]
local-devel-dataexplorer: local-devel-prep
   podman run -d --replace --name lumina-redis-commander -p 8082:8081 -e REDIS_HOSTS=host.containers.internal:6379 ghcr.io/joeferner/redis-commander:latest
   podman run -d --replace --name lumina-pgweb -p 8081:8081 -e'PGWEB_DATABASE_URL=postgres://lumina:lumina_pw@host.containers.internal:5432/lumina_config?sslmode=disable' sosedoff/pgweb:latest
