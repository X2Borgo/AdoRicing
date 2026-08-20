#!/usr/bin/env bash

set -euo pipefail

config_file="$HOME/.config/hypr/UserConfigs/01-UserDefaults.conf"
rofi_theme="$HOME/.config/rofi/config-edit.rasi"
iDIR="$HOME/.config/swaync/images"
terminal_cmd="${TERMINAL:-kitty}"

notify_user() {
    local title="$1"
    local body="$2"
    local icon="${3:-}"

    if [[ -n "$icon" && -f "$icon" ]]; then
        notify-send -u low -i "$icon" "$title" "$body"
    else
        notify-send -u low "$title" "$body"
    fi
}

load_terminal_preference() {
    [[ -f "$config_file" ]] || return 0

    local tmp_config_file
    tmp_config_file="$(mktemp)"
    sed 's/^\$//g; s/ = /=/g' "$config_file" >"$tmp_config_file"
    # shellcheck disable=SC1090
    source "$tmp_config_file"
    rm -f "$tmp_config_file"

    if [[ -n "${term:-}" ]]; then
        terminal_cmd="$term"
    fi
}

require_command() {
    command -v "$1" >/dev/null 2>&1
}

run_in_terminal() {
    local title="$1"
    shift

    if require_command "$terminal_cmd"; then
        case "$terminal_cmd" in
            kitty)
                kitty --title "$title" sh -lc "$*; printf '\nPress Enter to close...'; read -r" >/dev/null 2>&1 &
                ;;
            ghostty)
                ghostty --title="$title" -e sh -lc "$*; printf '\nPress Enter to close...'; read -r" >/dev/null 2>&1 &
                ;;
            foot)
                foot sh -lc "$*; printf '\nPress Enter to close...'; read -r" >/dev/null 2>&1 &
                ;;
            wezterm)
                wezterm start -- sh -lc "$*; printf '\nPress Enter to close...'; read -r" >/dev/null 2>&1 &
                ;;
            alacritty)
                alacritty -t "$title" -e sh -lc "$*; printf '\nPress Enter to close...'; read -r" >/dev/null 2>&1 &
                ;;
            *)
                "$terminal_cmd" -e sh -lc "$*; printf '\nPress Enter to close...'; read -r" >/dev/null 2>&1 &
                ;;
        esac
        return 0
    fi

    if require_command kitty; then
        kitty --title "$title" sh -lc "$*; printf '\nPress Enter to close...'; read -r" >/dev/null 2>&1 &
        return 0
    fi

    notify_user "Docker menu" "No supported terminal was found." "$iDIR/error.png"
    return 1
}

rofi_pick() {
    local prompt="$1"
    local message="${2:-}"
    shift 2

    printf '%s\n' "$@" | rofi -i -dmenu -config "$rofi_theme" -p "$prompt" -mesg "$message"
}

pick_container() {
    local prompt="$1"
    local all_flag="${2:-false}"
    local format='{{.Names}}'
    local cmd=(docker ps --format "$format")

    if [[ "$all_flag" == "true" ]]; then
        cmd=(docker ps -a --format "$format")
    fi

    mapfile -t containers < <("${cmd[@]}" | sed '/^$/d')

    if (( ${#containers[@]} == 0 )); then
        notify_user "Docker menu" "No containers available for this action." "$iDIR/info.png"
        return 1
    fi

    rofi_pick "$prompt" "Select a container" "${containers[@]}"
}

docker_exec_shell() {
    local container="$1"
    local shell_cmd='if command -v bash >/dev/null 2>&1; then exec bash; elif command -v sh >/dev/null 2>&1; then exec sh; else echo "No shell found inside container."; read -r; fi'
    run_in_terminal "docker:$container" "docker exec -it \"$container\" sh -lc '$shell_cmd'"
}

compose_project_dir() {
    local dir
    dir="$(printf '%s' "${DOCKER_COMPOSE_DIR:-$HOME}" | rofi -dmenu -config "$rofi_theme" -p "Compose dir" -mesg "Enter a folder that contains docker-compose.yml or compose.yaml")"

    [[ -n "$dir" ]] || return 1

    dir="${dir/#\~/$HOME}"

    if [[ ! -d "$dir" ]]; then
        notify_user "Docker menu" "Directory not found: $dir" "$iDIR/error.png"
        return 1
    fi

    printf '%s\n' "$dir"
}

show_main_menu() {
    rofi_pick "Docker" "Choose an action" \
        "Running containers" \
        "All containers" \
        "Images" \
        "Compose projects" \
        "Container logs" \
        "Start container" \
        "Stop container" \
        "Restart container" \
        "Open shell in container" \
        "Compose up -d" \
        "Compose down"
}

main() {
    load_terminal_preference

    if ! require_command rofi; then
        notify_user "Docker menu" "rofi is required to open the Docker menu." "$iDIR/error.png"
        exit 1
    fi

    if ! require_command docker; then
        notify_user "Docker menu" "docker is not installed or not in PATH." "$iDIR/error.png"
        exit 1
    fi

    case "${1:-}" in
        --ps)
            run_in_terminal "docker:ps" "docker ps"
            exit 0
            ;;
        --ps-all)
            run_in_terminal "docker:psa" "docker ps -a"
            exit 0
            ;;
        --images)
            run_in_terminal "docker:images" "docker images"
            exit 0
            ;;
        --compose-ps)
            run_in_terminal "docker:compose-ps" "docker compose ps"
            exit 0
            ;;
    esac

    if pgrep -x rofi >/dev/null 2>&1; then
        pkill rofi
    fi

    local choice
    choice="$(show_main_menu)"
    [[ -n "$choice" ]] || exit 0

    case "$choice" in
        "Running containers")
            run_in_terminal "docker:ps" "docker ps"
            ;;
        "All containers")
            run_in_terminal "docker:psa" "docker ps -a"
            ;;
        "Images")
            run_in_terminal "docker:images" "docker images"
            ;;
        "Compose projects")
            run_in_terminal "docker:compose-ps" "docker compose ps"
            ;;
        "Container logs")
            container="$(pick_container "Logs" true)" || exit 0
            run_in_terminal "docker:logs:$container" "docker logs --tail 200 -f \"$container\""
            ;;
        "Start container")
            container="$(pick_container "Start" true)" || exit 0
            docker start "$container" >/dev/null
            notify_user "Docker menu" "Started container: $container" "$iDIR/ja.png"
            ;;
        "Stop container")
            container="$(pick_container "Stop" false)" || exit 0
            docker stop "$container" >/dev/null
            notify_user "Docker menu" "Stopped container: $container" "$iDIR/ja.png"
            ;;
        "Restart container")
            container="$(pick_container "Restart" true)" || exit 0
            docker restart "$container" >/dev/null
            notify_user "Docker menu" "Restarted container: $container" "$iDIR/ja.png"
            ;;
        "Open shell in container")
            container="$(pick_container "Shell" false)" || exit 0
            docker_exec_shell "$container"
            ;;
        "Compose up -d")
            dir="$(compose_project_dir)" || exit 0
            run_in_terminal "docker:compose-up" "cd \"$dir\" && docker compose up -d"
            ;;
        "Compose down")
            dir="$(compose_project_dir)" || exit 0
            run_in_terminal "docker:compose-down" "cd \"$dir\" && docker compose down"
            ;;
    esac
}

main "$@"
