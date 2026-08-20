#!/usr/bin/env bash

set -euo pipefail

log_file="${XDG_RUNTIME_DIR:-/tmp}/dms-launch.log"

shell_running() {
  pgrep -x qs >/dev/null 2>&1 || pgrep -x quickshell >/dev/null 2>&1
}

# DMS owns org.freedesktop.Notifications while it runs; mako is only the
# notification daemon for the Waybar fallback path.
stop_mako() {
  pkill -x mako >/dev/null 2>&1 || true
}

start_mako() {
  if ! pgrep -x mako >/dev/null 2>&1 && command -v mako >/dev/null 2>&1; then
    mako >/dev/null 2>&1 &
  fi
}

start_waybar() {
  pkill -x ags >/dev/null 2>&1 || true
  pkill -x qs >/dev/null 2>&1 || true
  pkill -x quickshell >/dev/null 2>&1 || true
  pkill -x waybar >/dev/null 2>&1 || true
  if command -v waybar >/dev/null 2>&1; then
    waybar >/dev/null 2>&1 &
  fi
  start_mako
}

if ! command -v dms >/dev/null 2>&1; then
  start_waybar
  exit 0
fi

pkill -x waybar >/dev/null 2>&1 || true
stop_mako
dms run --daemon >"$log_file" 2>&1 &

for _ in {1..40}; do
  if shell_running; then
    pkill -x waybar >/dev/null 2>&1 || true
    stop_mako
    exit 0
  fi

  sleep 0.2
done

if shell_running; then
  pkill -x waybar >/dev/null 2>&1 || true
  stop_mako
  exit 0
fi

start_waybar
sleep 0.3
notify-send "Shell fallback" "DMS failed to start, launching Waybar" -u low >/dev/null 2>&1 || true
