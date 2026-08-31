-- Session picker behind lazygit's `e`. Driven by nvim-open.fish:
--
--   nvim -u NONE -l nvim-open.lua [--line N] <path>...
--
-- Opens the paths in the neovim session already working on their repo and
-- prints the kitty window id that shows it. Exits non-zero, printing nothing,
-- when no such session exists -- the caller's cue to open a window itself.
--
-- Everything is asked of the sessions themselves over RPC, from this one
-- throwaway neovim. A session knows its own cwd, whether anyone is looking at
-- it and which kitty window it sits in; inferring any of that from the process
-- table guesses at a relationship neovim does not promise to keep.

local uv = vim.uv

-- Listing the live sessions, and leaving without stranding our own socket, is
-- shared with nvim-current-file.lua.
local here = debug.getinfo(1, "S").source:sub(2):gsub("[^/]+$", "")
local sessions = dofile(here .. "nvim-sessions.lua")
local quit = sessions.quit

-- ---------------------------------------------------------------------- args
local line
local files = {}
local i = 1
while arg[i] do
	if arg[i] == "--line" and arg[i + 1] then
		line = tonumber(arg[i + 1])
		i = i + 2
	else
		files[#files + 1] = arg[i]
		i = i + 1
	end
end
if #files == 0 then
	quit(1)
end

-- ----------------------------------------------------------------- the repo
-- Walking up for `.git` covers plain repos and linked worktrees, where it is a
-- file rather than a directory, and saves forking git. The path is resolved
-- first so the answer is the physical one a session's cwd will also report.
local function repo_root(path)
	local dir = uv.fs_realpath(path)
	if dir then
		-- `openDirInEditor` hands us a directory. It is its own starting
		-- point: taking its parent would walk out of a repo whose root it
		-- already is.
		local st = uv.fs_stat(dir)
		if not st or st.type ~= "directory" then
			dir = vim.fs.dirname(dir)
		end
	else
		-- The path can be gone already -- a file staged for deletion. Where it
		-- used to live is still the right place to start looking.
		dir = uv.fs_realpath(vim.fs.dirname(path))
	end
	if not dir then
		return nil
	end
	while true do
		if uv.fs_stat(dir .. "/.git") then
			return dir
		end
		local parent = vim.fs.dirname(dir)
		if parent == dir then
			return nil
		end
		dir = parent
	end
end

-- Nothing outside a repo is this hook's business: let the caller open a window
-- for it rather than guessing at a session from an unrelated project.
local root = repo_root(files[1])
if not root then
	quit(1)
end

-- -------------------------------------------------------------- the sessions
local PROBE = [[
    local paths = ...
    local holds = false
    for _, p in ipairs(paths) do
        if vim.fn.bufexists(p) == 1 then
            holds = true
            break
        end
    end
    return {
        cwd   = (vim.uv or vim.loop).cwd(),
        uis   = #vim.api.nvim_list_uis(),
        win   = vim.env.KITTY_WINDOW_ID,
        kitty = vim.env.KITTY_PID,
        holds = holds,
    }
]]

-- Pick the session for this project, but only among the ones someone can
-- actually see. A server with no UI attached -- one that was `:detach`ed, or a
-- `--headless` job -- still answers on its socket and still reports the
-- KITTY_WINDOW_ID it happened to inherit, so "the socket replies" is no proof
-- of a usable session: the file would land where nobody is looking.
local best, best_score
sessions.probe(PROBE, { files }, function(info, sock)
	if info.uis == 0 then
		return
	end
	local score
	if info.cwd == root then
		score = 1e6
	elseif vim.startswith(info.cwd, root .. "/") then
		-- Deepest cwd inside the repo wins, so a session opened in a
		-- subdirectory still counts when none sits at the root.
		score = #vim.split(info.cwd, "/", { plain = true })
	else
		return
	end
	-- Among sessions that rank the same, the one already holding the file takes
	-- it, rather than opening a second copy elsewhere.
	if info.holds then
		score = score + 0.5
	end
	if not best_score or score > best_score then
		best, best_score = { sock = sock, info = info }, score
	end
end)

if not best then
	quit(1)
end

-- ------------------------------------------------------------------ delivery
local OPEN = [[
    local paths, lnum = ...
    -- Land in a normal window: dropped into a floating one, the file would go
    -- away with whatever dismisses that float.
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

local connected, chan = pcall(vim.fn.sockconnect, "pipe", best.sock, { rpc = true })
if not connected then
	quit(1)
end
local delivered = pcall(vim.rpcrequest, chan, "nvim_exec_lua", OPEN, { files, line })
pcall(vim.fn.chanclose, chan)
if not delivered then
	quit(1)
end

-- A window id only means anything for the kitty we are running under. A
-- session left over from an earlier kitty names an id that now belongs to
-- somebody else's window, so say nothing rather than send the focus there.
if best.info.win and best.info.kitty == vim.env.KITTY_PID then
	io.stdout:write(best.info.win, "\n")
end
io.stdout:flush()
quit(0)
