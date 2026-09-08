set shell := ["sh", "-cuo", "pipefail"]
oat_version := "0.6.2"
export LUMINA_CONF_DIR := `mkdir -p "$(pwd)/lumina/backend/build/data/config" && echo "$(pwd)/lumina/backend/build/data/config"`
export LUMINA_DATA_DIR := `mkdir -p "$(pwd)/lumina/backend/build/data/data" && echo "$(pwd)/lumina/backend/build/data/data"`
export LUMINA_DB_URL := "postgresql://postgres@127.0.0.1:5432/postgres?sslmode=disable"

[private]
default:
	@just --list
	@echo "Data is stored in $LUMINA_DATA_DIR, configuration in $LUMINA_CONF_DIR."

[doc('Vendor dependencies and prepare files for building Lumina')]
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
	cat ./lumina/backend/priv/static/lumina-extended.css >> "./lumina/backend/priv/lumina.css"

	# Minify the css bundle
	deno x minifier lumina/backend/priv/lumina.css --output lumina/backend/priv/lumina.min.css

	# Also copy over other files, such as licence file.
	cp ./LICENCE ./lumina/backend/priv/licence
	@just embed-docs

[doc('Migrate or initialise database and update Squirrel with it. This requires the database, so either run it from just
dev or start the database by hand.')]
migrate $DATABASE_URL=`echo "$LUMINA_DB_URL"`:
	dbmate up
	cd ./lumina/backend/ && (gleam run --no-print-progress -m squirrel check || gleam run --no-print-progress -m squirrel)

[doc('Manually start the postgres database.')]
start-db:
	if ! pg_ctl status >/dev/null 2>&1 ; then pg_ctl -D "$PGDATA" -l "$LOG_PATH" -o "-c listen_addresses=\"127.0.0.1\"" start; fi
	@echo "Be sure to run pg_ctl stop when done!"

[doc('Build and run Lumina, this does not start the database.')]
run: prepare-build
	cd ./lumina/backend && gleam run

[doc("Build and test Lumina instance, including database.")]
test-instance: prepare-build
	if ! pg_ctl status >/dev/null 2>&1 ; then pg_ctl -D "$PGDATA" -l "$LOG_PATH" -o "-c listen_addresses=\"127.0.0.1\"" start; fi
	just migrate || echo "Something went wrong running 'just migrate'."
	trap 'pg_ctl stop' EXIT; (cd ./lumina/backend && gleam test)

[doc("Build and test Lumina SPA.")]
test-spa:
	cd ./lumina/web/initialiser/ && gleam test --target javascript --runtime deno

[doc("Build and test both SPA and instance.")]
[parallel]
test: test-spa test-instance

[doc('Build Lumina.')]
build: prepare-build
	cd ./lumina/backend && gleam export erlang-shipment

[doc('Continuously build and run Lumina, including database.')]
dev:
	if ! pg_ctl status >/dev/null 2>&1 ; then pg_ctl -D "$PGDATA" -l "$LOG_PATH" -o "-c listen_addresses=\"127.0.0.1\"" start; fi
	just migrate || echo "Something went wrong running 'just migrate'."
	trap 'pg_ctl stop' EXIT; watchexec --restart --verbose --wrap-process=session --stop-signal SIGTERM --exts gleam,mjs,mts,djot,css --debounce 500ms -- just run

[doc('Runs gleam clean for all Gleam packages within the repository, as well as clear the database.')]
clean:
	cd ./lumina/backend/ && gleam clean
	cd ./lumina/web/initialiser/ && gleam clean

update-elp:
	#!/usr/bin/env bash
	set -euo pipefail
	backend_dir="$(pwd)/lumina/backend"
	app_name=$(awk -F'"' '/^name[[:space:]]*=/ { print $2; exit }' "$backend_dir/gleam.toml")
	build_dir="$backend_dir/build/dev/erlang/$app_name"

	rm -fr .elp
	mkdir -p .elp

	for erl_file in "$build_dir/_gleam_artefacts/*.erl"; do
		[ -e "$erl_file" ] || continue
		base_name=$(basename "$erl_file")
		already_in_src=$(find src -name "$base_name" -print -quit)
	  	if [ -z "$already_in_src" ]; then
			ln -sf "$(pwd)/$erl_file" ".elp/$base_name"
		fi
	done

	list_deps() {
		for dep_dir in build/dev/erlang/*/; do
			dep_name=$(basename "$dep_dir")
			[ "$dep_name" = "$app_name" ] && continue

			if [ -d "${dep_dir}_gleam_artefacts" ]; then

				dep_src_dir=_gleam_artefacts
				elif find "${dep_dir}src" -maxdepth 1 -iname "*.erl" -print -quit 2>/dev/null | grep -q .; then
				dep_src_dir=src
				else
					continue
				fi

			jq -n --arg name "$dep_name" --arg dir "build/dev/erlang/$dep_name" --arg src_dir "$dep_src_dir" '{name: $name, dir: $dir, src_dirs: [$src_dir], include_dirs: ["include"], ebin: "ebin"}'
		done
	}
	jq -n --arg name "$app_name" --arg include_dir "$build_dir/include" --arg ebin_dir "$build_dir/ebin" --slurpfile deps <(list_deps) '{
	apps: [{
		name: $name,
		dir: ".",
		src_dirs: ["src"],
		extra_src_dirs: [".elp"],
		include_dirs: [$include_dir],
		ebin: $ebin_dir
		}],
		deps: $deps
	}' > .elp.build_info
	echo "wrote .elp.build_info for app \"$app_name\""


[group("Docs")]
[doc('Builts and assembles the documentation files for Lumina. This is quite experimental at the moment.')]
build-docs:
	rm -fr ./dist/documentation/

	rm -fr ./lumina/backend/build/docs-temp; cp -r ./docs-new ./lumina/backend/build/docs-temp
	cd ./lumina/backend/ && gleam docs build
	cd ./lumina/web/initialiser/ && gleam docs build && mkdir -p ./build/dev/docs/lumina_spa/lumina_spa

	mkdir -p ./dist/documentation/development/
	mkdir -p ./docgentemp


	mv ./lumina/backend/build/dev/docs/lumina_server -T ./dist/documentation/development
	# List the module links in both the client and the instance packages
	grep "module-link" ./lumina/web/initialiser/build/dev/docs/lumina_spa/index.html | tr '\n' '\r' | sed 's,/,SCHUINE-STREEP,g'  > ./docgentemp/client-modules.esc.html
	# Insert the client modules into the instance' docs
	find "./dist/documentation/development" -name "*.html" -type f -exec just insert-client-mods {} \;
	cat ./dist/documentation/development/index.html
	grep "module-link" ./dist/documentation/development/index.html | tr '\n' '\r'  | sed 's,/,SCHUINE-STREEP,g' > ./docgentemp/modules.esc.html

	# Move the Gleam-generated documentation files into the output directory
	mkdir ./dist/documentation/development/client/
	mv ./dist/documentation/development/lumina_server ./dist/documentation/development/instance && mv ./dist/documentation/development/lumina_server.html ./dist/documentation/development/instance.html
	# Prepare client HTML files for mingling with server HTML files.
	find "./lumina/web/initialiser/build/dev/docs/lumina_spa" -name "*.html" -type f -exec just insert-mods-client {} \;
	mv ./lumina/web/initialiser/build/dev/docs/lumina_spa/lumina_spa ./dist/documentation/development/client
	mv ./lumina/web/initialiser/build/dev/docs/lumina_spa/lumina_spa.html ./dist/documentation/development/client.html

	# Some CSS alterations
	(cat ./vendor/oat/oat.min.css && cat "./dist/documentation/development/css/index.css" && cat "./lumina/backend/priv/static/lumina-base.css" &&  echo "{{devdocs-css}}") >./dist/documentation/development/css/index.css.tmp
	mv ./dist/documentation/development/css/index.css.tmp ./dist/documentation/development/css/index.css
	sed -i 's/\.theme-dark/\.disabled-theme-dark/g' ./dist/documentation/development/css/index.css

	# Merge the search data
	sed 's/{"items":\[{"type":"page","parentTitle":"lumina_spa","title":"lumina_spa","doc":"","ref":"index.html"}//g' ./lumina/web/initialiser/build/dev/docs/lumina_spa/search-data.json > ./docgentemp/search-data-client.part.json
	sed -i "s/\],\"proglang\":\"gleam\"}//g" ./dist/documentation/development/search-data.json
	cat ./docgentemp/search-data-client.part.json >> ./dist/documentation/development/search-data.json
	just dev-docs-finalise-html ./dist/documentation/development/search-data.json

	# The index page differs from any module pages. It needs to be populated freshly with content.
	sed 's,/,SCHUINE-STREEP,g' ./dist/documentation/development/index.html > ./docgentemp/development-index.html.tmp
	sed -i "/.*<main.*/a <!-- start of converted djot --> \
		$(deno x -y --allow-all npm:@djot/djot ./docs-new/development/readme.dj -t html | \
		sed "s,/,SCHUINE-STREEP,g;s,’,\\'," | tr '\n' '\r' )\
		<!-- end of converted djot -->" ./docgentemp/development-index.html.tmp
	just dev-docs-finalise-html ./docgentemp/development-index.html.tmp
	mv ./docgentemp/development-index.html.tmp ./dist/documentation/development/index.html

	# Remove temporary files
	rm -fr ./docgentemp
	find "./dist" -name "*.tmp" -type f -exec rm {} \;


devdocs-css:="""
	:root {
		color-scheme: light;
		--bg: var(--muted);
		--fg-shade-1: var(--muted-foreground);
	}
	body,.page {
		background-color: var(--bg);
	}
	.page-header {
		background-color: var(--accent);
		color: var(--accent-foreground);
	}
	main.content {
		margin-left: calc(var(--sidebar-width) * 1.5);
		background-color: var(--bg);
		color: var(--fg-shade-1);
		width: calc(100VW - var(--sidebar-width));
		max-width: 100vw;
	}
	body.drawer-closed {
		@media only screen and (max-width: 600px) {
			main.content {
				width:unset;
				margin-left:unset;
			}
		}
	}
	.sidebar {
		background-color: var(--background);
	    	color: var(--foreground);
		height: calc(100VH - var(--header-height));
		h2 {
			font-size:1.2rem;
		}
	}
	.module-name, .icon-gleam-chasse, .icon-gleam-chasse-2, #project-version,.display-controls {
		display: none !important;
	}
 	.module-name +p {
		>strong {
			font-size: 1rem;
			margin-top: 2.5rem;
			margin-right: 0px;
			margin-left: 0px;
			margin-bottom: 0;
		}
		+h1 {
			margin-top: 0;
			margin-right: 0px;
			margin-left: 0px;
			margin-bottom: 1.5rem;
			font-size: 3rem;
			text-decoration: underline dotted 8px;
			text-underline-position: under;
        		text-underline-offset: 3px;
		}
	}
	code.hljs {

	}

	blockquote {
		background-color: var(--card);
		color: var(--card-foreground);
	}
"""

[private]
insert-client-mods filename:
	sed 's,/,SCHUINE-STREEP,g' {{filename}} > {{filename}}.tmp
	sed -i "/$(grep 'module-link' {{filename}}.tmp | tail -n 1 | tr -d '\n' )/a $(cat ./docgentemp/client-modules.esc.html)" {{filename}}.tmp
	just dev-docs-finalise-html {{filename}}.tmp
	# difft {{filename}} {{filename}}.tmp
	mv {{filename}}.tmp {{filename}}
[private]
dev-docs-finalise-html filename:
	sed \
	's,SCHUINE-STREEP,/,g;\
	s,syntax-theme,,g;\
	s,module-link">lumina_server,module-link">instance,g;\
	s,module-link">lumina_spa,module-link">web client,g;\
	s,.*docs_config\.js".*,\t<!-- It has been removed for Lumina -->,;\
	s,>README</a>,>Development documentation</a><!-- Other doc branches may grow here\, like users -->,g;\
	s,href=".*./index\.html",href="/documentation/development/",g;\
	s,href="\./\(.*\).html",href="/documentation/development/\1.html",;\
	s,href=".*./css/,href="/documentation/development/css/,g;s,".*\./lumina_,"\./lumina_,g;\
	s,\./lumina_spa,/documentation/development/client,g;\
	s,\./lumina_server,/documentation/development/instance,g;\
	s,href=".*/">lumina_.*</a>,href="/documentation/development/index\.html">Lumina dev docs</a>,;\
	s,lumina_spa\.html,client\.html,g;\
	s/"ref":"lumina_server/"ref":"instance/g;\
	s/"ref":"lumina_spa/"ref":"client/g' {{filename}} \
	| tr '\r' '\n' > {{filename}}.2
	mv {{filename}}.2 {{filename}}


[private]
insert-mods-client filename:
	sed 's,/,SCHUINE-STREEP,g' {{filename}} > {{filename}}.tmp
	sed -i '0,/module-link/s//linked-module/' {{filename}}.tmp
	sed -i 's/.*module-link.*//' {{filename}}.tmp
	sed -i "s/.*linked-module.*/ $(cat ./docgentemp/modules.esc.html) /" {{filename}}.tmp
	just dev-docs-finalise-html {{filename}}.tmp
	# difft {{filename}} {{filename}}.tmp
	mv {{filename}}.tmp {{filename}}

[group("Docs")]
[doc('Builds and deploys Lumina documentation to <https://sites.wisp.place/did:plc:jgtfsmv25thfs4zmydtbccnn/lumina-documentation>. This is quite experimental at the moment.')]
deploy-docs: build-docs
	rm -fr  ./dist/documentation-site
	cp -r ./dist/documentation ./dist/documentation-site
	find "./dist/documentation-site/" -name "*.html" -type f -exec sed -i 's,"/documentation,"https://sites.wisp.place/did:plc:jgtfsmv25thfs4zmydtbccnn/lumina-documentation,g' {} \;
	deno x -y --allow-all npm:wispctl deploy did:plc:jgtfsmv25thfs4zmydtbccnn \
			--path ./dist/documentation-site/ \
			--site lumina-documentation
[doc('Embeds the docs from `dist/documentation` into the server files. Only builds once (if directory is not found), run build-docs to process changes.')]
embed-docs:
	@[ ! -d "./dist/documentation/" ] && just build-docs || echo "Documentation was generated before, run just build-docs to regenerate."
	rm -fr ./lumina/backend/priv/static/documentation
	cp -r ./dist/documentation ./lumina/backend/priv/static/documentation
