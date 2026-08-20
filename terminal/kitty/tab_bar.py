from kitty.tab_bar import draw_tab_with_powerline


CODEX_COLOR = 0xD000FF
CLAUDE_COLOR = 0xFF8C00

PREFIXES = {
    "▶ ": ("▶ ", CODEX_COLOR),
    "? ": ("? ", CODEX_COLOR),
    "✓ ": ("✓ ", CODEX_COLOR),
    "◆ ": ("▶ ", CLAUDE_COLOR),
    "⁇ ": ("? ", CLAUDE_COLOR),
    "◇ ": ("✓ ", CLAUDE_COLOR),
}


def sgr_foreground(rgb):
    return f"\x1b[38;2;{rgb >> 16};{(rgb >> 8) & 0xff};{rgb & 0xff}m"


def draw_tab(draw_data, screen, tab, before, max_tab_length, index, is_last, extra_data):
    title = tab.title
    for prefix, (symbol, color) in PREFIXES.items():
        if title.startswith(prefix):
            original_color = screen.cursor.fg >> 8
            colored_symbol = (
                sgr_foreground(color)
                + symbol
                + sgr_foreground(original_color)
            )
            tab = tab._replace(title=colored_symbol + title[len(prefix):])
            break

    return draw_tab_with_powerline(
        draw_data, screen, tab, before, max_tab_length, index, is_last, extra_data
    )
