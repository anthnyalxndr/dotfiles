#!/usr/bin/env sh
# ENV VARIABLES
export TEMPLATES="$HOME/templates"
export XDG_CONFIG_HOME="$HOME/.config"
export BASHRC="$HOME/.bashrc"
export EDITOR="$HOME/scripts/vscode_edit_in_place.sh"
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"
export PATH="/Library/PostgreSQL/16/bin:$PATH:$HOME/bin"
export PROJECTS="$HOME/Projects"
export ROOT_VSCODE_DIR="$HOME/.vscode-root"
export SSH="$HOME/.ssh"
export ZSHRC="$HOME/.zshrc"

# LLVM configuration (commented out, can be uncommented if needed)
# If you need to have llvm first in your PATH, run:
# echo 'export PATH="/opt/homebrew/opt/llvm/bin:$PATH"' >> ~/.zshrc

# For compilers to find llvm you may need to set:
# export LDFLAGS="-L/opt/homebrew/opt/llvm/lib"
# export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"