# kitty/tab_bar.py names a pane after its foreground program (nvim, lazygit)
# or "terminal" at the shell prompt, but kitty only redraws the tab bar when
# something it tracks changes, such as the title. fish reports a command and
# sets the title before the program is exec'd, so that redraw still sees fish,
# and nvim never sets the title afterwards. This redraws the tab bar again a
# moment after the shell integration reports a command starting. Not when it
# stops: back at the prompt fish sets the title, and that redraws on its own.

from typing import Any

from kitty.boss import Boss
from kitty.fast_data_types import add_timer, get_boss
from kitty.window import Window

# seconds after the report; the program is usually running by the first one
DELAYS = (0.1, 0.5)


def refresh_tab_bar(os_window_id: int) -> None:
    tm = get_boss().os_window_map.get(os_window_id)
    if tm is not None:
        tm.mark_tab_bar_dirty()


def on_cmd_startstop(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    if not data.get("is_start"):
        return
    os_window_id = window.os_window_id
    for delay in DELAYS:
        add_timer(lambda timer_id: refresh_tab_bar(os_window_id), delay, False)
