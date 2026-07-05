function nt --wraps='nvim' --description 'alias nt=notes'
  cd ~/notes/ && kitty @set-tab-title notes && nvim
end
