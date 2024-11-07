#!/usr/bin/env bash

LOCA=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
SECONDS=0
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
rm -rf "$LOCA/backend/priv/generated/js"
mkdir "$LOCA/backend/priv/generated/js"

if [[ "$*" == *"--frontend-ts"* ]]; then
	echo "Building front-end (TS)..."
	cd "$LOCA/frontend-ts/"
	bun install
	bun build "$LOCA/frontend-ts/app.ts" --minify --target=browser --outdir "$LOCA/backend/priv/generated/js/" --sourcemap=linked --minify
	bun "$LOCA/tobundle.ts" -- js-1 "$LOCA/backend/priv/generated/js/app.js"
else
	if [[ "$*" == *"--frontend-gleam"* ]]; then
		echo "Building front-end (Gleam)..."

		cd "$LOCA/frontend/"
		if gleam build --target js --no-print-progress; then
			echo "Frontend build success."
		else
			echo "Frontend compilation ran into an error."
			exit 1
		fi
		echo "import { main } from \"./frontend.mjs\";main();" >"$LOCA/frontend/build/dev/javascript/frontend/app.js"
		bun build "$LOCA/frontend/build/dev/javascript/frontend/app.js" --minify --target=browser --outdir "$LOCA/backend/priv/generated/js/" --sourcemap=external --minify
		bun "$LOCA/tobundle.ts" -- js-1 "$LOCA/backend/priv/generated/js/app.js"
	else
		echo "Invalid or missing frontend option, expected either \"--frontend-ts\" or \"--frontend-gleam\"."
		exit 1
	fi
fi
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
echo "Front-end should be done. Continuing to generated assets."
cd "$LOCA/backend/"
bun install
rm -rf "$LOCA/backend/priv/generated/css/"
mkdir "$LOCA/backend/priv/generated/css/"
echo "Generating CSS... (TailwindCSS)"
bun x postcss -o "$LOCA/backend/priv/generated/css/main.css" "$LOCA/backend/assets/styles/main.pcss" -u autoprefixer -u tailwindcss
bun "$LOCA/tobundle.ts" -- css-1 "$LOCA/backend/priv/generated/css/main.css"
echo "Minifying CSS..."
bun x cleancss -O1 specialComments:all --inline none "$LOCA/backend/priv/generated/css/main.css" -o "$LOCA/backend/priv/generated/css/main.min.css"
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
echo "Starting on back-end compilation"
cd "$LOCA/backend/"
if gleam build --target erlang --no-print-progress; then
	echo "Success!"
else
	echo "Compilation ran into an error!"
	exit 1
fi
duration=$SECONDS
echo "Build completed, took $((duration / 60)) minutes and $((duration % 60)) seconds."
if [[ "$*" == *"--run"* ]]; then
	echo "'--run' detected. Running Lumina directly!"
	gleam run -- start
else
	if [[ "$*" == *"--pack"* ]]; then
		echo "'--pack' detected. Packaging for deployment."
	fi
fi
