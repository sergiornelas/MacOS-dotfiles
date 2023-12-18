# FZF
export FZF_DEFAULT_OPTS='--bind ctrl-o:up,ctrl-i:down,ctrl-j:accept,ctrl-n:toggle+down,ctrl-p:toggle+up,ctrl-m:preview-down,ctrl-k:preview-up  --layout=reverse'

# FZF fish
fzf_configure_bindings --variables

# Default editor
set -gx EDITOR nvim

# Node default version (you have to open terminal twice to apply)
set --universal nvm_default_version 18.16.0

# Fish_prompt:
set -U fish_greeting ""

# Rust
set -U fish_user_paths $HOME/.cargo/bin $fish_user_paths

# FEATURE            |  MNEMONIC KEY SEQUENCE        |  CORRESPONDING OPTION
# Search directory   |  Ctrl+Alt+F (F for file)      |  --directory
# Search git log     |  Ctrl+Alt+L (L for log)       |  --git_log
# Search git status  |  Ctrl+Alt+S (S for status)    |  --git_status
# Search history     |  Ctrl+R     (R for reverse)   |  --history
# Search variables   |  Ctrl+V     (V for variable)  |  --variables
# Search processes   |  Ctrl+Alt+P (P for process)   |  --processes

# EXAMPLES
# Install the default mnemonic bindings
#   $ fzf_configure_bindings
# Install the default bindings but override git log's binding to Ctrl+G
#   $ fzf_configure_bindings --git_log=\cg
# Install the default bindings but leave search history unbound
#   $ fzf_configure_bindings --history
# Alternative style of disabling search history
#   $ fzf_configure_bindings --history=
# An agglomeration of all the options
#   $ fzf_configure_bindings --git_status=\cg --history=\ch --variables --directory --git_log

# Default browser
# set -gx BROWSER brave

# Alias is just using eval to make a function anyway. It also
# seems to call out to sed, so that might be why it's slow.
# I tend to think alias should be removed from fish anyway.
# For optimal startup time you should use functions and make them lazy-loaded
# which you can do interactively with funced and funcsave,
# or manually by saving each function in its own file
# ~/.config/fish/functions/name-of-function.fish
