# Claude Code reports its own status to kitty through the Program Status
# Protocol (OSC 7501, kitty 0.50+): idle, working, blocked (kind question,
# permission or auth), done and error. kitty keeps those records per window
# (program_status in `kitten @ ls`), redraws the tab bar when they change and
# drops done/error once the window is seen, so kitty/tab_bar.py and
# kitty/agent-tabs.sh read them directly.
#
# This watcher only does what kitty does not:
# - refreshes the sketchybar agents item when a Claude window's status changes,
#   popping its menu up (ATTENTION=1) when one starts needing you while you are
#   looking elsewhere;
# - marks Claude windows with the user var claude=1 (the one
#   nvim/lua/plugins/claudecode.lua sets on the windows it opens): once a done
#   is seen kitty drops it and the window has no records left, but the tab bar
#   still has to know it is a Claude window;
# - drops a done/error record that arrives while its window is focused: you saw
#   it happen, it must not be flagged as soon as you look away. kitty only
#   drops them when the window gains focus or gets a key press.

import os
import subprocess
from typing import Any

from kitty.boss import Boss
from kitty.fast_data_types import add_timer, current_focused_os_window_id, get_boss
from kitty.window import Window

CLAUDE_APP = "claude-code"
sketchybar_bin = "/opt/homebrew/bin/sketchybar"

# window id -> last status sent to sketchybar, so only real changes refresh it
# (the records change with every tool Claude runs, their msg says which)
sent: dict[int, str] = {}
# windows whose done/error is being dropped right now, see drop_seen
dropping: set[int] = set()


def claude_status(records: list[dict[str, Any]]) -> tuple[str, str] | None:
    """(status, reason) of a window's Claude records, or None without any.

    Same priority as agent-tabs.sh: a turn that ends while background tasks
    still run keeps their working records, so it is not done yet.
    """
    records = [r for r in records if r.get("app") == CLAUDE_APP]
    if not records:
        return None
    states = {r.get("state") for r in records}
    for r in records:
        if r.get("state") == "blocked":
            return "attention", r.get("kind") or "input"
    if "working" in states:
        return "running", ""
    if "error" in states:
        return "attention", "error"
    if "done" in states:
        return "attention", "done"
    return "idle", ""


def is_focused(window: Window) -> bool:
    return get_boss().active_window is window and current_focused_os_window_id() == window.os_window_id


def refresh(popup: bool = False) -> None:
    try:
        subprocess.Popen(
            [sketchybar_bin, "--trigger", "agents_update", f"ATTENTION={int(popup)}"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except Exception:
        pass


def drop_seen(window_id: int) -> None:
    window = get_boss().window_id_map.get(window_id)
    if window is None:
        return
    # Dropping the records calls on_program_status_change again from inside
    # this call; `dropping` keeps that call from scheduling another drop
    dropping.add(window_id)
    try:
        window.program_status_seen_by_user()
    finally:
        dropping.discard(window_id)


def on_program_status_change(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    status = claude_status(data.get("program_status") or [])
    if status is None:
        if sent.pop(window.id, None) is not None:
            refresh()
        return
    if "claude" not in window.user_vars:
        window.set_user_var("claude", "1")
    state, reason = status
    focused = is_focused(window)
    if reason in ("done", "error") and focused and window.id not in dropping:
        window_id = window.id
        add_timer(lambda timer_id: drop_seen(window_id), 0, False)
        return
    key = f"{state}:{reason}"
    previous = sent.get(window.id, "")
    if key == previous:
        return
    sent[window.id] = key
    # Only the first request pops the menu up, not a question that turns into
    # a permission prompt
    refresh(popup=state == "attention" and not focused and not previous.startswith("attention"))


# Claude run from a shell (fish shell integration reports the command): the
# window stops being a Claude window when it exits
def on_cmd_startstop(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    if data.get("is_start") or "claude" not in window.user_vars:
        return
    words = (data.get("cmdline") or "").split()
    if words and os.path.basename(words[0]) == "claude":
        window.set_user_var("claude", None)
        # A user var change does not redraw the tab bar on its own
        tm = boss.os_window_map.get(window.os_window_id)
        if tm is not None:
            tm.mark_tab_bar_dirty()


def on_close(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    if sent.pop(window.id, None) is not None:
        refresh()
