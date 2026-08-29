# Editor hook for lazygit's `e`. Hands the file to the neovim session already
# working on this project instead of nesting a new one inside lazygit.
#
# lazygit's own `nvim-remote` preset can't do this: it keys off $NVIM, which
# neovim only exports to processes it spawns itself. lazygit runs in a kitty
# overlay, so $NVIM is never set there and the preset always nests.
#
# Usage: fish nvim-open.fish [--line N] <file>...   (absolute paths)

set -l line
if test (count $argv) -ge 2 -a "$argv[1]" = --line
    set line $argv[2]
    set -e argv[1..2]
end

set -l files $argv
test (count $files) -eq 0; and exit 0

# The project is the repo the file belongs to.
set -l root (git -C (dirname "$files[1]") rev-parse --show-toplevel 2>/dev/null)

# Sockets newest first, so a tie between two sessions on the same directory
# goes to the most recently started one. The pid in the name is neovim's
# `--embed` child, which is the process that actually holds the server.
set -l socks (find $TMPDIR/nvim.$USER -maxdepth 2 -type s -exec stat -f '%m %N' {} \; 2>/dev/null | sort -rn | cut -d' ' -f2-)

set -l pids
for s in $socks
    set -a pids (string replace -r '.*/nvim\.([0-9]+)\.0$' '$1' -- $s)
end

test (count $pids) -eq 0; and set pids

# Everything below is resolved with one call per tool rather than one per
# session, so the cost stays flat no matter how many neovims are running.

# 1. cwd of each server. Accurate because vim's `:cd` calls chdir(), so a
#    process cwd tracks getcwd() exactly.
set -l cwd_pids
set -l cwd_vals
if test (count $pids) -gt 0
    set -l cur
    for l in (lsof -a -d cwd -p (string join , $pids) -Fpn 2>/dev/null)
        switch $l
            case 'p*'
                set cur (string sub -s 2 -- $l)
            case 'n*'
                set -a cwd_pids $cur
                set -a cwd_vals (string sub -s 2 -- $l)
        end
    end
end

# 2. The UI process of each server, which is its parent.
set -l pp_pids
set -l pp_vals
if test (count $pids) -gt 0
    for l in (ps -o pid=,ppid= -p (string join , $pids) 2>/dev/null)
        set -l parts (string split -n ' ' -- (string trim $l))
        set -a pp_pids $parts[1]
        set -a pp_vals $parts[2]
    end
end

# 3. The kitty window showing each process, if any.
set -l fg_pids
set -l fg_wins
for l in (kitty @ ls 2>/dev/null | jq -r '.[].tabs[].windows[] | .id as $w | .foreground_processes[]? | "\(.pid) \($w)"' 2>/dev/null)
    set -l parts (string split -n ' ' -- $l)
    set -a fg_pids $parts[1]
    set -a fg_wins $parts[2]
end

# Pick the session for this project, but only among the ones you can actually
# see. A neovim whose UI died leaves its `--embed` server running and answering
# on its socket, so "the socket replies" is not proof of a usable session --
# sending a file there drops it into a window that no longer exists.
set -l best
set -l best_win
set -l best_depth -1

if test -n "$root"
    for i in (seq (count $socks))
        set -l ci (contains -i -- $pids[$i] $cwd_pids)
        test -z "$ci"; and continue
        set -l cwd $cwd_vals[$ci]

        set -l pi (contains -i -- $pids[$i] $pp_pids)
        test -z "$pi"; and continue
        set -l wi (contains -i -- $pp_vals[$pi] $fg_pids)
        test -z "$wi"; and continue
        set -l win $fg_wins[$wi]

        if test "$cwd" = "$root"
            set best $socks[$i]
            set best_win $win
            break
        else if string match -q -- "$root/*" "$cwd"
            # Deepest cwd inside the repo wins, so a session opened in a
            # subdirectory still counts when none sits at the root.
            set -l depth (string split / -- "$cwd" | count)
            if test $depth -gt $best_depth
                set best $socks[$i]
                set best_win $win
                set best_depth $depth
            end
        end
    end
end

if test -n "$best"
    for f in $files
        nvim --server $best --remote "$f" >/dev/null 2>&1 </dev/null
    end
    if test -n "$line"
        nvim --server $best --remote-send ":$line<CR>" >/dev/null 2>&1 </dev/null
    end

    # Go to where the file landed. Best effort: when lazygit is an overlay over
    # this very window kitty won't focus the covered window, but then quitting
    # lazygit uncovers it anyway, which is the same result.
    kitty @ focus-window --match id:$best_win >/dev/null 2>&1

    # Then get lazygit out of the way. It runs us as a subprocess and can't be
    # told to quit, so send it `q`.
    #
    # This has to outlive us. A fish `&` won't do -- a non-interactive fish
    # waits for its background jobs -- so the detaching is delegated to sh,
    # which doesn't. Rather than guess at a delay, wait for this process to
    # die: that is the moment lazygit is done with us. The trailing sleep is
    # the only slack left; raise it if the `q` ever gets dropped.
    if test -n "$KITTY_WINDOW_ID"
        sh -c "(while kill -0 $fish_pid 2>/dev/null; do sleep 0.01; done
                sleep 0.05
                kitty @ send-text --match id:$KITTY_WINDOW_ID q) >/dev/null 2>&1 &"
    end
else
    # No visible session for this project. We can't nest a neovim in lazygit's
    # own terminal: editInTerminal is false (that's what removes the flash of
    # lazygit suspending), so lazygit keeps the screen and a nested TUI would
    # have nowhere to draw and would hang. Give it a kitty overlay of its own;
    # quitting it drops you back into lazygit, which is how nesting behaved.
    if test -n "$line"
        kitty @ launch --type=overlay-main --cwd=current --title=nvim \
            nvim +$line -- $files >/dev/null 2>&1
    else
        kitty @ launch --type=overlay-main --cwd=current --title=nvim \
            nvim -- $files >/dev/null 2>&1
    end
end
