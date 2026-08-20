#!/usr/bin/env bash
# Open a URL/file in the user's browser WITHOUT xdg-open: on this system
# xdg-utils' desktop detection falls through to xprop, which hangs forever
# (DISPLAY is set but no Xwayland runs). Go straight to a real browser.
set -u

url="$1"

candidates=(
    "${BROWSER:-}"
    "$HOME/.local/share/applications/downloaded/zen/zen"
    zen
    google-chrome
    firefox
)

for b in "${candidates[@]}"; do
    [ -n "$b" ] && command -v "$b" > /dev/null 2>&1 && exec "$b" "$url"
done

exec xdg-open "$url"   # last resort
