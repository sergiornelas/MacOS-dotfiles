function conf --wraps='nvim' --description 'alias conf=config'
  cd ~/.config/ && kitty @set-tab-title .config && nvim && kitty @set-tab-title
end
