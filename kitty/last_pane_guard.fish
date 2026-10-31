# Sourced by the kitty-sessions after nvim exits.
# Closing the last pane quits kitty. close_window.py asks first, but only for
# kitty_mod+w and fish's ctrl-d: when the pane's own program exits (:q in nvim)
# kitty closes it without asking. So ask here instead; answering anything but
# "y" keeps the pane open with a shell.
set -l panes (kitten @ ls | jq "[.[] | select(any(.tabs[].windows[]; .id == $KITTY_WINDOW_ID)) | .tabs[].windows[]] | length")

if test "$panes" = 1
    read -n 1 -P "Close the last pane? This will quit kitty. [y/N] " answer
    if not string match -qi y -- $answer
        exec fish
    end
end
