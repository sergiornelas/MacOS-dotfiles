-- Fixed sessions, like kitty's goto_session (kitty/sessions/*.kitty-session).
-- Only defines actions; keys are bound in init.lua. Loaded with require("sessions.sessions").
--
-- session_goto name=X  goes to the session labeled X. If it doesn't exist it
--                      creates it with one tab running its command in its
--                      directory; if it exists but is empty (the program exited,
--                      Rex keeps the session with no tabs), it opens the tab again.
-- session_last         goes back to the session you came from, like kitty's
--                      goto_session -1. Only switches made with these actions are
--                      remembered (not the sidebar or cmd+k); without one it falls
--                      back to Rex's session.previous.

local HOME = os.getenv("HOME")

local SESSIONS = {
	notes = { title = "Notes 󱞂 ", cwd = HOME .. "/notes", cmd = "exec nvim" },
	nvim = { title = "Neovim 󰢀 ", cwd = HOME .. "/.config/nvim", cmd = "exec nvim" },
	config = { title = "Config 󱁤 ", cwd = HOME .. "/.config", cmd = "exec nvim" },
	spreadsheet = {
		title = "Spreadsheet 󰓱 ",
		cwd = HOME .. "/notes/data",
		cmd = "source ~/.config/rex/sessions/spreadsheet.fish",
	},
	practice = { title = "Practice  ", cwd = HOME .. "/Desktop/practice", cmd = "exec nvim" },
}

-- Survives `rex config reload`, same as lazygit.lua's origin files.
local LAST_FILE = "/tmp/rex-last-session"

local function read_last()
	local f = io.open(LAST_FILE, "r")
	if not f then
		return nil
	end
	local id = f:read("*l")
	f:close()
	return id
end

local function write_last(id)
	local f = io.open(LAST_FILE, "w")
	if f then
		f:write(id)
		f:close()
	end
end

local function find_session(pred)
	local res = rex.call("session.list", {})
	for _, s in ipairs((res or {}).sessions or {}) do
		if pred(s) then
			return s
		end
	end
end

local function window_spec(spec)
	return {
		window_label = spec.title,
		layout = {
			block = {
				flavor = "com.superlogical.terminal.shell",
				options = {
					command = { "fish", "--interactive", "--login", "-c", spec.cmd },
					cwd = spec.cwd,
				},
			},
		},
	}
end

-- Shows the session in the client that ran the action and remembers where it came from.
local function switch_to(ctx, session_id)
	if session_id == ctx.session_id then
		return
	end
	if ctx.session_id then
		write_last(ctx.session_id)
	end
	rex.client.queue("session.select", { session_id = session_id })
end

rex.action({
	name = "session_goto",
	title = "Session: Go To",
	description = "Goes to a fixed session (notes, nvim, config, spreadsheet, practice), creating it or its tab if needed.",
	category = "Sessions",
	args = { name = "string" },
	run = function(ctx, args)
		local spec = SESSIONS[args.name]
		if not spec then
			error("unknown session: " .. tostring(args.name), 0)
		end

		local session = find_session(function(s)
			return s.label == args.name
		end)

		local session_id
		if session then
			session_id = session.session_id
			-- Acting on another session needs this connection attached to it.
			local attached, aerr = rex.call("session.attach", { session_id = session_id })
			if aerr then
				error(aerr, 0)
			end
			local view = attached.view
			if not (view and view.windows and #view.windows > 0) then
				local w = window_spec(spec)
				local _, err = rex.session.new_window({
					session_id = session_id,
					window_label = w.window_label,
					layout = w.layout,
				})
				if err then
					error(err, 0)
				end
			end
			if session_id ~= ctx.session_id then
				rex.call("session.detach", { session_id = session_id })
			end
		else
			local created, err = rex.call("session.create", {
				label = args.name,
				initial_windows = { window_spec(spec) },
			})
			if err then
				error(err, 0)
			end
			session_id = created.session_id
		end

		switch_to(ctx, session_id)
		return { session_id = session_id }
	end,
})

rex.action({
	name = "session_last",
	title = "Session: Go Back",
	description = "Goes back to the session you came from with session_goto/session_last.",
	category = "Sessions",
	run = function(ctx)
		local last = read_last()
		local exists = last
			and last ~= ctx.session_id
			and find_session(function(s)
				return s.session_id == last
			end)
		if exists then
			switch_to(ctx, last)
		else
			rex.client.queue("session.previous")
		end
	end,
})
