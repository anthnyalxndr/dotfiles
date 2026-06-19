#!/usr/bin/env bash
SHELL_CONFIG="$HOME/.config/shell"
source "$SHELL_CONFIG/env_variables"
source "$SHELL_CONFIG/aliases"
source "$SHELL_CONFIG/dotfiles_alias"
source "$SHELL_CONFIG/nvm_config"
source "$SHELL_CONFIG/nnn_config"
source "$SHELL_CONFIG/functions"
source "$SHELL_CONFIG/shell_behavior"
source "$SHELL_CONFIG/go"

# OS-specific modules (darwin / linux).
OS="$(uname | tr '[:upper:]' '[:lower:]')"
if [ -d "$SHELL_CONFIG/os/$OS" ]; then
  for f in "$SHELL_CONFIG/os/$OS"/*; do
    [ -r "$f" ] && source "$f"
  done
fi

# Machine-local overrides (untracked): secrets, per-host tweaks, machine-specific aliases.
[ -r "$SHELL_CONFIG/local" ] && source "$SHELL_CONFIG/local"
