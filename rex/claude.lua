-- Claude Code panes in Rex. claudecode.nvim keeps only the IDE integration
-- (diffs in nvim, go/gl/gll/g.); the pane is a real Rex block labeled "claude",
-- in a split to the right of the nvim that launched it. Hiding it means zooming
-- nvim (like kitty's stack layout) and showing it means removing that zoom.
--
-- Two clients use it:
--   * nvim/lua/claudecode_rex.lua (claudecode.nvim's provider), through
--     `rex do -b $REX_BLOCK <action>`: ctx.block_id is the nvim block.
--   * ctrl+shift+space (claude_toggle), like kitty/toggle_term.py.
--
-- Only defines actions; the key is bound in init.lua. Loaded with
-- require("claude").

local util = require("util")

local LABEL = "claude"

-- A tab's Claude block, looked up in its tiled layer.
local function find_claude(window)
	for _, layer in ipairs(window.layers or {}) do
		if layer.kind == "tiled" then
			for _, b in ipairs(layer.blocks or {}) do
				if b.label == LABEL then
					return b.block_id
				end
			end
		end
	end
end

-- The tab's editor: the first nvim among the splits or, if there's none, the
-- first pane that isn't Claude.
local function find_editor(ctx, window)
	local fallback
	for _, layer in ipairs(window.layers or {}) do
		if layer.kind == "tiled" then
			for _, b in ipairs(layer.blocks or {}) do
				if b.label ~= LABEL then
					if util.nvim_in(ctx, b.block_id) then
						return b.block_id
					end
					fallback = fallback or b.block_id
				end
			end
		end
	end
	return fallback
end

local function unzoom(window)
	if window.tiled_zoomed_block_id then
		rex.session.zoom_block({ block_id = window.tiled_zoomed_block_id, zoom = false })
	end
end

local function show(window, claude)
	unzoom(window)
	util.ensure_fullscreen_zoom()
	rex.session.focus_block({ block_id = claude })
end

local function hide(ctx, window, claude)
	local editor = find_editor(ctx, window)
	if not editor then
		return
	end
	rex.session.focus_block({ block_id = editor })
	rex.session.zoom_block({ block_id = editor, zoom = true })
end

-- Unsent draft in Claude's input box. Port of capture() from
-- nvim/lua/claudecode_input_handoff.lua: the box sits between two "─────" rules,
-- with the "❯ " caret on its first line.
local function capture_draft(screen)
	-- Claude separates the caret from the text with U+00A0, which %s doesn't match.
	screen = screen:gsub("\194\160", " ")
	local lines = {}
	for l in (screen .. "\n"):gmatch("(.-)\n") do
		lines[#lines + 1] = l
	end

	local function is_rule(s)
		return s:match("^%s*─────") ~= nil
	end

	-- Bottom border of the input: the last "─────" rule on screen.
	local bottom
	for i = #lines, 1, -1 do
		if is_rule(lines[i]) then
			bottom = i
			break
		end
	end
	if not bottom then
		return nil
	end

	-- First input line: the nearest "❯" above the bottom border, without going
	-- past the top border.
	local caret
	for i = bottom - 1, 1, -1 do
		if lines[i]:match("^%s*❯") then
			caret = i
			break
		end
		if is_rule(lines[i]) then
			break
		end
	end
	if not caret then
		return nil
	end

	local parts = {}
	for i = caret, bottom - 1 do
		local after = lines[i]:match("^%s*❯%s?(.*)$")
		if after ~= nil then
			parts[#parts + 1] = (after:gsub("%s+$", ""))
		else
			-- Continuation line: drop the 2-column indent under the caret.
			parts[#parts + 1] = (lines[i]:gsub("%s+$", ""):gsub("^  ", "", 1))
		end
	end

	local text = table.concat(parts, "\n"):gsub("%s+$", "")
	if text == "" then
		return nil
	end
	return text
end

local function screen_of(ctx, block_id)
	local res = util.terminal_call(ctx, block_id, "format", { format = "text", trim = true })
	return res and res.content
end

rex.action({
	name = "claude_launch",
	title = "Claude: Launch",
	description = "Opens Claude Code in a split to the right of nvim (ctx.block_id). With replace_orphan, closes the tab's orphaned Claude and returns its draft.",
	category = "Claude",
	args = { cmd = "string?", env = "object?", cwd = "string?", replace_orphan = "boolean?" },
	run = function(ctx, args)
		args = args or {}
		local view = rex.session.view({})
		local window = util.window_of(view, ctx.block_id)
		if not window then
			return { error = "nvim is not in any tab" }
		end

		local cmd = args.cmd or "claude"
		local draft
		if args.replace_orphan then
			-- A Claude that outlived its nvim lost the IDE link and can't be
			-- reconnected (see claudecode.lua): rescue its draft, close it and
			-- relaunch with --continue.
			local orphan = find_claude(window)
			if orphan then
				local screen = screen_of(ctx, orphan)
				draft = screen and capture_draft(screen)
				rex.call("block.close", { session_id = ctx.session_id, block_id = orphan })
				if not cmd:match("%-%-continue") and not cmd:match("%-%-resume") then
					cmd = cmd .. " --continue"
				end
				view = rex.session.view({})
				window = util.window_of(view, ctx.block_id) or window
			end
		end

		unzoom(window)
		util.ensure_fullscreen_zoom()

		-- Rex layouts take no environment variables: pass them through env(1).
		local argv = { "env" }
		for k, v in pairs(args.env or {}) do
			argv[#argv + 1] = k .. "=" .. tostring(v)
		end
		argv[#argv + 1] = "sh"
		argv[#argv + 1] = "-c"
		argv[#argv + 1] = "exec " .. cmd

		local created, err = rex.session.new_split({
			anchor_id = ctx.block_id,
			direction = "horizontal",
			side = "after",
			ratio = 0.5,
			focus = true,
			layout = {
				block = {
					flavor = "com.superlogical.terminal.shell",
					label = LABEL,
					options = { command = argv, cwd = args.cwd },
				},
			},
		})
		if err then
			rex.log("error", "claude_launch: " .. tostring(err))
			return { error = tostring(err) }
		end
		return { block_id = created.block_ids and created.block_ids[1], draft = draft }
	end,
})

rex.action({
	name = "claude_show",
	title = "Claude: Show",
	description = "Shows and focuses the Claude block. ok=false if it no longer exists.",
	category = "Claude",
	args = { block_id = "string" },
	run = function(ctx, args)
		local view = rex.session.view({})
		local window = util.window_of(view, args.block_id)
		if not window then
			return { ok = false }
		end
		show(window, args.block_id)
		return { ok = true }
	end,
})

rex.action({
	name = "claude_close",
	title = "Claude: Close",
	category = "Claude",
	args = { block_id = "string" },
	run = function(ctx, args)
		rex.call("block.close", { session_id = ctx.session_id, block_id = args.block_id })
	end,
})

-- Pastes the rescued draft into the new Claude, without submitting it, once its
-- input ("❯") is ready; before that, bracketed paste isn't enabled yet and the
-- paste would be lost. nvim retries it while it returns pasted=false.
rex.action({
	name = "claude_paste",
	title = "Claude: Paste Draft",
	category = "Claude",
	args = { block_id = "string", text = "string" },
	run = function(ctx, args)
		local screen = screen_of(ctx, args.block_id)
		if not screen then
			return { pasted = false, gone = true }
		end
		if not screen:find("❯", 1, true) then
			return { pasted = false }
		end
		util.terminal_call(ctx, args.block_id, "write", { data = "\27[200~" .. args.text .. "\27[201~" })
		return { pasted = true }
	end,
})

-- ctrl+shift+space, like kitty/toggle_term.py:
--   * no Claude in the tab: types :ClaudeCode into nvim, which launches it with
--     the IDE integration;
--   * Claude hidden (another pane zoomed): shows and focuses it;
--   * Claude visible: focuses nvim and zooms it.
rex.action({
	name = "claude_toggle",
	title = "Toggle Claude",
	description = "Shows or hides the tab's Claude Code pane; if there is none, opens it from nvim.",
	category = "Claude",
	keywords = "claude code ai agent toggle",
	run = function(ctx)
		local view = rex.session.view({})
		local window = util.window_of(view, ctx.block_id)
		if not window then
			for _, w in ipairs((view or {}).windows or {}) do
				if w.window_id == view.active_window_id then
					window = w
				end
			end
		end
		if not window then
			return
		end

		local claude = find_claude(window)
		if not claude then
			local editor = (ctx.block_id and util.nvim_in(ctx, ctx.block_id)) and ctx.block_id
				or find_editor(ctx, window)
			if editor and util.nvim_in(ctx, editor) then
				util.terminal_call(ctx, editor, "write", { data = "\27:ClaudeCode\r" })
			end
			return
		end

		local zoomed = window.tiled_zoomed_block_id
		if zoomed and zoomed ~= claude then
			show(window, claude)
		else
			hide(ctx, window, claude)
		end
	end,
})
