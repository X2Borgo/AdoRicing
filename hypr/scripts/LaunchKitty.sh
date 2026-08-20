#!/usr/bin/env bash

# Restore the saved session only for the first Kitty instance. Additional
# windows should be fresh rather than duplicating every resumed agent thread.

set -u

if pgrep -x kitty >/dev/null 2>&1; then
  exec kitty --session none
fi

exec kitty
