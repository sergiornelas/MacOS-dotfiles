function cale --wraps='nvim' --description 'alias cale=calendar-ui'
  cd ~/nextiva/connect-calendar-ui/ && kitty @set-tab-title connect-calendar-ui && nvim && kitty @set-tab-title
end
