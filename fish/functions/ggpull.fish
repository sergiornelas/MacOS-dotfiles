function ggpull --wraps='git pull origin (current_branch)' --description 'alias ggpull=git pull origin (current_branch)'
  git pull origin (current_branch) $argv; 
end
