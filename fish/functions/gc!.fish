function gc! --wraps='git commit -v --amend' --description 'alias gc!=git commit -v --amend'
  git commit -v --amend $argv; 
end
