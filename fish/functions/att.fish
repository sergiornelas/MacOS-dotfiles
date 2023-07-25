function att --wraps='nvim' --description 'alias att=attachments'
  cd ~/nextiva/attachments-ui && kitty @set-tab-title attachments-ui && nvim && kitty @set-tab-title
end
