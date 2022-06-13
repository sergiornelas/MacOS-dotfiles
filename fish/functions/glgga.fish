function glgga --wraps='git log --graph --decorate --all' --description 'alias glgga=git log --graph --decorate --all'
  git log --graph --decorate --all $argv; 
end
