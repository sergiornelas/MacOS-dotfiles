-- Abre archivos en un nvim que ya está corriendo, por su socket. Lo usa
-- rex/lazygit-edit.fish:
--
--   nvim -u NONE -l lazygit-open.lua <socket> [--line N] <archivo>...
--
-- Sale con 0 si el nvim recibió los archivos y con 1 si no.

local sock = arg[1]
local line
local files = {}
local i = 2
while arg[i] do
	if arg[i] == "--line" and arg[i + 1] then
		line = tonumber(arg[i + 1])
		i = i + 2
	else
		files[#files + 1] = arg[i]
		i = i + 1
	end
end

local OPEN = [[
    local paths, lnum = ...
    -- Abrir en una ventana normal: en una flotante, el archivo desaparecería
    -- con lo que cierre esa flotante.
    if vim.api.nvim_win_get_config(0).relative ~= '' then
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            if vim.api.nvim_win_get_config(win).relative == '' then
                vim.api.nvim_set_current_win(win)
                break
            end
        end
    end
    for _, p in ipairs(paths) do
        vim.cmd('drop ' .. vim.fn.fnameescape(p))
    end
    if lnum then
        local last = vim.api.nvim_buf_line_count(0)
        vim.api.nvim_win_set_cursor(0, { math.min(lnum, last), 0 })
        vim.cmd('normal! zz')
    end
]]

local delivered = false
if sock and #files > 0 then
	local connected, chan = pcall(vim.fn.sockconnect, "pipe", sock, { rpc = true })
	if connected then
		delivered = pcall(vim.rpcrequest, chan, "nvim_exec_lua", OPEN, { files, line })
		pcall(vim.fn.chanclose, chan)
	end
end

-- cquit y no os.exit: cquit hace el cierre normal de nvim, que borra el socket
-- de este nvim temporal.
vim.cmd("cquit " .. (delivered and 0 or 1))
