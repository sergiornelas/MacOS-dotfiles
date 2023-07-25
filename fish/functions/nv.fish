function nv --wraps='nvim' --description 'alias nv=nvim'
  cd ~/.config/nvim/ && kitty @set-tab-title nvim && nvim && kitty @set-tab-title
end
