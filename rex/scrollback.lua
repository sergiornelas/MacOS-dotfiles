-- kitty's show_scrollback (kitty_mod+y) in Rex. Only defines actions; the key
-- is bound in init.lua (ctrl+shift+y → scrollback_open). Loaded with
-- require("scrollback").
--
-- Opens the focused pane's screen and scrollback, with its colors, in a minimal
-- nvim that sits in a floating layer right on top of the pane. Yanking copies to
-- the clipboard and closes it; `q` closes it without copying. Settings and
-- keymaps are kitty/scrollback_init.lua's (shared with kitty), the rest is in
-- rex/scrollback_pager.lua.
--
-- Unlike kitty, Rex doesn't say how far the pane was scrolled, so the pager
-- always opens at the bottom, with the cursor where the pane had it.

local util = require("util")
local terminal_call = util.terminal_call
local window_of = util.window_of

local LABEL = "Copy 󰆏"

-- Runs the pager and, when it quits cleanly (yank or `q`), focuses the origin
-- pane before the layer closes, so Rex doesn't send focus to some other pane
-- (same as lazygit.lua). Exit code 3 means the pager closed itself because focus
-- moved to another pane or tab (scrollback_pager.lua): focus stays there.
-- $1 file, $2 screen rows, $3 cursor row, $4 cursor column, $5 alternate screen,
-- $6 session, $7 origin block.
local WRAPPER = [[
nvim -u "$HOME/.config/kitty/scrollback_init.lua" \
	-c "lua dofile(vim.fn.expand('~/.config/rex/scrollback_pager.lua'))('$1', $2, $3, $4, $5, '$6')" \
	-c 'set readonly nolist'
status=$?
rm -f "$1" "/tmp/rex-scrollback-origin-${REX_BLOCK#block:}"
if [ "$status" -eq 3 ]; then
	exit 0
fi
if [ "$status" -eq 0 ]; then
	rex focus "$7" >/dev/null 2>&1
fi
exit "$status"
]]

