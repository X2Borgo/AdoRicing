#!/usr/bin/env bash
# Print the widget summary JSON from the cached data; collect first if there
# is no cache yet.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/instal-i18n"

if [[ ! -f "$CACHE/data.json" ]]; then
    exec "$DIR/refresh.sh"
fi
python3 "$DIR/summarize.py" "$CACHE/data.json"
