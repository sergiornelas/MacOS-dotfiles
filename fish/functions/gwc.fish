function gwc --wraps='git whatchanged -p --abbrev-commit --pretty=medium' --description 'alias gwc=git whatchanged -p --abbrev-commit --pretty=medium'
  git whatchanged -p --abbrev-commit --pretty=medium $argv; 
end
