function gup --wraps='git pull --rebase' --description 'alias gup=git pull --rebase'
  git pull --rebase $argv; 
end
