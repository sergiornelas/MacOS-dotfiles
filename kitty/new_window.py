from kittens.tui.handler import result_handler

def main(args):
    pass

def new_window(boss):
    tab = boss.active_tab

    all_another_wins = tab.all_window_ids_except_active_window
    have_only_one = len(all_another_wins) == 0

    if have_only_one:
        tab.goto_layout("fat")
        boss.launch("--cwd=current")
        tab.neighboring_window("bottom")
    else:
        if tab.current_layout.name == "stack":
            tab.last_used_layout()
            boss.launch("--cwd=current")
        else:
            boss.launch("--cwd=current")

@result_handler(no_ui=True)
def handle_result(args, result, target_window_id, boss):
    window = boss.window_id_map.get(target_window_id)

    if window is None:
        return

    new_window(boss)
