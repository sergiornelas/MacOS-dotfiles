#!/bin/sh
export ZDOTDIR=$HOME/.config/zsh

# Useful Functions
source "$ZDOTDIR/zsh-functions"

# Normal files to source
zsh_add_file "zsh-exports"
zsh_add_file "zsh-vim-mode"
zsh_add_file "zsh-aliases"
zsh_add_file "zsh-git-aliases"

# Plugins
# zsh_add_plugin "zsh-users/zsh-autosuggestions"
# zsh_add_plugin "zsh-users/zsh-syntax-highlighting"
# zsh_add_plugin "hlissner/zsh-autopair"
# zsh_add_plugin "so-fancy/diff-so-fancy"
# gitstatus prompt is added in root:
source ~/gitstatus/gitstatus.prompt.zsh
zsh_add_file "zsh-prompt"
PROMPT+=' $GITSTATUS_PROMPT '
# For more plugins: https://github.com/unixorn/awesome-zsh-plugins

# Completion
# zsh_add_completion "esc/conda-zsh-completion" false
# More completions https://github.com/zsh-users/zsh-completions

# Key-bindings
# bindkey -s '^f' 'zi^M'
# bindkey -s '^s' 'ncdu^M'
# bindkey -s '^n' 'nvim $(fzf)^M'
# bindkey -s '^v' 'nvim\n'
# bindkey -s '^z' 'zi^M'
# bindkey '^[[P' delete-char
# bindkey "^p" up-line-or-beginning-search # Up
# bindkey "^n" down-line-or-beginning-search # Down
# bindkey "^k" up-line-or-beginning-search # Up
# bindkey "^j" down-line-or-beginning-search # Down

export PATH="$HOME/.cargo/bin:$PATH"
# exec vim
# bash -c 'nvim'

# ===============================
# How to load .zshrc inside ~/.config?
# In ~/.zprofile:
#   export ZDOTDIR=$HOME/.config/zsh

