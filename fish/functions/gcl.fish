function gcl --wraps='git config --list' --description 'alias gcl=git config --list'
  git config --list $argv; 
end
