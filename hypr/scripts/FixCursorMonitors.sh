#!/usr/bin/env bash

# Work around a Hyprland 0.55 (Lua build) bug: with more than one monitor the
# pointer can stay clamped inside a single output's box, so the cursor refuses
# to cross to the other screen (it parks on the seam, e.g. x=1919 of a 1920-wide
# laptop panel). Seen both after a hotplug and at startup with the external
# monitor already attached.
#
# What actually cures it, established empirically on this machine:
#   * `hyprctl reload` alone            -> does NOT clear the clamp
#   * the `movecursor` dispatcher       -> reports ok, moves nothing
#   * injected pointer motion alone     -> still clamped at the seam
#   * reload, THEN injected motion      -> clears it
# So both halves are required, in that order.
#
# Usage:
#   --once    settle, unstick, exit
#   --watch   startup pass, then unstick after every monitor change (default)

set -uo pipefail

readonly LOG_TAG="FixCursorMonitors"
readonly SETTLE_TRIES=30 # 30 * 0.5s = 15s ceiling waiting for outputs
readonly DEBOUNCE=2      # seconds of quiet before acting on a hotplug burst

log() { printf '%s %s: %s\n' "$(date '+%H:%M:%S')" "$LOG_TAG" "$*" >&2; }

require() {
  local missing=0 cmd
  for cmd in "$@"; do
    command -v "$cmd" >/dev/null 2>&1 || { log "missing dependency: $cmd"; missing=1; }
  done
  return "$missing"
}

monitor_count() { hyprctl monitors -j 2>/dev/null | jq 'length' 2>/dev/null || echo 0; }

cursor_pos() { hyprctl cursorpos 2>/dev/null | tr -d ' '; }

# Bottom-right corner of the whole logical layout (scale-aware).
layout_extent() {
  hyprctl monitors -j 2>/dev/null | jq -r '
    [.[] | {x: (.x + (.width / .scale)), y: (.y + (.height / .scale))}] as $m
    | "\(($m | map(.x) | max) | floor),\(($m | map(.y) | max) | floor)"
  ' 2>/dev/null
}

focused_center() {
  hyprctl monitors -j 2>/dev/null | jq -r '
    (first(.[] | select(.focused)) // .[0])
    | "\((.x + (.width / .scale / 2)) | floor),\((.y + (.height / .scale / 2)) | floor)"
  ' 2>/dev/null
}

# Wait until the monitor count stops changing, so a flapping HDMI link settles
# before we touch anything.
wait_for_settle() {
  local last=-1 now stable=0 i
  for ((i = 0; i < SETTLE_TRIES; i++)); do
    now="$(monitor_count)"
    if [[ "$now" == "$last" ]] && ((now > 0)); then
      ((++stable >= 2)) && return 0
    else
      stable=0
    fi
    last="$now"
    sleep 0.5
  done
}

# Absolute move built from relative deltas: reliable once the clamp is gone,
# unlike ydotool's own absolute mapping.
#
# One unit of injected motion does not equal one logical pixel — on a scaled
# monitor it is amplified (2x on a scale-2 output), so a naive "move by the
# delta" overshoots by exactly the gain and oscillates forever. Request half
# the delta first, measure what actually happened, then divide by the observed
# gain. Percent-scaled integer maths keeps it in bash.
warp_to() {
  local target_x="$1" target_y="$2" tolerance=25
  local pos cx cy px py dx dy gain=200 moved requested i

  for ((i = 0; i < 6; i++)); do
    pos="$(cursor_pos)"
    cx="${pos%%,*}"
    cy="${pos##*,}"
    [[ "$cx" =~ ^-?[0-9]+$ && "$cy" =~ ^-?[0-9]+$ ]] || return 1

    dx=$((target_x - cx))
    dy=$((target_y - cy))
    ((dx * dx + dy * dy <= tolerance * tolerance)) && return 0

    # re-measure the gain from the previous step where we can (x only: y often
    # saturates against the top/bottom edge and would poison the estimate)
    if ((i > 0)); then
      moved=$((cx - px))
      ((moved < 0)) && moved=$((-moved))
      ((requested < 0)) && requested=$((-requested))
      if ((requested > 20 && moved > 0)); then
        gain=$((moved * 100 / requested))
        ((gain < 25)) && gain=25
        ((gain > 400)) && gain=400
      fi
    fi

    px="$cx"
    py="$cy"
    requested=$((dx * 100 / gain))
    ydotool mousemove -x "$requested" -y "$((dy * 100 / gain))" >/dev/null 2>&1 || return 1
    sleep 0.15
  done

  return 0
}

unstick() {
  local before extent ex ey home
  if (($(monitor_count) < 2)); then
    log "single monitor, nothing to do"
    return 0
  fi

  before="$(cursor_pos)"
  extent="$(layout_extent)"
  ex="${extent%%,*}"
  ey="${extent##*,}"
  [[ "$ex" =~ ^[0-9]+$ && "$ey" =~ ^[0-9]+$ ]] || { log "could not read layout extent"; return 1; }

  # 1. recompute the layout
  hyprctl reload >/dev/null 2>&1
  sleep 1

  # 2. slam the pointer into the far corner with injected input: this is the
  #    half that actually clears the stale clamp.
  ydotool mousemove -a -x "$ex" -y "$ey" >/dev/null 2>&1
  sleep 0.3

  # 3. park it back on the focused monitor instead of a random corner
  home="$(focused_center)"
  [[ -n "$home" ]] && warp_to "${home%%,*}" "${home##*,}"

  log "unstuck (was $before, layout ${ex}x${ey}, now $(cursor_pos))"
}

watch_mode() {
  local socket="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.socket2.sock"
  if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" || ! -S "$socket" ]]; then
    log "Hyprland event socket not found ($socket)"
    return 1
  fi

  # one instance per Hyprland session
  local lock="${XDG_RUNTIME_DIR:-/tmp}/ado-fix-cursor-monitors.lock"
  exec 9>"$lock"
  flock -n 9 || { log "already running"; return 0; }

  wait_for_settle
  unstick

  local pending=0 line
  while true; do
    if read -r -t 1 line; then
      case "$line" in
        monitoradded*| monitorremoved*) pending="$DEBOUNCE" ;;
      esac
    else
      # idle tick: count down the debounce, then act once the burst is over
      if ((pending > 0)); then
        ((pending--))
        ((pending == 0)) && { wait_for_settle; unstick; }
      fi
    fi
  done < <(socat -u UNIX-CONNECT:"$socket" -)
}

require hyprctl jq ydotool || exit 1

case "${1:---watch}" in
  --once)
    wait_for_settle
    unstick
    ;;
  --watch)
    require socat || exit 1
    watch_mode
    ;;
  *)
    echo "usage: ${0##*/} [--once|--watch]" >&2
    exit 2
    ;;
esac
