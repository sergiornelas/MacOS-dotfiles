# Bound to `tab` in kitty.conf. Opens lazygit for the current project, but only
# ever one: a second press goes back to the one already running.
#
# The check has to live here rather than in the launched script, because by the
# time a script runs kitty has already made a window for it. It also has to be
# here rather than in kitty.conf, which has no way to say "only if".

from kittens.tui.handler import result_handler
from kitty.constants import config_dir
import os


def main(args):
    pass


def project_of(path):
    """The repo a path belongs to; the path itself when it belongs to none."""
    directory = os.path.realpath(path)
    while True:
        if os.path.exists(os.path.join(directory, ".git")):
            return directory
        parent = os.path.dirname(directory)
        if parent == directory:
            return os.path.realpath(path)
        directory = parent


def lazygit_cwd(window):
    """Where this window's lazygit is running, or None if it isn't one."""
    try:
        processes = window.child.foreground_processes
    except Exception:
        return None
    for process in processes:
        cmdline = process.get("cmdline") or []
        if cmdline and os.path.basename(cmdline[0]) == "lazygit":
            return process.get("cwd")
    return None


def open_lazygit(boss, window):
    here = window.child.foreground_cwd or window.cwd_of_child
    if not here:
        return
    project = project_of(here)

    # Compared by repo rather than by directory, so a window sitting in a
    # subdirectory of the project still counts as the same project.
    for other in boss.all_windows:
        cwd = lazygit_cwd(other)
        if cwd and project_of(cwd) == project:
            # Includes the case of pressing the key from inside lazygit, where
            # kitty swallows tab before lazygit can see it: focusing the window
            # that is already active does nothing, which beats stacking a
            # second lazygit on top of the first.
            boss.set_active_window(other, switch_os_window_if_needed=True)
            return

    boss.launch(
        "--type=overlay-main",
        "--cwd=current",
        "--title=lazygit",
        "--tab-title=lazygit",
        "--copy-env",
        os.path.join(config_dir, "lazygit-toggle-full-screen.fish"),
    )


@result_handler(no_ui=True)
def handle_result(args, result, target_window_id, boss):
    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return
    open_lazygit(boss, window)
