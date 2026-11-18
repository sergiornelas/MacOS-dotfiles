#!/usr/bin/env bash

# Prints the name of the display that has focus, for the output_name of the
# kitten panels (qat.sh, float_term.sh): a panel opens on whatever display
# macOS picks, not the focused one.
#
# yabai's display id is the NSScreenNumber, whose localizedName is that name.
# Names are cached because asking macOS takes ~0.1s. Prints nothing when it
# can't tell.

export PATH="/opt/homebrew/bin:$PATH"
cache="/tmp/qat-displays"

id="$(yabai -m query --displays --display 2>/dev/null | jq -r '.id')" || exit 0
[[ -n "$id" && "$id" != "null" ]] || exit 0

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
