#!/bin/bash

WINDOW_TITLE=$(yabai -m query --windows --window | jq -r '.title')

if [[ $WINDOW_TITLE = "" ]]; then
  WINDOW_TITLE="אנשים שלא חושבים על איך הם רוצים לחיות בסופו של דבר יחיו כמ"
fi

if [[ $WINDOW_TITLE = "fish" ]]; then
  WINDOW_TITLE="Vim"
fi

# In browser, filter search remove additional text
if [[ $WINDOW_TITLE == *"Find in page"* ]]; then
  exit 0
fi

DISPLAY_COUNT=$(yabai -m query --displays | jq 'length')

# If there is only one display (builtin), get the number of spaces on that display
if [ "$DISPLAY_COUNT" -eq 1 ]; then
  SPACES=$(yabai -m query --spaces | jq '. | length')
else
  # If there are multiple displays, get the number of spaces on display 2
  SPACES=$(yabai -m query --displays | jq '.[1].spaces | length')
fi

# Adjust the title based on the number of spaces
if [[ "$SPACES" -eq 1 && ${#WINDOW_TITLE} -gt 88 ]]; then
  WINDOW_TITLE=$(echo "$WINDOW_TITLE" | cut -c 1-87)
  sketchybar --set title label="$WINDOW_TITLE"…
  exit 0
fi

if [[ "$SPACES" -eq 2 && ${#WINDOW_TITLE} -gt 83 ]]; then
  WINDOW_TITLE=$(echo "$WINDOW_TITLE" | cut -c 1-82)
  sketchybar --set title label="$WINDOW_TITLE"…
  exit 0
fi

if [[ "$SPACES" -eq 3 && ${#WINDOW_TITLE} -gt 77 ]]; then
  WINDOW_TITLE=$(echo "$WINDOW_TITLE" | cut -c 1-76)
  sketchybar --set title label="$WINDOW_TITLE"…
  exit 0
fi

if [[ "$SPACES" -eq 4 && ${#WINDOW_TITLE} -gt 71 ]]; then
  WINDOW_TITLE=$(echo "$WINDOW_TITLE" | cut -c 1-70)
  sketchybar --set title label="$WINDOW_TITLE"…
  exit 0
fi

sketchybar --set title label="$WINDOW_TITLE"
