from kitty.boss import Boss
from kittens.tui.handler import result_handler


CODEX_PREFIXES = ("▶ ", "? ", "✓ ")
CLAUDE_PREFIXES = ("◆ ", "⁇ ", "◇ ")
ALL_PREFIXES = CODEX_PREFIXES + CLAUDE_PREFIXES


def main(args):
    pass


def base_title(title):
    previous = None
    while title != previous:
        previous = title
        for prefix in ALL_PREFIXES:
            if title.startswith(prefix):
                title = title[len(prefix):]
                break
    return title


@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id, boss: Boss):
    window = boss.window_id_map.get(target_window_id)
    tab = window.tabref() if window is not None else None
    if tab is None or len(args) < 2:
        return

    action = args[1]
    if action == "ready":
        title = tab.effective_title
        if title.startswith(CODEX_PREFIXES):
            tab.set_title("✓ " + base_title(title))
        elif title.startswith(CLAUDE_PREFIXES):
            tab.set_title("◇ " + base_title(title))
        return

    if action != "cycle-question":
        return

    tab_manager = tab.tab_manager_ref()
    if tab_manager is None or not tab_manager.tabs:
        return

    current = tab_manager.tabs.index(tab)
    for offset in range(1, len(tab_manager.tabs) + 1):
        candidate = tab_manager.tabs[(current + offset) % len(tab_manager.tabs)]
        if candidate.effective_title.startswith(("? ", "⁇ ")):
            tab_manager.set_active_tab(candidate)
            return