-- The screen and scrollback as escape sequences, plus the cursor (row, column
-- on screen). Output too large for one reply comes in parts through blob_read.
local function capture(ctx, block_id)
	local res, err = terminal_call(ctx, block_id, "format", {
		format = "vt",
		extra_cursor = true,
		extra_palette = true, -- OSC 4 at the start, for the basic colors
		max_bytes = 983040,
	})
	if not res then
		return nil, err
	end
	local parts = { res.content }
	if res.id then
		local offset = #res.content
		while true do
			local chunk, chunk_err = terminal_call(ctx, block_id, "blob_read", {
				id = res.id,
				offset = offset,
				max_bytes = 983040,
			})
			if not chunk then
				return nil, chunk_err
			end
			parts[#parts + 1] = chunk.data
			offset = offset + #chunk.data
			if chunk.eof or #chunk.data == 0 then
				break
			end
		end
	end
	local content = table.concat(parts)
	-- extra_cursor puts the cursor at the very end as ESC[row;colH. Look only at
	-- the tail: a pattern over the whole scrollback is "too complex" for Rex's Lua.
	local tail_start = math.max(1, #content - 31)
	local start, row, col = content:sub(tail_start):match("()\27%[(%d+);(%d+)H$")
	if start then
		return content:sub(1, tail_start + start - 2), tonumber(row), tonumber(col)
	end
	return content, nil, nil
end

-- The block's rect [x, y, w, h] in its window: from the tiled layout (the whole
-- window when zoomed), or the bounds of its floating layer.
local function rect_of(window, layer, block_id)
	if layer.kind ~= "tiled" then
		return layer.bounds
	end
	if window.tiled_zoomed_block_id == block_id then
		return { 0, 0, 1, 1 }
	end
	local function find(node)
		if type(node) ~= "table" then
			return nil
		end
		if node.block_id == block_id and node.rect then
			return node.rect
		end
		for _, child in pairs(node) do
			local found = find(child)
			if found then
				return found
			end
		end
	end
	return find(layer.layout) or layer.bounds
end

-- Origin pane of each pager, for focus_next/focus_previous. The wrapper removes
-- the file when the pager ends.
local function origin_file(pager_block)
	return "/tmp/rex-scrollback-origin-" .. pager_block:gsub("^block:", "")
end

rex.action({
	name = "scrollback_open",
	title = "Show Scrollback",
	description = "Opens the pane's scrollback in nvim on top of it; yanking copies and closes it.",
	keywords = "scrollback history copy yank nvim pager",
	run = function(ctx)
		local origin = ctx.block_id
		if not origin then
			return
		end
		local view = rex.session.view({})
		local window, layer = window_of(view or {}, origin)
		if not window then
			return
		end
		for _, b in ipairs(layer.blocks or {}) do
			if b.block_id == origin and b.label == LABEL then
				return -- already in the pager
			end
		end

		local content, row, col = capture(ctx, origin)
		if not content then
			rex.log("error", "scrollback_open: " .. tostring(row))
			return
		end
		local size = terminal_call(ctx, origin, "size") or {}
		local modes = terminal_call(ctx, origin, "modes") or {}
		local rows = size.rows or 0
		local alt = modes.screen == "alternate"

		local file = "/tmp/rex-scrollback-" .. origin:gsub("^block:", "") .. ".ansi"
		local f = io.open(file, "wb")
		if not f then
			rex.log("error", "scrollback_open: can't write " .. file)
			return
		end
		f:write(content)
		f:close()

		local created, err = rex.session.new_layer({
			window_id = window.window_id,
			bounds = rect_of(window, layer, origin),
			focus = true,
			layout = {
				block = {
					flavor = "com.superlogical.terminal.shell",
					label = LABEL,
					options = {
						command = {
							"sh",
							"-c",
							WRAPPER,
							"sh",
							file,
							string.format("%d", rows),
							string.format("%d", row or rows),
							string.format("%d", col or 1),
							tostring(alt),
							ctx.session_id or view.session_id,
							origin,
						},
					},
				},
			},
		})
		if err then
			os.remove(file)
			rex.log("error", "scrollback_open: " .. tostring(err))
			return
		end
		-- A new block starts at 80x24 until a client draws it: give it the pane's
		-- size right away so the text wraps like in the pane. The client resizes it
		-- again once it shows it.
		local pager = created and created.block_ids and created.block_ids[1]
		if pager then
			local of = io.open(origin_file(pager), "w")
			if of then
				of:write(origin)
				of:close()
			end
		end
		if pager and size.columns and size.rows then
			terminal_call(ctx, pager, "resize", {
				columns = size.columns,
				rows = size.rows,
				cell_width_px = size.cell_width_px,
				cell_height_px = size.cell_height_px,
			})
		end
	end,
})

-- cmd+[ / cmd+] (and ctrl+shift+i / ctrl+shift+o), bound in init.lua in place
-- of pane.focus_previous / pane.focus_next. The pager is one more pane of the
-- window, so from it "next" or "previous" usually landed on the origin pane
-- under it. From the pager, these count from the origin pane, skipping the
-- pager, then close it. Anywhere else they do what the built-in actions do.

local function focus_step(ctx, step)
	local view = rex.session.view({})
	local window, layer = window_of(view or {}, ctx.block_id)
	local pager_label
	for _, b in ipairs((layer or {}).blocks or {}) do
		if b.block_id == ctx.block_id then
			pager_label = b.label
		end
	end
	local f = window and pager_label == LABEL and io.open(origin_file(ctx.block_id), "r")
	local origin = f and f:read("*l")
	if f then
		f:close()
	end
	if not origin or not window_of(view, origin) then
		if step > 0 then
			rex.session.focus_next_pane({ wrap = true })
		else
			rex.session.focus_previous_pane({ wrap = true })
		end
		return
	end

	-- The window's panes in focus order, without the pager or minimized layers
	local blocks, index = {}, nil
	for _, l in ipairs(window.layers or {}) do
		if l.layer_id ~= layer.layer_id and l.state ~= "minimized" then
			for _, b in ipairs(l.blocks or {}) do
				blocks[#blocks + 1] = b.block_id
				if b.block_id == origin then
					index = #blocks
				end
			end
		end
	end
	local target = index and blocks[(index - 1 + step) % #blocks + 1] or origin
	-- Focus first, then close: the pager's nvim ends without moving focus back
	rex.session.focus_block({ block_id = target })
	rex.session.close_layer({ layer_id = layer.layer_id })
	os.remove(origin_file(ctx.block_id))
end

rex.action({
	name = "focus_next",
	title = "Focus Next Pane",
	description = "pane.focus_next, but from the scrollback pager it counts from the pane under it and closes the pager.",
	keywords = "pane focus next scrollback",
	run = function(ctx)
		focus_step(ctx, 1)
	end,
})

rex.action({
	name = "focus_previous",
	title = "Focus Previous Pane",
	description = "pane.focus_previous, but from the scrollback pager it counts from the pane under it and closes the pager.",
	keywords = "pane focus previous scrollback",
	run = function(ctx)
		focus_step(ctx, -1)
	end,
})
