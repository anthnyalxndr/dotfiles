#!/usr/bin/env bash

# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

SHELL_CONFIG="$HOME/.config/shell"

source "$HOME/.profile"
source "$SHELL_CONFIG/bash/color"
source "$SHELL_CONFIG/bash/completions"
source "$SHELL_CONFIG/bash/functions"
source "$SHELL_CONFIG/bash/functions"
source "$SHELL_CONFIG/bash/history"
source "$SHELL_CONFIG/bash/less"
source "$SHELL_CONFIG/bash/prompt"

# Source completions if they exist
[ -f /usr/local/etc/bash_completion ] && ./usr/local/etc/bash_completion
