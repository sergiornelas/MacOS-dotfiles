# Fuzzy session picker (cmd+space), replaces the built-in goto_session menu.
# Runs in a quick access panel (qat.sh), so it talks to the main kitty.
# Lists every file in sessions/: open sessions first (most recently focused
# on top, so enter jumps back to the previous one; the current session closes
# the group), then the rest alphabetically. Switches via remote control.
# Open sessions show their pane count across all their tabs.
set sessions_dir ~/.config/kitty/sessions
set socket (~/.config/kitty/main-socket.sh); or exit

# Open sessions as "name<TAB>is_current<TAB>panes", most recently focused first.
# A tab belongs to the session of any of its windows; panes are counted as
# window groups, so overlays (lazygit...) don't add to the count.
set open (kitty @ --to $socket ls | jq -r '
  [.[] | . as $os | .tabs[]
    | ([.windows[].session_name // "" | select(. != "")] | first) as $name
    | select($name != null)
    | {name: $name, t: ([.windows[].last_focused_at // 0] | max),
       cur: ($os.last_focused and .is_active), panes: (.groups | length)}]
  | group_by(.name)
  | map({name: .[0].name, t: (map(.t) | max), cur: (map(.cur) | any), panes: (map(.panes) | add)})
  | sort_by(-.t) | .[] | "\(.name)\t\(.cur)\t\(.panes)"')

set files (path change-extension '' (path basename $sessions_dir/*.kitty-session))

set green (set_color b8ba25)
set gray (set_color 928373)
set yellow (set_color fabc2e)
set reset (set_color normal)

# Pad open session names so the pane counts line up
set width (string split -f1 \t -- $open | string length | sort -n | tail -1)

set open_names
set current
set lines
for entry in $open
    set parts (string split \t -- $entry)
    set name $parts[1]
    set padded (string pad -r -w $width -- $name)
    set -a open_names $name
    if test "$parts[2]" = true
        set current "$name\t$yellow● $padded $gray($parts[3]) (actual)$reset"
    else
        set -a lines "$name\t$green● $reset$padded $gray($parts[3])$reset"
    end
end

if test -n "$current"
    set -a lines $current
end

for name in $files
    if not contains -- $name $open_names
        set -a lines "$name\t$gray○ $reset$name"
    end
end

set choice (printf '%b\n' $lines | fzf --ansi --delimiter=\t --with-nth=2.. \
    --prompt='session > ' --pointer='▶' --no-info --no-scrollbar \
    --color='bg+:#272727,fg+:#ebdbb2,hl:#fabc2e,hl+:#fabc2e,prompt:#fb4833,pointer:#fb4833,gutter:-1' |
    string split -f1 \t)

if test -n "$choice"
    kitty @ --to $socket action goto_session $sessions_dir/$choice.kitty-session
    open -a kitty
end