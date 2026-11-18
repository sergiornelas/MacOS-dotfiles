#!/usr/bin/env bash

# Floating terminal toggled with kitty_mod+; (kitty.conf), opened in the
# directory of the active window: the one running in it, neovim included
# (launch --cwd=current runs this script there).
#
# A kitten quick-access-terminal panel (float-term.conf) that stays alive while
# hidden, so it shows instantly and keeps its history; only the first use pays
# for starting it (~1s). Each time it is shown its shell cds to the current
# directory, unless it is busy running something. It hides on kitty_mod+;
# again (the panel reads kitty.conf, so the key works inside it too), when it
# loses focus, and it closes with exit.

set -u

export PATH="/opt/homebrew/bin:$PATH"
kitten_bin="/Applications/kitty.app/Contents/MacOS/kitten"
group="float-term"
# Fixed address: --listen-on does not append the pid for this kitten
socket="unix:/tmp/kitty-$group"
cwd="$PWD"

state="$("$kitten_bin" @ --to "$socket" ls 2>/dev/null |
  jq -c '.[0] | {focused: .is_focused, shell: .tabs[0].windows[0] | {at_prompt, cwd}}')"

# First use: started from here, a child of the main kitty, so the panel gets
# its environment. A new panel opens on whatever display macOS picks, so it is
# told the focused one (later shows move it to the active monitor on their own)
if [[ -z "$state" ]]; then
  output="$("$HOME/.config/kitty/focused-display.sh")"
  exec "$kitten_bin" quick-access-terminal --config "$HOME/.config/kitty/float-term.conf" \
    ${output:+-o "output_name=$output"} --instance-group "$group" --listen-on "$socket"
fi

# With hide_on_focus_loss it is only on screen while focused
if [[ "$(jq -r '.focused' <<<"$state")" == "true" ]]; then
  "$kitten_bin" @ --to "$socket" resize-os-window --action=hide
  exit 0
fi

# cd only at an idle prompt, not into a program running there. ctrl-u first
# clears anything left half typed. No leading space: fish ate it with the
# next character
if [[ "$(jq -r '.shell.at_prompt' <<<"$state")" == "true" &&
  "$(jq -r '.shell.cwd' <<<"$state")" != "$cwd" ]]; then
  # fish quotes the path for itself, whatever it contains
  quoted="$(fish --no-config -c 'string escape -- $argv[1]' "$cwd")"
  "$kitten_bin" @ --to "$socket" send-text "\\x15cd $quoted\\r"
fi

# Hidden first, so the toggle below always shows it, on the display in use
# (quick-access-terminal moves it to the active monitor when showing it)
"$kitten_bin" @ --to "$socket" resize-os-window --action=hide
exec "$kitten_bin" quick-access-terminal --config "$HOME/.config/kitty/float-term.conf" \
  --instance-group "$group" --listen-on "$socket"
