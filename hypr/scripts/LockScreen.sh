#!/usr/bin/env bash
# /* ---- 💫 https://github.com/LinuxBeginnings 💫 ---- */  ##

set -u

weather_script="$HOME/.config/hypr/UserScripts/WeatherWrap.sh"

update_weather() {
    bash "$weather_script" >/dev/null 2>&1 || true
}

noctalia_running() {
    command -v noctalia >/dev/null 2>&1 && pgrep -x noctalia >/dev/null 2>&1
}

# Noctalia has no lock-state query; a successful IPC reply means the lock
# surface was requested.
noctalia_lock() {
    noctalia_running || return 1
    timeout 2s noctalia msg session lock >/dev/null 2>&1
}

noctalia_lock_blackout() {
    noctalia_lock || return 1
    # Let the lock surface map before blanking, or the desktop flashes on wake.
    sleep 0.5
    timeout 2s noctalia msg dpms-off >/dev/null 2>&1 || hyprctl dispatch dpms off >/dev/null 2>&1 || true
}

dms_ipc() {
    command -v dms >/dev/null 2>&1 || return 1
    timeout 2s dms ipc "$@" 2>/dev/null
}

dms_lock() {
    dms_ipc call lock lock >/dev/null
}

# Locks and immediately powers the outputs down, so the machine looks off.
dms_lock_blackout() {
    dms_ipc call lock lockAndOutputsOff >/dev/null
}

dms_is_locked() {
    [[ "$(dms_ipc call lock isLocked | tr -d '\r\n')" == "true" ]]
}

wait_for_dms_lock() {
    local attempts=20

    command -v dms >/dev/null 2>&1 || return 1

    while (( attempts > 0 )); do
        if dms_is_locked; then
            return 0
        fi

        sleep 0.1
        attempts=$((attempts - 1))
    done

    return 1
}

start_hyprlock_fallback() {
    command -v hyprlock >/dev/null 2>&1 || return 1

    if ! pidof hyprlock >/dev/null 2>&1; then
        # grace is a CLI flag since hyprlock 0.9.x (the general:grace option was removed)
        hyprlock -q --grace 1 >/dev/null 2>&1 &
    fi

    return 0
}

# Fallback for --stealth: an all-black hyprlock surface plus DPMS off. If input
# wakes the outputs back up, hyprlock-black.conf still draws nothing but black.
start_hyprlock_blackout_fallback() {
    command -v hyprlock >/dev/null 2>&1 || return 1

    if ! pidof hyprlock >/dev/null 2>&1; then
        hyprlock -q --grace 0 -c "$HOME/.config/hypr/hyprlock-black.conf" >/dev/null 2>&1 &
    fi

    # Give hyprlock a moment to map its surface before blanking the outputs,
    # otherwise the desktop flashes when DPMS comes back on.
    sleep 0.5
    hyprctl dispatch dpms off >/dev/null 2>&1 || true

    return 0
}

trigger_logind_lock() {
    loginctl lock-session >/dev/null 2>&1
}

handle_logind_hook() {
    # Noctalia locks itself on logind's Lock signal.
    if noctalia_running; then
        exit 0
    fi

    if wait_for_dms_lock; then
        exit 0
    fi

    start_hyprlock_fallback
}

# Stealth lock: no weather refresh, no clock, no glow -- lock and kill the
# backlight so the screen is indistinguishable from a powered-off monitor.
handle_stealth_lock() {
    if noctalia_lock_blackout; then
        exit 0
    fi

    if dms_lock_blackout && wait_for_dms_lock; then
        trigger_logind_lock || true
        exit 0
    fi

    if trigger_logind_lock && wait_for_dms_lock; then
        dms_lock_blackout || hyprctl dispatch dpms off >/dev/null 2>&1 || true
        exit 0
    fi

    start_hyprlock_blackout_fallback
}

handle_manual_lock() {
    update_weather

    if noctalia_lock; then
        exit 0
    fi

    if dms_lock && wait_for_dms_lock; then
        trigger_logind_lock || true
        exit 0
    fi

    if trigger_logind_lock; then
        if wait_for_dms_lock; then
            exit 0
        fi
    fi

    start_hyprlock_fallback
}

case "${1:-}" in
    --logind-hook)
        handle_logind_hook
        ;;
    --stealth|--blackout)
        handle_stealth_lock
        ;;
    *)
        handle_manual_lock
        ;;
esac
