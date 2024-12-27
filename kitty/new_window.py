from kittens.tui.handler import result_handler

def main(args):
    pass

def new_window(boss):
    tab = boss.active_tab

    if tab.current_layout.name == 'stack':
        tab.goto_layout('fat')
        boss.launch('--cwd=current', '--location=hsplit')
    else:
        boss.launch('--cwd=current', '--location=hsplit')

@result_handler(no_ui=True)
def handle_result(args, result, target_window_id, boss):
    window = boss.window_id_map.get(target_window_id)

    if window is None:
        return

    new_window(boss)
