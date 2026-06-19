#!/usr/bin/env bash
set -euo pipefail
REPO="${1:-https://github.com/anthnyalxndr/dotfiles.git}"
GIT_DIR="$HOME/.dotfiles"
dotfiles() { git --git-dir="$GIT_DIR" --work-tree="$HOME" "$@"; }

[ -e "$GIT_DIR" ] && { echo "$GIT_DIR already exists; aborting." >&2; exit 1; }
git clone --bare "$REPO" "$GIT_DIR"
dotfiles config --local status.showUntrackedFiles no

if ! dotfiles checkout 2>/tmp/dotfiles-co.err; then
  BACKUP="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"; mkdir -p "$BACKUP"
  echo "Backing up pre-existing files to $BACKUP"
  awk '/^[[:space:]]+\./{print $1}' /tmp/dotfiles-co.err | while read -r f; do
    mkdir -p "$BACKUP/$(dirname "$f")"; mv "$HOME/$f" "$BACKUP/$f"
  done
  dotfiles checkout
fi
echo "Dotfiles checked out. Open a new shell (the 'dotfiles' alias loads via ~/.config/shell/dotfiles_alias)."
