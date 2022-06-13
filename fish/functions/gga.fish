function gga --wraps='git gui citool --amend' --description 'alias gga=git gui citool --amend'
  git gui citool --amend $argv; 
end
