-- Floating lazygit in Rex. Only defines actions; the key is bound in init.lua
-- (tab → lazygit_toggle). Loaded with require("lazygit.lazygit").
--
-- One lazygit per tab, in a floating layer. The key opens it in the focused
-- pane's directory; if it already exists, it shows and focuses it, and if it's
-- already focused, it minimizes it (it keeps running). Quitting lazygit with `q`
-- closes the layer. On minimize or quit, focus returns to the pane it was
-- opened/shown from.
-- Rex takes <tab>: inside the terminal use ctrl+i, which sends the same
-- character (same as in kitty, see kitty/open_lazygit.py).

local util = require("util")
local terminal_call = util.terminal_call
local window_of = util.window_of
local nvim_in = util.nvim_in
local ensure_fullscreen_zoom = util.ensure_fullscreen_zoom

local LAZYGIT_LABEL = "lazygit"
-- The float covers the whole Rex window ([x, y, w, h] fractions of the window).
local LAZYGIT_BOUNDS = { 0, 0, 1, 1 }

-- Origin pane of each lazygit, in one file per block: the action reads it on
-- minimize and the wrapper on `q` (the config has no "program exited" event).
local function origin_file(lazygit_block)
	return "/tmp/rex-lazygit-" .. lazygit_block:gsub("^block:", "")
end

local function save_origin(lazygit_block, origin_block)
	local f = io.open(origin_file(lazygit_block), "w")
	if f then
		f:write(origin_block)
		f:close()
	end
end

local function read_origin(lazygit_block)
	local f = io.open(origin_file(lazygit_block), "r")
	if not f then
		return nil
	end
	local origin = f:read("*l")
	f:close()
	return origin
end

-- Runs lazygit and, if it exits cleanly (`q`), focuses the origin pane before
-- the layer closes, so Rex doesn't send focus to some other pane. If it fails,
-- the exit code is kept and the pane stays open showing the error.
-- rex/lazygit/lazygit.yml is loaded on top of the usual config.yml: it changes `e` to
-- open the file in the tab's nvim (rex/lazygit/lazygit-edit.fish).
local LAZYGIT_WRAPPER = [[
lazygit --use-config-file "$(lazygit --print-config-dir)/config.yml,$HOME/.config/rex/lazygit/lazygit.yml"
status=$?
file="/tmp/rex-lazygit-${REX_BLOCK#block:}"
if [ "$status" -eq 0 ] && [ -s "$file" ]; then
	rex focus "$(cat "$file")" >/dev/null 2>&1
fi
rm -f "$file"
exit "$status"
]]

local function contains(list, value)
	for _, v in ipairs(list or {}) do
		if v == value then
			return true
		end
	end
	return false
end

-- The pane's directory: the foreground process's (nvim, fish...) or, failing
-- that, the last one the shell reported, which comes as file://host/path (OSC 7).
local function cwd_of(ctx)
	if not ctx.block_id then
		return nil
	end
	local proc = terminal_call(ctx, ctx.block_id, "process")
	local cwd = proc and ((proc.foreground and proc.foreground.cwd) or (proc.child and proc.child.cwd))
	if cwd and cwd ~= "" then
		return cwd
	end
	local res = terminal_call(ctx, ctx.block_id, "pwd")
	local pwd = res and res.pwd
	if not pwd then
		return nil
	end
	pwd = pwd:gsub("^file://[^/]*", "")
	return (pwd:gsub("%%(%x%x)", function(h)
		return string.char(tonumber(h, 16))
	end))
end

-- Whether lazygit is still running, or already exited (e.g. with an error
-- outside a git repo, which leaves the pane open showing the message).
local function lazygit_alive(ctx, block_id)
	local proc = terminal_call(ctx, block_id, "process")
	return proc ~= nil and proc.child ~= nil and proc.last_exit == nil
end

