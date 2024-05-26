#!/bin/bash
	
HAS_ZOOM=$(yabai -m query --windows --window | jq -r '."has-parent-zoom"')

function lazygit_with_post_command() {
  lazygit
  yabai -m window --toggle zoom-fullscreen
}

if [[ $HAS_ZOOM = "true" ]]; then
  lazygit
  exit 0
fi

yabai -m window --toggle zoom-fullscreen && lazygit_with_post_command
