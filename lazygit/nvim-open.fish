# Editor hook for lazygit's `e`. Hands the file to the neovim session already
# working on this project instead of nesting a new one inside lazygit.
#
# lazygit's own `nvim-remote` preset can't do this: it keys off $NVIM, which
# neovim only exports to processes it spawns itself. lazygit runs in a kitty
# overlay, so $NVIM is never set there and the preset always nests.
#
# Finding the session is nvim-open.lua's job -- it asks every running neovim
# about itself over RPC, from a single throwaway one. This half is only what
# has to happen around that: put the window in front, and get lazygit out of
# the way.
#
# Usage: fish nvim-open.fish [--line N] <file>...   (absolute paths)

set -l line
if test (count $argv) -ge 2 -a "$argv[1]" = --line
    set line $argv[2]
    set -e argv[1..2]
end

set -l files $argv
test (count $files) -eq 0; and exit 0

set -l lua_args
test -n "$line"; and set lua_args --line $line

# Prints the kitty window the file landed in, and exits non-zero when no
# session would take it.
set -l win (nvim -u NONE -l (status dirname)/nvim-open.lua $lua_args $files)
set -l delivered $status

if test $delivered -ne 0
    # No visible session for this project. We can't nest a neovim in lazygit's
    # own terminal: editInTerminal is false (that's what removes the flash of
    # lazygit suspending), so lazygit keeps the screen and a nested TUI would
    # have nowhere to draw and would hang. Give it a kitty overlay of its own;
    # quitting it drops you back into lazygit, which is how nesting behaved.
    #
    # kitty's own error is left on stderr on purpose: lazygit shows it in a
    # popup, which beats the file quietly never opening.
    set -l opts
    test -n "$line"; and set opts +$line
    kitty @ launch --type=overlay-main --cwd=current --title=nvim \
        nvim $opts -- $files >/dev/null
    exit $status
end

# Go to where the file landed. Best effort: when lazygit is an overlay over
# this very window kitty won't focus the covered window, but then quitting
# lazygit uncovers it anyway, which is the same result.
test -n "$win"; and kitty @ focus-window --match id:$win >/dev/null 2>&1

# Then get lazygit out of the way. It runs us as a subprocess and can't be told
# to quit, so send it `q`.
#
# This has to outlive us. A fish `&` won't do -- a non-interactive fish waits
# for its background jobs -- so the detaching is delegated to sh, which
# doesn't. Rather than guess at a delay, wait for this process to die: that is
# the moment lazygit is done with us. The count bounds a wait that a recycled
# pid could otherwise leave spinning; the trailing sleep is the only slack
# left, raise it if the `q` ever gets dropped.
#
# The key is only sent while lazygit still holds the window. By then we have
# let go of it, and a `q` aimed at whatever took its place -- a shell, or the
# neovim we just focused -- would be worse than leaving lazygit open.
if test -n "$KITTY_WINDOW_ID"
    sh -c '(n=0
            while kill -0 '$fish_pid' 2>/dev/null && [ $n -lt 300 ]; do
                sleep 0.01
                n=$((n + 1))
            done
            sleep 0.05
            kitty @ ls --match id:'$KITTY_WINDOW_ID' |
              jq -e "[.[].tabs[].windows[].foreground_processes[].cmdline[0]] |
                     any(type == \"string\" and (. == \"lazygit\" or endswith(\"/lazygit\")))" >/dev/null &&
              kitty @ send-text --match id:'$KITTY_WINDOW_ID' q) >/dev/null 2>&1 &'
end
