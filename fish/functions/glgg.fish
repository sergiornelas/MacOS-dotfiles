function glgg --wraps='git log --graph --max-count=10' --description 'alias glgg=git log --graph --max-count=10'
  git log --graph --max-count=10 $argv; 
end
