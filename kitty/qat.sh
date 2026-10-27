#!/usr/bin/env bash

# Opens a picker in a floating quick access panel (kitten quick-access-terminal),
# from any app, kitty included, through skhd (cmd+space and cmd+;).
# Adapted from github.com/linkarzu/dotfiles-latest (561-skhdQatOpencode.sh).
#
#   qat.sh sessions   session picker (session-picker.fish)
#   qat.sh agents     Claude Code agents picker (agent-tabs.sh)
#
# The panel hides when the picker exits (enter or esc), and pressing the key
# again while it's open hides it too. It stays alive hidden, so it shows
# instantly; only the first use pays for starting it (~1s). Restart the panels
# after editing this script or the pickers:
#   pkill -f 'kitty-quick-access.*--instance-group=picker-'

set -euo pipefail

export PATH="/opt/homebrew/bin:$PATH"
kitty_bin="/Applications/kitty.app/Contents/MacOS/kitty"
kitten_bin="/Applications/kitty.app/Contents/MacOS/kitten"
kitty_dir="$HOME/.config/kitty"

case "${1:-}" in
sessions | agents) ;;
*)
  echo "usage: qat.sh sessions|agents" >&2
  exit 1
  ;;
esac

group="picker-$1"
# Exists while the picker is on screen. In /tmp since skhd and kitty may not
# share TMPDIR
picking="/tmp/qat-$group.picking"

# Through fish, whose config sets FZF_DEFAULT_OPTS (fzf bindings). The panel
# only has the main kitty's environment, which never went through fish
picker() {
  case "$1" in
  sessions) fish "$kitty_dir/session-picker.fish" ;;
  agents) fish -c "$kitty_dir/agent-tabs.sh" ;;
  esac
}

# Runs inside the panel: show the picker, hide when it exits, wait for the
# next keypress from qat.sh
if [[ "${2:-}" == "--loop" ]]; then
  # The panel is its own process and would outlive the main kitty (pid in $3),
  # so close it when that kitty quits. $PPID is the panel.
  panel="$PPID"
  (
    while kill -0 "$3" 2>/dev/null; do sleep 2; done
    kill "$panel"
  ) &
  while true; do
    touch "$picking"
    "$kitten_bin" @ resize-os-window --self --action=show
    picker "$1" || true
    rm -f "$picking"
    # Blank, so showing it again doesn't flash the old list
    clear
    "$kitten_bin" @ resize-os-window --self --action=hide
    IFS= read -rsn1 _
  done
fi

# A panel opens on whatever display macOS picks, not the focused one, so it
# gets the focused display by name (output-name). yabai's display id is the
# NSScreenNumber, whose localizedName is that name. Names are cached because
# asking macOS takes ~0.1s.
focused_display_name() {
  local id cache="/tmp/qat-displays"
  id="$(yabai -m query --displays --display 2>/dev/null | jq -r '.id')" || return 0
  if ! grep -q "^$id"$'\t' "$cache" 2>/dev/null; then
    osascript -l JavaScript >"$cache" <<'EOF'
ObjC.import("AppKit")
const screens = $.NSScreen.screens
const lines = []
for (let i = 0; i < screens.count; i++) {
  const screen = screens.objectAtIndex(i)
  lines.push(screen.deviceDescription.objectForKey("NSScreenNumber").js + "\t" + screen.localizedName.js)
}
lines.join("\n")
EOF
  fi
  grep "^$id"$'\t' "$cache" | cut -f2
}

pid="$(pgrep -f "kitty-quick-access.*--instance-group=$group" | head -1 || true)"
output="$(focused_display_name || true)"

if [[ -n "$pid" ]]; then
  socket="unix:/tmp/kitty-$pid"
  if [[ -e "$picking" ]]; then
    # Open: abort the picker, the loop hides the panel
    "$kitten_bin" @ --to "$socket" send-key escape
  else
    if [[ -n "$output" ]]; then
      "$kitten_bin" @ --to "$socket" resize-os-window --action=os-panel \
        --incremental "output-name=$output"
    fi
    "$kitten_bin" @ --to "$socket" send-key enter
  fi
  exit 0
fi

# First use: launched by the main kitty so the panel inherits its environment
# (PATH with fzf, jq...). Without a main kitty there is nothing to pick.
rm -f "$picking"
socket="$("$kitty_dir/main-socket.sh" 2>/dev/null)" || exit 0
# kitty @ action splits its arguments again on spaces, hence the inner quotes
"$kitty_bin" @ --to "$socket" action launch --type=background \
  kitten quick-access-terminal --config "$kitty_dir/qat-picker.conf" \
  ${output:+-o "'output_name=$output'"} \
  --instance-group "$group" "$kitty_dir/qat.sh" "$1" --loop "${socket##*-}"
