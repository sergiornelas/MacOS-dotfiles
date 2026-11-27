-- Paneles de Claude Code en Rex. claudecode.nvim se queda solo con la
-- integración IDE (diffs en nvim, go/gl/gll/g.); el panel es un bloque real de
-- Rex con label "claude", en un split a la derecha del nvim que lo lanzó.
-- Ocultarlo es hacer zoom al nvim (como el layout stack de kitty) y mostrarlo es
-- quitar ese zoom.
--
-- Lo usan dos clientes:
--   * nvim/lua/claudecode_rex.lua (el provider de claudecode.nvim), con
--     `rex do -b $REX_BLOCK <acción>`: ctx.block_id es el bloque de nvim.
--   * ctrl+shift+space (claude_toggle), como kitty/toggle_term.py.
--
-- Se carga desde init.lua con require("claude").

local util = require("util")

local LABEL = "claude"

-- El bloque de Claude de una pestaña, buscado en su capa de splits.
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

-- El editor de la pestaña: el primer nvim de los splits y, si no hay, el primer
-- panel que no sea Claude.
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

-- Borrador sin enviar en el input de Claude. Port de capture() de
-- nvim/lua/claudecode_input_handoff.lua: el input va entre dos líneas "─────",
-- con el cursor "❯ " en su primera línea.
local function capture_draft(screen)
	-- Claude separa el cursor del texto con U+00A0, que %s no reconoce.
	screen = screen:gsub("\194\160", " ")
	local lines = {}
	for l in (screen .. "\n"):gmatch("(.-)\n") do
		lines[#lines + 1] = l
	end

	local function is_rule(s)
		return s:match("^%s*─────") ~= nil
	end

	-- Borde inferior del input: la última línea "─────" de la pantalla.
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

	-- Primera línea del input: el "❯" más cercano por encima del borde inferior,
	-- sin pasar el borde superior.
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
			-- Línea de continuación: quitar la sangría de 2 columnas bajo el cursor.
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
	description = "Abre Claude Code en un split a la derecha del nvim (ctx.block_id). Con replace_orphan, cierra el Claude huérfano de la pestaña y devuelve su borrador.",
	category = "Claude",
	args = { cmd = "string?", env = "object?", cwd = "string?", replace_orphan = "boolean?" },
	run = function(ctx, args)
		args = args or {}
		local view = rex.session.view({})
		local window = util.window_of(view, ctx.block_id)
		if not window then
			return { error = "nvim no está en ninguna pestaña" }
		end

		local cmd = args.cmd or "claude"
		local draft
		if args.replace_orphan then
			-- Un Claude que sobrevivió a su nvim perdió el enlace IDE y no se puede
			-- volver a conectar (ver claudecode.lua): rescatar el borrador, cerrarlo y
			-- relanzar con --continue.
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

		-- El layout de Rex no acepta variables de entorno: van por env(1).
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
	description = "Muestra y enfoca el bloque de Claude. ok=false si ya no existe.",
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

-- Pega el borrador rescatado en el Claude nuevo, sin enviarlo, en cuanto su
-- input ("❯") está listo; antes, el bracketed paste aún no está activo y se
-- perdería. nvim la reintenta mientras devuelva pasted=false.
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

-- ctrl+shift+space, como kitty/toggle_term.py:
--   * sin Claude en la pestaña: escribe :ClaudeCode en el nvim, que lo lanza
--     con la integración IDE;
--   * Claude oculto (otro panel con zoom): lo muestra y enfoca;
--   * Claude visible: enfoca el nvim y le hace zoom.
rex.action({
	name = "claude_toggle",
	title = "Toggle Claude",
	description = "Muestra u oculta el panel de Claude Code de la pestaña; si no existe, lo abre desde nvim.",
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

rex.bind("ctrl+shift+space", "claude_toggle")
