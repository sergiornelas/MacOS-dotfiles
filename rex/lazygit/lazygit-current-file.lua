-- The file an nvim that's already running is looking at, through its socket.
-- Used by rex/lazygit/lazygit-select.sh to open lazygit sitting on that file:
--
--   nvim -u NONE -l lazygit-current-file.lua <socket>
--
-- Prints the absolute path and exits 0. Exits 1 printing nothing when the
-- socket doesn't answer or the current buffer isn't a file on disk (terminal,
-- help, quickfix...): nothing for lazygit to select.

local sock = arg[1]

local PROBE = [[
    -- The window being read, not a float a plugin may have left on top.
    local win = 0
    if vim.api.nvim_win_get_config(0).relative ~= '' then
        for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            if vim.api.nvim_win_get_config(w).relative == '' then
                win = w
                break
            end
        end
    end
    local buf = vim.api.nvim_win_get_buf(win)
    local name = vim.api.nvim_buf_get_name(buf)
    if vim.bo[buf].buftype ~= '' or name == '' then
        return ''
    end
    -- Resolved, because it's compared against the repo root git reports.
    return (vim.uv or vim.loop).fs_realpath(name) or name
]]

local file = ""
if sock then
	local connected, chan = pcall(vim.fn.sockconnect, "pipe", sock, { rpc = true })
	if connected then
		local ok, res = pcall(vim.rpcrequest, chan, "nvim_exec_lua", PROBE, {})
		if ok and type(res) == "string" then
			file = res
		end
		pcall(vim.fn.chanclose, chan)
	end
end

if file ~= "" then
	io.stdout:write(file, "\n")
	io.stdout:flush()
end
-- cquit, not os.exit: cquit runs nvim's normal shutdown, which removes this
-- throwaway nvim's socket.
vim.cmd("cquit " .. (file ~= "" and 0 or 1))
