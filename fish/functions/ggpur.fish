function ggpur --wraps='git pull --rebase origin (current_branch)' --description 'alias ggpur=git pull --rebase origin (current_branch)'
  git pull --rebase origin (current_branch) $argv; 
end
