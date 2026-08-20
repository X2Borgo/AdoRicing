#!/usr/bin/env bash
# WaybarCava.sh — safer single-instance handling, cleanup, and robustness
# Original concept by LinuxBeginnings; this variant focuses on lifecycle hardening.

set -euo pipefail

# Ensure cava exists
if ! command -v cava >/dev/null 2>&1; then
  echo "cava not found in PATH" >&2
  exit 1
fi

# 0..7 → ▁▂▃▄▅▆▇█
bar="▁▂▃▄▅▆▇█"
dict="s/;//g"
bar_length=${#bar}
for ((i = 0; i < bar_length; i++)); do
  dict+=";s/$i/${bar:$i:1}/g"
done

# Runtime dir for temp config file
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"

# Unique temp config + cleanup on exit
config_file="$(mktemp "$RUNTIME_DIR/waybar-cava.XXXXXX.conf")"
cleanup() {
  # Kill children (cava, sed) of this script, then remove files
  pkill -P "$$" 2>/dev/null || true
  rm -f "$config_file"
}
trap cleanup EXIT INT TERM

cat >"$config_file" <<EOF
[general]
framerate = 30
bars = 10

[input]
method = pulse
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
EOF

# Stream cava output and translate digits 0..7 to bar glyphs
# (no exec: keep this shell as the parent so the trap can reap children)
cava -p "$config_file" | sed -u "$dict"
