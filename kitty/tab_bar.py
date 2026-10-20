# PANES_LAYOUT picks how panes (windows) are shown in the tab bar:
#   "inline": each tab followed by its panes (draw_title, used by {custom} in tab_title_template)
#   "split": panes of the active tab on the left, tabs on the right, positioned here
#            instead of tab_bar_align because kitty's align shifts the whole line, panes included
import re

from kitty.fast_data_types import get_boss, wcswidth
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
CLAUDE_IDLE = "✳"
# The icon takes the place of the spinner: colored while Claude works, another
# color when it waits for input (claude_waiting, from
# claude/hooks/sketchybar-status.sh), the chip color when idle
CLAUDE_WORKING_FG = 0xFABD2F
CLAUDE_WAITING_FG = 0xFE8019


def is_claude(w) -> bool:
    return "claude" in w.user_vars or "claude_busy" in w.user_vars


def pane_title(w, limit: int) -> str:
    title = short(w.title, limit)
    if is_claude(w):
        title = CLAUDE_PREFIX.sub("", title)
        title = CLAUDE_ICON + " " + title
    return title


def claude_icon_fg(w) -> int | None:
    if not is_claude(w):
        return None
    if w.user_vars.get("claude_waiting", "0") not in ("", "0"):
        return CLAUDE_WAITING_FG
    prefix = CLAUDE_PREFIX.match(w.title.strip())
    if prefix and prefix.group().strip() != CLAUDE_IDLE:
        return CLAUDE_WORKING_FG
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
    c.x = 0
    for i, (text, fg, bg) in enumerate(chips):
        if i:
            c.bg = default_bg
            screen.draw(SEP)
        c.fg, c.bg, c.bold = as_rgb(fg), as_rgb(bg), bg == ACTIVE_PANE_BG
        screen.draw(text)


def draw_tab(draw_data, screen, tab, before, max_tab_length, index, is_last, extra_data) -> int:
    if PANES_LAYOUT == "inline":
        return draw_tab_with_fade(draw_data, screen, tab, before, max_tab_length, index, is_last, extra_data)
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
            draw_panes(draw_data, screen, start - 1)
            c.fg, c.bg, c.bold = fg, bg, bold
            c.x = before = start
    return draw_tab_with_fade(draw_data, screen, tab, before, max_tab_length, index, is_last, extra_data)
