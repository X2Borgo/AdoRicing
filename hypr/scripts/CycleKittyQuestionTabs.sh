#!/usr/bin/env bash

# Focus the next tab waiting for agent input in the current Kitty OS window.

set -uo pipefail

kitty_address="${KITTY_LISTEN_ON:-}"
[[ -n "$kitty_address" ]] || exit 0

kitty_state="$(kitten @ --to "$kitty_address" ls 2>/dev/null)" || exit 0
next_tab_id="$(
  jq -r '
    (first(.[] | select(.is_focused)) // first(.[])) as $os
    | ($os.tabs // []) as $tabs
    | ($tabs | map(.is_active) | index(true) // 0) as $current
    | first(
        range(1; ($tabs | length) + 1) as $offset
        | $tabs[($current + $offset) % ($tabs | length)]
        | select(.title | startswith("? ") or startswith("⁇ "))
        | .id
      ) // empty
  ' <<< "$kitty_state" 2>/dev/null
)"

[[ "$next_tab_id" =~ ^[0-9]+$ ]] || exit 0
kitten @ --to "$kitty_address" focus-tab \
  --match "id:$next_tab_id" >/dev/null 2>&1 || true
