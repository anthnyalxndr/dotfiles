#!/usr/bin/env bash
SHELL_CONFIG="$HOME/.config/shell"
source "$SHELL_CONFIG/env_variables"
source "$SHELL_CONFIG/aliases"
source "$SHELL_CONFIG/nvm"
source "$SHELL_CONFIG/nnn"
source "$SHELL_CONFIG/functions"
source "$SHELL_CONFIG/shell_behavior"
# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/ata/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/ata/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/ata/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/ata/google-cloud-sdk/completion.zsh.inc'; fi

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
