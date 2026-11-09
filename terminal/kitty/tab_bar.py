from kitty.tab_bar import as_rgb, draw_tab_with_powerline
from kitty.utils import color_as_int


CODEX_COLOR = 0xD000FF
CLAUDE_COLOR = 0xFF8C00
OVERFLOW_COLOR = 0x6C7A96

PREFIXES = {
    "▶ ": ("▶ ", CODEX_COLOR),
    "? ": ("? ", CODEX_COLOR),
    "✓ ": ("✓ ", CODEX_COLOR),
    "◆ ": ("▶ ", CLAUDE_COLOR),
    "⁇ ": ("? ", CLAUDE_COLOR),
    "◇ ": ("✓ ", CLAUDE_COLOR),
}

LEFT_ARROW = "‹"
RIGHT_ARROW = "›"

# Carousel state, one entry per tab bar keyed by its Screen.
#
# kitty never hands the whole tab list to a custom drawer: it calls draw_tab
# once per tab, twice per repaint — a layout pass (extra_data.for_layout, every
# tab measured from x=0 with the full bar width available) and then the real
# pass. So the layout pass is the only place to learn how wide every title
# wants to be, and the real pass uses those widths to decide which run of tabs
# to draw. Everything outside that run is skipped, which is what turns the bar
# into a sliding window instead of a row of truncated stubs.
_bars = {}


def bar_state(screen):
    state = _bars.get(id(screen))
    if state is None:
        state = _bars[id(screen)] = {"widths": [], "active": 0, "start": 0, "stop": 0}
    return state


def sgr_foreground(rgb):
    return f"\x1b[38;2;{rgb >> 16};{(rgb >> 8) & 0xff};{rgb & 0xff}m"


def colorize_agent_marker(tab):
    title = tab.title
    for prefix, (symbol, color) in PREFIXES.items():
        if title.startswith(prefix):
            return symbol, color, title[len(prefix):]
    return "", 0, title


def marker_width(count):
    # "‹12 " / " 12›"
    return 2 + len(str(count))


def kitty_max_tab_lengths(widths, columns, active):
    """Replica of TabBar.update()'s budget for each tab.

    Only needed to predict the one number we cannot see from here: after every
    tab it draws, kitty compares the cursor against `columns - budget[next]`
    and, if it has overrun, stamps a red ellipsis over the right edge and stops.
    Leaving that much room free keeps the marker ours instead of kitty's.
    """
    count = len(widths)
    default = max(1, (columns // max(1, count)) - 1)
    lengths = [default] * count
    extra = 0
    for i, width in enumerate(widths):
        if width < default:
            lengths[i] = width
            extra += default - width
    if extra > 0:
        if active < count and widths[active] > lengths[active]:
            given = min(extra, widths[active] - lengths[active])
            lengths[active] += given
            extra -= given
        if extra > 0:
            over = [i for i in range(count) if widths[i] > lengths[i]]
            if over:
                share = extra // len(over)
                if share > 0:
                    for i in over:
                        lengths[i] += share
    return lengths


def plan_window(state, columns):
    """Pick the run of whole tabs that keeps the active one nearest the middle."""
    widths = state["widths"]
    count = len(widths)
    if count == 0:
        return 0, 0
    active = state["active"]
    budgets = kitty_max_tab_lengths(widths, columns, active)
    runs = {}

    def run_from(start):
        """Where the run starting at `start` ends once the bar is full."""
        if start in runs:
            return runs[start]
        used = marker_width(start) if start else 0
        stop = start
        while stop < count:
            hidden = stop + 1
            if hidden < count:
                # Room for kitty's overflow check plus our own "N›" marker.
                reserve = budgets[hidden] + marker_width(count - hidden) + 2
            else:
                reserve = 0
            if used + widths[stop] > columns - reserve:
                break
            used += widths[stop]
            stop += 1
        # A title wider than the whole bar still gets its own slot; kitty
        # ellipsizes it for us in that case.
        runs[start] = stop = max(stop, start + 1)
        return stop

    def active_offset(start):
        """Cells between the left edge of the bar and the active tab."""
        return (marker_width(start) if start else 0) + sum(widths[start:active])

    # Of every window that shows the active tab whole, take the one whose
    # midpoint sits closest to the middle of the bar. Doubled to compare
    # midpoints without dividing.
    start, stop, best = 0, run_from(0), None
    for candidate in range(active + 1):
        reach = run_from(candidate)
        if reach <= active:
            continue
        score = abs(2 * active_offset(candidate) + widths[active] - columns)
        if best is None or score < best:
            start, stop, best = candidate, reach, score

    # "Centred when possible": at either end of the strip there is nothing left
    # to scroll towards, so hand the space back to the other side rather than
    # centring against a gap.
    while start > 0 and stop == count and run_from(start - 1) == count:
        start -= 1
    return start, run_from(start)


def draw_marker(draw_data, screen, text):
    # kitty picks the cursor colours and font style for this tab before calling
    # us, and the tab is drawn right after the marker, so put them back.
    saved = (screen.cursor.bg, screen.cursor.fg, screen.cursor.bold, screen.cursor.italic)
    screen.cursor.bg = as_rgb(color_as_int(draw_data.default_bg))
    screen.cursor.fg = as_rgb(OVERFLOW_COLOR)
    screen.cursor.bold = screen.cursor.italic = False
    screen.draw(text)
    (screen.cursor.bg, screen.cursor.fg, screen.cursor.bold, screen.cursor.italic) = saved


def draw_tab(draw_data, screen, tab, before, max_tab_length, index, is_last, extra_data):
    symbol, color, rest = colorize_agent_marker(tab)
    if symbol:
        original_color = screen.cursor.fg >> 8
        tab = tab._replace(
            title=sgr_foreground(color) + symbol + sgr_foreground(original_color) + rest
        )

    state = bar_state(screen)
    position = index - 1

    if extra_data.for_layout:
        # Measure only: let kitty lay the tab out at full width and record what
        # it asked for. Titles are never clipped here, so this is the whole
        # title's width.
        if index == 1:
            state["widths"] = []
            state["active"] = 0
        if tab.is_active:
            state["active"] = position
        end = draw_tab_with_powerline(
            draw_data, screen, tab, before, max_tab_length, index, is_last, extra_data
        )
        state["widths"].append(max(1, screen.cursor.x))
        return end

    if index == 1:
        state["start"], state["stop"] = plan_window(state, screen.columns)
    start, stop = state["start"], state["stop"]

    if not start <= position < stop:
        # Scrolled out of view: leave the cursor alone and hand back an empty
        # cell range so a click cannot land on a tab that is not on screen.
        return before - 1

    if position == start and start > 0:
        draw_marker(draw_data, screen, f"{LEFT_ARROW}{start} ")

    # Ignore kitty's per-tab budget — that budget is what shortens titles when
    # tabs outnumber the columns. The only cap left is the bar itself.
    room = max(3, screen.columns - screen.cursor.x - 1)
    end = draw_tab_with_powerline(
        draw_data, screen, tab, before, room, index, is_last, extra_data
    )

    if position == stop - 1 and stop < len(state["widths"]):
        draw_marker(draw_data, screen, f" {len(state['widths']) - stop}{RIGHT_ARROW}")

    return end
