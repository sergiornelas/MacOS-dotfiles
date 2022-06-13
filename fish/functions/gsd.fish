function gsd --wraps='git svn dcommit' --description 'alias gsd=git svn dcommit'
  git svn dcommit $argv; 
end
