# Info

## Don't load plugins in VSCode example

  cond = not vim.g.vscode,

```lua
return {
 {
  "sergiornelas/zippy.nvim",
  cond = not vim.g.vscode, // HERE
  lazy = false,
  keys = {
   {
    "<leader>z",
    "<cmd>lua require('zippy').insert_print()<cr>",
   },
  },
 },
}
```

## Create maps only available in VSCode

```lua
if vim.g.vscode then
 -- Normal mode mapping for saving with 'jk'
 -- map(
 --  "n",
 --  "jk",
 --  ":call VSCodeNotify('workbench.action.files.save')<CR>",
 --  { noremap = true, silent = true }
 -- )
 -- Normal mode mapping for saving with 'jw'
 -- map("n", "<space>w", ":call VSCodeNotify('workbench.action.files.save')<CR>")
 map("n", "<space>w", "<cmd>w<cr>")
end
```
