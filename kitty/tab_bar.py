# PANES_LAYOUT picks how panes (windows) are shown in the tab bar:
#   "inline": each tab followed by its panes (draw_title, used by {custom} in tab_title_template)
#   "split": panes of the active tab on the left, tabs on the right, positioned here
#            instead of tab_bar_align because kitty's align shifts the whole line, panes included
import re

from kitty.fast_data_types import add_timer, get_boss, wcswidth
from kitty.tab_bar import as_rgb, color_as_int, draw_tab_with_fade

PANES_LAYOUT = "inline"

# panes are drawn as chips with their own background, the focused one in [brackets]
ACTIVE_PANE_BG = 0x4F0000
ACTIVE_PANE_FG = 0xEBDBB2
PANE_BG = 0x2A0000
PANE_FG = 0xA89984
SEP = " "
INACTIVE_SEP = "|"
MAX_PANE_TITLE = 30

# os_window_id -> {tab index: width}, filled in kitty's measuring pass
tab_widths: dict = {}


def short(title: str, limit: int) -> str:
    title = title[title.rfind("/") + 1:].strip()
    return title if len(title) <= limit else title[: limit - 1] + "…"


# Claude Code prefixes its title with a small unicode glyph (✳ idle, ◐ spinner
# while working). It is swapped for the Nerd Font Claude icon: kitty only draws
# private use glyphs two cells wide, and only when a space follows them
CLAUDE_ICON = " "
CLAUDE_PREFIX = re.compile(r"^[^\w\s]+\s+")
# The icon takes the place of the spinner: colored while Claude works, another
# color when it needs you (a question, a permission, or a turn that finished
# while you were elsewhere), the chip color when idle. The state comes from the
# OSC 7501 records Claude reports to kitty, the same ones
# watchers/claude_status.py and agent-tabs.sh read; kitty redraws the tab bar
# when they change
CLAUDE_APP = "claude-code"
CLAUDE_WORKING_FG = 0xFABD2F
CLAUDE_WAITING_FG = 0xFE8019


def claude_states(w) -> set:
    status = getattr(w, "program_status", None)
    if status is None:
        return set()
    return {r.get("state") for r in status.as_list() if r.get("app") == CLAUDE_APP}


# claude=1 is set by nvim/lua/plugins/claudecode.lua on the windows it opens and
# by watchers/claude_status.py on any window Claude reports from: once a done is
# seen kitty drops it, and the window has no records left
def is_claude(w) -> bool:
    return "claude" in w.user_vars or bool(claude_states(w))


# A pane sitting in the shell (nothing running: no nvim, lazygit...) shows this
# instead of the cwd. at_prompt comes from kitty's shell integration (OSC 133
# marks), but a new pane is drawn before its shell prints the first prompt, and
# with a fixed --title (session files) nothing redraws it when the prompt shows
# up. So a pane whose only foreground processes are interactive shells counts
# as well, including what kitty starts the shell through on macOS:
# /usr/bin/login runs `kitten run-shell`, which then becomes the shell, and
# that is what a new pane has in the foreground when it is first drawn. A shell
# running a command or a script (fish -c ..., lazygit-toggle-full-screen.fish)
# is not a terminal: it is starting something, see shell_job.
SHELL_TITLE = "terminal \U000F018D"
SHELLS = {"fish", "zsh", "bash", "sh"}
SHELL_STARTERS = {"login", "kitten run-shell"}


def at_shell_prompt(w) -> bool:
    try:
        return bool(w.at_prompt)
    except Exception:
        return False


# A pane running one of these programs shows its title instead of the cwd. All
# the foreground processes are checked, not just the group leader: lazygit runs
# under lazygit-toggle-full-screen.fish (see open_lazygit.py). First match wins,
# so lazygit goes before nvim, which it can spawn as its editor
PROGRAM_TITLES = (
    ("lazygit", "Lazygit \U000F0093"),
    ("nvim", "Nvim \U000F0880"),
)


# name of a process: a login shell's argv[0] is "-fish"; kitten keeps its
# subcommand, since only `kitten run-shell` is part of starting the shell
def program_name(cmdline: list) -> str:
    name = (cmdline or [""])[0].rsplit("/", 1)[-1].lstrip("-")
    if name == "kitten" and len(cmdline) > 1:
        name += " " + cmdline[1]
    return name


def foreground_cmdlines(w) -> list:
    try:
        processes = w.child.foreground_processes
    except Exception:
        return []
    return [c for c in (p.get("cmdline") or [] for p in processes) if program_name(c)]


# What a shell process runs: "" when it is interactive, else its -c command or
# its script. None when it is not a shell. -C (init command, as in the
# terminals session's `fish -ilC "pnpm dev"`) still leaves it interactive.
def shell_job(cmdline: list) -> str | None:
    name = program_name(cmdline)
    if name in SHELL_STARTERS:
        return ""
    if name not in SHELLS:
        return None
    args = iter(cmdline[1:])
    for arg in args:
        if arg.startswith("--command="):
            return arg.split("=", 1)[1]
        if arg.startswith("--"):
            if arg == "--command":
                return next(args, "")
            if arg == "--init-command":
                next(args, None)
        elif arg.startswith("-"):
            if "c" in arg[1:]:
                return next(args, "")
            if "C" in arg[1:]:
                next(args, None)
        else:
            return arg
    return ""


