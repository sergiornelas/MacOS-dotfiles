-- The file the neovim in a given kitty window is looking at. Used by the
-- lazygit launcher to open lazygit already sitting on that file; see
-- kitty/lazygit-toggle-full-screen.fish.
--
--   nvim -u NONE -l nvim-current-file.lua <kitty window id>
--
-- Prints the absolute path. Exits non-zero and prints nothing when that window
-- holds no neovim, when nobody is looking at it, or when its current buffer is
-- not a file on disk -- all cases where there is nothing for lazygit to select.

local here = debug.getinfo(1, "S").source:sub(2):gsub("[^/]+$", "")
local sessions = dofile(here .. "nvim-sessions.lua")

local want = arg[1]
if not want or want == "" then
	sessions.quit(1)
end

local PROBE = [[
    -- The window the user is actually reading, which is not the floating one a
    -- plugin may have left on top.
    local win = 0
    if vim.api.nvim_win_get_config(0).relative ~= "" then
        for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            if vim.api.nvim_win_get_config(w).relative == "" then
                win = w
                break
            end
        end
    end
    local buf = vim.api.nvim_win_get_buf(win)
    local name = vim.api.nvim_buf_get_name(buf)
    return {
        win   = vim.env.KITTY_WINDOW_ID,
        kitty = vim.env.KITTY_PID,
        uis   = #vim.api.nvim_list_uis(),
        -- Resolved, because the caller compares it against a repo root that git
        -- reports resolved too.
        file  = name ~= "" and ((vim.uv or vim.loop).fs_realpath(name) or name) or "",
        -- Empty for a real file; a terminal, help or quickfix buffer says so
        -- here and has no path worth handing to lazygit.
        kind  = vim.bo[buf].buftype,
    }
]]

local found
sessions.probe(PROBE, {}, function(info)
	-- A window id only means anything inside the kitty we are running under,
	-- and a session with no UI attached is not one anybody is looking at.
	if info.win == want and info.kitty == vim.env.KITTY_PID and info.uis > 0 then
		found = info
	end
end)

if not found or found.kind ~= "" or found.file == "" then
	sessions.quit(1)
end

io.stdout:write(found.file, "\n")
io.stdout:flush()
sessions.quit(0)
