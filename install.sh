#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${HOME}"
INSTALL_PACKAGES=0

usage() { echo "Usage: $0 [--packages] [--target DIR]"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --packages) INSTALL_PACKAGES=1 ;;
    --target) shift; TARGET="$1" ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

case "$(uname)" in
  Darwin) OS_PKG="os-darwin" ;;
  Linux)  OS_PKG="os-linux" ;;
  *) echo "Unsupported OS: $(uname)" >&2; exit 1 ;;
esac
echo "OS package: $OS_PKG"

if ! command -v stow >/dev/null 2>&1; then
  echo "GNU Stow not found (brew/apt/dnf install stow)." >&2; exit 1
fi

if [ "$INSTALL_PACKAGES" -eq 1 ]; then
  case "$(uname)" in
    Darwin) command -v brew >/dev/null 2>&1 && brew bundle --file="$DOTFILES_DIR/Brewfile" ;;
    Linux)
      if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update && xargs -a "$DOTFILES_DIR/packages/apt.txt" sudo apt-get install -y
      elif command -v dnf >/dev/null 2>&1; then
        xargs -a "$DOTFILES_DIR/packages/dnf.txt" sudo dnf install -y
      fi ;;
  esac
fi

cd "$DOTFILES_DIR"
stow --restow --no-folding --target="$TARGET" base "$OS_PKG"
echo "Symlinks created for base + $OS_PKG -> $TARGET"

[ -d "$HOME/.oh-my-zsh" ] || git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
[ -d "$HOME/.tmux/plugins/tpm" ] || git clone --depth=1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"

if [ "$TARGET" = "$HOME" ] && [ "$(basename "${SHELL:-}")" != "zsh" ] && command -v zsh >/dev/null 2>&1; then
  echo "Changing default shell to zsh..."
  chsh -s "$(command -v zsh)" || echo "chsh failed; change shell manually." >&2
fi

echo "Done."
