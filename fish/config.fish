if status is-interactive
and not set -q TMUX
  exec tmux
end

# Alias is just using eval to make a function anyway. It also
# seems to call out to sed, so that might be why it's slow.
# I tend to think alias should be removed from fish anyway.

# For optimal startup time you should use functions and make them lazy-loaded
# which you can do interactively with funced and funcsave,
# or manually by saving each function in its own file
# ~/.config/fish/functions/name-of-function.fish

## eliminate fish_prompt:
# set -U fish_greeting ""
# fish_prompt

# Default editor
set -gx EDITOR nvim

# you have to open terminal twice to apply
set --universal nvm_default_version 14
# set --universal nvm_default_version latest

function _peco_change_directory
  if [ (count $argv) ]
    peco --layout=top-down --query "$argv "|perl -pe 's/([ ()])/\\\\$1/g'|read foo
  else
    peco --layout=bottom-up |perl -pe 's/([ ()])/\\\\$1/g'|read foo
  end
  if [ $foo ]
    builtin cd $foo
    commandline -r ''
    commandline -f repaint
  else
    commandline ''
  end
end

function peco_change_directory
  begin
    echo $HOME/.config
    # ghq list -p
    ls -ad */|perl -pe "s#^#$PWD/#"|grep -v \.git
    # ls -ad $HOME/Developments/*/* |grep -v \.git
    ls -ad $HOME/* |grep -v \.git
  end | sed -e 's/\/$//' | awk '!a[$0]++' | _peco_change_directory $argv
end

function peco_select_history
  if test (count $argv) = 0
    set peco_flags --layout=bottom-up
  else
    set peco_flags --layout=top-down --query "$argv"
  end
  history|peco $peco_flags|read foo
  if [ $foo ]
    commandline $foo
  else
    commandline ''
  end
end

# brew install peco
function fish_user_key_bindings
    # bind \cr 'peco_select_history (commandline -b)'
    # bind \co 'peco_change_directory' # Bind for peco change directory to Ctrl+F
end

# brew install fzf (fuzzy finder)
# brew install fd (styled fd)
# brew install bat (smarter cat)
# fisher install PatrickF1/fzf.fish
