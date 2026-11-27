-- Helpers compartidos por init.lua (lazygit) y claude.lua. Se carga con
-- require("util").

local M = {}

-- Llama un método del terminal de un bloque (process, pwd, format, write...).
function M.terminal_call(ctx, block_id, method, args)
	return rex.call("com.superlogical.terminal." .. method, {
		session_id = ctx.session_id,
		block_id = block_id,
		args = args or {},
	})
end

-- La ventana (pestaña) y la capa que contienen un bloque.
function M.window_of(view, block_id)
	for _, w in ipairs((view or {}).windows or {}) do
		for _, layer in ipairs(w.layers or {}) do
			for _, b in ipairs(layer.blocks or {}) do
				if b.block_id == block_id then
					return w, layer
				end
			end
		end
	end
end

-- { block_id, pid, cwd } si el programa en primer plano del bloque es nvim.
function M.nvim_in(ctx, block_id)
	local proc = M.terminal_call(ctx, block_id, "process")
	local fg = proc and proc.foreground
	if fg and fg.name == "nvim" then
		return { block_id = block_id, pid = fg.pid, cwd = fg.cwd }
	end
end

-- Pone la ventana de Rex a tamaño completo con yabai (lo mismo que hyper - l) si
-- no lo está. Nunca la devuelve a su tamaño, igual que kitty/fullscreen_zoom.sh.
-- Solo toca la ventana enfocada si es de Rex.
local YABAI = "/opt/homebrew/bin/yabai"

function M.ensure_fullscreen_zoom()
	local r = rex.exec({ YABAI, "-m", "query", "--windows", "--window" }, { timeout = 2 })
	if not (r and r.ok) then
		return
	end
	local ok, win = pcall(rex.json.decode, r.stdout)
	if not ok or type(win) ~= "table" or win.app ~= "Rex" or not win.id then
		return
	end
	if win["has-fullscreen-zoom"] == false then
		rex.exec({ YABAI, "-m", "window", string.format("%d", win.id), "--toggle", "zoom-fullscreen" }, { timeout = 2 })
	end
end

return M
