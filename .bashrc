# Resources
# - How to add git info to prompt: https://stackoverflow.com/questions/15883416 adding-git-branch-on-the-bash-command-prompt

blue='34m'
green='32m'
orange='33m'
white='00m'
export PS1='\[\033[01;$green\]\u@\h: \[\033[01;$blue\]\w  \[\033[01;$orange\]$(__git_ps1 "git:(%s)") \[\033[01;$white\]\$ '

# Homebrew shellenv is handled per-OS via ~/.profile -> ~/.config/shell/os/$OS/.
source "$HOME/.profile"
