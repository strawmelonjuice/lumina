#!/usr/bin/env bash

LOCA=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
GEN_ASSETS="$LOCA/backend/priv/generated"
SECONDS=0
QUIET=false
TESTS=false
PACK=false
BUNFLAGS=""
CARGOFLAGS=""
BCARGOFLAGS=""
TEST_FE_TS=false
TEST_FE_GLEAM=false
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

if [[ "$*" == *"--backend=rust"* ]]; then
	GEN_ASSETS="$LOCA/backend-rs/generated"
fi

if [[ "$*" == *"--quiet"* ]]; then
	QUIET=true
fi
if [[ "$*" == *"--test"* ]]; then
	QUIET=true
	TESTS=true
fi
if [[ "$*" == *"--pack"* ]]; then
	PACK=true
	BCARGOFLAGS="--release"
fi
if [[ "$*" == *"--run-packed"* ]]; then
	PACK=true
	BCARGOFLAGS="--release"
fi
if [ "$QUIET" = true ]; then
	echo "[quiet mode]" >&2
	BUNFLAGS="$BUNFLAGS --silent --quiet"
	CARGOFLAGS="$CARGOFLAGS --quiet"
	export BUN_DEBUG_QUIET_LOGS=1
fi
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

if [[ "$*" == *"--help"* ]]; then
	printf "Usage: ./build.sh [options]\n\n"
	printf "Options:\n\n"
	printf "  --help\n\t\tDisplay this help message.\n"
	printf "  --frontend={typescript | gleam}\n\t\tSpecify the frontend to build.\n"
	printf "  --test\n\t\tRun tests after building.\n"
	printf "  --run\n\t\tRun after building.\n"
	printf "  --quiet\n\t\tSuppress unneccessary output.\n"
	printf "  --pack\n\t\tPackage for deployment.\n"
	printf "  --run-packed\n\t\tBuild, compile and pack, then run the packed version of Lumina.\n"
	exit 0
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
rm -rf "$GEN_ASSETS/js"
mkdir -p "$GEN_ASSETS/js"
bun install $BUNFLAGS

if [[ "$*" == *"--frontend=typescript"* ]]; then
	noti "Building front-end (TS)..."
	TEST_FE_TS=true
	cd "$LOCA/frontend-ts/" || exit 1
	bun install $BUNFLAGS
	noti "Transpiling and copying to Lumina server..."
	bun $BUNFLAGS build "$LOCA/frontend-ts/app.ts" --minify --target=browser --outdir "$GEN_ASSETS/js/" --sourcemap=linked || {
		errnoti "Error while building the frontend."
		exit 1
	}
	bun $BUNFLAGS "$LOCA/tobundle.ts" -- js-1 "$GEN_ASSETS/js/app.js" || {
		errnoti "Error while bundling the frontend."
		exit 1
	}
else
	if [[ "$*" == *"--frontend=gleam"* ]]; then
		noti "Building front-end (Gleam)..."

		TEST_FE_GLEAM=true
		cd "$LOCA/frontend/" || exit 1
		if gleam build --target js; then
			success "\t--> Frontend build success."
		else
			errnoti "\t--> Frontend compilation ran into an error."
			exit 1
		fi
		noti "Copying to Lumina server..."
		echo "import { main } from \"./frontend.mjs\";main();" >"$LOCA/frontend/build/dev/javascript/frontend/app.js"
		bun $BUNFLAGS build "$LOCA/frontend/build/dev/javascript/frontend/app.js" --minify --target=browser --outdir "$GEN_ASSETS/js/" --sourcemap=linked || {
			errnoti "Error while bundling the frontend."
			exit 1
		}
		bun $BUNFLAGS "$LOCA/tobundle.ts" -- js-1 "$GEN_ASSETS/js/app.js" || {
			errnoti "Error while bundling the frontend."
			exit 1
		}
	else
		errnoti "Invalid or missing frontend option, expected either \"--frontend=typescript\" or \"--frontend=gleam\"."
		if [ "$TESTS" = false ]; then
			exit 1
		else
			noti "This option is not needed for tests, running both frontend tests without it."
			TEST_FE_TS=true
			TEST_FE_GLEAM=true
		fi
	fi
fi
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
noti "Front-end should be done. Continuing to generated assets."
cd "$LOCA/" || exit 1
bun install $BUNFLAGS
rm -rf "$GEN_ASSETS/css/"
mkdir -p "$GEN_ASSETS/css/"
noti "Generating CSS... (TailwindCSS)"
bun x postcss -o "$GEN_ASSETS/css/main.css" "$LOCA/backend/assets/styles/main.pcss" -u autoprefixer -u tailwindcss
bun "$LOCA/tobundle.ts" -- css-1 "$GEN_ASSETS/css/main.css"
noti "Minifying CSS and copying to Lumina server..."
bun x cleancss -O1 specialComments:all --inline none "$GEN_ASSETS/css/main.css" -o "$GEN_ASSETS/css/main.min.css"
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
if [[ "$*" == *"--backend=rust"* ]]; then
	noti "Building Rust backend..."
	cd "$LOCA/backend-rs/" || exit 1
	if cargo build $BCARGOFLAGS; then
		success "\t--> Rust backend build success."
	else
		errnoti "\t--> Rust backend compilation ran into an error."
		exit 1
	fi
