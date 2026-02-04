#!/usr/bin/env bash
set -euo pipefail

# MPD user service override
if command -v systemctl &>/dev/null; then
  mkdir -p "$HOME/.config/systemd/user/mpd.service.d"
  cat >"$HOME/.config/systemd/user/mpd.service.d/override.conf" <<'EOF_OVERRIDE'
[Service]
RuntimeDirectory=mpd
EOF_OVERRIDE

  systemctl --user daemon-reload || true
fi

# mpdscribble (Last.fm scrobbler)
if command -v systemctl &>/dev/null && [[ -f "$HOME/.config/mpdscribble/mpdscribble.conf" ]]; then
  if grep -q "YOUR_USERNAME" "$HOME/.config/mpdscribble/mpdscribble.conf" 2>/dev/null; then
    echo "mpdscribble: update ~/.config/mpdscribble/mpdscribble.conf with your credentials" >&2
  else
    systemctl --user enable --now mpdscribble >/dev/null 2>&1 || true
  fi
fi

# Spicetify setup (optional)
if command -v spicetify &>/dev/null; then
  spotify_path=""
  prefs_path=""
  share_dir="${XDG_DATA_HOME:-$HOME/.local/share}"

  if [[ -d "$share_dir/spotify-launcher/install/usr/share/spotify" ]]; then
    spotify_path="$share_dir/spotify-launcher/install/usr/share/spotify"
    prefs_path="$HOME/.config/spotify/prefs"
  elif [[ -d /opt/spotify ]]; then
    spotify_path="/opt/spotify"
    prefs_path="$HOME/.config/spotify/prefs"
  elif [[ -d "$share_dir/flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share/spotify" ]]; then
    spotify_path="$share_dir/flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share/spotify"
    prefs_path="$HOME/.var/app/com.spotify.Client/config/spotify/prefs"
  elif [[ -d /var/lib/flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share/spotify ]]; then
    spotify_path="/var/lib/flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share/spotify"
    prefs_path="$HOME/.var/app/com.spotify.Client/config/spotify/prefs"
  fi

  if [[ -n "$spotify_path" ]]; then
    spicetify >/dev/null 2>&1 || true

    if [[ ! -w "$spotify_path" ]] || [[ -d "$spotify_path/Apps" && ! -w "$spotify_path/Apps" ]]; then
      if command -v sudo &>/dev/null; then
        sudo chmod a+wr "$spotify_path" 2>/dev/null || true
        sudo chmod a+wr -R "$spotify_path/Apps" 2>/dev/null || true
      fi
    fi

    mkdir -p "$(dirname "$prefs_path")"
    touch "$prefs_path"

    spicetify config spotify_path "$spotify_path" >/dev/null 2>&1 || true
    spicetify config prefs_path "$prefs_path" >/dev/null 2>&1 || true
    spicetify config spotify_launch_flags "--ozone-platform=wayland" >/dev/null 2>&1 || true
    spicetify config current_theme symphony color_scheme base >/dev/null 2>&1 || true
    spicetify config inject_css 1 replace_colors 1 >/dev/null 2>&1 || true

    spicetify backup apply >/dev/null 2>&1 || echo "spicetify: launch Spotify once, then run 'spicetify backup apply'" >&2
  else
    echo "spicetify: install Spotify first, then re-run this hook" >&2
  fi
fi
