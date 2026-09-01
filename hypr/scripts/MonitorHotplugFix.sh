#!/usr/bin/env bash
# Workaround for a Hyprland 0.55 (Lua build) bug: after a monitor is added,
# the cursor stays clamped to the old layout until the config is reloaded.
# Listens on Hyprland's event socket and reloads when a monitor appears.

set -u

SOCKET="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.socket2.sock"

if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" || ! -S "$SOCKET" ]]; then
  echo "MonitorHotplugFix: Hyprland event socket not found ($SOCKET)" >&2
  exit 1
fi

# Only one instance per Hyprland session
LOCK="${XDG_RUNTIME_DIR:-/tmp}/ado-monitor-hotplug-fix.lock"
exec 9>"$LOCK"
flock -n 9 || exit 0

socat -u UNIX-CONNECT:"$SOCKET" - | while read -r line; do
  case "$line" in
    monitoradded'>>'* | monitoraddedv2'>>'*)
      # Give Hyprland a moment to finish bringing the output up,
      # then reload so the cursor bounds pick up the new monitor.
      sleep 1
      hyprctl reload >/dev/null
      ;;
  esac
done
