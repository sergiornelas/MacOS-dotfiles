# lazygit's `e` inside Rex (os.edit in rex/lazygit/lazygit.yml).
#
# Opens the files in the tab's nvim: first the one in the pane lazygit was
# opened from, then any other (rex/lazygit/lazygit.lua, lazygit_editors). Rex gives each
# nvim's pid, so its socket is known without asking the other nvims (a hung one
# elsewhere can't freeze lazygit). Then it minimizes lazygit and focuses that
# nvim; with no nvim in the tab, it opens one in a split.
#
# Usage: fish lazygit-edit.fish [--line N] <file>...

set -l line
if test (count $argv) -ge 2 -a "$argv[1]" = --line
    set line $argv[2]
    set -e argv[1..2]
end
set -l files $argv
test (count $files) -eq 0; and exit 0

set -l lua_args
test -n "$line"; and set lua_args --line $line

# nvim sockets live at $TMPDIR/nvim.$USER/<random>/nvim.<pid>.0
set -l tmp $TMPDIR
test -n "$tmp"; or set tmp (getconf DARWIN_USER_TEMP_DIR)
set -l rundir (string trim -r -c / -- $tmp)/nvim.$USER

for editor in (rex do -b $REX_BLOCK lazygit_editors --json 2>/dev/null | jq -r '.editors[] | "\(.block_id) \(.pid)"')
    set -l parts (string split ' ' -- $editor)
    # An nvim with a UI holds its socket in its `nvim --embed` child.
    for pid in $parts[2] (pgrep -P $parts[2])
        for sock in $rundir/*/nvim.$pid.0
            if nvim -u NONE -l (status dirname)/lazygit-open.lua $sock $lua_args $files
                rex do -b $REX_BLOCK lazygit_show_editor --args (jq -nc --arg b $parts[1] '{block_id: $b}') >/dev/null
                exit 0
            end
        end
    end
end

# No nvim in the tab: a new one in a split next to the origin pane.
set -l cmd nvim
test -n "$line"; and set -a cmd +$line
set -a cmd -- $files
rex do -b $REX_BLOCK lazygit_show_editor \
    --args (jq -nc --arg cwd $PWD '{argv: $ARGS.positional, cwd: $cwd}' --args $cmd) >/dev/null
