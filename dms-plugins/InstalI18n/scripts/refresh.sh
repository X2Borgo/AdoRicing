#!/usr/bin/env bash
# Re-collect Django i18n stats across the Instal workspace, rebuild the local
# dashboard, and print the compact widget summary JSON to stdout.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/instal-i18n"
WORKSPACE="${INSTAL_WORKSPACE:-$HOME/Desktop/Instal}"

mkdir -p "$CACHE"
python3 "$DIR/collect_i18n.py" "$WORKSPACE" > "$CACHE/data.json.tmp"
mv "$CACHE/data.json.tmp" "$CACHE/data.json"
python3 "$DIR/build_dashboard.py" "$CACHE/data.json" "$CACHE/dashboard.html"
python3 "$DIR/summarize.py" "$CACHE/data.json"
