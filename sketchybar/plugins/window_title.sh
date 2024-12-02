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
if [[ "$SPACES" -eq 1 && ${#WINDOW_TITLE} -gt 90 ]]; then
  WINDOW_TITLE=$(echo "$WINDOW_TITLE" | cut -c 1-89)
  sketchybar --set title label="$WINDOW_TITLE"…
  exit 0
fi

if [[ "$SPACES" -eq 2 && ${#WINDOW_TITLE} -gt 85 ]]; then
  WINDOW_TITLE=$(echo "$WINDOW_TITLE" | cut -c 1-84)
  sketchybar --set title label="$WINDOW_TITLE"…
  exit 0
fi

if [[ "$SPACES" -eq 3 && ${#WINDOW_TITLE} -gt 79 ]]; then
  WINDOW_TITLE=$(echo "$WINDOW_TITLE" | cut -c 1-78)
  sketchybar --set title label="$WINDOW_TITLE"…
  exit 0
fi

if [[ "$SPACES" -eq 4 && ${#WINDOW_TITLE} -gt 73 ]]; then
  WINDOW_TITLE=$(echo "$WINDOW_TITLE" | cut -c 1-72)
  sketchybar --set title label="$WINDOW_TITLE"…
  exit 0
fi

sketchybar --set title label="$WINDOW_TITLE"
