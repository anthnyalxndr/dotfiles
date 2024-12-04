#!/usr/bin/env sh
# ALIASES
alias lsd="ls -d */"
alias lc="wc -l"
alias line-count="wc -l"
alias bashrc="code ~/.bashrc"
alias profile="code ~/.profile"
alias c="code"
alias chrome_debug='/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222 --user-data-dir=$HOME/chrome_debug_user_data_dir&'
alias chrome-debug=chrome_debug
alias e="echo"
alias fcmd="{compgen -c && alias | sed 's/\=.*//'} | fzf"
alias fman="fcmd | xargs man"
alias g="/usr/bin/env git"
alias hfzf="history | cut -c 8- | fzf --tac"
alias less="less --IGNORE-CASE"
alias lower="tr \"[:upper:]\" \"[:lower:]\""
alias upper="tr \"[:lower:]\" \"[:upper:]\""
alias sudocode="code --user-data-dir=ROOT_VSCODE_DIR"
alias t="tmux"
alias tc="tmux command"
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