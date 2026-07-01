#!/usr/bin/env bash
set -euo pipefail
REPO="${1:-https://github.com/anthnyalxndr/dotfiles.git}"
GIT_DIR="$HOME/.dotfiles"
dotfiles() { git --git-dir="$GIT_DIR" --work-tree="$HOME" "$@"; }

# Abort on an existing dir OR a (possibly dangling) symlink at the git-dir path.
if [ -e "$GIT_DIR" ] || [ -L "$GIT_DIR" ]; then
  echo "$GIT_DIR already exists; remove it to re-bootstrap. Aborting." >&2
  exit 1
fi

git clone --bare "$REPO" "$GIT_DIR"
dotfiles config --local status.showUntrackedFiles no
# Route this repo's hooks to a tracked, version-controlled dir so the secret-scan
# pre-commit hook is present on every machine. Absolute path (per-machine $HOME);
# the hook script itself is checked out below.
dotfiles config --local core.hooksPath "$HOME/.config/dotfiles/git-hooks"

ERR="$(mktemp)"
trap 'rm -f "$ERR"' EXIT
BACKUP="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

# Check out into $HOME. If pre-existing files would be overwritten, git lists them
# tab-indented; back those up and retry. Loop so a backup pass that uncovers more
# conflicts still converges.
checked_out=0
for _ in 1 2 3 4 5; do
  if dotfiles checkout 2>"$ERR"; then
    checked_out=1
    break
  fi
  moved=0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    if [ -e "$HOME/$f" ]; then
      mkdir -p "$BACKUP/$(dirname "$f")"
      mv "$HOME/$f" "$BACKUP/$f"
      moved=1
    fi
  done < <(awk -F'\t' '/^\t/{print $2}' "$ERR")
  if [ "$moved" -eq 1 ]; then
    echo "Backed up pre-existing files to $BACKUP"
  else
    echo "Checkout still failing and nothing left to back up:" >&2
    cat "$ERR" >&2
    exit 1
  fi
done

if [ "$checked_out" -ne 1 ]; then
  echo "Checkout did not converge after backups:" >&2
  cat "$ERR" >&2
  exit 1
fi
echo "Dotfiles checked out."

# --- Provision: Homebrew, packages, then macOS defaults ----------------------
# Order matters: install Homebrew, populate the machine from the Brewfile, and
# ONLY THEN apply macOS defaults — the default-app step needs duti (from the
# Brewfile) and the target apps present. Each step degrades to a warning so a
# fresh checkout is never left half-bootstrapped by one flaky package or a
# missing optional app.
BREWFILE="$HOME/.config/dotfiles/Brewfile"

if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew (may prompt for your sudo password once)..."
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
# Load brew into this shell: Apple Silicon, then Intel, then Linuxbrew.
for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  [ -x "$_brew" ] && eval "$("$_brew" shellenv)" && break
done

if command -v brew >/dev/null 2>&1 && [ -f "$BREWFILE" ]; then
  echo "Installing packages from Brewfile..."
  brew bundle --file="$BREWFILE" ||
    echo "warning: some Brewfile entries failed; re-run 'brew bundle --file=$BREWFILE'." >&2
else
  echo "warning: brew or Brewfile unavailable; skipping package install." >&2
fi

# macOS-only defaults (default-app associations, etc.). Runs after packages so
# duti exists; the script itself errors usefully if a target app is missing.
if [ "$(uname)" = "Darwin" ]; then
  echo "Applying macOS defaults..."
  bash "$HOME/.config/dotfiles/macos-defaults.sh" ||
    echo "warning: macos-defaults did not complete (see above)." >&2
fi

echo "Bootstrap complete. Open a new shell so the 'dotfiles' alias loads (via ~/.config/shell/dotfiles_alias)."
