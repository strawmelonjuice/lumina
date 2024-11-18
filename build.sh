#!/usr/bin/env bash

LOCA=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
SECONDS=0
QUIET=false
TESTS=false
PACK=false
BUNFLAGS=""
CARGOFLAGS=""
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

if [[ "$*" == *"--quiet"* ]]; then
	QUIET=true
fi
if [[ "$*" == *"--test"* ]]; then
	QUIET=true
	TESTS=true
fi
if [[ "$*" == *"--pack"* ]]; then
	PACK=true
fi
if [[ "$*" == *"--run-packed"* ]]; then
	PACK=true
fi
if [ "$QUIET" = true ]; then
	echo "Quiet mode enabled."
	BUNFLAGS="$BUNFLAGS --silent --quiet"
	CARGOFLAGS="$CARGOFLAGS --quiet"
	export BUN_DEBUG_QUIET_LOGS=1
fi
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
noti() {
	if [ "$QUIET" = true ]; then
		return
	fi
	echo -e "\e[3m\e[1m$1\e[23m\e[22m"
}
errnoti() {
	if [ "$QUIET" = true ]; then
		return
	fi
	echo -e "\x1B[31m$1\e[0m"
}
success() {
	if [ "$QUIET" = true ]; then
		if [ "$TESTS" = false ]; then
			return
		fi
	fi
	echo -e "\e[38;5;42m$1\e[39m"
}
res_noti() {
	if [ "$QUIET" = true ]; then
		if [ "$TESTS" = false ]; then
			return
		fi
	fi
	if [[ "$1" = 1 ]]; then
		echo -e "\e[3m\e[1m$2\e[23m\e[22m"
	else
		echo -e "\e[4m\e[3m\e[1m$2\e[23m\e[22m\e[0m"
	fi
}
res_fail() {
	if [ "$QUIET" = true ]; then
		if [ "$TESTS" = false ]; then
			return
		fi
	fi
	echo -e "\e[4m\x1B[31m$1\e[0m\e[0m"
}
res_succ() {
	if [ "$QUIET" = true ]; then
		if [ "$TESTS" = false ]; then
			return
		fi
	fi
	echo -e "\e[4m\e[38;5;42m$1\e[39m\e[0m"
}

# echo "noti:"
# noti "This is a notification."
# echo "errnoti:"
# errnoti "This is an error notification."
# echo "success:"
# success "This is a success message."
# echo "res_noti:"
# res_noti 1 "This is a result notification."
# res_noti 2 "This is a result phase change."
# echo "res_fail:"
# res_fail "This is a failed result."
# echo "res_succ:"
# res_succ "This is a successful result."

# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
res_noti 2 "Starting build process..."
rm -rf "$LOCA/backend/priv/generated/js"
mkdir -p "$LOCA/backend/priv/generated/js"

if [[ "$*" == *"--frontend-ts"* ]]; then
	noti "Building front-end (TS)..."
	cd "$LOCA/frontend-ts/" || exit 1
	bun install $BUNFLAGS
	noti "Transpiling and copying to Lumina server..."
	bun $BUNFLAGS build "$LOCA/frontend-ts/app.ts" --minify --target=browser --outdir "$LOCA/backend/priv/generated/js/" --sourcemap=linked
	bun $BUNFLAGS "$LOCA/tobundle.ts" -- js-1 "$LOCA/backend/priv/generated/js/app.js"
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
		bun $BUNFLAGS build "$LOCA/frontend/build/dev/javascript/frontend/app.js" --minify --target=browser --outdir "$LOCA/backend/priv/generated/js/" --sourcemap=none
		bun $BUNFLAGS "$LOCA/tobundle.ts" -- js-1 "$LOCA/backend/priv/generated/js/app.js"
	else
		errnoti "Invalid or missing frontend option, expected either \"--frontend-ts\" or \"--frontend-gleam\"."
		exit 1
	fi
fi
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
noti "Front-end should be done. Continuing to generated assets."
cd "$LOCA/backend/" || exit 1
bun install $BUNFLAGS
rm -rf "$LOCA/backend/priv/generated/css/"
mkdir -p "$LOCA/backend/priv/generated/css/"
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
mkdir -p "$LOCA/backend/priv/generated/libs/"
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
res_noti 1 "Build completed, took $((duration / 60)) minutes and $((duration % 60)) seconds."
if [[ "$*" == *"--run"* ]]; then
	noti "'--run' detected. Running Lumina directly!"
	gleam run -- start
else
	if [[ "$*" == *"--pack"* ]]; then
		noti "'--pack' detected. Packaging for deployment."
		rm -rf "$LOCA/target/"
		mkdir -p "$LOCA/target/"
		gleam run -m gleescript &&
			cp -r "$LOCA/backend/priv/" "$LOCA/target/" &&
			mv ./lumina "$LOCA/target/lumina" &&
			res_succ "Lumina Escript written to \"$LOCA/target/lumina\", ready for deployment."
		exit 0
	else
		if [[ "$*" == *"--test"* ]]; then
			clear
			res_noti 1 "Build completed, took $((duration / 60)) minutes and $((duration % 60)) seconds."
			res_noti 2 "Running tests"
			res_noti 1 "Running Cargo tests"
			cd "$LOCA/rsffi/" || exit 1
			cargo test || {
				res_fail "\t--> Cargo tests ran into an error."
				exit 1
			}
			res_succ "\t-> Success"
			res_noti 1 "Running backend tests"
			cd "$LOCA/backend/" || exit 1
			gleam run -m backend_test --target erlang || {
				res_fail "\t--> Backend tests ran into an error."
				exit 1
			}
			res_succ "\t-> Success"

			# # These tests are not needed, the shared libary can be tested within the gleam frontend and backend tests.
			# res_noti 1 "Running library tests"
			# cd "$LOCA/shared/" || exit 1
			# gleam test --target erlang || {
			# 	res_fail "\t--> Library tests ran into an error."
			# 	exit 1
			# }
			# res_succ "\t-> Success"
			res_noti 1 "Running frontend tests"
			if [[ "$*" == *"--frontend-ts"* ]]; then
				cd "$LOCA/frontend-ts/" || exit 1
				bun test || {
					res_fail "\t--> Frontend tests ran into an error."
					exit 1
				}
				res_succ "\t-> Success"
			else
				if [[ "$*" == *"--frontend-gleam"* ]]; then
					cd "$LOCA/frontend/" || exit 1
					gleam test --target javascript || {
						res_fail "\t--> Frontend tests ran into an error."
						exit 1
					}
					res_succ "\t-> Success"
				fi
			fi
			res_succ "\n\nAll tests completed."
		fi
	fi
fi
