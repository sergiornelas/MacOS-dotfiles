# Bound to kitty_mod+j / kitty_mod+k in kitty.conf, in place of next_window and
# previous_window.
#
# Those two walk window *groups*, and kitty puts an overlay in the same group as
# the window it covers -- the docs say so outright: "Does not traverse overlay
# windows". lazygit is launched as an overlay over neovim, so to them the two
# are one pane and there is nowhere to move to. This walks the windows instead.
#
# Usage: kitten cycle_window.py [next|prev]

from kittens.tui.handler import result_handler


def main(args):
    pass


def panes(tab):
    """Every window of the tab, overlays included, in a stable order.

    Groups keep their layout order. Inside a group windows are ordered by id,
    so a window always comes before the overlay covering it no matter which of
    the two is on top at the moment -- otherwise the cycle would reverse under
    you as you moved through it.
    """
    windows = []
    for group in tab.windows.groups:
        windows.extend(sorted(group, key=lambda window: window.id))
    return windows


def cycle(boss, window, step):
    tab = boss.tab_for_id(window.tab_id)
    if tab is None:
        return
    windows = panes(tab)
    if len(windows) < 2:
        return
    ids = [w.id for w in windows]
    if window.id not in ids:
        return
    # Focusing a covered window raises it within its group, so this reveals
    # whatever was underneath rather than only moving the focus ring.
    boss.set_active_window(windows[(ids.index(window.id) + step) % len(windows)])


@result_handler(no_ui=True)
def handle_result(args, result, target_window_id, boss):
    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return
    cycle(boss, window, -1 if args[-1] == "prev" else 1)
