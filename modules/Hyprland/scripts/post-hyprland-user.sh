#!/usr/bin/env bash
set -euo pipefail

# Ensure common directories exist
mkdir -p "$HOME/Pictures/Screenshots" "$HOME/Wallpapers" "$HOME/.config/autostart" "$HOME/.local/share/applications" "$HOME/.local/share/applications/icons" "$HOME/.local/bin"

# Ensure Symphony has a current theme symlink before Hyprland starts.
symphony_dir="$HOME/.config/symphony"
themes_dir="$symphony_dir/themes"
current_link="$symphony_dir/current"
if [[ -d "$themes_dir/dynamic" ]]; then
  if [[ ! -e "$current_link" ]]; then
    ln -sfn "$themes_dir/dynamic" "$current_link"
  fi
  if [[ ! -f "$symphony_dir/.current-theme" ]]; then
    printf "%s\n" "dynamic" >"$symphony_dir/.current-theme"
  fi
fi

# Disable tray applets (waybar handles these)
for app in blueman nm-applet; do
  if [[ -f "/etc/xdg/autostart/${app}.desktop" ]]; then
    printf "[Desktop Entry]\nHidden=true\n" >"$HOME/.config/autostart/${app}.desktop"
  fi
done

# Set GTK dark theme
if command -v gsettings &>/dev/null; then
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
  gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' || true
fi

# Set power profile based on device type
if command -v powerprofilesctl &>/dev/null; then
  if ls /sys/class/power_supply/BAT* &>/dev/null; then
    powerprofilesctl set balanced &>/dev/null || true
  else
    powerprofilesctl set performance &>/dev/null || true
  fi
fi

# Initialize a default keyring for auto-unlock
if command -v gnome-keyring-daemon &>/dev/null; then
  keyring_dir="$HOME/.local/share/keyrings"
  keyring_file="$keyring_dir/Default_keyring.keyring"

  if [[ ! -f "$keyring_file" ]]; then
    mkdir -p "$keyring_dir"
    cat >"$keyring_file" <<EOF_KEYRING
[keyring]
display-name=Default keyring
ctime=$(date +%s)
mtime=0
lock-on-idle=false
lock-after=false
EOF_KEYRING

    echo "Default_keyring" >"$keyring_dir/default"

    chmod 700 "$keyring_dir"
    chmod 600 "$keyring_file"
    chmod 644 "$keyring_dir/default"
  fi
fi

# Hide noisy system apps in launchers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -x "$SCRIPT_DIR/hide-apps" ]]; then
  "$SCRIPT_DIR/hide-apps" >/dev/null 2>&1 || true
fi

# Refresh desktop database and clear rofi cache
if command -v update-desktop-database &>/dev/null; then
  update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
fi
rm -f "$HOME/.cache/rofi"* 2>/dev/null || true
