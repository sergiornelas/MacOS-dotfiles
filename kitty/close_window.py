from kittens.tui.handler import result_handler

# confirm_os_window_close only covers closing tabs/OS windows, not single
# panes, so closing the last pane would quit kitty without asking. This asks
# first when the pane is the last one left in its OS window.

def main(args):
    pass

@result_handler(no_ui=True)
def handle_result(args, result, target_window_id, boss):
    window = boss.window_id_map.get(target_window_id)
    tm = boss.active_tab_manager

    if window is None or tm is None:
        return

    remaining = sum(1 for tab in tm.tabs for _ in tab.windows)

    if remaining > 1:
        boss.mark_window_for_close(window)
        return

    boss.confirm(
        "Close the last pane? This will quit kitty.",
        lambda confirmed: confirmed and boss.mark_window_for_close(window),
        window=window,
    )
