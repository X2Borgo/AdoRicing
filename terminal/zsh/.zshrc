# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Theme (Overridden by Starship later, but good fallback)
ZSH_THEME="gozilla"

# Plugins
plugins=(git python pip npm colored-man-pages fzf zsh-interactive-cd)

source $ZSH/oh-my-zsh.sh

# --- 0.0 ADO STARTUP DEBUG ---
# Logs shell startup/display context without writing into the terminal.
export ADO_DISPLAY_LOG="${ADO_DISPLAY_LOG:-${XDG_STATE_HOME:-$HOME/.local/state}/ado-display.log}"

function ado_log() {
    local log_dir="${ADO_DISPLAY_LOG:h}"
    mkdir -p "$log_dir" 2>/dev/null || return 0
    print -r -- "[$(date '+%Y-%m-%d %H:%M:%S')] pid=$$ ppid=$PPID $*" >> "$ADO_DISPLAY_LOG" 2>/dev/null
}

function ado_parent_cmd() {
    ps -o comm= -p "$PPID" 2>/dev/null | tr -d '[:space:]'
}

function ado_is_freelens_shell() {
    local parent_cmd="${1:-$(ado_parent_cmd)}"
    [[ "$parent_cmd" == "freelens" || "$TERM_PROGRAM" == "Freelens" || "$TERM_PROGRAM" == "freelens" ]]
}

function ado_process_chain() {
    local pid="$PPID"
    local chain=()
    local row ppid comm

    while [[ -n "$pid" && "$pid" != "0" && "${#chain[@]}" -lt 8 ]]; do
        row="$(ps -o ppid= -o comm= -p "$pid" 2>/dev/null)"
        [[ -z "$row" ]] && break
        ppid="${row%% *}"
        comm="${row#${ppid}}"
        comm="${comm##[[:space:]]}"
        chain+=("${pid}:${comm:-unknown}")
        pid="$ppid"
    done

    print -r -- "${(j: <- :)chain}"
}

function ado_startup_log() {
    local parent_cmd="$(ado_parent_cmd)"
    ado_log "startup interactive=$([[ -o interactive ]] && print yes || print no) tty=$(tty 2>/dev/null) parent=${parent_cmd:-unknown} chain=$(ado_process_chain) term=${TERM:-unset} term_program=${TERM_PROGRAM:-unset} kitty=${KITTY_WINDOW_ID:-unset} shlvl=${SHLVL:-unset} kubecfg=$([[ -n "${KUBECONFIG:-}" ]] && print set || print unset) pwd=$PWD"
    if ado_is_freelens_shell "$parent_cmd"; then
        ado_log "startup detected=freelens_shell"
    fi
}

ado_startup_log

