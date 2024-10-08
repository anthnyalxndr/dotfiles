# Resources
# - How to add git info to prompt: https://stackoverflow.com/questions/15883416 adding-git-branch-on-the-bash-command-prompt

# Allows PS1 to interpolate __git_ps1 function to add git info to prompt
source $HOME/.dotfiles/git-prompt.sh

blue='34m'
green='32m'
orange='33m'
white='00m'
export PS1='\[\033[01;$green\]\u@\h: \[\033[01;$blue\]\w  \[\033[01;$orange\]$(__git_ps1 "git:(%s)") \[\033[01;$white\]\$ '

# Set PATH, MANPATH, etc., for Homebrew.
eval "$(/opt/homebrew/bin/brew shellenv)"


source "$HOME/.profile"
