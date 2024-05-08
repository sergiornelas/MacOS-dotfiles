#!/usr/bin/env bash

NAME="headphones"
DEVICES="$(system_profiler SPBluetoothDataType -json -detailLevel basic 2>/dev/null | jq -rc '.SPBluetoothDataType[0].device_connected[] | select ( .[] | .device_minorType == "Headphones")' | jq '.[]')"
if [ "$DEVICES" = "" ]; then
  sketchybar -m --set $NAME drawing=off
else
  sketchybar -m --set $NAME drawing=on
  left="$(echo $DEVICES | jq -r .device_batteryLevelLeft)"
  right="$(echo $DEVICES | jq -r .device_batteryLevelRight)"
  case="$(echo $DEVICES | jq -r .device_batteryLevelCase)"

  if [[ "$left" == "null"  ]]; then
    left="󰂭"
  fi

  if [[ "$right" == "null" ]]; then
    right="󰂭"
  fi

  if [[ "$case" == "null" ]]; then
    sketchybar -m --set $NAME label="$left $right"
    exit 0
  fi

  sketchybar -m --set $NAME label="$left $right $case"
fi
