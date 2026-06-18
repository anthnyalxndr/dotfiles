#!/usr/bin/env bash
set -euo pipefail
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-$HOME}"
case "$(uname)" in
  Darwin) OS_PKG="os-darwin" ;;
  Linux)  OS_PKG="os-linux" ;;
  *) echo "Unsupported OS: $(uname)" >&2; exit 1 ;;
esac
cd "$DOTFILES_DIR"
stow -D --no-folding --target="$TARGET" base "$OS_PKG"
echo "Removed symlinks for base + $OS_PKG from $TARGET"
