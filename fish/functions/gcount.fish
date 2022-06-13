function gcount --wraps='git shortlog -sn' --description 'alias gcount=git shortlog -sn'
  git shortlog -sn $argv; 
end
