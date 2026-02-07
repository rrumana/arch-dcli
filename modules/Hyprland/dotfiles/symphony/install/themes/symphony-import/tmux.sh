#!/bin/bash

gen_tmux() {
    local overlay_0 surface_2 surface_1 surface_0 mantle crust

    overlay_0=$(lighten "$bg" 24)
    surface_2=$(lighten "$bg" 18)
    surface_1=$(lighten "$bg" 12)
    surface_0=$(lighten "$bg" 8)
    mantle=$(darken "$bg" 6)
    crust=$(darken "$bg" 12)

    cat > "$dest/.config/tmux/catppuccin_dynamic_tmux.conf" <<EOF
# vim:set ft=tmux:
# Symphony tmux theme
# Theme: Omarchy $name
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
set -gq @thm_overlay_0 "$overlay_0"
set -gq @thm_surface_2 "$surface_2"
set -gq @thm_surface_1 "$surface_1"
set -gq @thm_surface_0 "$surface_0"
set -gq @thm_mantle "$mantle"
set -gq @thm_crust "$crust"
EOF
}
