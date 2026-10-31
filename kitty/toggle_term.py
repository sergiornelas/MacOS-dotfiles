import os
import subprocess

from kitty.constants import config_dir
from kittens.tui.handler import result_handler

FULLSCREEN_ZOOM = os.path.join(config_dir, "fullscreen_zoom.sh")

def main(args):
    pass

# Full size when showing the split / restore when going back to stack (see
# fullscreen_zoom.sh). Runs in the background without waiting: the kitten runs on
# kitty's main thread, and yabai asks kitty (accessibility) about the window; if kitty
# waits for yabai, neither makes progress until the timeout.
def fullscreen_zoom(action):
    try:
        subprocess.Popen(
            [FULLSCREEN_ZOOM, action],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True,
        )
    except Exception:
        pass

def toggle_term(boss, window):
    tab = boss.active_tab

    all_another_wins = tab.all_window_ids_except_active_window
    have_only_one = len(all_another_wins) == 0

    if have_only_one:
        # active_window = boss.active_window
        # cwd = active_window.cwd_of_child if active_window else "~"
        # tab.goto_layout("tall")
        # boss.call_remote_control(
        #     active_window,
        #     ("launch", f"--cwd={cwd}", "--type=window", "opencode", "--port")
        # )
        # tab.neighboring_window("right")
        # Full size is set by launch_pane in claudecode.lua when it opens Claude.
        window.write_to_child("\x1b:ClaudeCode\r")
        return
    else:
        if tab.current_layout.name == "stack":
            fullscreen_zoom("ensure")
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
            fullscreen_zoom("restore")

@result_handler(no_ui=True)
def handle_result(args, result, target_window_id, boss):
    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return
    toggle_term(boss, window)
