-- Called from kitty's scrollback_pager (kitty_mod+y) with what depends on kitty's
-- arguments and the text it pipes in. Settings, colors and keymaps are in
-- scrollback_init.lua.

local tab_title = "Copy 󰆏"
-- Backgrounds in nvim/lua/config/autocommands.lua cleared from a copy of nvim
local nvim_cleared_bgs = {
	"#25424D", -- CursorLine
	"#0f0e0e", -- CursorLineNr
	"#403e3e", -- LspReference* (snacks.words); GitSignsCurrentLineBlame uses it too
}

-- How kitty writes a background color in the ANSI text it pipes in
local function bg_sgr(hex)
	local r, g, b = hex:match("#(%x%x)(%x%x)(%x%x)")
	return string.format("48:2:%d:%d:%d", tonumber(r, 16), tonumber(g, 16), tonumber(b, 16))
end

-- Apps that hide the terminal cursor (so kitty's CURSOR_LINE/COLUMN point wherever
-- they last drew) and paint their own with a background. Keyed by that background
-- as kitty writes it, the value says which spot painted with it is the cursor:
-- "first" or "last" on screen (when the color also marks other spots before it).
local selections = {
	-- lazygit: selectedLineBgColor in lazygit/config.yml, only on the focused panel
	-- (unfocused ones use bold)
	[bg_sgr("#434c5e")] = "first",
	-- sc-im: CELL_SELECTION bg=YELLOW in sc-im/scimrc. It also marks the current
	-- column letter (above) and row number (left of the cell).
	-- If that bg changes, update the key with how kitty writes it, which depends on
	-- the kind of color:
	--   basic (BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE): 40 to 47, in that order
	--   one from DEFINE_COLOR "name" r g b: not its RGB. sc-im redefines a palette
	--   slot with it and uses the slot's number, e.g. 100 to 107 or 48:5:<n>
	--   ("comment", the first one in scimrc, shows as 90 in the foreground)
	-- To check it, open sc-im, grab its screen from another pane with
	--   kitty @ get-text --match id:<window> --ansi | grep -a -o $'\e\\[[0-9;:]*m' | sort | uniq -c
	-- and look for the code with the new color next to the cell.
	-- The new color must be used only by the selection (and its column/row headers),
	-- or another cell painted with it could be taken for the cursor.
	["43"] = "last",
}

-- A copy of an nvim pane carries its cursorline, which would show next to the
-- pager's own once the cursor moves, and the references snacks.words marks for the
-- word under its cursor. Swap those backgrounds for the default (49).
local function clear_backgrounds(lines, colors)
	for _, color in ipairs(colors) do
		local sgr = bg_sgr(color)
		for i, line in ipairs(lines) do
			if line:find(sgr, 1, true) then
				lines[i] = line:gsub(vim.pesc(sgr) .. "%f[^%d]", "49")
			end
		end
	end
end

-- Screen column where byte `start` of a row falls, ignoring escape sequences
local function column_at(screen_line, start)
	local before = screen_line
		:sub(1, start - 1)
		:gsub("\27%].-\7", "")
		:gsub("\27%].-\27\\", "")
		:gsub("\27%[[%d;:?<>=]*[%a@`~]", "")
		:gsub("\27[()]%w", "")
	return vim.fn.strdisplaywidth(before) + 1
end

-- The text in rows as kitty counts them for INPUT_LINE_NUMBER: \r marks where a
-- line wrapped
local function screen_rows(lines)
	local rows = {}
	for _, line in ipairs(lines) do
		vim.list_extend(rows, vim.split((line:gsub("\r$", "")), "\r", { plain = true }))
	end
	return rows
end

-- Finds the cursor of an app in `selections`
local function find_selection(lines)
	local last_row, last_column
	for row, screen_line in ipairs(screen_rows(lines)) do
		for start, params in screen_line:gmatch("()\27%[([%d;:]*)m") do
			-- Whole parameters only: "43" must not match inside "38:2:43:..."
			for param in params:gmatch("[^;]+") do
				if selections[param] == "first" then
					return row, column_at(screen_line, start)
				elseif selections[param] == "last" then
					last_row, last_column = row, column_at(screen_line, start)
				end
			end
		end
	end
	return last_row, last_column
end

-- Names the pager's tab and closes the pager when focus moves to another kitty
-- pane/tab, but not when switching to another app.
local function mark_pager()
	-- kitty opens the pager titled "History" and ignores the titles nvim sets, so
	-- rename the window through remote control instead
	if vim.env.KITTY_WINDOW_ID then
		vim.system({ "kitty", "@", "set-window-title", "--match", "id:" .. vim.env.KITTY_WINDOW_ID, tab_title })
	end

	vim.api.nvim_create_autocmd("FocusLost", {
		callback = function()
			-- A kitty OS window still focused means a pane/tab change, not an app switch
			vim.defer_fn(function()
				vim.system(
					{ "kitty", "@", "ls" },
					{ text = true },
					vim.schedule_wrap(function(result)
						local ok, os_windows = pcall(vim.json.decode, result.stdout or "")
						if not ok then
							return
						end
						for _, os_window in ipairs(os_windows) do
							if os_window.is_focused then
								vim.cmd("qa!")
								return
							end
						end
					end)
				)
			end, 50)
		end,
	})
end

-- Puts the cursor where it was in kitty. nvim_open_term fills the buffer
-- asynchronously (and starts with empty screen lines), so wait until the
-- terminal refreshes settle and the UI is attached.
local function restore_cursor(top, row, column)
	local timer = assert(vim.uv.new_timer())
	local done = false

	local function place_cursor()
		if done or #vim.api.nvim_list_uis() == 0 then
			return
		end
		done = true
		timer:close()
		vim.fn.cursor(top, 1)
		vim.cmd("normal! zt")
		vim.fn.cursor(row, 1)
		-- column is a screen column, `|` moves by screen column (multibyte safe)
		vim.cmd("normal! " .. column .. "|")
	end

	local function settle()
		if not done then
			timer:start(20, 0, vim.schedule_wrap(place_cursor))
		end
	end

	vim.api.nvim_buf_attach(0, false, {
		on_lines = function()
			if done then
				return true
			end
			settle()
		end,
	})
	vim.api.nvim_create_autocmd("UIEnter", { once = true, callback = settle })
end

-- Shows the text with its colors: nvim_open_term turns the buffer into a terminal
-- (no process behind it) that interprets the ANSI codes. The buffer is emptied and
-- the text sent without a newline after the last line, which would leave an empty
-- row at the bottom.
local function render_ansi(lines)
	vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
	vim.api.nvim_chan_send(vim.api.nvim_open_term(0, {}), table.concat(lines, "\r\n"))
end

return function(top, cursor_line, cursor_column)
	-- The raw text kitty piped in, read once before render_ansi replaces it
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local row, column
	-- lazygit, sc-im and nvim run in the alternate screen, which kitty pipes without
	-- history, so the screen starts at line 1. Any history (top > 1) rules them out.
	if top == 1 then
		row, column = find_selection(lines)
		clear_backgrounds(lines, nvim_cleared_bgs)
	end
	restore_cursor(top, row or top + cursor_line - 1, column or cursor_column)
	mark_pager()
	render_ansi(lines)
end
