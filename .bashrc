#!/bin/bash
# shellcheck source=$HOME/.bash_profile
[ -n "$PS1" ] && source "$HOME/.bash_profile";

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

#THIS MUST BE AT THE END OF THE FILE FOR JENV TO WORK!!!
[[ -s "/Users/ssbarnea/.jenv/bin/jenv-init.sh" ]] && source "/Users/ssbarnea/.jenv/bin/jenv-init.sh" && source "/Users/ssbarnea/.jenv/commands/completion.sh"
