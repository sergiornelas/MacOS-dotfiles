-- Says something inside the neovim living in a given kitty window. The lazygit
-- launcher uses it to explain why a key did nothing, where you are looking,
-- rather than opening a window just to say so.
--
--   nvim -u NONE -l nvim-notify.lua <kitty window id> <message>
--
-- Exits non-zero and says nothing when that window holds no neovim, or when
-- nobody is looking at it.

local here = debug.getinfo(1, "S").source:sub(2):gsub("[^/]+$", "")
local sessions = dofile(here .. "nvim-sessions.lua")

local want, message = arg[1], arg[2]
if not want or want == "" or not message or message == "" then
	sessions.quit(1)
end

local PROBE = [[
    return {
        win   = vim.env.KITTY_WINDOW_ID,
        kitty = vim.env.KITTY_PID,
        uis   = #vim.api.nvim_list_uis(),
    }
]]

local target
sessions.probe(PROBE, {}, function(info, sock)
	-- A window id only means anything inside the kitty we are running under,
	-- and a session with no UI attached is not one anybody is looking at.
	if info.win == want and info.kitty == vim.env.KITTY_PID and info.uis > 0 then
		target = sock
	end
end)
if not target then
	sessions.quit(1)
end

local connected, chan = pcall(vim.fn.sockconnect, "pipe", target, { rpc = true })
if not connected then
	sessions.quit(1)
end
-- vim.notify rather than a bare message, so it comes out through whatever
-- notifier the session has set up.
pcall(
	vim.rpcrequest,
	chan,
	"nvim_exec_lua",
	"local msg = ... vim.notify(msg, vim.log.levels.WARN, { title = 'lazygit' })",
	{ message }
)
pcall(vim.fn.chanclose, chan)
sessions.quit(0)
