#!/bin/bash
# tmux - symlink generated theme and reload running server

set -euo pipefail

CURRENT_LINK="${CURRENT_LINK:-$HOME/.config/symphony/current}"
src="$CURRENT_LINK/.config/tmux/catppuccin_dynamic_tmux.conf"

lighten() {
    local hex="${1#\#}" amt="${2:-20}"
    local r=$((16#${hex:0:2})) g=$((16#${hex:2:2})) b=$((16#${hex:4:2}))
    r=$((r + amt > 255 ? 255 : r + amt))
    g=$((g + amt > 255 ? 255 : g + amt))
    b=$((b + amt > 255 ? 255 : b + amt))
    printf "#%02x%02x%02x" "$r" "$g" "$b"
}

darken() {
    local hex="${1#\#}" amt="${2:-20}"
    local r=$((16#${hex:0:2})) g=$((16#${hex:2:2})) b=$((16#${hex:4:2}))
    r=$((r - amt < 0 ? 0 : r - amt))
    g=$((g - amt < 0 ? 0 : g - amt))
    b=$((b - amt < 0 ? 0 : b - amt))
    printf "#%02x%02x%02x" "$r" "$g" "$b"
}

build_from_ghostty() {
    local ghostty_theme="$1"
    local out="$2"
    local parsed

    parsed="$(
        awk '
            /^[[:space:]]*background[[:space:]]*=/ {bg=$3}
            /^[[:space:]]*foreground[[:space:]]*=/ {fg=$3}
            /^[[:space:]]*palette[[:space:]]*=/ {
                split($3, a, "=")
                idx=a[1]
                col=a[2]
                c[idx]=col
            }
            END {
                if (!bg || !fg) exit 1
                printf "%s %s", bg, fg
                for (i=0; i<16; i++) printf " %s", c[i]
            }
        ' "$ghostty_theme"
    )" || return 1

    local bg fg black red green yellow blue magenta cyan white bblack bred bgreen byellow bblue bmagenta bcyan bwhite
    read -r bg fg black red green yellow blue magenta cyan white bblack bred bgreen byellow bblue bmagenta bcyan bwhite <<<"$parsed"

    black="${black:-$bg}"
    red="${red:-#cc6666}"
    green="${green:-#98c379}"
    yellow="${yellow:-#e5c07b}"
    blue="${blue:-#61afef}"
    magenta="${magenta:-#c678dd}"
    cyan="${cyan:-#56b6c2}"
    white="${white:-$fg}"
    bblack="${bblack:-$(lighten "$bg" 28)}"
    bred="${bred:-$red}"
    bgreen="${bgreen:-$green}"
    byellow="${byellow:-$yellow}"
    bblue="${bblue:-$blue}"
    bmagenta="${bmagenta:-$magenta}"
    bcyan="${bcyan:-$cyan}"
    bwhite="${bwhite:-$fg}"

    cat >"$out" <<EOF
# vim:set ft=tmux:
# Symphony tmux theme (derived from current ghostty palette)
set -gq @thm_bg "$bg"
set -gq @thm_fg "$fg"

set -gq @thm_rosewater "$white"
set -gq @thm_flamingo "$bred"
set -gq @thm_pink "$bmagenta"
set -gq @thm_mauve "$magenta"
set -gq @thm_red "$red"
set -gq @thm_maroon "$bred"
set -gq @thm_peach "$byellow"
set -gq @thm_yellow "$yellow"
set -gq @thm_green "$green"
set -gq @thm_teal "$cyan"
set -gq @thm_sky "$bcyan"
set -gq @thm_sapphire "$bblue"
set -gq @thm_blue "$blue"
set -gq @thm_lavender "$bmagenta"

set -gq @thm_subtext_1 "$white"
set -gq @thm_subtext_0 "$bwhite"
set -gq @thm_overlay_2 "$bblack"
set -gq @thm_overlay_1 "$white"
set -gq @thm_overlay_0 "$(lighten "$bg" 24)"
set -gq @thm_surface_2 "$(lighten "$bg" 18)"
set -gq @thm_surface_1 "$(lighten "$bg" 12)"
set -gq @thm_surface_0 "$(lighten "$bg" 8)"
set -gq @thm_mantle "$(darken "$bg" 6)"
set -gq @thm_crust "$(darken "$bg" 12)"
EOF
}

if [[ ! -f "$src" ]]; then
    ghostty_theme="$CURRENT_LINK/.config/ghostty/theme"
    [[ -f "$ghostty_theme" ]] || exit 0

    cache_dir="$HOME/.cache/symphony/tmux"
    mkdir -p "$cache_dir"
    src="$cache_dir/catppuccin_dynamic_tmux.conf"
    build_from_ghostty "$ghostty_theme" "$src" || exit 0
fi

mkdir -p "$HOME/.config/tmux"
ln -sf "$src" "$HOME/.config/tmux/catppuccin_dynamic_tmux.conf"

mkdir -p "$HOME/.config/tmux/plugins/tmux/themes"
ln -sf "$src" "$HOME/.config/tmux/plugins/tmux/themes/catppuccin_dynamic_tmux.conf"

if [[ -d "$HOME/.tmux/plugins/tmux/themes" ]]; then
    ln -sf "$src" "$HOME/.tmux/plugins/tmux/themes/catppuccin_dynamic_tmux.conf"
fi

command -v tmux >/dev/null 2>&1 || exit 0
tmux ls >/dev/null 2>&1 || exit 0

# Force refresh for existing generated theme files that were written with
# "set -o" (older versions). This ensures theme values are re-applied on reload.
for opt in \
    bg fg rosewater flamingo pink mauve red maroon peach yellow green teal sky sapphire blue lavender \
    subtext_1 subtext_0 overlay_2 overlay_1 overlay_0 surface_2 surface_1 surface_0 mantle crust; do
    tmux set-option -gu "@thm_${opt}" 2>/dev/null || true
done

if [[ -f "$HOME/.config/tmux/tmux.conf" ]]; then
    tmux source-file "$HOME/.config/tmux/tmux.conf" >/dev/null 2>&1 || true
elif [[ -f "$HOME/.tmux.conf" ]]; then
    tmux source-file "$HOME/.tmux.conf" >/dev/null 2>&1 || true
fi

while IFS= read -r client; do
    [[ -n "$client" ]] && tmux refresh-client -S -t "$client" >/dev/null 2>&1 || true
done < <(tmux list-clients -F '#{client_tty}' 2>/dev/null || true)

exit 0
