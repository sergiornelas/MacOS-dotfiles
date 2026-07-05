function cf --wraps='nvim' --description 'alias cf=config'
  cd ~/.config/ && kitty @set-tab-title .config && nvim
end
