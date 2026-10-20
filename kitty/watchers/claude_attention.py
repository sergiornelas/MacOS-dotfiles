# Clears Claude Code attention once its kitty window stays focused for two
# seconds, so the sketchybar agents item and the cmd+a picker
# (kitty/agent-tabs.sh) stop flagging it.
# Adapted from github.com/linkarzu/dotfiles-latest (kitty/watchers).
#
# claude/hooks/sketchybar-status.sh raises attention through the
# claude_waiting user var when a session finishes or needs input while its
# window is not focused.

import subprocess
from typing import Any

from kitty.boss import Boss
from kitty.fast_data_types import add_timer, current_focused_os_window_id, get_boss
from kitty.window import Window

ack_delay = 2.0
sketchybar_bin = "/opt/homebrew/bin/sketchybar"


def waiting(window: Window) -> bool:
    return window.user_vars.get("claude_waiting", "0") not in ("", "0")


def acknowledge(window_id: int) -> None:
    boss = get_boss()
    window = boss.window_id_map.get(window_id)
    if window is None or not waiting(window):
        return
    if boss.active_window is not window or current_focused_os_window_id() != window.os_window_id:
        return

    window.set_user_var("claude_waiting", "0")
    window.set_user_var("claude_reason", "none")
    subprocess.Popen(
        [sketchybar_bin, "--trigger", "agents_update"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def on_set_user_var(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    # kitty/tab_bar.py colors the Claude icon from these vars, a title change is
    # the only other thing that redraws the tab bar
    if not data.get("key", "").startswith("claude_"):
        return
    tm = boss.os_window_map.get(window.os_window_id)
    if tm is not None:
        tm.mark_tab_bar_dirty()


def on_focus_change(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    if not data.get("focused") or not waiting(window):
        return
    window_id = window.id
    add_timer(lambda timer_id: acknowledge(window_id), ack_delay, False)
