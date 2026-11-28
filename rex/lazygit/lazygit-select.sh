#!/bin/sh
# Puts lazygit's Files panel on the file the nvim next to it is editing, if git
# sees a change in it (modified or new). Launched in the background by
# lazygit_toggle (rex/lazygit/lazygit.lua) when it opens or shows lazygit:
#
#   sh lazygit-select.sh <lazygit block> <nvim pid> <lazygit cwd> <new|show>
#
# Port of kitty/lazygit-toggle-full-screen.fish, which explains each step in
# more detail; `rex capture` and `rex send` stand in for kitty's get-text and
# send-text.
#
# lazygit can't be told which file to select, so it goes through its filter:
# `/<path>` narrows the tree to that one file, `>` drops onto it (always the
# last row) and <esc> restores the full list keeping the selection. Every step
# is confirmed on screen before the next, since a key that lands while lazygit
# re-renders is lost. The witness is the list footer: "N of M" counts the
# rows, and while a filter is on, the bottom line names the path.

BLOCK=$1 PID=$2 CWD=$3 MODE=$4
[ -n "$BLOCK" ] && [ -n "$PID" ] && [ -n "$CWD" ] || exit 0
# Run by the Rex server, whose PATH has neither Homebrew nor the rex CLI (it
# lives inside the app; Versions/Current follows updates).
PATH="/opt/homebrew/bin:$PATH:$HOME/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS"
HERE=$(dirname "$0")

# nvim sockets live at $TMPDIR/nvim.$USER/<random>/nvim.<pid>.0, and an nvim
# with a UI holds its socket in its `nvim --embed` child (same as
# lazygit-edit.fish).
TMP=${TMPDIR:-$(getconf DARWIN_USER_TEMP_DIR)}
RUNDIR="${TMP%/}/nvim.$USER"
FILE=
for pid in "$PID" $(pgrep -P "$PID"); do
	for sock in "$RUNDIR"/*/nvim."$pid".0; do
		[ -S "$sock" ] || continue
		FILE=$(nvim -u NONE -l "$HERE/lazygit-current-file.lua" "$sock" 2>/dev/null) && break 2
	done
done
[ -n "$FILE" ] || exit 0

cd "$CWD" || exit 0
ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
[ -n "$ROOT" ] || exit 0
# lazygit shows paths from the repo root. A file outside this repo isn't in
# its list.
REL=${FILE#"$ROOT"/}
[ "$REL" != "$FILE" ] || exit 0
# Only a file git sees a change in is in the Files panel.
[ -n "$(git status --porcelain -- "$FILE" 2>/dev/null)" ] || exit 0
# While a merge has conflicts lazygit shows only the conflicted files, so only
# one of those can be found. -z: otherwise git escapes non-ASCII paths.
UNMERGED=$(git diff --name-only -z --diff-filter=U 2>/dev/null | tr "\000" "\n")
if [ -n "$UNMERGED" ] && ! printf "%s\n" "$UNMERGED" | grep -qxF "$REL"; then
	exit 0
fi

# -s with the block too: a bare -b only looks in the caller's own session.
send() { printf "%s" "$1" | rex send -s "$BLOCK" -b "$BLOCK" >/dev/null 2>&1; }

# settled: the list has rows (lazygit blanks it while re-rendering). Leaves
# the screen in TXT and the footer's numbers in AT and OF. grep -a: a diff on
# screen can contain a NUL, and grep would call the text binary.
settled() {
	TXT=$(rex capture -s "$BLOCK" -b "$BLOCK" --trim 2>/dev/null)
	POS=$(printf "%s\n" "$TXT" | grep -aoE "[0-9]+ of [0-9]+" | head -1)
	AT=${POS%% of *}
	OF=${POS##* of }
	[ -n "$POS" ] && [ "$OF" -gt 0 ]
}
filtering() { printf "%s\n" "$TXT" | tail -1 | grep -aqF "$REL"; }

# Wait for lazygit to have loaded the list (on `new` it's still starting).
n=0
while [ $n -lt 100 ]; do
	settled && break
	sleep 0.02
	n=$((n + 1))
done

# Shown again: it may have been left on another panel, and its list may be
# older than the change. 1 jumps to Files (the first panel: the config hides
# Status), r refreshes it.
if [ "$MODE" = show ]; then
	send "1r"
	sleep 0.05
	n=0
	while [ $n -lt 40 ]; do
		settled && break
		sleep 0.02
		n=$((n + 1))
	done
fi

# Narrow to the file and drop onto it. `>` is idempotent, so it's repeated
# until the cursor is on the last row.
send "/$REL$(printf '\r')>"
n=0
while [ $n -lt 40 ]; do
	sleep 0.02
	if settled && filtering; then
		[ "$AT" = "$OF" ] && break
		send ">"
	fi
	n=$((n + 1))
done

# Back to the whole list. The escape can get lost too (read as Alt+key), so
# ask again every few rounds.
send "$(printf '\033')"
n=0
while [ $n -lt 40 ]; do
	sleep 0.02
	settled && ! filtering && break
	[ $((n % 8)) -eq 7 ] && send "$(printf '\033')"
	n=$((n + 1))
done

# Leaving the filter keeps the selection but doesn't scroll to it: a step up
# and back down makes the view follow. Not on the first row, where `k` has
# nowhere to go and `j` would end one below.
WANT=$AT
if [ -n "$WANT" ] && [ "$WANT" -gt 1 ]; then
	send "kj"
	n=0
	while [ $n -lt 15 ]; do
		n=$((n + 1))
		sleep 0.02
		settled || continue
		[ "$AT" = "$WANT" ] && break
		if [ "$AT" -lt "$WANT" ]; then send "j"; else send "k"; fi
	done
fi
