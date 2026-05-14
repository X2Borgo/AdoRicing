#!/usr/bin/env bash
# /* ---- 💫 https://github.com/LinuxBeginnings 💫 ---- */  ##

set -u

weather_script="$HOME/.config/hypr/UserScripts/WeatherWrap.sh"

update_weather() {
    bash "$weather_script" >/dev/null 2>&1 || true
}

dms_ipc() {
    command -v dms >/dev/null 2>&1 || return 1
    timeout 2s dms ipc "$@" 2>/dev/null
}

dms_lock() {
    dms_ipc call lock lock >/dev/null
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
        hyprlock -q >/dev/null 2>&1 &
    fi

    return 0
}

trigger_logind_lock() {
    loginctl lock-session >/dev/null 2>&1
}

handle_logind_hook() {
    if wait_for_dms_lock; then
        exit 0
    fi

    start_hyprlock_fallback
}

handle_manual_lock() {
    update_weather

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
    *)
        handle_manual_lock
        ;;
esac
