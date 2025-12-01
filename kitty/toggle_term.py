from kittens.tui.handler import result_handler

def main(args):
    pass

def toggle_term(boss):
    tab = boss.active_tab

    all_another_wins = tab.all_window_ids_except_active_window
    have_only_one = len(all_another_wins) == 0

    if have_only_one:
        tab.goto_layout("tall")
        boss.launch("--cwd=current")
        tab.neighboring_window("right")
    else:
        if tab.current_layout.name == "stack":
            tab.last_used_layout()
            if tab.current_layout.name == "tall":
                tab.neighboring_window("right")
            if tab.current_layout.name == "fat":
                tab.neighboring_window("bottom")
        else:
            if tab.current_layout.name == "tall":
                tab.neighboring_window("left")
            if tab.current_layout.name == "fat":
                tab.neighboring_window("top")
            tab.goto_layout("stack")

@result_handler(no_ui=True)
def handle_result(args, result, target_window_id, boss):
    window = boss.window_id_map.get(target_window_id)

    if window is None:
        return

    toggle_term(boss)
