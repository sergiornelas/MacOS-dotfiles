local wezterm = require("wezterm")

return {
	font_size = 18, --major number = bigger chars
	-- window_background_opacity = 0.6, -- major number = darker
	-- Gruvbox theme
	-- colors = {
	-- 	-- The default text color
	-- 	foreground = "#e6d4a3",
	-- 	-- The default background color
	-- 	background = "black",
	--
	-- 	-- Overrides the cell background color when the current cell is occupied by the
	-- 	-- cursor and the cursor style is set to Block
	-- 	cursor_bg = "#7b0000",
	-- 	-- cursor_bg = "#aad71e",
	-- 	-- Overrides the text color when the current cell is occupied by the cursor
	-- 	cursor_fg = "white",
	-- 	-- Specifies the border color of the cursor when the cursor style is set to Block,
	-- 	-- or the color of the vertical or horizontal bar when the cursor style is set to
	-- 	-- Bar or Underline.
	-- 	cursor_border = "#e6d4a3",
	--
	-- 	-- the foreground color of selected text
	-- 	selection_fg = "#534a42",
	-- 	-- the background color of selected text
	-- 	selection_bg = "#e6d4a3",
	--
	-- 	-- The color of the scrollbar "thumb"; the portion that represents the current viewport
	-- 	scrollbar_thumb = "#222222",
	--
	-- 	-- The color of the split lines between panes
	-- 	split = "#444444",
	--
	-- 	ansi = {
	-- 		"#1e1e1e",
	-- 		"#be0f17",
	-- 		"#868715",
	-- 		"#cc881a",
	-- 		"#377375",
	-- 		"#a04b73",
	-- 		"#578e57",
	-- 		"#978771",
	-- 	},
	-- 	brights = {
	-- 		"#7f7061",
	-- 		"#f73028",
	-- 		"#aab01e",
	-- 		"#f7b125",
	-- 		"#719586",
	-- 		"#c77089",
	-- 		"#7db669",
	-- 		"#e6d4a3",
	-- 	},
	--
	-- 	-- Arbitrary colors of the palette in the range from 16 to 255
	-- 	indexed = { [136] = "#af8700" },
	--
	-- 	-- When the IME, a dead key or a leader key are being processed and are effectively
	-- 	-- holding input pending the result of input composition, change the cursor
	-- 	-- to this color to give a visual cue about the compose state.
	-- 	compose_cursor = "orange",
	-- },
	-- color_scheme = "Solarized Dark Higher Contrast",
	-- color_scheme = "SeaShells",
	--==================================================
	-- unzoom_on_switch_pane = false,
	-- font = wezterm.font("Iosevka", { italic = true }),
	default_prog = { "/usr/local/bin/fish", "-l" },
	window_padding = {
		left = 0,
		right = 0,
		top = 12,
		bottom = 0,
	},
	font = wezterm.font("Iosevka"),
	text_background_opacity = 1,
	enable_tab_bar = false,
	window_decorations = "RESIZE",
	front_end = "OpenGL",
	-- front_end = "Software",
	term = "wezterm", --more than 256color:
	-- set tempfile $(mktemp) \
	--   && curl -o $tempfile https://raw.githubusercontent.com/wez/wezterm/main/termwiz/data/wezterm.terminfo \
	--   && tic -x -o ~/.terminfo $tempfile \
	--   && rm $tempfile
}
