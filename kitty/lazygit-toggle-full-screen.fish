# Close our own window by id. A bare `close-window` acts on whatever is
# active, and lazygit's editor hook (lazygit/nvim-open.fish) now focuses the
# neovim window before quitting lazygit -- without this, the cleanup below
# would close that neovim instead of this overlay.
set SELF_WINDOW
if test -n "$KITTY_WINDOW_ID"
    set SELF_WINDOW --match id:$KITTY_WINDOW_ID
end

set HAS_ZOOM (yabai -m query --windows --window | jq -r '."has-parent-zoom"')

# Save the current layout of the focused tab and maximize the pane by changing it to 'stack'.
# Skip the layout swap if already in 'stack' so we don't overwrite kitty's
# "last used layout" (toggle_term.py relies on it via last_used_layout()).
set ORIGINAL_LAYOUT (kitty @ ls | jq -r '.[] | select(.is_focused) | .tabs[] | select(.is_focused) | .layout')
if test "$ORIGINAL_LAYOUT" != "stack"
    kitty @ goto-layout stack
end

# Open sitting on the file you were just editing. lazygit cannot be told which
# file to select -- no flag, nothing in its state file -- so the way in is its
# own filter: `/<path>` narrows the tree to that one file, `>` drops onto the
# file itself (always the last row, whatever directories sit above it) and
# <esc> restores the full list with the selection kept.
#
# All of it runs off to the side, in a process that outlives us -- hence sh, a
# fish `&` would be waited on. Working out which file you were on costs a neovim
# and two gits, and lazygit has no reason to wait on them: started here, they
# run while it loads.
#
# open_lazygit.py names the window this overlay covered.
if test -n "$LAZYGIT_SOURCE_WINDOW" -a -n "$KITTY_WINDOW_ID"
    env SRC=$LAZYGIT_SOURCE_WINDOW WIN=$KITTY_WINDOW_ID sh -c '(
        FILE=$(nvim -u NONE -l "$HOME/.config/lazygit/nvim-current-file.lua" "$SRC" 2>/dev/null)
        ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

        # Only a file git already sees a change in is in the Files panel to be
        # selected. Anything else -- no neovim in that window, a terminal
        # buffer, a file outside this repo -- leaves lazygit to open as it
        # always did.
        if [ -n "$FILE" ] && [ -n "$ROOT" ] &&
           [ -n "$(git status --porcelain -- "$FILE" 2>/dev/null)" ]; then
            # lazygit shows paths from the repo root, so the filter has to match
            # that. Quoted inside the expansion so a root with a bracket or a
            # star in it stays a string rather than becoming a pattern.
            REL=${FILE#"$ROOT"/}

            # The keys have to wait for lazygit, and a fixed delay is the wrong
            # way to do it: too short and they land half-processed, leaving the
            # cursor on a directory, and how short is too short depends on how
            # long the repo takes to load. So wait for the precondition itself:
            # the Files panel having rows, which its footer counts. The whole
            # list lands in one go, so a count above zero means lazygit is done
            # starting and will keep every key.
            m=0
            while [ $m -lt 50 ]; do
                POS=$(kitty @ get-text --match id:$WIN 2>/dev/null |
                        grep -oE "[0-9]+ of [0-9]+" | head -1)
                [ -n "$POS" ] && [ "${POS##* of }" -gt 0 ] && break
                sleep 0.01
                m=$((m + 1))
            done
            printf "/%s\r>\033" "$REL" | kitty @ send-text --match id:$WIN --stdin

            # Wait out the filter before reading the list again. The escape
            # that ends it can go missing -- a key you press right behind it is
            # read as Alt+key instead, and the filter stays on -- so watch for
            # it, which is easy because its footer names the path, and ask again
            # every few rounds. The dance takes lazygit about 70ms and reading
            # the screen costs half that, so give it the head start rather than
            # spend a read watching it work.
            sleep 0.06
            d=0
            while [ $d -lt 30 ]; do
                TXT=$(kitty @ get-text --match id:$WIN 2>/dev/null)
                echo "$TXT" | tail -1 | grep -qF "$REL" || break
                [ $((d % 6)) -eq 5 ] && printf "\033" | kitty @ send-text --match id:$WIN --stdin
                sleep 0.01
                d=$((d + 1))
            done

            # Leaving the filter puts the selection back on the file but does
            # not scroll to it, so in a list long enough to need scrolling the
            # cursor would sit off screen. A step up and back down makes the
            # view follow. Skipped on the first row, the one place where the up
            # step has nowhere to go and the down step would leave us a file
            # below where we meant to be -- and the one place that was never
            # scrolled away from anyway.
            POS=$(echo "$TXT" | grep -oE "[0-9]+ of [0-9]+" | head -1)
            [ -n "$POS" ] && [ "${POS%% of *}" -gt 1 ] &&
              printf "kj" | kitty @ send-text --match id:$WIN --stdin
        fi) >/dev/null 2>&1 &'
end

if test "$HAS_ZOOM" = "true"
    lazygit
    # tmux kill-window
    if test "$ORIGINAL_LAYOUT" != "stack"
        kitty @ goto-layout "$ORIGINAL_LAYOUT"
    end
    kitty @ close-window $SELF_WINDOW
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
    kitty @ close-window $SELF_WINDOW
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
