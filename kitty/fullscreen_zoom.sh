#!/bin/sh
# Full size (what hyper - l does) of the focused window when showing Claude, and its
# restore when hiding it. Called by kitty/toggle_term.py (kitty_mod+space) and
# nvim/lua/plugins/claudecode.lua (g], g[, go, gl), sharing the same marker so each
# can undo what the other expanded.
#
#   ensure   expands it if it isn't already, and leaves the "I expanded it" marker
#   restore  shrinks it only if the marker exists and it's still expanded (doesn't
#            touch a full size set by hand with hyper - l, nor re-expands one that
#            was already removed by hand)
#
# The marker is keyed by yabai window id. lockf serializes the calls: two ensures in
# a row would both see "not expanded" and the second toggle would shrink it.
[ -z "$FULLSCREEN_ZOOM_LOCKED" ] &&
	FULLSCREEN_ZOOM_LOCKED=1 exec /usr/bin/lockf -k "${TMPDIR:-/tmp}/kitty-fullscreen-zoom.lock" "$0" "$@"

YABAI=/opt/homebrew/bin/yabai
JQ=/opt/homebrew/bin/jq

info=$($YABAI -m query --windows --window) || exit
id=$(printf '%s' "$info" | $JQ -r '.id')
zoom=$(printf '%s' "$info" | $JQ -r '."has-fullscreen-zoom"')
marker="${TMPDIR:-/tmp}/kitty-fullscreen-zoom-$id"

case "$1" in
ensure)
	[ "$zoom" = false ] && $YABAI -m window "$id" --toggle zoom-fullscreen && touch "$marker"
	;;
restore)
	[ -f "$marker" ] && rm "$marker" && [ "$zoom" = true ] && $YABAI -m window "$id" --toggle zoom-fullscreen
	;;
esac
