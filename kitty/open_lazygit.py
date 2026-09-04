# Bound to `tab` and to `ctrl+tab` in kitty.conf. Opens lazygit for the current
# project -- plain, or filtered to the history of the file you are editing --
# and only ever one at a time: pressing either key again goes back to the one
# already running rather than stacking another.
#
#   kitten open_lazygit.py        the working tree
#   kitten open_lazygit.py log    that one file's commits, via lazygit -f
#
# The check has to live here rather than in the launched script, because by the
# time a script runs kitty has already made a window for it -- and `-f` has to
# be decided before lazygit starts, since lazygit only takes it as a flag. It
# also has to be here rather than in kitty.conf, which has no way to say
# "only if".

from kittens.tui.handler import result_handler
from kitty.constants import config_dir
import os
import shutil
import subprocess

# The neovim helpers live beside lazygit's config, not kitty's.
LAZYGIT_DIR = os.path.join(os.path.dirname(config_dir), "lazygit")


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


def lazygit_in(window):
    """(cwd, filtered path) of this window's lazygit, or None if it isn't one."""
    try:
        processes = window.child.foreground_processes
    except Exception:
        return None
    for process in processes:
        cmdline = process.get("cmdline") or []
        if cmdline and os.path.basename(cmdline[0]) == "lazygit":
            filtered = None
            for flag, value in zip(cmdline, cmdline[1:]):
                if flag in ("-f", "--filter"):
                    filtered = value
                    break
            return process.get("cwd"), filtered
    return None


def path_of(window):
    try:
        return window.child.foreground_environ.get("PATH")
    except Exception:
        return None


def find(boss, window, name):
    """Find a program the way the windows do.

    kitty's own PATH is the bare one it was launched with, and neovim is not on
    it. The windows carry the user's, so borrow theirs -- starting with the one
    this is about, falling back to any other, which keeps working through a
    change of install rather than naming a directory here.
    """
    seen = [path_of(window), os.environ.get("PATH")]
    seen += [path_of(other) for other in boss.all_windows]
    for path in seen:
        if path:
            exe = shutil.which(name, path=path)
            if exe:
                return exe
    return None


def run(boss, window, argv, wait=True):
    exe = find(boss, window, argv[0])
    if not exe:
        return None
    argv = [exe] + list(argv[1:])
    # The helpers tell one kitty's window ids from another's by KITTY_PID, and
    # kitty sets that on the windows it spawns, not on itself -- so a child
    # started from in here inherits an environment without it, and the helpers
    # would match nothing. We are kitty, so our own pid is the one they mean.
    env = dict(os.environ, KITTY_PID=str(os.getpid()))
    path = path_of(window)
    if path:
        env["PATH"] = path
    try:
        if not wait:
            subprocess.Popen(argv, env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            return ""
        # A timeout because this blocks kitty's own loop: a wedged neovim must
        # not be able to take the window manager down with it.
        done = subprocess.run(argv, env=env, capture_output=True, text=True, timeout=2)
    except Exception:
        return None
    return done.stdout


def file_with_history(boss, window):
    """The file open in this window's neovim, if git has anything on it."""
    path = run(
        boss,
        window,
        ["nvim", "-u", "NONE", "-l", os.path.join(LAZYGIT_DIR, "nvim-current-file.lua"), str(window.id)],
    )
    path = (path or "").strip()
    if not path:
        return None
    # Untracked files list no commits, and a history of nothing is not worth a
    # window.
    log = run(boss, window, ["git", "-C", os.path.dirname(path), "log", "-1", "--format=%H", "--", path])
    return path if (log or "").strip() else None


def open_lazygit(boss, window, want_log):
    here = window.child.foreground_cwd or window.cwd_of_child
    if not here:
        return
    project = project_of(here)

    target = None
    if want_log:
        target = file_with_history(boss, window)
        if not target:
            # Said where you are looking rather than in a window you did not
            # ask for. Not waited on: the message is not worth a pause.
            run(
                boss,
                window,
                [
                    "nvim", "-u", "NONE", "-l",
                    os.path.join(LAZYGIT_DIR, "nvim-notify.lua"),
                    str(window.id),
                    "No git history for this buffer",
                ],
                wait=False,
            )
            return

    # Compared by repo rather than by directory, so a window sitting in a
    # subdirectory of the project still counts as the same project.
    for other in boss.all_windows:
        found = lazygit_in(other)
        if not found or project_of(found[0]) != project:
            continue
        if found[1] == target:
            # Already showing what was asked for. Includes pressing the key from
            # inside lazygit, where kitty swallows it before lazygit can see it:
            # focusing the window that is already active does nothing, which
            # beats stacking a second lazygit on top of the first.
            boss.set_active_window(other, switch_os_window_if_needed=True)
            # Repaint the active border, which focusing alone leaves behind on
            # whichever window had it before. See cycle_window.py.
            other_tab = boss.tab_for_id(other.tab_id)
            if other_tab is not None:
                other_tab.relayout_borders()
            return
        # One per project, so the one showing the other thing has to go. `q`
        # rather than closing the window, to let it put the layout back and
        # close itself the way it knows how.
        other.write_to_child("q")
        break

    launch = [
        "--type=overlay-main",
        # Named rather than "current": that would resolve against whichever
        # window is active, which is this one when the key is pressed but not
        # when the kitten is driven from elsewhere.
        "--cwd={}".format(here),
        "--title=lazygit",
        "--tab-title=lazygit",
        "--copy-env",
        # Which window this overlay is covering, so the launcher can ask the
        # neovim living there what file to open on. See the fish script.
        "--env=LAZYGIT_SOURCE_WINDOW={}".format(window.id),
    ]
    # Always stated, never left to chance: --copy-env copies the environment of
    # whatever window is active, and when that is a filtered lazygit being
    # replaced, its own LAZYGIT_FILTER would carry over and the replacement
    # would come up filtered too. A bare name removes the variable.
    launch.append("--env=LAZYGIT_FILTER={}".format(target) if target else "--env=LAZYGIT_FILTER")
    launch.append(os.path.join(config_dir, "lazygit-toggle-full-screen.fish"))
    boss.launch(*launch)


@result_handler(no_ui=True)
def handle_result(args, result, target_window_id, boss):
    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return
    open_lazygit(boss, window, args[-1] == "log")
