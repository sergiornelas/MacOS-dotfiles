function gsta --wraps='git stash' --description 'alias gsta=git stash'
  git stash $argv; 
end
