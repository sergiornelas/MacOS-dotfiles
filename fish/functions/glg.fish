function glg --wraps='git log --stat --max-count=10' --description 'alias glg=git log --stat --max-count=10'
  git log --stat --max-count=10 $argv; 
end
