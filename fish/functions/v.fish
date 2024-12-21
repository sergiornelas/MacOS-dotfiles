function v --wraps=nvim --description 'alias v=nvim'
  cd ~/notes/data
  kitty @ set-tab-title "spreadsheet  "
  sc-im spreadsheet.sc
  kitty @ close-window
end
