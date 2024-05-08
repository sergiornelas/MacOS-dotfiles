#!/bin/sh

IP_ADDRESS=$(scutil --nwi | grep address | sed 's/.*://' | tr -d ' ' | head -1)
IS_VPN=$(scutil --nwi | grep -m1 'utun' | awk '{ print $1 }')

if [[ $IS_VPN != "" ]]; then
	COLOR="0xFFD79921"
	ICON=🔒
elif [[ $IP_ADDRESS != "" ]]; then
	COLOR="0xFF689D6A"
	ICON=
else
	COLOR="0xFFCC241D"
	ICON=󱚼
fi

sketchybar --set $NAME icon.color=$COLOR icon.y_offset=2 icon=$ICON
