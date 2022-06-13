function grset --wraps='git remote set-url' --description 'alias grset=git remote set-url'
  git remote set-url $argv; 
end
