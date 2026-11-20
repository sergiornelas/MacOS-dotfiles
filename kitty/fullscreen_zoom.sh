#!/bin/sh
# Full size (what hyper - l does) of the focused window when showing a hidden Claude
# pane; it's never shrunk back. Called by kitty/toggle_term.py (kitty_mod+space) and
# nvim/lua/plugins/claudecode.lua (g], g[, go, gl).
#
# lockf serializes the calls: two in a row would both see "not expanded" and the
# second toggle would shrink it.
[ -z "$FULLSCREEN_ZOOM_LOCKED" ] &&
	FULLSCREEN_ZOOM_LOCKED=1 exec /usr/bin/lockf -k "${TMPDIR:-/tmp}/kitty-fullscreen-zoom.lock" "$0" "$@"

YABAI=/opt/homebrew/bin/yabai
JQ=/opt/homebrew/bin/jq

info=$($YABAI -m query --windows --window) || exit
id=$(printf '%s' "$info" | $JQ -r '.id')
zoom=$(printf '%s' "$info" | $JQ -r '."has-fullscreen-zoom"')

[ "$zoom" = false ] && $YABAI -m window "$id" --toggle zoom-fullscreen