def program_title(names) -> str | None:
    return next((t for program, t in PROGRAM_TITLES if program in names), None)


# A pane still settling (being created, or its shell starting up without a
# prompt yet, as in `fish -c nvim` from the session files) gets nothing that
# would redraw the tab bar once its program runs: no title change, no command
# reported. So it is checked again every RECHECK_DELAY seconds until it
# settles, at most RECHECK_TRIES times.
RECHECK_DELAY = 0.25
RECHECK_TRIES = 12
# window id -> checks left; windows with a check pending
recheck_tries: dict = {}
recheck_pending: set = set()


def recheck_later(w) -> None:
    left = recheck_tries.get(w.id, RECHECK_TRIES)
    if w.id in recheck_pending or left <= 0:
        return
    recheck_tries[w.id] = left - 1
    recheck_pending.add(w.id)
    window_id, os_window_id = w.id, w.os_window_id

    def recheck(timer_id) -> None:
        recheck_pending.discard(window_id)
        tm = get_boss().os_window_map.get(os_window_id)
        if tm is not None:
            tm.mark_tab_bar_dirty()

    add_timer(recheck, RECHECK_DELAY, False)


# window id -> title last shown for it, see pane_title
last_titles: dict = {}


# A pane starting something: its processes can't be read yet (it is just being
# created, or its shell is starting a program), or only a shell running a
# command or a script is there. Rather than flash a wrong title it keeps what
# it showed, else names the program it is about to run: the first word of the
# -c command (a session's `fish -c "nvim; ..."`), or its window title
# (open_lazygit.py launches with --title=lazygit), else shows its title.
def starting_title(w, cmdlines: list, limit: int) -> str:
    if w.id in last_titles:
        return last_titles[w.id]
    words = {w.title.strip().lower()}
    for cmdline in cmdlines:
        job = shell_job(cmdline) or ""
        first = re.split(r"[\s;&|]+", job.strip(), maxsplit=1)[0]
        words.add(first.rsplit("/", 1)[-1])
    return program_title(words) or short(w.title, limit)


def pane_title(w, limit: int) -> str:
    if is_claude(w):
        return CLAUDE_ICON + " " + CLAUDE_PREFIX.sub("", short(w.title, limit))
    settled = True
    if at_shell_prompt(w):
        title = SHELL_TITLE
    else:
        cmdlines = foreground_cmdlines(w)
        jobs = [shell_job(c) for c in cmdlines]
        title = program_title({program_name(c) for c in cmdlines})
        if title is None and None in jobs:
            # some other program: its own title
            title = short(w.title, limit)
        elif title is None and jobs and not any(jobs):
            # interactive shell, no prompt yet
            title = SHELL_TITLE
            settled = False
        elif title is None:
            # a guess, not remembered: what it settles on replaces it
            recheck_later(w)
            return starting_title(w, cmdlines, limit)
    if settled:
        # the next time it changes it gets all its checks again
        recheck_tries.pop(w.id, None)
    else:
        recheck_later(w)
    last_titles[w.id] = title
    return title


# Same priority as watchers/claude_status.py: background tasks still running
# after a turn keep it working
def claude_icon_fg(w) -> int | None:
    states = claude_states(w)
    if "blocked" in states:
        return CLAUDE_WAITING_FG
    if "working" in states:
        return CLAUDE_WORKING_FG
    if states & {"done", "error"}:
        return CLAUDE_WAITING_FG
    return None


def draw_title(data: dict) -> str:
    if PANES_LAYOUT != "inline":
        return ""
    tab = get_boss().tab_for_id(data["tab"].tab_id)
    if tab is None:
        return ""
    fmt = data["fmt"]
    tm = tab.tab_manager_ref()
    is_active_tab = tm is not None and tm.active_tab is tab
    active = tab.active_window
    panes = []
    for w in tab:
        title = f"  {pane_title(w, MAX_PANE_TITLE)}  "
        fg_code = fmt.fg.tab
        if is_active_tab:
            bg, fg = (ACTIVE_PANE_BG, ACTIVE_PANE_FG) if w is active else (PANE_BG, PANE_FG)
            fg_code = getattr(fmt.fg, f"_{fg:06x}")
        icon_fg = claude_icon_fg(w)
        if icon_fg is not None:
            title = title.replace(CLAUDE_ICON, getattr(fmt.fg, f"_{icon_fg:06x}") + CLAUDE_ICON + fg_code, 1)
        if is_active_tab:
            title = getattr(fmt.bg, f"_{bg:06x}") + fg_code + title + fmt.bg.tab + fmt.fg.tab
        panes.append(title)
    # inactive tabs have no chip colors, "|" takes the place of SEP to keep the same spacing
    return " " + (SEP if is_active_tab else INACTIVE_SEP).join(panes)


