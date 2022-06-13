function git-svn-dcommit-push --wraps='git svn dcommit; and git push github master:svntrunk' --description 'alias git-svn-dcommit-push=git svn dcommit; and git push github master:svntrunk'
  git svn dcommit; and git push github master:svntrunk $argv; 
end
