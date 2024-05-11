#!/bin/bash

WINDOW_TITLE=$(yabai -m query --windows --window | jq -r '.title')

if [[ $WINDOW_TITLE = "" ]]; then
  WINDOW_TITLE="אנשים שלא חושבים על איך הם רוצים לחיות בסופו של דבר יחיו כמו שהם חושבים"
fi

if [[ ${#WINDOW_TITLE} -gt 121 ]]; then
  WINDOW_TITLE=$(echo "$WINDOW_TITLE" | cut -c 1-120)
  sketchybar --set title label="$WINDOW_TITLE"…
  exit 0
fi

sketchybar --set title label="$WINDOW_TITLE"
