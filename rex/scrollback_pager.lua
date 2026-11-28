-- Called from rex/scrollback.lua (ctrl+shift+y) with the file holding the pane's
-- screen and scrollback as escape sequences and where its cursor was. Settings,
-- colors and keymaps are in kitty/scrollback_init.lua (shared with kitty's
-- pager); the apps in `selections` and the colors in `nvim_cleared_bgs` are
-- explained in kitty/scrollback_pager.lua.
--
-- Unlike kitty's pager, the text doesn't go through nvim_open_term: a terminal
-- buffer wraps at the window's width, and Rex's floating layer (title bar and
-- border) is a bit smaller than the pane, so every full-width row (an nvim
-- screen, for instance) wrapped. Instead the escape sequences become highlights
-- on a plain buffer with 'nowrap': one pane row is one line, whatever the width.

-- Backgrounds in nvim/lua/config/autocommands.lua cleared from a copy of nvim
-- (CursorLine, CursorLineNr, LspReference*/GitSignsCurrentLineBlame)
local nvim_cleared_bgs = { "#25424d", "#0f0e0e", "#403e3e" }

-- Apps that hide the terminal cursor and paint their own with a background,
-- keyed by that background: "#rrggbb" for an RGB color, "b<n>" for a basic one
-- (40-47 → b0-b7, 100-107 → b8-b15). The value says which spot painted with it
-- is the cursor: "first" or "last" on screen.
local selections = {
	["#434c5e"] = "first", -- lazygit: selectedLineBgColor in lazygit/config.yml
	["b3"] = "last", -- sc-im: CELL_SELECTION bg=YELLOW in sc-im/scimrc
}

local ns = vim.api.nvim_create_namespace("rex_scrollback")

-- The 256-color palette: Rex sends the pane's own with OSC 4 at the start of the
-- file; xterm's defaults fill in anything missing.
local palette = {}
do
	local base = {
		"#000000", "#cd0000", "#00cd00", "#cdcd00", "#0000ee", "#cd00cd", "#00cdcd", "#e5e5e5",
		"#7f7f7f", "#ff0000", "#00ff00", "#ffff00", "#5c5cff", "#ff00ff", "#00ffff", "#ffffff",
	}
	for i = 0, 15 do
		palette[i] = base[i + 1]
	end
	local steps = { 0, 95, 135, 175, 215, 255 }
	for i = 16, 231 do
		local n = i - 16
		palette[i] = string.format("#%02x%02x%02x", steps[math.floor(n / 36) + 1], steps[math.floor(n / 6) % 6 + 1], steps[n % 6 + 1])
	end
	for i = 232, 255 do
		local v = 8 + (i - 232) * 10
		palette[i] = string.format("#%02x%02x%02x", v, v, v)
	end
end

-- Highlight groups, one per distinct style, created as they show up. Kept so
-- they can be set again if 'background' changes (that resets highlights).
local groups = {}
local group_specs = {}

