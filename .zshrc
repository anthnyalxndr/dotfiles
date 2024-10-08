# Import shell agnostic env vars, aliases, etc.
source "$HOME/.profile"

# Allow extended RE patterns
set -o extendedglob

# Set the theme to load. See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Uncomment one of the following lines to change the auto-update behavior
zstyle ':omz:update' mode auto      # update automatically without asking

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.


# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(colored-man-pages pyenv zsh-autosuggestions zsh-syntax-highlighting poetry)

source ~/.oh-my-zsh/oh-my-zsh.sh

# Add custom functions to fpath
fpath=(                    
    ~/.zfunc
    ~/.zfunc/**/*~*/(CVS)#(/N)
    "${fpath[@]}"
)

# autoload all custom functions
for file in $HOME/.zfunc/*; do
    if [[ $file = $HOME/.zfunc/READ_ME.md ]]; then
        continue
    fi
    autoload -Uz $file
done

tmux new -A -t "$VSCODE_WORKSPACE"
