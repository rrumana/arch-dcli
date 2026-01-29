#!/bin/bash
# shared helpers and color extraction

RED='\033[0;31m' GREEN='\033[0;32m' BLUE='\033[0;34m' RESET='\033[0m'
ok()   { echo -e "${GREEN}[OK]${RESET} $1"; }
err()  { echo -e "${RED}[ERROR]${RESET} $1" >&2; }
info() { echo -e "${BLUE}[INFO]${RESET} $1"; }

hex() { echo "${1#\#}"; }

lighten() {
    local hex="${1#\#}" amt="${2:-20}"
    local r=$((16#${hex:0:2})) g=$((16#${hex:2:2})) b=$((16#${hex:4:2}))
    r=$((r + amt > 255 ? 255 : r + amt))
    g=$((g + amt > 255 ? 255 : g + amt))
    b=$((b + amt > 255 ? 255 : b + amt))
    printf "#%02x%02x%02x" $r $g $b
}

darken() {
    local hex="${1#\#}" amt="${2:-20}"
    local r=$((16#${hex:0:2})) g=$((16#${hex:2:2})) b=$((16#${hex:4:2}))
    r=$((r - amt < 0 ? 0 : r - amt))
    g=$((g - amt < 0 ? 0 : g - amt))
    b=$((b - amt < 0 ? 0 : b - amt))
    printf "#%02x%02x%02x" $r $g $b
}

get_colors() {
    local src="$1"
    local theme_file=""

    if [[ -f "$src/.config/ghostty/theme" ]]; then
        theme_file="$src/.config/ghostty/theme"
    elif [[ -f "$src/ghostty/theme" ]]; then
        theme_file="$src/ghostty/theme"
    elif [[ -f "$src/ghostty-theme" ]]; then
        theme_file="$src/ghostty-theme"
    fi

    [[ -z "$theme_file" ]] && return 1

    awk '
        /^background[[:space:]]*=/ {bg=$3}
        /^foreground[[:space:]]*=/ {fg=$3}
        /^palette[[:space:]]*=/ {
            split($3,a,"=");
            idx=a[1]; col=a[2];
            c[idx]=col;
        }
        END {
            if(bg && fg) {
                printf "%s %s ", bg, fg;
                for(i=0;i<16;i++) printf "%s ", c[i];
            }
        }
    ' "$theme_file"
}
