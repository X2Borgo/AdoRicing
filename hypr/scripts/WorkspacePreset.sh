#!/usr/bin/env bash
# Create named workspace presets without duplicating windows on every switch.

set -euo pipefail

workspace_name="${1:-}"

case "$workspace_name" in
  work|drevia) ;;
  *)
    echo "Usage: $0 {work|drevia}" >&2
    exit 1
    ;;
esac

require_command() {
  command -v "$1" >/dev/null 2>&1
}

if ! require_command hyprctl; then
  echo "hyprctl is required" >&2
  exit 1
fi

if ! require_command jq; then
  hyprctl dispatch workspace "name:${workspace_name}" >/dev/null 2>&1 || true
  exit 0
fi

WORK_PROJECT_DIR="${WORK_PROJECT_DIR:-$HOME/Desktop/DoraFeature}"
DREVIA_PROJECT_DIR="${DREVIA_PROJECT_DIR:-$HOME/Desktop/DreviaEsports}"

if [[ ! -d "$WORK_PROJECT_DIR" ]]; then
  WORK_PROJECT_DIR="$HOME"
fi

if [[ ! -d "$DREVIA_PROJECT_DIR" ]]; then
  DREVIA_PROJECT_DIR="$HOME"
fi

workspace_client_count() {
  hyprctl clients -j | jq --arg ws "$1" '[.[] | select(.workspace.name == $ws)] | length'
}

wait_for_window() {
  local ws="$1"
  local baseline="$2"

  for _ in {1..40}; do
    local current
    current="$(workspace_client_count "$ws")"
    if (( current > baseline )); then
      hyprctl activewindow -j | jq -r '.address // empty'
      return 0
    fi
    sleep 0.2
  done

  return 1
}

focus_window() {
  local address="$1"
  [[ -n "$address" ]] || return 0
  hyprctl dispatch focuswindow "address:${address}" >/dev/null 2>&1 || true
  sleep 0.1
}

open_browser_window() {
  if require_command firefox; then
    firefox --new-window about:blank >/dev/null 2>&1 &
    return 0
  fi
  if require_command floorp; then
    floorp --new-window about:blank >/dev/null 2>&1 &
    return 0
  fi
  if require_command zen-browser; then
    zen-browser --new-window about:blank >/dev/null 2>&1 &
    return 0
  fi
  if require_command brave-browser; then
    brave-browser --new-window about:blank >/dev/null 2>&1 &
    return 0
  fi
  if require_command google-chrome; then
    google-chrome --new-window about:blank >/dev/null 2>&1 &
    return 0
  fi
  if require_command chromium; then
    chromium --new-window about:blank >/dev/null 2>&1 &
    return 0
  fi

  xdg-open about:blank >/dev/null 2>&1 &
}

open_floorp_window() {
  if require_command floorp; then
    floorp --new-window about:blank >/dev/null 2>&1 &
    return 0
  fi

  open_browser_window
}

open_terminal_window() {
  local dir="$1"

  if require_command kitty; then
    kitty --directory "$dir" >/dev/null 2>&1 &
    return 0
  fi
  if require_command ghostty; then
    ghostty --working-directory="$dir" >/dev/null 2>&1 &
    return 0
  fi
  if require_command foot; then
    foot -D "$dir" >/dev/null 2>&1 &
    return 0
  fi
  if require_command wezterm; then
    wezterm start --cwd "$dir" >/dev/null 2>&1 &
    return 0
  fi
  if require_command alacritty; then
    alacritty --working-directory "$dir" >/dev/null 2>&1 &
    return 0
  fi

  xdg-open "$dir" >/dev/null 2>&1 &
}

open_editor_window() {
  local dir="$1"

  if require_command zed; then
    (
      cd "$dir"
      zed .
    ) >/dev/null 2>&1 &
    return 0
  fi
  if require_command code; then
    code "$dir" >/dev/null 2>&1 &
    return 0
  fi
  if require_command codium; then
    codium "$dir" >/dev/null 2>&1 &
    return 0
  fi

  open_terminal_window "$dir"
}

get_secondary_monitor() {
  local focused
  focused="$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name' | head -n1)"
  hyprctl monitors -j | jq -r --arg focused "$focused" '.[] | select(.name != $focused) | .name' | head -n1
}

move_window_to_monitor() {
  local address="$1"
  local monitor_name="$2"

  [[ -n "$address" && -n "$monitor_name" ]] || return 0
  focus_window "$address"
  hyprctl dispatch movewindow "mon:${monitor_name}" >/dev/null 2>&1 || true
  sleep 0.1
}

spawn_window() {
  local ws="$1"
  shift
  local baseline
  baseline="$(workspace_client_count "$ws")"
  "$@"
  wait_for_window "$ws" "$baseline" || true
}

seed_work_workspace() {
  local terminal_addr
  local editor_addr
  local floorp_addr
  local secondary_monitor

  terminal_addr="$(spawn_window work open_terminal_window "$WORK_PROJECT_DIR")"
  editor_addr="$(spawn_window work open_editor_window "$WORK_PROJECT_DIR")"
  floorp_addr="$(spawn_window work open_floorp_window)"

  # On multi-monitor setups, keep the first two on the current (main) monitor
  # and move the third one to the secondary monitor.
  secondary_monitor="$(get_secondary_monitor)"
  move_window_to_monitor "$floorp_addr" "$secondary_monitor"

  focus_window "$terminal_addr"
  focus_window "$editor_addr"
}

seed_drevia_workspace() {
  local editor_addr
  local browser_addr

  editor_addr="$(spawn_window drevia open_editor_window "$DREVIA_PROJECT_DIR")"
  browser_addr="$(spawn_window drevia open_browser_window)"
  focus_window "$browser_addr"

  spawn_window drevia open_terminal_window "$DREVIA_PROJECT_DIR" >/dev/null
  focus_window "$editor_addr"
}

hyprctl dispatch workspace "name:${workspace_name}" >/dev/null 2>&1 || true
sleep 0.2

if (( $(workspace_client_count "$workspace_name") > 0 )); then
  exit 0
fi

# These presets assume the repo default of dwindle so the spawn order becomes
# the arrangement. If you are currently using master, windows will still open,
# but the final tiling pattern may differ.
hyprctl keyword general:layout dwindle >/dev/null 2>&1 || true

case "$workspace_name" in
  work)
    seed_work_workspace
    ;;
  drevia)
    seed_drevia_workspace
    ;;
esac
