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
for _ in 1 2 3 4 5; do
  if dotfiles checkout 2>"$ERR"; then
    echo "Dotfiles checked out. Open a new shell (the 'dotfiles' alias loads via ~/.config/shell/dotfiles_alias)."
    exit 0
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

echo "Checkout did not converge after backups:" >&2
cat "$ERR" >&2
exit 1
