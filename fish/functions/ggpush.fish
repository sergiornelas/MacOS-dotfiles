function ggpush --wraps='git push origin (current_branch)' --description 'alias ggpush=git push origin (current_branch)'
  git push origin (current_branch) $argv; 
end
