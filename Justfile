default:
    @just --list

[doc("Build the styles for Lumina client")]
[group('building')]
build-styles:
    cd ./client/ && bun x @tailwindcss/cli -i ./app.css -o ./priv/static/lumina_client.css

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
