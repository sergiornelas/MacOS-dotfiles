#!/bin/bash
	
HAS_ZOOM=$(yabai -m query --windows --window | jq -r '."has-parent-zoom"')

if [[ $HAS_ZOOM = "true" ]]; then
  lazygit
  exit 0
fi

yabai -m window --toggle zoom-fullscreen && lazygit
