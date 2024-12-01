#!/bin/bash

WINDOW_TITLE=$(yabai -m query --windows --window | jq -r '.title')

if [[ $WINDOW_TITLE = "" ]]; then
  WINDOW_TITLE="אנשים שלא חושבים על איך הם רוצים לחיות בסופו של דבר יחיו כמו שהם"
fi

if [[ $WINDOW_TITLE = "fish" ]]; then
  WINDOW_TITLE="Vim"
fi

# In browser, filter search remove additional text
if [[ $WINDOW_TITLE == *"Find in page"* ]]; then
  exit 0
fi

# Cut the window title if is large in order to fit before the notch
if [[ ${#WINDOW_TITLE} -gt 84 ]]; then
  WINDOW_TITLE=$(echo "$WINDOW_TITLE" | cut -c 1-83)
  sketchybar --set title label="$WINDOW_TITLE"…
  exit 0
fi

sketchybar --set title label="$WINDOW_TITLE"