def pane_chips(os_window_id: int, limit: int) -> list:
    tm = get_boss().os_window_map.get(os_window_id)
    tab = tm.active_tab if tm is not None else None
    if tab is None:
        return []
    windows = list(tab)
    if len(windows) < 2:
        return []
    active = tab.active_window
    chips = []
    for w in windows:
        if w is active:
            chips.append((f"[ {pane_title(w, limit)} ]", ACTIVE_PANE_FG, ACTIVE_PANE_BG))
        else:
            chips.append((f" {pane_title(w, limit)} ", PANE_FG, PANE_BG))
    return chips


def draw_panes(draw_data, screen, available: int) -> None:
    # shrink pane titles until they fit next to the tabs
    for limit in (MAX_PANE_TITLE, 15, 8):
        chips = pane_chips(draw_data.os_window_id, limit)
        width = sum(wcswidth(text) for text, _, _ in chips) + len(SEP) * (len(chips) - 1)
        if width <= available:
            break
    else:
        return
    if not chips:
        return
    c = screen.cursor
    default_bg = as_rgb(color_as_int(draw_data.default_bg))
    for i, (text, fg, bg) in enumerate(chips):
        if i:
            c.bg = default_bg
            screen.draw(SEP)
        c.fg, c.bg, c.bold = as_rgb(fg), as_rgb(bg), bg == ACTIVE_PANE_BG
        screen.draw(text)


# The active session is shown as a chip at the far left. Its label is the
# --title of the session file's first titled launch (pane titles no longer show
# it, they show the program instead), else the session file's name
SESSION_BG = 0x182A8F
SESSION_FG = 0xEBDBB2


def session_label(os_window_id: int) -> str:
    tm = get_boss().os_window_map.get(os_window_id)
    tab = tm.active_tab if tm is not None else None
    w = tab.active_window if tab is not None else None
    name = w.effective_session_name if w is not None else ""
    if not name:
        return ""
    titled = [
        w for t in tm for w in t
        if w.effective_session_name == name and getattr(w, "override_title", None)
    ]
    return min(titled, key=lambda w: w.id).override_title.strip() if titled else name


def draw_session(draw_data, screen) -> None:
    label = session_label(draw_data.os_window_id)
    if not label:
        return
    # restore the cursor colors that kitty set up for the first tab
    c = screen.cursor
    fg, bg, bold = c.fg, c.bg, c.bold
    c.fg, c.bg, c.bold = as_rgb(SESSION_FG), as_rgb(SESSION_BG), True
    screen.draw(f" {label} ")
    c.bg, c.bold = as_rgb(color_as_int(draw_data.default_bg)), False
    screen.draw(" ")
    c.fg, c.bg, c.bold = fg, bg, bold


# How many sessions are open, as a chip at the far right, only when there is
# more than the current one. Only in the inline layout: in split the tabs are there
SESSIONS_ICON = "\U000F0328"


def draw_session_count(draw_data, screen) -> None:
    count = len(set(get_boss().all_loaded_session_names))
    if count < 2:
        return
    text = f" {SESSIONS_ICON} {count} "
    # After the last tab kitty erases the line from the cursor on, so the chip
    # stops one cell short of the edge and the cursor is left on that cell
    start = screen.columns - wcswidth(text) - 1
    c = screen.cursor
    if start <= c.x:
        return
    fg, bg, bold = c.fg, c.bg, c.bold
    c.x = start
    c.fg, c.bg, c.bold = as_rgb(SESSION_FG), as_rgb(SESSION_BG), True
    screen.draw(text)
    c.fg, c.bg, c.bold = fg, bg, bold


def draw_tab(draw_data, screen, tab, before, max_tab_length, index, is_last, extra_data) -> int:
    if PANES_LAYOUT == "inline":
        # also in the measuring pass, so the first tab's width includes the chip
        if index == 1:
            screen.cursor.x = before
            draw_session(draw_data, screen)
            before = screen.cursor.x
        end = draw_tab_with_fade(draw_data, screen, tab, before, max_tab_length, index, is_last, extra_data)
        if is_last and not extra_data.for_layout:
            draw_session_count(draw_data, screen)
        return end
    widths = tab_widths.setdefault(draw_data.os_window_id, {})
    # for_layout is kitty's measuring pass: each tab is drawn alone from column 0
    if extra_data.for_layout:
        if index == 1:
            widths.clear()
        end = draw_tab_with_fade(draw_data, screen, tab, before, max_tab_length, index, is_last, extra_data)
        widths[index] = screen.cursor.x
        return end
    if index == 1:
        start = screen.columns - sum(widths.values())
        if start > 0:
            # draw_panes changes the cursor colors that kitty set up for this tab
            c = screen.cursor
            fg, bg, bold = c.fg, c.bg, c.bold
            c.x = 0
            draw_session(draw_data, screen)
            draw_panes(draw_data, screen, start - 1 - c.x)
            c.fg, c.bg, c.bold = fg, bg, bold
            c.x = before = start
    return draw_tab_with_fade(draw_data, screen, tab, before, max_tab_length, index, is_last, extra_data)
