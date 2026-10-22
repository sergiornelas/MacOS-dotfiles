#!/usr/bin/env bash

# Prints the remote control socket of the main kitty (unix:/tmp/kitty-PID).
# Quick access panels (qat.sh) are kitty instances too and open their own
# /tmp/kitty-* sockets, so KITTY_LISTEN_ON or the first socket found could
# point at a panel instead of the main kitty.
# Adapted from github.com/linkarzu/dotfiles-latest (549-kittyMainSocket.sh).

set -euo pipefail

kitty_bin="/Applications/kitty.app/Contents/MacOS/kitty"

for sock in /tmp/kitty-*; do
  [[ -S "$sock" ]] || continue
  pid="${sock##*-}"
  command="$(ps -p "$pid" -o command= 2>/dev/null || true)"
  # Panels run as kitty-quick-access, only the main binary matches
  if [[ "$command" == "$kitty_bin" || "$command" == "$kitty_bin "* ]]; then
    printf 'unix:%s\n' "$sock"
    exit 0
  fi
done

echo "No main kitty socket found." >&2
exit 1
