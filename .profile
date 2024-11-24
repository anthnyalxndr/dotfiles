# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# ENV VARIABLES
export TEMPLATES="$HOME/templates"
export XDG_CONFIG_HOME="$HOME/.config"
export BASHRC="$HOME/.bashrc"
export EDITOR="$HOME/scripts/vscode_edit_in_place.sh"
export SSH=$HOME/.ssh

# ALIASES
# Run `alias` to see active aliases.
# Run whence $alias to see the command an alias aligns to.
alias lsd="ls -d */"
alias lc="wc -l"         # ws with the `l` flag returns a line count
alias line-count="wc -l" # ws with the `l` flag returns a line count
alias bashrc="code ~/.bashrc"
alias profile="code ~/.profile"
alias c="code"
alias e="echo"
alias fcmd="{compgen -c && alias | sed 's/\=.*//'} | fzf"
alias fman="fcmd | xargs man"
alias g="/usr/bin/git"
alias hfzf="history | cut -c 8- | fzf --tac"
alias less="less --IGNORE-CASE"
alias lower="tr \"[:upper:]\" \"[:lower:]\""
alias upper="tr \"[:lower:]\" \"[:upper:]\""
alias sudocode="code --user-data-dir=ROOT_VSCODE_DIR"
alias t="tmux"
alias tc="tmux command" # quick access to tmux command mode
alias tcm="tmux copy-mode"
alias tobin="bc --obase 2 --expression"
alias tohex="bc --obase 16 --expression"
alias tmux-conf='echo $XDG_CONFIG_HOME/tmux/tmux.conf'
alias trim="sed -E 's/^[[:space:]]+//' | sed -E 's/[[:space:]]+$//'"
alias ltrim="sed -E 's/^[[:space:]]+//'"
alias rtrim="sed -E 's/[[:space:]]+$//'"
alias update_dotfiles='$HOME/Projects/shell_scripts/update_dotfiles/update_dotfiles'
alias update-dotfiles=update_dotfiles
alias word-count=wc

# Configure nnn
export NNN_FIFO="/tmp/nnn.fifo"
export NNN_PLUG="p:preview-tui;f:fzcd;"
export NNN_TERMINAL="tmux"

# Configure cd on quit for nnn
n() {
  # Block nesting of nnn in subshells
  [ "${NNNLVL:-0}" -eq 0 ] || {
    echo "nnn is already running"
    return
  }

  # The behaviour is set to cd on quit (nnn checks if NNN_TMPFILE is set)
  # If NNN_TMPFILE is set to a custom path, it must be exported for nnn to
  # see. To cd on quit only on ^G, remove the "export" and make sure not to
  # use a custom path, i.e. set NNN_TMPFILE *exactly* as follows:
  NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
  # export NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"

  # Unmask ^Q (, ^V etc.) (if required, see `stty -a`) to Quit nnn
  # stty start undef
  # stty stop undef
  # stty lwrap undef
  # stty lnext undef

  # The command builtin allows one to alias nnn to n, if desired, without
  # making an infinitely recursive alias. -deH are flags that I like to always
  # be set.
  command nnn -deH "$@"

  [ ! -f "$NNN_TMPFILE" ] || {
    # shellcheck disable=SC1090
    . "$NNN_TMPFILE"
    rm -f -- "$NNN_TMPFILE" >/dev/null
  }
}

# Function Definitions

# ord returns the character code associated with a character.
# In the context of character encoding, "ordinal" refers to the position of a character within a specific ordered set of characters, such as ASCII or Unicode.  The ord() function essentially gives you the numerical position (or "ordinal number") of that character within the relevant character set.
ord() {
  # Note the single quote before $1 that causes $1 to evaluate to the ASCII / UTF8 form of itself (just like in C).
  LC_CTYPE=C printf '%d' "'$1"
}

# chr returns the character associated with a character code.
# A note on why octals are used here. Historically, octal representation was commonly used to represent character codes, especially in Unix-like systems.  This is because octal numbers neatly map to groups of 3 bits, which was convenient for working with early computer systems.
chr() {
  [ "$1" -lt 256 ] || return 1
  octal=$(printf '%o' "$1")
  # takes the octal output and embeds it into an escape sequence. A \ starts the escape sequence and then we must escape that backslash so that it's interpreted literally.
  escaped_octal=\\$octal
  printf "$escaped_octal"
}

update_vscode_server_socket() {
  export VSCODE_IPC_HOOK_CLI=$(lsof | grep $UID/vscode-ipc | awk '{print $(NF-2)}' | head -n 1)
}

# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi