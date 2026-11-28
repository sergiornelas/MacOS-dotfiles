# Launched by the spreadsheet session in Rex (cmd+e, rex/sessions/sessions.lua).
# Makes the Rex window yabai-fullscreen while sc-im is open and restores the
# original size on exit (ctrl+q). Same as kitty/spreadsheet-fullscreen.fish,
# minus `kitty @ close-window`: Rex closes the pane when the command ends.
set HAS_ZOOM (yabai -m query --windows --window | jq -r '."has-fullscreen-zoom"')

cd ~/notes/data
if test "$HAS_ZOOM" = "true"
    # Already fullscreen — leave yabai as it was on exit
    sc-im spreadsheet.sc
else
    yabai -m window --toggle zoom-fullscreen
    sc-im spreadsheet.sc
    set HAS_ZOOM_AFTER (yabai -m query --windows --window | jq -r '."has-fullscreen-zoom"')
    if test "$HAS_ZOOM_AFTER" = "true"
        yabai -m window --toggle zoom-fullscreen
    end
end
