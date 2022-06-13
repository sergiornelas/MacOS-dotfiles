function glo --wraps='git log --oneline' --description 'alias glo=git log --oneline'
  git log --oneline $argv; 
end