else
	if [[ "$*" == *"--backend=gleam"* ]]; then
		noti "Compiling Rust libraries..."
		cd "$LOCA/rsffi/" || exit 1
		if cargo build --release; then
			success "\t--> Rust libraries build success."
		else
			errnoti "\t--> Rust libraries compilation ran into an error."
			exit 1
		fi
		rm -rf "$GEN_ASSETS/libs/"
		mkdir -p "$GEN_ASSETS/libs/"
		noti "Copying Rust libraries to Lumina server..."
		cp "$LOCA/rsffi/target/release/librsffi.so" "$GEN_ASSETS/libs/rsffi.so"
		# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		noti "Starting on Lumina server compilation"
		cd "$LOCA/backend/" || exit 1
		if gleam build --target erlang; then
			success "\t--> Back-end build success."
		else
			errnoti "\t--> Compilation ran into an error!"
			exit 1
		fi
	else
		errnoti "Invalid or missing backend option, expected either \"--backend=gleam\" or \"--backend=rust\"."
		if [ "$TESTS" = false ]; then
			exit 1
		else
			noti "This option is not needed for tests, running both backend tests without it."
		fi
	fi
fi
build_duration=$SECONDS
res_noti 1 "Build completed, took $((build_duration / 60)) minutes and $((build_duration % 60)) seconds."
if [[ "$*" == *"--run"* ]]; then
	noti "'--run' detected. Running Lumina directly!"
	if [[ "$*" == *"--backend=rust"* ]]; then
		if [ "$PACK" = true ]; then
			"$LOCA/backend-rs/target/release/lumina-server" || exit 1
		else
			"$LOCA/backend-rs/target/debug/lumina-server" || exit 1
		fi
	else
		cd "$LOCA/backend/" || exit 1
		gleam run -- start
	fi
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
			SECONDS=0
			TESTS_SUCCEEDED=true
			res_noti 1 "Build completed, took $((duration / 60)) minutes and $((duration % 60)) seconds."
			res_noti 2 "Running tests"
			res_noti 1 "Running Cargo tests"
			cd "$LOCA/rsffi/" || exit 1
			cargo test || {
				res_fail "\t--> Cargo tests ran into an error."
				TESTS_SUCCEEDED=false
			}
			res_succ "\t-> Success: Rust libraries"
			res_noti 1 "Running tests on Lumina server (backend)"
			cd "$LOCA/backend/" || exit 1
			gleam run -m backend_test --target erlang || {
				res_fail "\t--> Backend tests ran into an error."
				TESTS_SUCCEEDED=false
			}
			res_succ "\t-> Success: Lumina server"

			# # These tests are not needed, the shared libary can be tested within the gleam frontend and backend tests.
			# res_noti 1 "Running library tests"
			# cd "$LOCA/shared/" || exit 1
			# gleam test --target erlang || {
			# 	res_fail "\t--> Library tests ran into an error."
			# 	exit 1
			# }
			# res_succ "\t-> Success"
			res_noti 1 "Running frontend tests"
			if [ "$TEST_FE_TS" = true ]; then
				cd "$LOCA/frontend-ts/" || exit 1
				bun test || {
					res_fail "\t--> TypeScript frontend tests failed"
					TESTS_SUCCEEDED=false
				}
				res_succ "\t-> Success: Frontend (TypeScript)"
			fi
			if [ "$TEST_FE_GLEAM" = true ]; then
				cd "$LOCA/frontend/" || exit 1
				gleam test --target javascript || {
					res_fail "\t--> Gleam frontend tests failed."
					TESTS_SUCCEEDED=false
				}
				res_succ "\t-> Success: Frontend (Gleam)"
			fi
			if [ "$TESTS_SUCCEEDED" = false ]; then
				res_fail "\n\nOne or more tests failed."
				exit 1
			else
				res_succ "\n\nAll tests passed successfully."
				test_duration=$SECONDS
				printf "\nTime taken for tests: %d minutes and %d seconds\n" $((test_duration / 60)) $((test_duration % 60))
				total_duration=$((build_duration + test_duration))
				printf "\nTime taken for tests and building: %d minutes and %d seconds\n" $((total_duration / 60)) $((total_duration % 60))
			fi
		fi
	fi
fi
