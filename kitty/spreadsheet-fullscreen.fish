# Launched by the spreadsheet kitty-session (cmd+e).
# Makes the kitty OS window yabai-fullscreen while sc-im is open and restores
# the original size on exit (ctrl+q). Mirrors the lazygit toggle.
#
# NOTE: we run sc-im directly instead of the `v` function, because `v` ends
# with `kitty @ close-window`, which would tear down this process before the
# yabai restore below could run. So we restore first, then close the window.
set HAS_ZOOM (yabai -m query --windows --window | jq -r '."has-fullscreen-zoom"')

if test "$HAS_ZOOM" = "true"
    # Already fullscreen — leave yabai as it was on exit
    cd ~/notes/data
    sc-im spreadsheet.sc
else
    yabai -m window --toggle zoom-fullscreen
    cd ~/notes/data
    sc-im spreadsheet.sc
    set HAS_ZOOM_AFTER (yabai -m query --windows --window | jq -r '."has-fullscreen-zoom"')
    if test "$HAS_ZOOM_AFTER" = "true"
        yabai -m window --toggle zoom-fullscreen
    end
end

kitty @ close-window