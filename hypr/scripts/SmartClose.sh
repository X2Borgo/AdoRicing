#!/usr/bin/env bash

# Save a resumable Kitty startup session before asking Hyprland to close it.

set -u

scripts_dir="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts"
active_window="$(hyprctl activewindow -j 2>/dev/null)" || exit 1
address="$(jq -r '.address // empty' <<< "$active_window")"
window_class="$(jq -r '.class // empty' <<< "$active_window")"
window_pid="$(jq -r '.pid // empty' <<< "$active_window")"

[[ "$address" =~ ^0x[0-9a-fA-F]+$ ]] || exit 1

if [[ "${window_class,,}" == "kitty" ]]; then
  if ! "$scripts_dir/SaveKittySession.sh" --save --pid "$window_pid"; then
    notify-send -u critical "Kitty was not closed" \
      "The tab/session state could not be saved. Try Super+Q again."
    exit 1
  fi
fi

hyprctl dispatch "hl.dsp.window.close({ window = \"address:$address\" })"
