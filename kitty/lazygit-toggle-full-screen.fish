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
# open_lazygit.py names the window this overlay covered; the file comes from the
# neovim living there. It only counts when git already sees a change in it,
# because otherwise it is not in the Files panel to be selected. Anything that
# does not resolve -- no neovim there, a terminal buffer, a file outside this
# repo -- just leaves lazygit to open the way it always did.
if test -n "$LAZYGIT_SOURCE_WINDOW" -a -n "$KITTY_WINDOW_ID"
    set -l FILE (nvim -u NONE -l $HOME/.config/lazygit/nvim-current-file.lua $LAZYGIT_SOURCE_WINDOW)
    set -l ROOT (git rev-parse --show-toplevel 2>/dev/null)
    set -l CHANGED (git status --porcelain -- "$FILE" 2>/dev/null)
    if test -n "$FILE" -a -n "$ROOT"; and test (count $CHANGED) -gt 0
        # lazygit shows paths from the repo root, so the filter has to match that.
        # The path travels through the environment rather than the command line:
        # it can hold quotes, spaces, '#' and '%' and none of them are ours to
        # re-escape.
        #
        # The keys have to wait for lazygit, and a fixed delay is the wrong way
        # to do it: too short and they land half-processed, leaving the cursor on
        # a directory, and how short is too short depends on how long the repo
        # takes to load -- 50ms was plenty for a toy repo and never once enough
        # for this one. So wait for the precondition itself: the file appearing
        # in the panel. Until it is listed there is nothing to filter for, and by
        # the time it is listed lazygit is done starting and keeps every key.
        #
        # The bound is there for the case where the file is real but scrolled out
        # of view in a long list; sending anyway is harmless, a filter that
        # matches nothing just leaves the cursor where it started. This has to
        # outlive us, hence sh: a fish `&` would be waited on.
        env REL=(string replace -- "$ROOT/" "" "$FILE") BASE=(basename "$FILE") WIN=$KITTY_WINDOW_ID sh -c '(m=0
            while [ $m -lt 50 ]; do
                kitty @ get-text --match id:$WIN 2>/dev/null | grep -qF "$BASE" && break
                sleep 0.02
                m=$((m + 1))
            done
            printf "/%s\r>\033" "$REL" | kitty @ send-text --match id:$WIN --stdin
            # A key you press right behind that trailing escape is read as
            # Alt+key -- an escape is only an Escape if nothing follows it for a
            # moment -- and the filter never closes. The two cannot be kept from
            # colliding, so watch for the filter, which names the path it is
            # filtering by, and send another escape until it lets go. This runs
            # after the keys have landed, so it costs nothing you can see.
            k=0
            while [ $k -lt 8 ]; do
                sleep 0.2
                kitty @ get-text --match id:$WIN 2>/dev/null | tail -1 | grep -qF "$REL" || break
                printf "\033" | kitty @ send-text --match id:$WIN --stdin
                k=$((k + 1))
            done) >/dev/null 2>&1 &'
    end
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
