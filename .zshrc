# Import shell agnostic env vars, aliases, etc.
source "$HOME/.profile"

# Source zsh specific configurations
for file in "$XDG_CONFIG_HOME"/zsh/*(N); do
    source "$file";
done

PROMPT="$ "

# Task Master aliases added on 6/29/2026
alias tm='task-master'
alias taskmaster='task-master'
