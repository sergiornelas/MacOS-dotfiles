function gclean --wraps='git reset --hard; and git clean -dfx' --description 'alias gclean=git reset --hard; and git clean -dfx'
  git reset --hard; and git clean -dfx $argv; 
end