local function group_for(st)
	if not (st.fg or st.bg or st.sp or st.bold or st.italic or st.underline or st.reverse or st.strikethrough) then
		return nil
	end
	local key = table.concat({
		st.fg or "",
		st.bg or "",
		st.sp or "",
		st.bold and "b" or "",
		st.italic and "i" or "",
		st.underline or "",
		st.reverse and "r" or "",
		st.strikethrough and "s" or "",
	}, "|")
	local name = groups[key]
	if not name then
		name = "RexScrollback" .. (#group_specs + 1)
		groups[key] = name
		local spec = {
			fg = st.fg,
			bg = st.bg,
			sp = st.sp,
			bold = st.bold,
			italic = st.italic,
			reverse = st.reverse,
			strikethrough = st.strikethrough,
		}
		if st.underline then
			spec[st.underline] = true
		end
		group_specs[#group_specs + 1] = { name, spec }
		vim.api.nvim_set_hl(0, name, spec)
	end
	return name
end

-- An extended color after 38/48/58: 5;n (palette) or 2;r;g;b. Takes the
-- parameters from `params` starting at i; returns the color, its key and the
-- index of the last parameter used.
local function extended_color(params, i)
	if params[i + 1] == 5 and params[i + 2] then
		local n = params[i + 2]
		return palette[n], "i" .. n, i + 2
	elseif params[i + 1] == 2 and params[i + 4] then
		local hex = string.format("#%02x%02x%02x", params[i + 2], params[i + 3], params[i + 4])
		return hex, hex, i + 4
	end
	return nil, nil, i + 1
end

local function apply_sgr(st, raw, cleared)
	local params = {}
	-- ':' sub-parameters (38:2::r:g:b, 4:3) are read like ';' ones, except
	-- the empty color-space slot of 38:2::r:g:b
	raw = raw:gsub("([345]8):2::", "%1:2:")
	for p in ((raw == "" and "0" or raw) .. ";"):gmatch("([^;:]*)[;:]") do
		params[#params + 1] = tonumber(p) or 0
	end
	local undercurl = raw:find("4:3", 1, true) ~= nil
	local i = 1
	while i <= #params do
		local p = params[i]
		if p == 0 then
			for k in pairs(st) do
				st[k] = nil
			end
		elseif p == 1 then
			st.bold = true
		elseif p == 3 then
			st.italic = true
		elseif p == 4 then
			st.underline = undercurl and "undercurl" or "underline"
			if params[i + 1] and raw:find("4:", 1, true) then
				i = i + 1 -- the 4:n style
			end
		elseif p == 7 then
			st.reverse = true
		elseif p == 9 then
			st.strikethrough = true
		elseif p == 21 then
			st.underline = "underdouble"
		elseif p == 22 then
			st.bold = nil
		elseif p == 23 then
			st.italic = nil
		elseif p == 24 then
			st.underline = nil
		elseif p == 27 then
			st.reverse = nil
		elseif p == 29 then
			st.strikethrough = nil
		elseif p >= 30 and p <= 37 then
			st.fg = palette[p - 30]
		elseif p >= 90 and p <= 97 then
			st.fg = palette[p - 90 + 8]
		elseif p == 39 then
			st.fg = nil
		elseif p >= 40 and p <= 47 then
			st.bg, st.bg_key = palette[p - 40], "b" .. (p - 40)
		elseif p >= 100 and p <= 107 then
			st.bg, st.bg_key = palette[p - 100 + 8], "b" .. (p - 100 + 8)
		elseif p == 49 then
			st.bg, st.bg_key = nil, nil
		elseif p == 38 then
			st.fg, _, i = extended_color(params, i)
		elseif p == 48 then
			st.bg, st.bg_key, i = extended_color(params, i)
			if st.bg and cleared[st.bg] then
				st.bg, st.bg_key = nil, nil
			end
		elseif p == 58 then
			st.sp, _, i = extended_color(params, i)
		elseif p == 59 then
			st.sp = nil
		end
		i = i + 1
	end
end

-- Turns the file's lines into plain text plus highlight runs per line
-- ({start byte, end byte, group}, 0-based), and finds the cursor of an app in
-- `selections` (row, screen column) when `find` is set.
local function parse(raw_lines, cleared, find)
	local text, runs = {}, {}
	local st = {}
	local sel_row, sel_col
	for row, line in ipairs(raw_lines) do
		local parts, line_runs = {}, {}
		local len = 0
		local cur_group, cur_start, cur_bg = group_for(st), 0, st.bg ~= nil

		local function flush()
			if cur_group and len > cur_start then
				line_runs[#line_runs + 1] = { cur_start, len, cur_group, cur_bg }
			end
		end
		local function set_style(changed)
			if changed then
				flush()
				cur_group, cur_start, cur_bg = group_for(st), len, st.bg ~= nil
			end
		end
		local function add(s)
			parts[#parts + 1] = s
			len = len + #s
		end

		local pos = 1
		while pos <= #line do
			local esc = line:find("\27", pos, true)
			if not esc then
				add(line:sub(pos))
				break
			end
			if esc > pos then
				add(line:sub(pos, esc - 1))
			end
			local kind = line:sub(esc + 1, esc + 1)
			if kind == "[" then
				local params, final, stop = line:match("^([%d;:?<>=]*)([%a@`~])()", esc + 2)
				if not stop then
					pos = esc + 2
				else
					if final == "m" and not params:find("[?<>=]") then
						local before_bg = st.bg_key
						apply_sgr(st, params, cleared)
						set_style(true)
						if find and st.bg_key and st.bg_key ~= before_bg and selections[st.bg_key] then
							local mode = selections[st.bg_key]
							if mode == "last" or not sel_row then
								sel_row = row
								sel_col = vim.fn.strdisplaywidth(table.concat(parts)) + 1
							end
							if mode == "first" then
								find = false
							end
						end
					elseif final == "C" then
						-- Rex writes runs of blank cells as cursor-forward
						local n = tonumber(params) or 1
						local saved = cur_group
						set_style(cur_group ~= nil)
						cur_group = nil
						add(string.rep(" ", n))
						cur_group, cur_start = saved, len
					end
					pos = stop
				end
			elseif kind == "]" then
				local stop = line:find("\7", esc, true)
				local st_stop = line:find("\27\\", esc + 1, true)
				local body_end, next_pos
				if st_stop and (not stop or st_stop < stop) then
					body_end, next_pos = st_stop - 1, st_stop + 2
				elseif stop then
					body_end, next_pos = stop - 1, stop + 1
				else
					body_end, next_pos = #line, #line + 1
				end
				local n, r, g, b = line:sub(esc + 2, body_end):match("^4;(%d+);rgb:(%x%x)%x*/(%x%x)%x*/(%x%x)")
				if n then
					palette[tonumber(n)] = "#" .. r .. g .. b
				end
				pos = next_pos
			elseif kind == "(" or kind == ")" then
				pos = esc + 3
			else
				pos = esc + 2
			end
		end
		flush()

		-- Drop trailing blanks (they'd end up in a yank), but keep the ones
		-- painted with a background, like a statusline's
		local s = table.concat(parts)
		local keep = #(s:gsub("%s+$", ""))
		for _, r in ipairs(line_runs) do
			if r[4] and r[2] > keep then
				keep = r[2]
			end
		end
		text[row] = s:sub(1, keep)
		local kept_runs = {}
		for _, r in ipairs(line_runs) do
			if r[1] < keep then
				kept_runs[#kept_runs + 1] = { r[1], math.min(r[2], keep), r[3] }
			end
		end
		runs[row] = kept_runs
	end
	return text, runs, sel_row, sel_col
end

-- Closes the pager when focus moves to another Rex pane or tab, but not when
-- switching to another app (the pager's block stays the focused one then).
local function close_on_pane_change(session_id)
	local block = vim.env.REX_BLOCK
	if not block or not session_id or session_id == "" then
		return
	end
	vim.api.nvim_create_autocmd("FocusLost", {
		callback = function()
			vim.defer_fn(function()
				vim.system(
					{ "rex", "api", "call", "session.view", vim.json.encode({ session_id = session_id }) },
					{ text = true },
					vim.schedule_wrap(function(result)
						local ok, view = pcall(vim.json.decode, result.stdout or "")
						if not ok or type(view) ~= "table" then
							return
						end
						for _, window in ipairs(view.windows or {}) do
							for _, layer in ipairs(window.layers or {}) do
								for _, b in ipairs(layer.blocks or {}) do
									if b.block_id == block then
										if window.window_id ~= view.active_window_id or window.focused_block_id ~= block then
											-- 3: the wrapper in scrollback.lua leaves focus where it went
											vim.cmd("cquit 3")
										end
										return
									end
								end
							end
						end
					end)
				)
			end, 50)
		end,
	})
end

-- Puts the cursor on `row`, `column` (a screen column) with the last line at
-- the bottom of the window, as in the pane. Done once the UI is attached, and
-- again when Rex resizes the layer right after it opens.
local function place_cursor(row, column)
	local placed_at
	local function place()
		local last = vim.api.nvim_buf_line_count(0)
		vim.api.nvim_win_set_cursor(0, { last, 0 })
		vim.cmd("normal! zb")
		vim.api.nvim_win_set_cursor(0, { math.min(math.max(1, row), last), 0 })
		-- `|` moves by screen column (multibyte safe)
		vim.cmd("normal! " .. column .. "|")
		placed_at = placed_at or vim.uv.now()
	end
	if #vim.api.nvim_list_uis() > 0 then
		place()
	else
		vim.api.nvim_create_autocmd("UIEnter", { once = true, callback = vim.schedule_wrap(place) })
	end
	vim.api.nvim_create_autocmd("VimResized", {
		callback = function()
			if placed_at and vim.uv.now() - placed_at < 1000 then
				place()
			end
		end,
	})
end

return function(file, rows, cursor_row, cursor_column, alternate, session_id)
	local raw = vim.fn.readfile(file, "b")
	os.remove(file)
	for i, line in ipairs(raw) do
		raw[i] = line:gsub("\r$", "")
	end

	-- lazygit, sc-im and nvim run in the alternate screen, which has no history:
	-- the file is just the screen. Only there look for their cursor and clear
	-- nvim's backgrounds.
	local cleared = {}
	if alternate then
		for _, c in ipairs(nvim_cleared_bgs) do
			cleared[c] = true
		end
	end
	local text, runs, sel_row, sel_col = parse(raw, cleared, alternate)

	local buf = vim.api.nvim_get_current_buf()
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].swapfile = false
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, text)
	vim.bo[buf].modifiable = false
	vim.bo[buf].modified = false
	vim.wo.wrap = false
	vim.o.sidescroll = 1

	vim.api.nvim_set_decoration_provider(ns, {
		on_win = function(_, _, b)
			return b == buf
		end,
		on_line = function(_, _, b, line)
			for _, r in ipairs(runs[line + 1] or {}) do
				vim.api.nvim_buf_set_extmark(b, ns, line, r[1], {
					end_col = r[2],
					hl_group = r[3],
					ephemeral = true,
					priority = 100, -- under the yank flash (vim.hl.priorities.user)
				})
			end
		end,
	})
	vim.api.nvim_create_autocmd("OptionSet", {
		pattern = "background",
		callback = function()
			for _, g in ipairs(group_specs) do
				vim.api.nvim_set_hl(0, g[1], g[2])
			end
		end,
	})

	local row = #text - rows + cursor_row
	local column = cursor_column
	if sel_row then
		row, column = sel_row, sel_col
	end
	place_cursor(row, column)
	close_on_pane_change(session_id)
end
