#!/usr/bin/env bash
# /* ---- 💫 https://github.com/LinuxBeginnings 💫 ---- */  ##
# Scripts for refreshing the DMS shell, rofi, and wallust

SCRIPTSDIR=$HOME/.config/hypr/scripts
UserScripts=$HOME/.config/hypr/UserScripts

# Define file_exists function
file_exists() {
  if [ -e "$1" ]; then
    return 0 # File exists
  else
    return 1 # File does not exist
  fi
}

restart_shell() {
  if command -v dms >/dev/null 2>&1; then
    dms kill >/dev/null 2>&1 || true
  fi

  pkill -x qs >/dev/null 2>&1 || true
  pkill -x quickshell >/dev/null 2>&1 || true
  pkill -x ags >/dev/null 2>&1 || true
  pkill -x waybar >/dev/null 2>&1 || true

  "$SCRIPTSDIR/LaunchShell.sh" >/dev/null 2>&1 &
}

# Kill already running processes
_ps=(rofi)
for _prs in "${_ps[@]}"; do
  if pidof "${_prs}" >/dev/null; then
    pkill "${_prs}"
  fi
done

# Clean up any Waybar-spawned cava instances (unique temp conf names)
pkill -f 'waybar-cava\..*\.conf' 2>/dev/null || true
restart_shell
sleep 0.3

# Relaunching rainbow borders if the script exists
sleep 1
if file_exists "${UserScripts}/RainbowBorders.sh"; then
  ${UserScripts}/RainbowBorders.sh &
fi

exit 0
