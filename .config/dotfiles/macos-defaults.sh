#!/usr/bin/env bash
# macOS one-time provisioning: default-app associations and other `defaults`
# tweaks. Idempotent and re-runnable. Invoked by bootstrap.sh AFTER Homebrew and
# `brew bundle` have populated the machine, but also safe to run standalone:
#   ~/.config/dotfiles/macos-defaults.sh
#
# Default-app associations live in ~/.config/dotfiles/duti-settings — a native
# duti settings file ('<bundle-id>  <extension-or-UTI>  <role>' per line). Edit
# THAT file to change associations; this script just preflights and applies it.
# It installs nothing — a missing tool or target app produces an actionable error.
set -euo pipefail

[ "$(uname)" = "Darwin" ] || { echo "macos-defaults: not macOS, skipping."; exit 0; }

SETTINGS="$HOME/.config/dotfiles/duti-settings"

# --- Preflight ---------------------------------------------------------------
if ! command -v duti >/dev/null 2>&1; then
  {
    echo "macos-defaults: 'duti' not found — install with 'brew install duti' (it's in the Brewfile)."
    echo "Skipping default-app associations. Re-run: ~/.config/dotfiles/macos-defaults.sh"
  } >&2
  exit 1
fi
if [ ! -f "$SETTINGS" ]; then
  echo "macos-defaults: settings file not found at $SETTINGS; nothing to apply." >&2
  exit 1
fi

# --- Apply default-app associations ------------------------------------------
# duti applies the good lines and exits 0 even when some fail, printing failures
# to stderr. So we capture stderr and treat any output as a real error — the
# usual cause is a target app in the settings file that isn't installed.
n=$(grep -cvE '^[[:space:]]*(#|$)' "$SETTINGS")
echo "Applying $n default-app associations from ~/.config/dotfiles/duti-settings..."
err="$(mktemp)"
trap 'rm -f "$err"' EXIT
duti "$SETTINGS" 2>"$err" || true
if [ -s "$err" ]; then
  {
    echo "macos-defaults: duti could not set some associations (is the target app installed?):"
    sed 's/^/  /' "$err"
    echo "Resolve the above, then re-run: ~/.config/dotfiles/macos-defaults.sh"
  } >&2
  exit 1
fi
echo "Done."

# --- Future macOS `defaults write ...` tweaks go below -----------------------
