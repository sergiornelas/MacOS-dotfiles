-- Finding the neovim sessions that are running right now. Shared by
-- nvim-open.lua and nvim-current-file.lua, which both need it and which both
-- depend on the same two things being remembered:
--
--   * our own socket sits among theirs and must not be probed;
--   * leaving through os.exit skips the shutdown that unlinks that socket, so
--     every run would leave one behind for the next run to trip over.
--
-- Load with a path relative to this file:
--
--   local here = debug.getinfo(1, "S").source:sub(2):gsub("[^/]+$", "")
--   local sessions = dofile(here .. "nvim-sessions.lua")

local uv = vim.uv
local M = {}

-- See the note above: `cquit` runs neovim's shutdown, os.exit does not.
function M.quit(code)
	vim.cmd("cquit " .. code)
end

-- Every session's socket lives beside ours, under the parent of this process's
-- own run directory. Newest first, so a tie between two sessions on the same
-- directory goes to the one started most recently.
function M.sockets()
	local socks = {}
	local sockdir = vim.fs.dirname(vim.fn.stdpath("run"))
	pcall(function()
		for name, kind in vim.fs.dir(sockdir, { depth = 2 }) do
			local path = sockdir .. "/" .. name
			if kind == "socket" and path ~= vim.v.servername then
				local st = uv.fs_stat(path)
				socks[#socks + 1] = { path = path, mtime = st and st.mtime.sec or 0 }
			end
		end
	end)
	table.sort(socks, function(a, b)
		return a.mtime > b.mtime
	end)
	return socks
end

-- Put the same question to every session that answers, and hand each reply to
-- `visit(reply, socket)`. Sessions that are gone, wedged, or too old to run the
-- chunk are skipped rather than reported: a session that cannot answer is one
-- the caller could not have used anyway.
function M.probe(code, args, visit)
	for _, sock in ipairs(M.sockets()) do
		local connected, chan = pcall(vim.fn.sockconnect, "pipe", sock.path, { rpc = true })
		if connected then
			local answered, info = pcall(vim.rpcrequest, chan, "nvim_exec_lua", code, args or {})
			if answered and type(info) == "table" then
				visit(info, sock.path)
			end
			pcall(vim.fn.chanclose, chan)
		end
	end
end

return M
