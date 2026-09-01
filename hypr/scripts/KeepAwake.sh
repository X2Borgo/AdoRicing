#!/usr/bin/env bash
# KeepAwake.sh — run a command while holding a systemd sleep/lid inhibitor.
#
# Closing the lid makes logind suspend the whole machine (HandleLidSwitch=suspend),
# which freezes every process. There is no way to exempt a single process from a
# suspend, so instead we block the suspend for as long as the command runs.
#
# Usage:
#   KeepAwake.sh claude
#   KeepAwake.sh -- npm run build
#   KeepAwake.sh --why "long training run" python train.py
#
# The inhibitor dies with the command, so the laptop goes back to normal
# lid-suspend behaviour the moment the job finishes.

set -euo pipefail

why="keep-awake: long-running job"

while [ $# -gt 0 ]; do
  case "$1" in
    --why) why="${2:?--why needs a value}"; shift 2 ;;
    --) shift; break ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) break ;;
  esac
done

if [ $# -eq 0 ]; then
  echo "KeepAwake.sh: no command given" >&2
  exit 2
fi

if ! command -v systemd-inhibit >/dev/null 2>&1; then
  echo "KeepAwake.sh: systemd-inhibit not found; running without inhibitor" >&2
  exec "$@"
fi

# handle-lid-switch  -> lid close does nothing
# sleep              -> systemctl suspend / hypridle suspend is blocked
# idle               -> idle timers do not fire
exec systemd-inhibit \
  --what=handle-lid-switch:sleep:idle \
  --who="KeepAwake" \
  --why="$why" \
  --mode=block \
  "$@"
