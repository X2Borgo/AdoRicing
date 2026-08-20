#!/usr/bin/env bash
set -euo pipefail

target="${1:-}"

if [[ -z "$target" || ! "$target" =~ ^[0-9]+$ ]]; then
  exit 2
fi

active="$(hyprctl activeworkspace -j | jq -r '.id')"

if [[ -z "$active" || "$active" == "null" || "$active" == "$target" ]]; then
  exit 0
fi

tmp="9999"
while hyprctl workspaces -j | jq -e --argjson ws "$tmp" '.[] | select(.id == $ws)' >/dev/null; do
  tmp="$((tmp + 1))"
done

clients="$(hyprctl clients -j)"

mapfile -t active_windows < <(jq -r --argjson ws "$active" '.[] | select(.workspace.id == $ws) | .address' <<<"$clients")
mapfile -t target_windows < <(jq -r --argjson ws "$target" '.[] | select(.workspace.id == $ws) | .address' <<<"$clients")

move_window() {
  local workspace="$1"
  local address="$2"

  hyprctl dispatch "hl.dsp.window.move({ workspace = $workspace, window = \"address:$address\", follow = false })" >/dev/null
}

for addr in "${target_windows[@]}"; do
  move_window "$tmp" "$addr"
done

for addr in "${active_windows[@]}"; do
  move_window "$target" "$addr"
done

for addr in "${target_windows[@]}"; do
  move_window "$active" "$addr"
done

hyprctl dispatch "hl.dsp.focus({ workspace = $active })" >/dev/null
