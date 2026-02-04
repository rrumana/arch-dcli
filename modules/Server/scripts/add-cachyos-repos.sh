#!/usr/bin/env bash
set -euo pipefail

conf="/etc/pacman.conf"
tmp="$(mktemp)"

block="$(cat <<'EOF'
# BEGIN DCLI CACHYOS REPOS
[cachyos-znver4]
Include = /etc/pacman.d/cachyos-mirrorlist

[cachyos-core-znver4]
Include = /etc/pacman.d/cachyos-mirrorlist

[cachyos-extra-znver4]
Include = /etc/pacman.d/cachyos-mirrorlist

[cachyos-v4]
Include = /etc/pacman.d/cachyos-mirrorlist

[cachyos-core-v4]
Include = /etc/pacman.d/cachyos-mirrorlist

[cachyos-extra-v4]
Include = /etc/pacman.d/cachyos-mirrorlist
# END DCLI CACHYOS REPOS
EOF
)"

if grep -q "# BEGIN DCLI CACHYOS REPOS" "$conf"; then
  awk -v block="$block" '
    /# BEGIN DCLI CACHYOS REPOS/ { print block; inblock=1; next }
    /# END DCLI CACHYOS REPOS/ { inblock=0; next }
    !inblock { print }
  ' "$conf" > "$tmp"
else
  awk -v block="$block" '
    /^\[core\]/ && !inserted { print block; inserted=1 }
    { print }
    END { if (!inserted) print block }
  ' "$conf" > "$tmp"
fi

install -m 644 "$tmp" "$conf"
rm -f "$tmp"
