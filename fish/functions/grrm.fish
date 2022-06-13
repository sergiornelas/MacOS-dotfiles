function grrm --wraps='git remote remove' --description 'alias grrm=git remote remove'
  git remote remove $argv; 
end
