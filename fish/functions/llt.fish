function llt --wraps='ll --tree' --wraps='exa --long --header --git --tree' --description 'alias llt=exa --long --header --git --tree'
  exa --long --header --git --tree $argv; 
end
