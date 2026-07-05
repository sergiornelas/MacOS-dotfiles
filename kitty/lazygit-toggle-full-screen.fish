set HAS_ZOOM (yabai -m query --windows --window | jq -r '."has-parent-zoom"')

# Save the current layout of the focused tab and maximize the pane by changing it to 'stack'.
# Skip the layout swap if already in 'stack' so we don't overwrite kitty's
# "last used layout" (toggle_term.py relies on it via last_used_layout()).
set ORIGINAL_LAYOUT (kitty @ ls | jq -r '.[] | select(.is_focused) | .tabs[] | select(.is_focused) | .layout')
if test "$ORIGINAL_LAYOUT" != "stack"
    kitty @ goto-layout stack
end

if test "$HAS_ZOOM" = "true"
    lazygit
    # tmux kill-window
    if test "$ORIGINAL_LAYOUT" != "stack"
        kitty @ goto-layout "$ORIGINAL_LAYOUT"
    end
    kitty @ close-window
else
    yabai -m window --toggle zoom-fullscreen
    lazygit
    set HAS_ZOOM_AFTER_LAZYGIT (yabai -m query --windows --window | jq -r '."has-parent-zoom"')
    if test "$HAS_ZOOM_AFTER_LAZYGIT" = "true"
        yabai -m window --toggle zoom-fullscreen
        # tmux kill-window
    end
    if test "$ORIGINAL_LAYOUT" != "stack"
        kitty @ goto-layout "$ORIGINAL_LAYOUT"
    end
    kitty @ close-window
end

# bash version
##!/bin/bash
#
#HAS_ZOOM=$(yabai -m query --windows --window | jq -r '."has-parent-zoom"')
#
#if [[ $HAS_ZOOM = "true" ]]; then
#  lazygit
#  # tmux kill-window
#else
#  yabai -m window --toggle zoom-fullscreen
#  lazygit
#  HAS_ZOOM_AFTER_LAZYGIT=$(yabai -m query --windows --window | jq -r '."has-parent-zoom"')
#  if [[ $HAS_ZOOM_AFTER_LAZYGIT = "true" ]]; then
#    yabai -m window --toggle zoom-fullscreen
#    # tmux kill-window
#  fi
#fi
