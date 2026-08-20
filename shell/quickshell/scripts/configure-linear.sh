#!/usr/bin/env bash

set -euo pipefail

secret_dir="${XDG_CONFIG_HOME:-$HOME/.config}/DankMaterialShell/secrets"
key_file="$secret_dir/linear-api-key"

printf 'Linear personal API key: '
IFS= read -r -s api_key
printf '\n'

if [[ -z "$api_key" ]]; then
    printf 'No key entered; nothing changed.\n' >&2
    exit 1
fi

install -d -m 700 "$secret_dir"
umask 077
printf '%s\n' "$api_key" > "$key_file"
chmod 600 "$key_file"

printf 'Linear key stored at %s\n' "$key_file"
printf 'Refresh App Inbox or restart DMS to connect.\n'
