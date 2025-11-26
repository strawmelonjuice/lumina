#!/usr/bin/env bash
set -euo pipefail

echo "Running devcontainer post-attach script"

if command -v mise >/dev/null 2>&1; then
  echo "Found mise — running local-devel-prep"
  mise run local-devel-prep || true
else
  echo "mise not found; skipping local-devel-prep"
fi