# --- 0. ADO DISPLAY FUNCTION (With Dynamic Height) ---
function ado_display() {
    local parent_cmd="$(ado_parent_cmd)"
    ado_log "ado_display start interactive=$([[ -o interactive ]] && print yes || print no) tty=$(tty 2>/dev/null) parent=${parent_cmd:-unknown} chain=$(ado_process_chain) term=${TERM:-unset} term_program=${TERM_PROGRAM:-unset} kitty=${KITTY_WINDOW_ID:-unset} kubecfg=$([[ -n "${KUBECONFIG:-}" ]] && print set || print unset) pwd=$PWD"

    if [[ -n "${CODEX_CI:-}" ]]; then
        ado_log "ado_display skip reason=CODEX_CI"
        return 0
    fi

    if ado_is_freelens_shell "$parent_cmd"; then
        ado_log "ado_display skip reason=freelens_shell"
        return 0
    fi

    if [[ ! -t 1 ]]; then
        ado_log "ado_display skip reason=stdout_not_tty"
        return 0
    fi

    local CONFIG_FILE="$HOME/.config/fastfetch/ado.jsonc"
    local CACHE_DIR="/tmp/fastfetch_spotify"
    mkdir -p "$CACHE_DIR"

    # Dynamic Height: Half the terminal height, but at least 10 lines
    local TERM_LINES=$(tput lines)
    local MAX_HEIGHT=$(( TERM_LINES / 2 ))
    if (( MAX_HEIGHT < 10 )); then MAX_HEIGHT=10; fi
    ado_log "ado_display terminal lines=${TERM_LINES:-unknown} max_height=$MAX_HEIGHT"

    # Check if Spotify is running
    if pgrep -x "spotify" > /dev/null; then
        ado_log "ado_display spotify=running"
        local METADATA=$(qdbus6 org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Metadata 2>/dev/null)
        local ART_URL=$(echo "$METADATA" | grep "mpris:artUrl" | cut -d' ' -f2-)
        local TRACK_ID=$(echo "$METADATA" | grep "mpris:trackid" | awk -F'/' '{print $NF}')

        if [[ -n "$ART_URL" && -n "$TRACK_ID" ]]; then
            local COVER_FILE="$CACHE_DIR/${TRACK_ID}.jpg"

            # Download only if new
            if [[ ! -f "$COVER_FILE" ]]; then
                rm -f "$CACHE_DIR"/*.jpg
                curl -s -o "$COVER_FILE" "$ART_URL"
            fi

            # Display with dynamic height limit
            ado_log "ado_display fastfetch mode=spotify cover=$COVER_FILE"
            fastfetch --config "$CONFIG_FILE" --logo "$COVER_FILE" --logo-type auto --logo-width 36 --logo-height "$MAX_HEIGHT"
            return
        fi
    else
        ado_log "ado_display spotify=not_running"
    fi

    # Fallback (Default Image)
    ado_log "ado_display fastfetch mode=fallback"
    fastfetch --config "$CONFIG_FILE" --logo-height "$MAX_HEIGHT"
}

# --- 1. INITIALIZE TOOLS ---
# Run Fastfetch on startup
# ado_display

function set_win_title(){
    echo -ne "\033]0; WORLD ADOMINATION \007"
}

# Initialize Starship Prompt (Must be last)
eval "$(starship init zsh)"

precmd_functions+=(set_win_title)

# --- 2. CURSOR FIX (Force Beam Shape) ---
# 5 = Blinking Beam.
# This ensures Zsh doesn't reset it to a block.
function precmd() {
    printf '\033[5 q'
}

# --- 3. ALIASES ---
alias conf="kate ~/Desktop/AdoRicing/terminalCustomization/zsh/.zshrc"
alias re="source $HOME/.zshrc"
alias c="clear" # 'clear' is overridden below to show Ado
alias kconf="kate ~/Desktop/AdoRicing/terminalCustomization/kitty/kitty.conf"
alias fconf="kate $HOME/.config/fastfetch/ado.jsonc"

# Custom zed workspace aliases
alias ado="cd ~/Desktop/AdoRicing && zed ."
alias adoi="~/Desktop/AdoRicing/install.sh"
alias dora="cd ~/Desktop/DoraFeature && zed ."
alias pn="cd ~/Desktop/price-ninja-css && zed ."
alias drv="cd ~/Desktop/DreviaEsports && zed ."

alias bigup='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y'
alias rdms="dms kill && ~/.config/hypr/scripts/LaunchShell.sh"

alias gg="gemini"
alias gs="git status"
alias z="zed ."
alias k="kubecolor"

# Create the standard alias for typing 'clear'
alias clear="tput reset && ado_display && set_win_title"

# --- 3.1 BINDKEYS---

# Bind Ctrl+Delete to delete the word in front of the cursor
bindkey "^[[3;5~" kill-word
# Often, people want Ctrl+Backspace too:
bindkey "^H" backward-kill-word
# bind ctrl+shift+a to select all text
select-all() {
  zle beginning-of-line
  zle set-mark-command
  zle end-of-line
}
zle -N select-all
bindkey "^[[97;6u" select-all

# --- 4. ENVIRONMENT & PATHS ---
. "$HOME/.local/bin/env"
export PATH="$PATH:$HOME/.local/bin"
export PATH=$PATH:$(go env GOPATH)/bin
export PATH="$PATH:$HOME/development/flutter/bin"
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
if [ -d "$HOME/.nix-profile/bin" ]; then export PATH="$HOME/.nix-profile/bin:$PATH"; fi
if [ -d "/nix/var/nix/profiles/default/bin" ]; then export PATH="/nix/var/nix/profiles/default/bin:$PATH"; fi

# Google Cloud SDK
if [ -f '/home/alborghi/google-cloud-sdk/path.zsh.inc' ]; then . '/home/alborghi/google-cloud-sdk/path.zsh.inc'; fi
if [ -f '/home/alborghi/google-cloud-sdk/completion.zsh.inc' ]; then . '/home/alborghi/google-cloud-sdk/completion.zsh.inc'; fi

# Angular & UV Autocomplete
source <(ng completion script)
eval "$(uv generate-shell-completion zsh)"
eval "$(uvx --generate-shell-completion zsh)"
