-- Rex config: https://www.superlogical.com/rex/docs/customize/config
--
-- Only key bindings live here. Each feature's logic lives in its own module,
-- which defines actions with rex.action:
--   lazygit.lua  lazygit_toggle, lazygit_editors, lazygit_show_editor
--   claude.lua   claude_toggle, claude_launch, claude_show, claude_close, claude_paste
--   util.lua     shared helpers

require("lazygit")
require("claude")

-- Tabs
rex.bind("ctrl+shift+t", "client.tab.new")

-- Panes
rex.bind("ctrl+shift+i", "pane.focus_previous")
rex.bind("ctrl+shift+o", "pane.focus_next")

-- Floating lazygit (lazygit.lua). Inside the terminal, ctrl+i acts as <tab>.
rex.bind("tab", "lazygit_toggle")

-- Claude Code in a split next to nvim (claude.lua)
rex.bind("ctrl+shift+space", "claude_toggle")
