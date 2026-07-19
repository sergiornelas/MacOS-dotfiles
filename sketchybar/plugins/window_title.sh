#!/bin/bash

# Trailing-edge debounce: coalesce bursts of title_change events (rapid tab
# switching, apps with live/dynamic titles) so only the LAST event in a burst
# does the actual work. Each invocation stamps this file with its PID, waits,
# then bails out if a newer invocation has overwritten the stamp meanwhile.
# PID is used as the token because macOS `date` has no millisecond support.
DEBOUNCE_STAMP="/tmp/sketchybar_window_title.debounce"
echo $$ >"$DEBOUNCE_STAMP"
sleep 0.19
[[ "$(cat "$DEBOUNCE_STAMP" 2>/dev/null)" == "$$" ]] || exit 0

WINDOW_INFO=$(yabai -m query --windows --window)
CURRENT_APP=$(echo "$WINDOW_INFO" | jq -r '.app')
WINDOW_TITLE=$(echo "$WINDOW_INFO" | jq -r '.title')

if [[ $CURRENT_APP = "kitty" ]]; then
  TERMINAL_NUM_PANES=$(ps | grep -v scratch.js | awk 'NR > 1 {print $2}' | sort | uniq | wc -l | awk '{$1=$1};1')
  if [[ $WINDOW_TITLE = "lazygit" ]]; then
    WINDOW_TITLE="git 󰂓 | 󱂬 $TERMINAL_NUM_PANES"
  elif [[ $WINDOW_TITLE == *"Grab "* ]]; then
    WINDOW_TITLE="Vim mode 󰚺 | 󱂬 $TERMINAL_NUM_PANES"
  elif [[ $WINDOW_TITLE == *"Last command output"* ]]; then
    WINDOW_TITLE="Last command output 󱙬  | 󱂬 $TERMINAL_NUM_PANES"
  elif [[ $WINDOW_TITLE == *"kitten"* ]]; then
    WINDOW_TITLE="kitten 󰄛 "
  elif [[ $WINDOW_TITLE == *"Choose text"* ]]; then
    WINDOW_TITLE="Choose text 󰃵 "
  elif [[ $WINDOW_TITLE == *"OC | "* ]]; then
    WINDOW_TITLE="Opencode 󱚝 | 󱂬 $TERMINAL_NUM_PANES"
  elif [[ $TERMINAL_NUM_PANES -gt 1 ]]; then
    WINDOW_TITLE="$WINDOW_TITLE | 󱂬 $TERMINAL_NUM_PANES"
  fi
fi

# Ghostty:
# if [[ $CURRENT_APP = "Ghostty" ]]; then
#   TERMINAL_NUM_PANES=$(ps | grep -v scratch.js | awk 'NR > 1 {print $2}' | sort | uniq | wc -l | awk '{$1=$1};1')
#   if [[ $TERMINAL_NUM_PANES -gt 1 ]]; then
#     WINDOW_TITLE="$WINDOW_TITLE 󰆍 $TERMINAL_NUM_PANES"
#   fi
# fi

if [[ $WINDOW_TITLE = "" ]]; then
  WINDOW_TITLE="אנשים שלא חושבים על איך הם רוצים לחיות בסופו של דבר יחיו כמ"
fi

# In browser, filter search remove additional text
if [[ $WINDOW_TITLE == *"Find in page"* ]]; then
  exit 0
fi

DISPLAYS_INFO=$(yabai -m query --displays)
DISPLAY_COUNT=$(echo "$DISPLAYS_INFO" | jq 'length')

# If there is only one display (builtin), get the number of spaces on that display
if [ "$DISPLAY_COUNT" -eq 1 ]; then
  SPACES=$(yabai -m query --spaces | jq '. | length')
else
  # If there are multiple displays, get the number of spaces on display 2
  SPACES=$(echo "$DISPLAYS_INFO" | jq '.[1].spaces | length')
fi

# Adjust the title based on the number of spaces
if [[ "$SPACES" -eq 1 && ${#WINDOW_TITLE} -gt 88 ]]; then
  WINDOW_TITLE="${WINDOW_TITLE:0:87}…"
elif [[ "$SPACES" -eq 2 && ${#WINDOW_TITLE} -gt 83 ]]; then
  WINDOW_TITLE="${WINDOW_TITLE:0:82}…"
elif [[ "$SPACES" -eq 3 && ${#WINDOW_TITLE} -gt 77 ]]; then
  WINDOW_TITLE="${WINDOW_TITLE:0:76}…"
elif [[ "$SPACES" -eq 4 && ${#WINDOW_TITLE} -gt 71 ]]; then
  WINDOW_TITLE="${WINDOW_TITLE:0:70}…"
fi

sketchybar --set title label="$WINDOW_TITLE"
