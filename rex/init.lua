-- Rex config: https://www.superlogical.com/rex/docs/customize/config
--
-- Only key bindings live here. Each feature's logic lives in its own module,
-- which defines actions with rex.action:
--   lazygit.lua  lazygit_toggle, lazygit_editors, lazygit_show_editor
--   claude.lua   claude_toggle, claude_launch, claude_show, claude_close, claude_paste
--   scrollback.lua  scrollback_open, focus_next, focus_previous
--   util.lua     shared helpers

require("lazygit")
require("claude")
require("scrollback")

-- Tabs
rex.bind("ctrl+shift+t", "client.tab.new")

-- Panes. Like pane.focus_previous / pane.focus_next, but from the scrollback
-- pager they close it and go to the pane next to the one under it (scrollback.lua)
rex.bind("ctrl+shift+i", "focus_previous")
rex.bind("ctrl+shift+o", "focus_next")
rex.bind("cmd+[", "focus_previous")
rex.bind("cmd+]", "focus_next")

-- Floating lazygit (lazygit.lua). Inside the terminal, ctrl+i acts as <tab>.
rex.bind("tab", "lazygit_toggle")

-- Claude Code in a split next to nvim (claude.lua)
rex.bind("ctrl+shift+space", "claude_toggle")

-- Scrollback in nvim on top of the pane, like kitty's show_scrollback (scrollback.lua)
rex.bind("ctrl+shift+y", "scrollback_open")
