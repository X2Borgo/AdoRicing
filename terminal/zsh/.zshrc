# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Theme (Overridden by Starship later, but good fallback)
ZSH_THEME="gozilla"

# Plugins
plugins=(git python pip npm colored-man-pages fzf zsh-interactive-cd)

source $ZSH/oh-my-zsh.sh

# --- 0. ADO DISPLAY FUNCTION (With Dynamic Height) ---
function ado_display() {
    local CONFIG_FILE="$HOME/.config/fastfetch/ado.jsonc"
    local CACHE_DIR="/tmp/fastfetch_spotify"
    mkdir -p "$CACHE_DIR"

    # Dynamic Height: Half the terminal height, but at least 10 lines
    local TERM_LINES=$(tput lines)
    local MAX_HEIGHT=$(( TERM_LINES / 2 ))
    if (( MAX_HEIGHT < 10 )); then MAX_HEIGHT=10; fi

    # Check if Spotify is running
    if pgrep -x "spotify" > /dev/null; then
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
            fastfetch --config "$CONFIG_FILE" --logo "$COVER_FILE" --logo-type auto --logo-width 36 --logo-height "$MAX_HEIGHT"
            return
        fi
    fi

    # Fallback (Default Image)
    fastfetch --config "$CONFIG_FILE" --logo-height "$MAX_HEIGHT"
}

# --- 1. INITIALIZE TOOLS ---
# Run Fastfetch on startup
ado_display

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
alias ado="zed ~/Desktop/AdoRicing"

alias gg="gemini"
alias z="zed ."

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

# Google Cloud SDK
if [ -f '/home/alborghi/google-cloud-sdk/path.zsh.inc' ]; then . '/home/alborghi/google-cloud-sdk/path.zsh.inc'; fi
if [ -f '/home/alborghi/google-cloud-sdk/completion.zsh.inc' ]; then . '/home/alborghi/google-cloud-sdk/completion.zsh.inc'; fi

# Angular & UV Autocomplete
source <(ng completion script)
eval "$(uv generate-shell-completion zsh)"
eval "$(uvx --generate-shell-completion zsh)"
