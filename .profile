#!/usr/bin/env bash

# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

SHELL_CONFIG=".config/shell"

source "$SHELL_CONFIG/path"
source "$SHELL_CONFIG/env_variables"
source "$SHELL_CONFIG/aliases"
source "$SHELL_CONFIG/nvm"
source "$SHELL_CONFIG/nnn"
source "$SHELL_CONFIG/functions"
source "$SHELL_CONFIG/history"
source "$SHELL_CONFIG/less"
source "$SHELL_CONFIG/prompt"
source "$SHELL_CONFIG/color"
source "$SHELL_CONFIG/completions"
source "$SHELL_CONFIG/shell_behavior"