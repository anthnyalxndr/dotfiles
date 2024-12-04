# shellcheck disable=SC2148
# Set PATH, MANPATH, etc., for Homebrew.
eval "$(/opt/homebrew/bin/brew shellenv)"

# ENV VARIABLES

## LLVM (See `brew info llvm`)
# If you need to have llvm first in your PATH, run:
# echo 'export PATH="/opt/homebrew/opt/llvm/bin:$PATH"' >> ~/.zshrc

# For compilers to find llvm you may need to set:
# export LDFLAGS="-L/opt/homebrew/opt/llvm/lib"
# export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"

export TEMPLATES="$HOME/templates"
export XDG_CONFIG_HOME="$HOME/.config"
export BASHRC="$HOME/.bashrc"
export EDITOR="$HOME/scripts/vscode_edit_in_place.sh"
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"
export PATH=/Library/PostgreSQL/16/bin:$PATH:$HOME/bin
export PROJECTS=$HOME/Projects
export ROOT_VSCODE_DIR=$HOME/.vscode-root
export SSH=$HOME/.ssh
export ZSHRC=$HOME/.zshrc

# ALIASES
# Run `alias` to see active aliases.
# Run whence $alias to see the command an alias aligns to.
alias lsd="ls -d */"
alias lc="wc -l"         # ws with the `l` flag returns a line count
alias line-count="wc -l" # ws with the `l` flag returns a line count
alias bashrc="code ~/.bashrc"
alias profile="code ~/.profile"
alias c="code"
alias chrome_debug='/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222 --user-data-dir=$HOME/chrome_debug_user_data_dir&'
alias chrome-debug=chrome_debug
alias e="echo"
alias fcmd="{compgen -c && alias | sed 's/\=.*//'} | fzf"
alias fman="fcmd | xargs man"
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
alias wake_thinkpad='wakeonlan 54:e1:ad:bb:48:53'
alias word-count=wc
alias zshrc="code ~/.zshrc"

# Configure nvm
export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
# shellcheck disable=SC1091
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR"/bash_completion # This loads nvm bash_completion

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
  printf "%s" "$escaped_octal"
}
