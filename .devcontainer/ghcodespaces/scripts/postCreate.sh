#!/usr/bin/env bash
set -euo pipefail

log() { printf '%s\n' "$1"; }

log "Running devcontainer post-create script"

# Set up Podman compatibility script
log "Setting up Podman compatibility script"
sudo cp .devcontainer/ghcodespaces/scripts/podman /usr/local/bin/podman
sudo chmod +x /usr/local/bin/podman


# Configure mise if available
if command -v mise >/dev/null 2>&1; then
  log "Configuring mise"
  mise trust || true
  mise use -g usage || true
  mise install || true
  mkdir -p ~/.local/share/bash-completion/completions
  mise completion bash --include-bash-completion-lib > ~/.local/share/bash-completion/completions/mise || true
  echo 'eval "$(mise activate bash)"' >> ~/.bashrc
fi

# Configure git remotes (best-effort, won't fail the script)
log "Configuring git remotes (best-effort)"
git remote set-url origin ssh://git@codeberg.org/strawmelonjuice/Lumina.git || true
git remote add github-remote ssh://git@github.com/strawmelonjuice/lumina.git || true
git remote add strawmeloncode ssh://git@git.strawmelonjuice.com/strawmelonjuice/Lumina.git || true

log "Post-create script finished"
