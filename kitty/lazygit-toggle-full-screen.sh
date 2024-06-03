#!/bin/bash

HAS_ZOOM=$(yabai -m query --windows --window | jq -r '."has-parent-zoom"')

if [[ $HAS_ZOOM = "true" ]]; then
  lazygit
  exit 0
else
  yabai -m window --toggle zoom-fullscreen
  lazygit
  HAS_ZOOM_AFTER_LAZYGIT=$(yabai -m query --windows --window | jq -r '."has-parent-zoom"')
  if [[ $HAS_ZOOM_AFTER_LAZYGIT = "true" ]]; then
    yabai -m window --toggle zoom-fullscreen
  fi
fi
