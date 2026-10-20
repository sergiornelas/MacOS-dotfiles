# PANES_LAYOUT picks how panes (windows) are shown in the tab bar:
#   "inline": each tab followed by its panes (draw_title, used by {custom} in tab_title_template)
#   "split": panes of the active tab on the left, tabs on the right, positioned here
#            instead of tab_bar_align because kitty's align shifts the whole line, panes included
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
        title = f"  {short(w.title, MAX_PANE_TITLE)}  "
        if is_active_tab:
            bg, fg = (ACTIVE_PANE_BG, ACTIVE_PANE_FG) if w is active else (PANE_BG, PANE_FG)
            title = getattr(fmt.bg, f"_{bg:06x}") + getattr(fmt.fg, f"_{fg:06x}") + title + fmt.bg.tab + fmt.fg.tab
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
            chips.append((f"[ {short(w.title, limit)} ]", ACTIVE_PANE_FG, ACTIVE_PANE_BG))
        else:
            chips.append((f" {short(w.title, limit)} ", PANE_FG, PANE_BG))
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
