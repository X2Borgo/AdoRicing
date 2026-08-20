#!/usr/bin/env bash

set -euo pipefail

secret_dir="${XDG_CONFIG_HOME:-$HOME/.config}/DankMaterialShell/secrets"
url_file="$secret_dir/google-calendar-ical-url"

printf 'Google Calendar private iCal URL: '
IFS= read -r -s calendar_url
printf '\n'

if [[ "$calendar_url" != https://* ]]; then
    printf 'Expected an HTTPS URL; nothing changed.\n' >&2
    exit 1
fi

install -d -m 700 "$secret_dir"
umask 077
printf '%s\n' "$calendar_url" > "$url_file"
chmod 600 "$url_file"

printf 'Calendar URL stored at %s\n' "$url_file"
printf 'Refresh App Inbox or restart DMS to connect.\n'
