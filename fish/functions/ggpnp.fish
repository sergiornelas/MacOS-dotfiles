function ggpnp --wraps='git pull origin (current_branch); and git push origin (current_branch)' --description 'alias ggpnp=git pull origin (current_branch); and git push origin (current_branch)'
  git pull origin (current_branch); and git push origin (current_branch) $argv; 
end
