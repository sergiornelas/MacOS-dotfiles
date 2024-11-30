#!/bin/bash

WINDOW_TITLE=$(yabai -m query --windows --window | jq -r '.title')

# Title contains the string Brave
# if [[ $WINDOW_TITLE == *"Brave"* ]]; then
#   WINDOW_TITLE="Brave Browser"
# fi

if [[ $WINDOW_TITLE = "" ]]; then
  WINDOW_TITLE="אנשים שלא חושבים על איך הם רוצים לחיות בסופו של דבר יחיו כמו שהם"
fi

if [[ $WINDOW_TITLE = "fish" ]]; then
  WINDOW_TITLE="Vim"
fi

# verifica el tema de las mayusculas
if [[ ${#WINDOW_TITLE} -gt 86 ]]; then
  WINDOW_TITLE=$(echo "$WINDOW_TITLE" | cut -c 1-85)
  sketchybar --set title label="$WINDOW_TITLE"…
  exit 0
fi

sketchybar --set title label="$WINDOW_TITLE"
