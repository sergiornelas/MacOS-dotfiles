function gsr --wraps='git svn rebase' --description 'alias gsr=git svn rebase'
  git svn rebase $argv; 
end
