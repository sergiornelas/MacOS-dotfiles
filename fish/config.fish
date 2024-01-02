# FZF
export FZF_DEFAULT_OPTS='--bind ctrl-o:up,ctrl-i:down,ctrl-j:accept,ctrl-n:toggle+down,ctrl-p:toggle+up,ctrl-m:preview-down,ctrl-k:preview-up,ctrl-g:toggle-all,ctrl-z:next-history,ctrl-x:prev-history --layout=reverse'

# Default editor
set -gx EDITOR nvim

# Map ctrl-o for up search
bind \co 'up-or-search'

# Node default version (you have to open terminal twice to apply)
set --universal nvm_default_version 18.16.0

# Fish_prompt:
set -U fish_greeting ""

# Rust
set -U fish_user_paths $HOME/.cargo/bin $fish_user_paths

# Default browser
# set -gx BROWSER brave

# Alias is just using eval to make a function anyway. It also
# seems to call out to sed, so that might be why it's slow.
# I tend to think alias should be removed from fish anyway.
# For optimal startup time you should use functions and make them lazy-loaded
# which you can do interactively with funced and funcsave,
# or manually by saving each function in its own file
# ~/.config/fish/functions/name-of-function.fish
