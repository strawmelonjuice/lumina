#!/usr/bin/env bash

LOCA=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
SECONDS=0
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

noti() {
	echo -e "\e[3m\e[1m$1\e[23m\e[22m"
}
errnoti() {
	echo -e "\x1B[31m$1\e[0m"
}
success() {
	echo -e "\e[38;5;42m$1\e[39m"
}

rm -rf "$LOCA/backend/priv/generated/js"
mkdir "$LOCA/backend/priv/generated/js"

if [[ "$*" == *"--frontend-ts"* ]]; then
	noti "Building front-end (TS)..."
	cd "$LOCA/frontend-ts/" || exit 1
	bun install
	noti "Transpiling and copying to Lumina server..."
	bun build "$LOCA/frontend-ts/app.ts" --minify --target=browser --outdir "$LOCA/backend/priv/generated/js/" --sourcemap=linked --minify
	bun "$LOCA/tobundle.ts" -- js-1 "$LOCA/backend/priv/generated/js/app.js"
else
	if [[ "$*" == *"--frontend-gleam"* ]]; then
		noti "Building front-end (Gleam)..."

		cd "$LOCA/frontend/" || exit 1
		if gleam build --target js; then
			success "\t--> Frontend build success."
		else
			errnoti "\t--> Frontend compilation ran into an error."
			exit 1
		fi
		noti "Copying to Lumina server..."
		echo "import { main } from \"./frontend.mjs\";main();" >"$LOCA/frontend/build/dev/javascript/frontend/app.js"
		bun build "$LOCA/frontend/build/dev/javascript/frontend/app.js" --minify --target=browser --outdir "$LOCA/backend/priv/generated/js/" --sourcemap=external --minify
		bun "$LOCA/tobundle.ts" -- js-1 "$LOCA/backend/priv/generated/js/app.js"
	else
		errnoti "Invalid or missing frontend option, expected either \"--frontend-ts\" or \"--frontend-gleam\"."
		exit 1
	fi
fi
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
noti "Front-end should be done. Continuing to generated assets."
cd "$LOCA/backend/" || exit 1
bun install
rm -rf "$LOCA/backend/priv/generated/css/"
mkdir "$LOCA/backend/priv/generated/css/"
noti "Generating CSS... (TailwindCSS)"
bun x postcss -o "$LOCA/backend/priv/generated/css/main.css" "$LOCA/backend/assets/styles/main.pcss" -u autoprefixer -u tailwindcss
bun "$LOCA/tobundle.ts" -- css-1 "$LOCA/backend/priv/generated/css/main.css"
noti "Minifying CSS and copying to Lumina server..."
bun x cleancss -O1 specialComments:all --inline none "$LOCA/backend/priv/generated/css/main.css" -o "$LOCA/backend/priv/generated/css/main.min.css"
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
noti "Compiling Rust libraries..."
cd "$LOCA/rsffi/" || exit 1
if cargo build --release; then
	success "\t--> Rust libraries build success."
else
	errnoti "\t--> Rust libraries compilation ran into an error."
	exit 1
fi
rm -rf "$LOCA/backend/priv/generated/libs/"
mkdir "$LOCA/backend/priv/generated/libs/"
noti "Copying Rust libraries to Lumina server..."
cp "$LOCA/rsffi/target/release/librsffi.so" "$LOCA/backend/priv/generated/libs/rsffi.so"
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
noti "Starting on Lumina server compilation"
cd "$LOCA/backend/" || exit 1
if gleam build --target erlang; then
	success "\t--> Back-end build success."
else
	errnoti "\t--> Compilation ran into an error!"
	exit 1
fi
duration=$SECONDS
noti "Build completed, took $((duration / 60)) minutes and $((duration % 60)) seconds."
if [[ "$*" == *"--run"* ]]; then
	noti "'--run' detected. Running Lumina directly!"
	gleam run -- start
else
	if [[ "$*" == *"--pack"* ]]; then
		noti "'--pack' detected. Packaging for deployment."
	else
		if [[ "$*" == *"--test"* ]]; then
			noti "'--test' detected. Running Cargo tests."
			cd "$LOCA/rsffi/" || exit 1
			cargo check || {
				errnoti "\t--> Cargo tests ran into an error."
				exit 1
			}
			noti "'--test' detected. Running backend tests."
			cd "$LOCA/backend/" || exit 1
			gleam test --target erlang || {
				errnoti "\t--> Backend tests ran into an error."
				exit 1
			}
			noti "'--test' detected. Running library tests."
			cd "$LOCA/shared/" || exit 1
			gleam test --target erlang || {
				errnoti "\t--> Library tests ran into an error."
				exit 1
			}
			noti "'--test' detected. Running frontend tests."
			if [[ "$*" == *"--frontend-ts"* ]]; then
				cd "$LOCA/frontend-ts/" || exit 1
				bun test || {
					errnoti "\t--> Frontend tests ran into an error."
					exit 1
				}
			else
				if [[ "$*" == *"--frontend-gleam"* ]]; then
					cd "$LOCA/frontend/" || exit 1
					gleam test --target javascript || {
						errnoti "\t--> Frontend tests ran into an error."
						exit 1
					}
				fi
			fi
			success "All tests completed."
		fi
	fi
fi
