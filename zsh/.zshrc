#!/bin/sh
export ZDOTDIR=$HOME/.config/zsh

# nvm zsh lazyload
export NVM_LAZY_LOAD=true

# Case insensitive
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Avoid duplicate in history
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS

# Avoid using cd when changing directory
setopt autocd

# Useful Functions
source "$ZDOTDIR/zsh-functions"

# Files to source
zsh_add_file "zsh-exports"
zsh_add_file "zsh-vim-mode"
zsh_add_file "zsh-aliases"
zsh_add_file "zsh-git-aliases"

# Plugins
zsh_add_plugin "agkozak/zsh-z"
zsh_add_plugin "zsh-users/zsh-autosuggestions"
zsh_add_plugin "zsh-users/zsh-syntax-highlighting"
zsh_add_plugin "lukechilds/zsh-nvm"
zsh_add_plugin "zpm-zsh/pr-jobs"

# Prompt
source ~/gitstatus/gitstatus.prompt.zsh
zsh_add_file "zsh-prompt"
PROMPT+=' $GITSTATUS_PROMPT '
PROMPT+='%(1j.%j.)'
PROMPT+='$pr_jobs '
RPROMPT="%1(j.X.)"
# zsh-z
source ~/.config/zsh/plugins/zsh-z/zsh-z.plugin.zsh

# Tab completion
autoload -Uz compinit && compinit

# Autosuggest select
bindkey '^v' autosuggest-accept

export PATH="$HOME/.cargo/bin:$PATH"
