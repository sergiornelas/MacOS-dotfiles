#!/bin/bash

# Claude Code sessions running in kitty, hidden when there are none: the label
# is how many, the icon turns red when one needs input. Clicking toggles a
# popup listing them, attention first; clicking a row focuses that window.
# Data comes from kitty/agent-tabs.sh, refreshed on agents_update, which the
# Claude hook (claude/hooks/sketchybar-status.sh) triggers on every change.
# The popup rows run this same script for their hover events.

AGENT_TABS="$HOME/.config/kitty/agent-tabs.sh"
AUTO_STAMP="/tmp/sketchybar-agents-popup"
AUTO_SECONDS=5.5

RED=0xFFFB4934
BLUE=0xFF458588
GREY=0xFF928374
LABEL=0xFFEBDBB2
HOVER=0xFF504945
# Claude icon (nf U+EC82), drawn in the row icon with Hack Nerd Font: Iosevka
# lacks it and the system fallback does not pick a Nerd Font
CLAUDE_ICON=$'\xee\xb2\x82'

case "$SENDER" in
mouse.entered)
  sketchybar --set "$NAME" background.color=$HOVER
  exit 0
  ;;
mouse.exited | mouse.exited.global)
  sketchybar --set "$NAME" background.color=0x00000000
  exit 0
  ;;
# There is no global click event, a focus change is the closest: clicking any
# other window or app closes the popup
front_app_switched | window_focus | space_change)
  sketchybar --set "$NAME" popup.drawing=off
  exit 0
  ;;
esac

# Removing every row closes the popup, so its state is put back once the rows
# are rebuilt
POPUP=$(sketchybar --query "$NAME" | jq -r '.popup.drawing')
if [[ "$SENDER" == "mouse.clicked" ]]; then
  [[ "$POPUP" == "on" ]] && POPUP=off || POPUP=on
  # A click takes over a menu that popped up by itself, so it is not closed
  rm -f "$AUTO_STAMP"
fi

WINDOWS=$("$AGENT_TABS" --json 2>/dev/null)
jq -e 'type == "array"' >/dev/null 2>&1 <<<"$WINDOWS" || WINDOWS="[]"

COUNT=$(jq 'length' <<<"$WINDOWS")
WAITING=$(jq '[.[] | select(.waiting > 0)] | length' <<<"$WINDOWS")

COLOR=$BLUE
((WAITING > 0)) && COLOR=$RED

# Without sessions the whole item is hidden
DRAWING=on
if ((COUNT == 0)); then
  DRAWING=off
  POPUP=off
fi

# The Claude hook passes ATTENTION=1 when a session starts waiting for input
# while its window is not focused: the menu pops up for a few seconds. The
# stamp lets only the latest pop up close it, and a click cancel the close
if [[ "${ATTENTION:-0}" == 1 ]] && ((COUNT > 0)); then
  POPUP=on
  echo $$ >"$AUTO_STAMP"
  (
    sleep $AUTO_SECONDS
    if [[ "$(cat "$AUTO_STAMP" 2>/dev/null)" == "$$" ]]; then
      rm -f "$AUTO_STAMP"
      sketchybar --set "$NAME" popup.drawing=off
    fi
  ) >/dev/null 2>&1 &
fi

# Every row gets the width of the longest one, so the hover backgrounds line
# up. Iosevka Bold 15.5 advances ~8px per character
MAX_CHARS=45
LONGEST=$(jq --argjson max $MAX_CHARS '[.[].display_title | length] + [18] | max | [., $max] | min' <<<"$WINDOWS")
ROW_WIDTH=$((40 + LONGEST * 8 + 16))

ARGS=(--set "$NAME" drawing=$DRAWING label="$COUNT" icon.color="$COLOR")
ARGS+=(--remove '/agents\.row\..*/')

row() {
  ARGS+=(
    --add item "agents.row.$1" "popup.$NAME"
    --set "agents.row.$1"
    width=$ROW_WIDTH
    icon="$2"
    icon.color="$3"
    icon.font="Hack Nerd Font:Bold:15.5"
    icon.padding_left=8
    icon.padding_right=6
    label="$4"
    label.color="$LABEL"
    label.max_chars=$MAX_CHARS
    background.drawing=on
    background.color=0x00000000
    background.height=24
    background.corner_radius=5
    script="$0"
    "${@:5}"
    --subscribe "agents.row.$1" mouse.entered mouse.exited
  )
}

while IFS=$'\t' read -r ID STATUS TITLE; do
  [[ -n "$ID" ]] || continue
  case "$STATUS" in
  attention) ROW_ICON="!" ROW_COLOR=$RED ;;
  running) ROW_ICON=">" ROW_COLOR=$BLUE ;;
  *) ROW_ICON="-" ROW_COLOR=$GREY ;;
  esac
  row "$ID" "$ROW_ICON $CLAUDE_ICON" "$ROW_COLOR" "$TITLE" \
    click_script="sketchybar --set $NAME popup.drawing=off; $AGENT_TABS --focus $ID"
done < <(jq -r '.[] | [.id, .status, .display_title] | @tsv' <<<"$WINDOWS")

ARGS+=(--set "$NAME" popup.drawing="$POPUP")

# Without rows the --remove regex has no match and only warns
sketchybar "${ARGS[@]}" >/dev/null
