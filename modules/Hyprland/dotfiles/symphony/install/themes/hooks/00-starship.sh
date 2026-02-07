#!/bin/bash
# starship - symlink config
src="$CURRENT_LINK/.config/starship.toml"
[[ -f "$src" ]] || exit 0

fix_starship_format_scope() {
    local file="$1"
    local first_table format_start format_end

    first_table=$(awk '/^\[/ { print NR; exit }' "$file")
    format_start=$(awk '/^format = """$/ { print NR; exit }' "$file")

    [[ -n "$format_start" ]] || return 0
    [[ -n "$first_table" ]] || return 0

    # Already top-level format (correct).
    if (( format_start < first_table )); then
        return 0
    fi

    format_end=$(awk -v s="$format_start" 'NR >= s && /^\$character"""$/ { print NR; exit }' "$file")
    [[ -n "$format_end" ]] || return 0

    local block tmp
    block=$(sed -n "${format_start},${format_end}p" "$file")
    tmp=$(mktemp)

    awk -v s="$format_start" -v e="$format_end" 'NR < s || NR > e { print }' "$file" >"$tmp"
    awk -v block="$block" '
        BEGIN { inserted = 0 }
        { print }
        /^palette = "colors"$/ && !inserted {
            print ""
            print block
            inserted = 1
        }
    ' "$tmp" >"$file"

    rm -f "$tmp"
}

fix_starship_format_scope "$src"
ln -sf "$src" "$HOME/.config/starship.toml"
