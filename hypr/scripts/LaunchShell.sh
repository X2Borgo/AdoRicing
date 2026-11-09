#!/usr/bin/env bash

set -euo pipefail

# Shell preference: Noctalia, then DMS, then Waybar + mako.
log_file="${XDG_RUNTIME_DIR:-/tmp}/shell-launch.log"

noctalia_running() {
  pgrep -x noctalia >/dev/null 2>&1
}

dms_running() {
  pgrep -x qs >/dev/null 2>&1 || pgrep -x quickshell >/dev/null 2>&1
}

# Noctalia and DMS own org.freedesktop.Notifications while they run; mako is
# only the notification daemon for the Waybar fallback path.
stop_mako() {
  pkill -x mako >/dev/null 2>&1 || true
}

start_mako() {
  if ! pgrep -x mako >/dev/null 2>&1 && command -v mako >/dev/null 2>&1; then
    mako >/dev/null 2>&1 &
  fi
}

stop_shells() {
  pkill -x noctalia >/dev/null 2>&1 || true
  pkill -x ags >/dev/null 2>&1 || true
  pkill -x qs >/dev/null 2>&1 || true
  pkill -x quickshell >/dev/null 2>&1 || true
  pkill -x waybar >/dev/null 2>&1 || true
}

start_waybar() {
  stop_shells
  if command -v waybar >/dev/null 2>&1; then
    waybar >/dev/null 2>&1 &
  fi
  start_mako
}

# Waits up to 8s for the given check to succeed.
wait_for() {
  for _ in {1..40}; do
    if "$1"; then
      return 0
    fi
    sleep 0.2
  done
  "$1"
}

pkill -x waybar >/dev/null 2>&1 || true
stop_mako

if command -v noctalia >/dev/null 2>&1; then
  # --daemon returns once the shell is up.
  timeout 15s noctalia --daemon >"$log_file" 2>&1 || true
  if wait_for noctalia_running; then
    exit 0
  fi
fi

if command -v dms >/dev/null 2>&1; then
  dms run --daemon >>"$log_file" 2>&1 &
  if wait_for dms_running; then
    notify-send "Shell fallback" "Noctalia failed to start, launched DMS" -u low >/dev/null 2>&1 || true
    exit 0
  fi
fi

start_waybar
sleep 0.3
notify-send "Shell fallback" "Noctalia and DMS failed to start, launching Waybar" -u low >/dev/null 2>&1 || true
