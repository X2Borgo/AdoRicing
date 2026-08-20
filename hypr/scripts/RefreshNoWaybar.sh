#!/usr/bin/env bash
# /* ---- 💫 https://github.com/LinuxBeginnings 💫 ---- */  ##

# Modified version of Refresh.sh but waybar wont refresh
# Used by automatic wallpaper change
# Refresh rofi background, Wallust, and the DMS shell only

SCRIPTSDIR=$HOME/.config/hypr/scripts
UserScripts=$HOME/.config/hypr/UserScripts

# Define file_exists function
file_exists() {
    if [ -e "$1" ]; then
        return 0  # File exists
    else
        return 1  # File does not exist
    fi
}

shell_running() {
    pgrep -x qs >/dev/null 2>&1 || pgrep -x quickshell >/dev/null 2>&1
}

restart_quickshell_if_active() {
    if ! shell_running; then
        return 0
    fi

    if command -v dms >/dev/null 2>&1; then
        dms restart >/dev/null 2>&1 || true
        return 0
    fi

    pkill -x qs >/dev/null 2>&1 || true
    pkill -x quickshell >/dev/null 2>&1 || true
    "${SCRIPTSDIR}/LaunchShell.sh" >/dev/null 2>&1 &
}

# Kill already running processes
_ps=(rofi)
for _prs in "${_ps[@]}"; do
    if pidof "${_prs}" >/dev/null; then
        pkill "${_prs}"
    fi
done

restart_quickshell_if_active

# Wallust refresh (synchronous to ensure colors are ready)
${SCRIPTSDIR}/WallustSwww.sh
sleep 0.2

# Relaunching rainbow borders if the script exists
sleep 1
if file_exists "${UserScripts}/RainbowBorders.sh"; then
    ${UserScripts}/RainbowBorders.sh &
fi


exit 0
