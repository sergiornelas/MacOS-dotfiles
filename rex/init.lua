-- Rex config: https://www.superlogical.com/rex/docs/customize/config

local util = require("util")
local terminal_call = util.terminal_call
local window_of = util.window_of
local nvim_in = util.nvim_in
local ensure_fullscreen_zoom = util.ensure_fullscreen_zoom

-- Claude Code en un split real de Rex, junto a nvim (ctrl+shift+space).
require("claude")

-- Pestañas
rex.bind("ctrl+shift+t", "client.tab.new")

-- Paneles
rex.bind("ctrl+shift+i", "pane.focus_previous")
rex.bind("ctrl+shift+o", "pane.focus_next")

-- Lazygit flotante
-- Un lazygit por pestaña, en una capa flotante. La tecla lo abre en el directorio
-- del panel enfocado; si ya existe, lo muestra y enfoca, y si ya está enfocado,
-- lo minimiza (sigue corriendo). Al salir de lazygit con `q`, la capa se cierra.
-- Al minimizar o salir, el foco vuelve al panel desde el que se abrió/mostró.
-- <tab> queda tomado por Rex: dentro de la terminal se usa ctrl+i, que manda el
-- mismo carácter (igual que en kitty, ver kitty/open_lazygit.py).
local LAZYGIT_LABEL = "lazygit"

-- Panel de origen de cada lazygit, en un archivo por bloque: lo lee la acción al
-- minimizar y el wrapper al salir con `q` (init.lua no tiene evento de "terminó").
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

-- Corre lazygit y, si sale bien (`q`), enfoca el panel de origen antes de que la
-- capa se cierre, para que Rex no mande el foco a otro panel. Si falla, conserva
-- el código de salida y el panel queda mostrando el error.
-- rex/lazygit.yml se carga encima del config.yml normal: cambia `e` para que abra
-- el archivo en el nvim de la pestaña (rex/lazygit-edit.fish).
local LAZYGIT_WRAPPER = [[
lazygit --use-config-file "$(lazygit --print-config-dir)/config.yml,$HOME/.config/rex/lazygit.yml"
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

-- Directorio del panel: el del proceso en primer plano (nvim, fish...) y, si no
-- se puede, el último que reportó la shell, que llega como file://host/ruta (OSC 7).
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

-- lazygit sigue vivo, o ya salió (p. ej. con error fuera de un repo git, que
-- deja el panel abierto mostrando el mensaje).
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
	description = "Abre, muestra o minimiza lazygit en una capa flotante de la pestaña actual.",
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
				-- Mostrado desde otro panel: ese pasa a ser el de origen.
				if window.focused_block_id and not focused then
					save_origin(lazygit_block, window.focused_block_id)
				end
				ensure_fullscreen_zoom()
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
			bounds = { 0.05, 0.05, 0.9, 0.9 },
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

rex.bind("tab", "lazygit_toggle")

-- `e` en lazygit: abrir el archivo en el nvim de la pestaña, no dentro del flotante.
-- Lo usa rex/lazygit-edit.fish, que corre dentro del panel de lazygit
-- (ctx.block_id es ese panel):
--   rex do lazygit_editors              los nvim candidatos
--   rex do lazygit_show_editor ...      minimizar lazygit y enfocar el editor

rex.action({
	name = "lazygit_editors",
	title = "Lazygit: Editors",
	description = "Los nvim de la pestaña de lazygit: primero el del panel de origen, luego los demás.",
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
	description = "Minimiza lazygit y enfoca block_id; sin block_id, abre argv en un split junto al panel de origen.",
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
