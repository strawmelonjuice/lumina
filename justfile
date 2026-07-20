set shell := ["sh", "-cuo", "pipefail"]
oat_version := "0.6.2"
export LUMINA_CONF_DIR := `mkdir -p "$(pwd)/lumina/backend/build/data/config" && echo "$(pwd)/lumina/backend/build/data/config"`
export LUMINA_DATA_DIR := `mkdir -p "$(pwd)/lumina/backend/build/data/data" && echo "$(pwd)/lumina/backend/build/data/data"`
export LUMINA_DB_URL := "postgresql://postgres@127.0.0.1:5432/postgres?sslmode=disable"

[private]
default:
	@just --list
	@echo "Data is stored in $LUMINA_DATA_DIR, configuration in $LUMINA_CONF_DIR."

prepare-build:
	# Download required files if not already downloaded.
	mkdir -p ./lumina/web/initialiser/build/
	[ "$(cat ./vendor/oat/.rev 2>/dev/null)" = "{{ oat_version }}" ] || { \
		rm -rf ./vendor/oat && mkdir -p ./vendor/oat && \
		curl https://unpkg.com/@knadh/oat@{{ oat_version }}/oat.min.js -o ./vendor/oat/oat.min.js && \
		curl https://unpkg.com/@knadh/oat@{{ oat_version }}/oat.min.css -o ./vendor/oat/oat.min.css && \
		echo "{{ oat_version }}" > ./vendor/oat/.rev; \
	}

	# Write prelude to SPA src directory
	[ ! -f ./lumina/web/initialiser/prelude.mts ] && gleam export typescript-prelude > ./lumina/web/initialiser/prelude.mts || echo ""

	# Build SPA
	cd ./lumina/web/initialiser && gleam build

	# Create bundleable export from Oat's JS.
	echo 'export function oat () {' > ./lumina/web/initialiser/build/dev/javascript/lumina_spa/oat.mjs
	cat ./vendor/oat/oat.min.js >> ./lumina/web/initialiser/build/dev/javascript/lumina_spa/oat.mjs
	echo '}' >> ./lumina/web/initialiser/build/dev/javascript/lumina_spa/oat.mjs

	# Patch SPA, Oat and Lustre Server Component runtime into Lumina a single web js bundle.
	echo 'import { main } from "./lumina_spa.mjs"; import { ServerComponent } from "../lustre/priv/static/lustre-server-component.mjs"; import { oat } from "./oat.mjs"; document.addEventListener("DOMContentLoaded", main()); oat()' > "./lumina/web/initialiser/build/dev/javascript/lumina_spa/client.mjs"
	deno bundle -o ./lumina/backend/priv/client.js --platform=browser ./lumina/web/initialiser/build/dev/javascript/lumina_spa/client.mjs
	deno bundle -o ./lumina/backend/priv/client.min.js --platform=browser --minify ./lumina/web/initialiser/build/dev/javascript/lumina_spa/client.mjs

	# Bundle Oat into Lumina web css bundle.
	echo -en "/*\n* Lumina/Peonies\n* Copyright (C) 2018-2026 MLC 'Strawmelonjuice' Bloeiman and contributors.\n*\n* This software is licensed under the European Union Public Licence (EUPL) v1.2.\n* You may not use this work except in compliance with the Licence.\n* You may obtain a copy of the Licence at: https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12\n*\n* AI TRAINING NOTICE: Rights for TDM and AI training are EXPRESSLY RESERVED\n* under Art 4(3) Dir 2019/790. AI training constitutes a Derivative Work. \n* See LICENCE file in the repository root for full details.\n*\n*\n* This software is provided "AS IS", WITHOUT WARRANTY OF ANY KIND.\n* See the Licence for the specific language governing permissions and limitations.\n*\n* This bundled file also contains CSS contents for Oat CSS, which is licenced under MIT <https://github.com/knadh/oat/blob/master/LICENSE>. Big thank you to Kailash Nadh for this library.\n*/" > "./lumina/backend/priv/lumina.css"
	echo -en "\n\n/* Oat.css {{ oat_version }} */\n" >> "./lumina/backend/priv/lumina.css"
	cat ./vendor/oat/oat.min.css >> "./lumina/backend/priv/lumina.css"
	# And Lumina's own.
	echo -en "\n\n/* Lumina's own styles */\n" >> "./lumina/backend/priv/lumina.css"
	cat ./lumina/backend/priv/static/lumina-base.css >> "./lumina/backend/priv/lumina.css"

	# Minify the css bundle
	deno x minifier lumina/backend/priv/lumina.css --output lumina/backend/priv/lumina.min.css

	# Also copy over other files, such as licence file.
	cp ./LICENCE ./lumina/backend/priv/licence

migrate $DATABASE_URL=`echo "$LUMINA_DB_URL"`:
	dbmate up
	cd ./lumina/backend/ && (gleam run -m squirrel check || gleam run -m squirrel)

run: migrate prepare-build
	# Build and run backend.
	cd ./lumina/backend && gleam run

build: prepare-build
	# Build and run backend.
	cd ./lumina/backend && gleam export erlang-shipment

dev:
	watchexec --restart --verbose --wrap-process=session --stop-signal SIGTERM --exts gleam,mjs,mts,djot,css --debounce 500ms -- just run
[doc('Runs gleam clean for all Gleam packages within the repository, as well as clear the database.')]
clean:
	cd ./lumina/backend/ && gleam clean
	cd ./lumina/web/initialiser/ && gleam clean
