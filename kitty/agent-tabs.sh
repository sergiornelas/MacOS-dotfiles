#!/usr/bin/env bash

# Claude Code windows across kitty (cmd+;), attention first. Also feeds the
# sketchybar agents item (sketchybar/plugins/agents.sh).
# Adapted from github.com/linkarzu/dotfiles-latest (kitty-opencode-sessions.sh).
#
#   agent-tabs.sh            fzf picker, enter focuses the window
#   agent-tabs.sh --json     agent windows as JSON
#   agent-tabs.sh --focus ID focus window ID and clear its attention
#
# Status comes from the user vars published by
# claude/hooks/sketchybar-status.sh: claude_waiting (needs input), claude_busy
# (working) and claude_reason (permission, question, done, error).

set -euo pipefail

export PATH="/opt/homebrew/bin:$PATH"
kitty_bin="/Applications/kitty.app/Contents/MacOS/kitty"
sessions_dir="$HOME/.config/kitty/sessions"

# Always the main kitty: this picker runs in a quick access panel (qat.sh),
# whose KITTY_LISTEN_ON is the panel's own socket
kitty_socket() {
  "$HOME/.config/kitty/main-socket.sh"
}

agent_windows() {
  local socket=""
  socket="$(kitty_socket 2>/dev/null || true)"
  if [[ -z "$socket" ]]; then
    printf '[]\n'
    return 0
  fi

  "$kitty_bin" @ --to "$socket" ls 2>/dev/null | jq '
    def number: try tonumber catch 0;
    def is_claude:
      any(.foreground_processes[]?.cmdline[0]? | select(type == "string"); split("/")[-1] == "claude");
    [
      .[] as $os
      | $os.tabs[] as $tab
      | $tab.windows[]?
      | select(is_claude)
      | {
          id,
          title: ((.title // "Claude Code") | sub("^[^[:alnum:][:space:]]+[[:space:]]+"; "")),
          session_name: (.session_name // ""),
          cwd: (.cwd // ""),
          focused: (($os.is_focused // false) and ($tab.is_focused // false) and (.is_focused // false)),
          last_focused_at: (.last_focused_at // 0),
          busy: ((.user_vars.claude_busy // "0") | number),
          waiting: ((.user_vars.claude_waiting // "0") | number),
          reason: (.user_vars.claude_reason // "none")
        }
      | .display_title = (
          if .session_name == "" then .title
          else "\(.session_name) | \(.title)"
          end
        )
      | .status = (if .waiting > 0 then "attention" elif .busy > 0 then "running" else "idle" end)
    ]
    | sort_by(
        if .waiting > 0 then 0 elif .busy > 0 then 1 else 2 end,
        -.last_focused_at
      )
  '
}

focus_window() {
  local window_id="$1"
  local socket=""
  local window=""
  local session_name=""

  [[ "$window_id" =~ ^[0-9]+$ ]] || return 1
  window="$(agent_windows | jq -c --argjson id "$window_id" '.[] | select(.id == $id)')"
  if [[ -z "$window" ]]; then
    printf 'Agent window %s is no longer available.\n' "$window_id" >&2
    return 1
  fi

  socket="$(kitty_socket)"
  session_name="$(jq -r '.session_name' <<<"$window")"
  "$kitty_bin" @ --to "$socket" set-user-vars --match "id:${window_id}" \
    claude_waiting=0 claude_reason=none
  sketchybar --trigger agents_update >/dev/null 2>&1 || true
  if [[ -n "$session_name" && -f "$sessions_dir/$session_name.kitty-session" ]]; then
    "$kitty_bin" @ --to "$socket" action goto_session "$sessions_dir/$session_name.kitty-session"
  fi
  "$kitty_bin" @ --to "$socket" focus-window --match "id:${window_id}"
  open -a kitty
}

menu_lines() {
  local id status reason display_title cwd color marker
  local tilde="~"
  local reset=$'\033[0m'
  local red=$'\033[38;2;251;73;52m'
  local blue=$'\033[38;2;131;165;152m'
  local gray=$'\033[38;2;146;131;116m'
  # Claude icon (nf U+EC82), the trailing space lets kitty draw it two cells wide
  local claude=$'\xee\xb2\x82 '

  while IFS=$'\t' read -r id status reason display_title cwd; do
    [[ -n "$id" ]] || continue

    case "$status" in
    attention)
      color="$red"
      marker="[!]"
      ;;
    running)
      color="$blue"
      marker="[>]"
      reason="running"
      ;;
    *)
      color="$gray"
      marker="[-]"
      reason="idle"
      ;;
    esac

    printf '%s\t%s%s%s %s %s  %s%s  %s%s\n' "$id" "$color" "$marker" "$reset" \
      "$claude" "$display_title" "$gray" "${cwd/#$HOME/$tilde}" "$reason" "$reset"
  done < <(
    agent_windows | jq -r '.[] | [.id, .status, .reason, .display_title, .cwd] | @tsv'
  )
}

pick_window() {
  local lines=""
  local selection=""

  lines="$(menu_lines)"
  [[ -n "$lines" ]] || return 1

  selection="$(printf '%s\n' "$lines" | fzf --ansi --reverse --no-multi \
    --delimiter=$'\t' --with-nth=2.. \
    --prompt='Agent tabs > ' --pointer='▶' --no-scrollbar \
    --color='bg+:#272727,fg+:#ebdbb2,hl:#fabc2e,hl+:#fabc2e,prompt:#fb4833,pointer:#fb4833,gutter:-1')" || return 1
  [[ -n "$selection" ]] || return 1
  printf '%s\n' "${selection%%$'\t'*}"
}

case "${1:-}" in
--json)
  agent_windows
  ;;
--focus)
  [[ -n "${2:-}" ]] || exit 1
  focus_window "$2"
  ;;
*)
  window_id="$(pick_window || true)"
  [[ -n "$window_id" ]] || exit 0
  focus_window "$window_id"
  ;;
esac
