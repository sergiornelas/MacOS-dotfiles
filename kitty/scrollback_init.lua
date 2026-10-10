-- Minimal init for kitty's scrollback pager (kitty_mod+y), in place of the full
-- neovim config: starts in a fraction of the time and keeps plugins such as
-- claudecode.nvim or auto-session out of the pager. Add here what it needs.

vim.o.loadplugins = false
vim.g.mapleader = " "
vim.o.modeline = false

-- From nvim/lua/config/options.lua
local o = vim.opt
o.clipboard = "unnamedplus"
o.cursorline = true
o.guicursor:append("a:blinkwait700-blinkon500-blinkoff500")
o.ignorecase = true
o.showcmd = false
o.smartcase = true
o.swapfile = false
o.report = 100000

-- No colorscheme: the text keeps the colors of the pane it was copied from. These
-- are the overrides from nvim/lua/config/autocommands.lua for what the pager draws
-- itself. Changing 'background' (nvim sets it once kitty reports its color) resets
-- the default highlights, so reapply them then too.
local function apply_highlights()
	vim.api.nvim_set_hl(0, "CursorLine", { bg = "#25424D" })
	vim.api.nvim_set_hl(0, "MsgArea", { fg = "#DACBA5" })
	vim.api.nvim_set_hl(0, "Visual", { bg = "#52524e" })
	vim.api.nvim_set_hl(0, "YankHighlight", { bg = "#7c6f64" })
end
apply_highlights()
vim.api.nvim_create_autocmd("OptionSet", { pattern = "background", callback = apply_highlights })

-- Flash what was yanked (the full config does it with tiny-glimmer), then close the
-- pager like kitty_grab did. Waiting for the flash also gives pbcopy, which runs
-- apart from nvim, time to take the text.
local yank_flash_ms = 150
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.hl.on_yank({ higroup = "YankHighlight", timeout = yank_flash_ms })
		if vim.v.event.operator == "y" then
			vim.defer_fn(function()
				vim.cmd("qa!")
			end, yank_flash_ms)
		end
	end,
})

-- From nvim/lua/config/keymaps.lua, plus q to leave
local function map(mode, lhs, rhs)
	vim.keymap.set(mode, lhs, rhs, { silent = true })
end
map("n", "q", "ZQ")
map("n", "gG", "<cmd>%y<cr>")
