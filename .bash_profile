#!/usr/bin/env bash
# Login shells: load the interactive config (which sources ~/.profile).
[ -r "$HOME/.bashrc" ] && . "$HOME/.bashrc"

# Homebrew bash completion if present (Intel and Apple Silicon prefixes).
[ -r /usr/local/etc/bash_completion ]    && . /usr/local/etc/bash_completion
[ -r /opt/homebrew/etc/bash_completion ] && . /opt/homebrew/etc/bash_completion