local function find_lazygit_layer(window)
	for _, layer in ipairs(window.layers or {}) do
		if layer.kind ~= "tiled" then
			for _, block in ipairs(layer.blocks or {}) do
				if block.label == LAZYGIT_LABEL then
					local ids = {}
					for _, b in ipairs(layer.blocks) do
						ids[#ids + 1] = b.block_id
					end
					return layer, ids, block.block_id
				end
			end
		end
	end
end

rex.action({
	name = "lazygit_toggle",
	title = "Toggle Lazygit",
	description = "Opens, shows or minimizes lazygit in a floating layer of the current tab.",
	keywords = "lazygit git float floating toggle",
	run = function(ctx)
		local view, err = rex.session.view({})
		if not view then
			rex.log("error", "lazygit_toggle: " .. tostring(err))
			return
		end

		local window
		for _, w in ipairs(view.windows or {}) do
			if w.window_id == view.active_window_id then
				window = w
			end
		end
		if not window then
			return
		end

		local layer, block_ids, lazygit_block = find_lazygit_layer(window)
		if layer and not lazygit_alive(ctx, lazygit_block) then
			rex.session.close_layer({ layer_id = layer.layer_id })
			os.remove(origin_file(lazygit_block))
			layer = nil
		end
		if layer then
			local focused = contains(block_ids, window.focused_block_id)
			if layer.state ~= "minimized" and focused then
				rex.session.set_layer_state({ layer_id = layer.layer_id, state = "minimized" })
				local origin = read_origin(lazygit_block)
				if origin then
					rex.session.focus_block({ block_id = origin })
				end
			else
				-- Shown from another pane: that one becomes the origin.
				if window.focused_block_id and not focused then
					save_origin(lazygit_block, window.focused_block_id)
				end
				ensure_fullscreen_zoom()
				-- Layers created with other bounds (or moved) go back to full size
				rex.session.resize_layer({ layer_id = layer.layer_id, bounds = LAZYGIT_BOUNDS })
				rex.session.set_layer_state({ layer_id = layer.layer_id, state = "normal", focus = true })
			end
			return
		end

		local options = { command = { "sh", "-c", LAZYGIT_WRAPPER } }
		local cwd = cwd_of(ctx)
		if cwd and cwd ~= "" then
			options.cwd = cwd
		end
		ensure_fullscreen_zoom()
		local origin = ctx.block_id or window.focused_block_id
		local created, new_err = rex.session.new_layer({
			window_id = window.window_id,
			bounds = LAZYGIT_BOUNDS,
			focus = true,
			layout = {
				block = {
					flavor = "com.superlogical.terminal.shell",
					label = LAZYGIT_LABEL,
					options = options,
				},
			},
		})
		if new_err then
			rex.log("error", "lazygit_toggle: " .. tostring(new_err))
		elseif origin and created.block_ids and created.block_ids[1] then
			save_origin(created.block_ids[1], origin)
		end
	end,
})

-- `e` in lazygit: open the file in the tab's nvim, not inside the float.
-- Used by rex/lazygit/lazygit-edit.fish, which runs inside the lazygit pane
-- (ctx.block_id is that pane):
--   rex do lazygit_editors              the candidate nvims
--   rex do lazygit_show_editor ...      minimize lazygit and focus the editor

rex.action({
	name = "lazygit_editors",
	title = "Lazygit: Editors",
	description = "The nvims in lazygit's tab: the origin pane's first, then the rest.",
	category = "Lazygit",
	run = function(ctx)
		local editors = {}
		local view = rex.session.view({})
		local window, layer = window_of(view or {}, ctx.block_id)
		if not window then
			return { editors = editors }
		end
		local seen = {}
		local function add(block_id)
			if block_id and not seen[block_id] and block_id ~= ctx.block_id then
				seen[block_id] = true
				local nvim = nvim_in(ctx, block_id)
				if nvim then
					editors[#editors + 1] = nvim
				end
			end
		end
		add(read_origin(ctx.block_id))
		for _, l in ipairs(window.layers or {}) do
			if l.layer_id ~= layer.layer_id then
				for _, b in ipairs(l.blocks or {}) do
					add(b.block_id)
				end
			end
		end
		return { editors = editors }
	end,
})

rex.action({
	name = "lazygit_show_editor",
	title = "Lazygit: Show Editor",
	description = "Minimizes lazygit and focuses block_id; without block_id, opens argv in a split next to the origin pane.",
	category = "Lazygit",
	args = { block_id = "string?", argv = "array?", cwd = "string?" },
	run = function(ctx, args)
		args = args or {}
		local view = rex.session.view({})
		local window, layer = window_of(view or {}, ctx.block_id)
		if not window then
			return
		end

		local target = args.block_id
		if not target and args.argv then
			local anchor = read_origin(ctx.block_id)
			if not anchor or not window_of(view, anchor) then
				anchor = nil
				for _, l in ipairs(window.layers or {}) do
					if l.kind == "tiled" and l.blocks and l.blocks[1] then
						anchor = l.blocks[1].block_id
					end
				end
			end
			local created, err = rex.session.new_split({
				anchor_id = anchor,
				window_id = (not anchor) and window.window_id or nil,
				direction = "horizontal",
				side = "after",
				layout = {
					block = {
						flavor = "com.superlogical.terminal.shell",
						label = "nvim",
						options = { command = args.argv, cwd = args.cwd },
					},
				},
			})
			if err then
				rex.log("error", "lazygit_show_editor: " .. tostring(err))
				return
			end
			target = created.block_ids and created.block_ids[1]
		end

		if layer.kind ~= "tiled" then
			rex.session.set_layer_state({ layer_id = layer.layer_id, state = "minimized" })
		end
		if target then
			rex.session.focus_block({ block_id = target })
		end
	end,
})
