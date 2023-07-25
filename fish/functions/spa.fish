function spa --wraps='nvim' --description 'alias spa=spa'
  cd ~/nextiva/nextiva-connect-spa/ && kitty @set-tab-title nextiva-connect-spa && nvim && kitty @set-tab-title
end
