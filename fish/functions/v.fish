function v --wraps=nvim --description 'alias v=nvim'
  cd ~/notes/data
  sc-im spreadsheet.sc
  kitty @ close-window
end
