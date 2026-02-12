#!/bin/bash
# Optional: sync selected theme/config files to remote nodes.

sync_script="$HOME/.config/symphony/scripts/remote-sync"
[[ -x "$sync_script" ]] || exit 0

"$sync_script" >/dev/null 2>&1 &
exit 0

