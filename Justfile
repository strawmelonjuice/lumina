[private]
default:
	@just --list

[doc("Build the styles for Lumina client")]
[group('building')]
build-styles:
	cd ./client/ && tailwindcss -i ./app.css -o ../server/priv/static/lumina_client.css

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
build-client: build-styles
	cd ./client/ &&\
	gleam build --target javascript &&\
	find ./src/ -type f -print0 | xargs -0 sha256sum | sha256sum | awk '{print $1}' > "../server/priv/static/lumina_client_rev.hash" &&\
	echo 'import { main } from "./lumina_client.mjs";document.addEventListener("DOMContentLoaded", main())' > "./build/dev/javascript/lumina_client/lumina_client.ts" &&\
	bun build ./build/dev/javascript/lumina_client/lumina_client.ts --minify --outfile ../server/priv/static/lumina_client.min.mjs --target=browser &&\
	bun build ./build/dev/javascript/lumina_client/lumina_client.ts --outfile ../server/priv/static/lumina_client.mjs --target=browser

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

[doc("Clean all build artifacts")]
clean-all:
	rm -rf ./client/node_modules
	cd client && gleam clean
	cd server && gleam clean
	rm -rf ./client/build/dev/javascript/lumina_client/lumina_client.mjs
	rm -rf ./client/build/dev/javascript/lumina_client/lumina_client.ts
	rm -rf ./server/priv/static/lumina_client.min.mjs
	rm -rf ./server/priv/static/lumina_client.css

[doc("Prepares database")]
[group("local-devel")]
local-devel-prep: create-data-dirs
   dbmate up


[doc("Run the server in development mode")]
[group("local-devel")]
local-devel: local-devel-prep build-server
   podman run --replace --name lumina-local-devel -v ./data/:/data -p 3000:3000 localhost/luminapeonies:latest

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
   @echo "This script needs to be rewritten for the gleam branch you are on."
   @exit 1

