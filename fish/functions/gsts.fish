function gsts --wraps='git stash show --text' --description 'alias gsts=git stash show --text'
  git stash show --text $argv; 
end
