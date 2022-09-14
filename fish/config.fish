# FZF
export FZF_DEFAULT_OPTS='--bind ctrl-o:up,ctrl-i:down,ctrl-j:accept,ctrl-d:half-page-down,ctrl-u:half-page-up --layout=reverse'

# Default editor
set -gx EDITOR nvim

# Node default version (you have to open terminal twice to apply)
set --universal nvm_default_version 14

# Fish_prompt:
set -U fish_greeting ""

# Default browser
# set -gx BROWSER brave

# Default shell in macOS:
# Terminal/Preferences/General/Shells open with: Command (complete path):
# /usr/local/bin/fish

# Alias is just using eval to make a function anyway. It also
# seems to call out to sed, so that might be why it's slow.
# I tend to think alias should be removed from fish anyway.
# For optimal startup time you should use functions and make them lazy-loaded
# which you can do interactively with funced and funcsave,
# or manually by saving each function in its own file
# ~/.config/fish/functions/name-of-function.fish
