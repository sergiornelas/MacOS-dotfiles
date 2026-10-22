# Closes the picker of a quick access panel (kitty/qat.sh) once the panel
# loses focus: another window, app or desktop. Esc aborts fzf, and the loop in
# qat.sh then hides the panel as usual. Loaded only by the panels, through
# kitty/qat-picker.conf.

from typing import Any

from kitty.boss import Boss
from kitty.window import Window


def picking(window: Window) -> bool:
    # Only while fzf runs. Hiding the panel also loses focus, and an Esc then
    # would reach the loop's read and show the panel again
    return any(
        (p.get("cmdline") or [""])[0].split("/")[-1] == "fzf"
        for p in window.child.foreground_processes
    )


def on_focus_change(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    if not data["focused"] and picking(window):
        window.write_to_child("\x1b")
