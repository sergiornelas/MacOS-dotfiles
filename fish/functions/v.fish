function v --wraps=nvim --description 'alias v=nvim'
  cd ~/notes/
  kitty @ set-tab-title "spreadsheet  "
  sc-im ~/notes/data/spreadsheet.sc
  kitty @ close-window
end
