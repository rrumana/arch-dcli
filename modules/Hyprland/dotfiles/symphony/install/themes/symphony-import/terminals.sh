#!/bin/bash
# ghostty theme generation

gen_terminals() {
    mkdir -p "$dest/.config/ghostty"
    cat > "$dest/.config/ghostty/theme" <<'EOT'
# Symphony by vyrx
# Theme: __THEME_NAME__

# primary
background = __BG__
foreground = __FG__
cursor-color = __ACCENT__
cursor-text = __BG__

# normal colors
palette = 0=__BLACK__
palette = 1=__RED__
palette = 2=__GREEN__
palette = 3=__YELLOW__
palette = 4=__BLUE__
palette = 5=__MAGENTA__
palette = 6=__CYAN__
palette = 7=__WHITE__

# bright colors
palette = 8=__BBLACK__
palette = 9=__BRED__
palette = 10=__BGREEN__
palette = 11=__BYELLOW__
palette = 12=__BBLUE__
palette = 13=__BMAGENTA__
palette = 14=__BCYAN__
palette = 15=__BWHITE__
EOT

    # Replace placeholders to avoid nested heredoc interpolation issues
    sed -i \
        -e "s/__THEME_NAME__/${name}/g" \
        -e "s#__BG__#${bg}#g" \
        -e "s#__FG__#${fg}#g" \
        -e "s#__ACCENT__#${accent}#g" \
        -e "s#__BLACK__#${black}#g" \
        -e "s#__RED__#${red}#g" \
        -e "s#__GREEN__#${green}#g" \
        -e "s#__YELLOW__#${yellow}#g" \
        -e "s#__BLUE__#${blue}#g" \
        -e "s#__MAGENTA__#${magenta}#g" \
        -e "s#__CYAN__#${cyan}#g" \
        -e "s#__WHITE__#${white}#g" \
        -e "s#__BBLACK__#${bblack}#g" \
        -e "s#__BRED__#${bred}#g" \
        -e "s#__BGREEN__#${bgreen}#g" \
        -e "s#__BYELLOW__#${byellow}#g" \
        -e "s#__BBLUE__#${bblue}#g" \
        -e "s#__BMAGENTA__#${bmagenta}#g" \
        -e "s#__BCYAN__#${bcyan}#g" \
        -e "s#__BWHITE__#${bwhite}#g" \
        "$dest/.config/ghostty/theme"
}
