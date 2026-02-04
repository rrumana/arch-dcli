# arch-config modules

This repository uses dcli modules to group packages, hooks, and dotfiles. The list below summarizes each module and which hosts enable it.

## Hosts

- **Arch-Desktop**: Desktop, Utilities, Terminal, Networking, Audio, Music, Productivity, Games, Other, Hyprland
- **Arch-Kube-Server**: Server, Kubernetes, Utilities, Terminal, Networking

## Modules

### Desktop
- **Description:** Desktop kernel packages (CachyOS + LTS)
- **Packages:** amd-ucode, linux-firmware, linux-cachyos, linux-cachyos-headers, linux-lts, linux-lts-headers
- **Hooks:** pre-install `modules/Desktop/scripts/add-cachyos-repos.sh` (once)
- **Dotfiles:** none
- **Enabled on:** Arch-Desktop

### Server
- **Description:** Server kernel packages (CachyOS server + LTS)
- **Packages:** amd-ucode, linux-firmware, linux-cachyos-server, linux-cachyos-server-headers, linux-lts, linux-lts-headers
- **Hooks:** pre-install `modules/Server/scripts/add-cachyos-repos.sh` (once)
- **Dotfiles:** none
- **Enabled on:** Arch-Kube-Server

### Kubernetes
- **Description:** Kubernetes tooling and networking
- **Packages:** kubeadm, kubectl, kubelet, crictl, iptables-nft, libnftnl, nftables
- **Hooks:** none
- **Dotfiles:** none
- **Enabled on:** Arch-Kube-Server

### Utilities
- **Description:** Common utilities
- **Packages:** 7zip, bat, btop, bzip2, curl, deno, dkms, downgrade, eza, fd, fzf, gzip, jq, keyd, less, localsend, net-tools, npm, ffmpeg, ripgrep, restic, rsync, tar, tcpdump, tree-sitter-cli, unzip, wget, which, zip, zoxide
- **Hooks:** post-install `modules/Utilities/scripts/setup-restic.sh` (once, root)
- **Dotfiles:** auto-sync `modules/Utilities/dotfiles/` to `~/.config/`
  - `btop/` → `~/.config/btop`
- **Enabled on:** Arch-Desktop, Arch-Kube-Server

### Terminal
- **Description:** Terminal tools and shell setup
- **Packages:** ghostty, tmux, bash, nvim, starship, lazygit, chafa, fastfetch
- **Hooks:** none
- **Dotfiles:** auto-sync `modules/Terminal/dotfiles/` to `~/.config/`
  - `ghostty/` → `~/.config/ghostty`
  - `fastfetch/` → `~/.config/fastfetch`
  - `lazygit/` → `~/.config/lazygit`
  - `nvim/` → `~/.config/nvim`
  - `tmux/` → `~/.config/tmux`
- **Dotfiles (explicit):**
  - `modules/Terminal/dotfiles/.bashrc` → `~/.bashrc`
  - `modules/Terminal/dotfiles/.tmux.conf` → `~/.tmux.conf`
  - `modules/Terminal/dotfiles/starship.toml` → `~/.config/starship.toml`
- **Enabled on:** Arch-Desktop, Arch-Kube-Server

### Games
- **Description:** Games and launchers
- **Packages:** prismlauncher, osu-lazer-bin
- **Hooks:** none
- **Dotfiles:** none
- **Enabled on:** Arch-Desktop

### Audio
- **Description:** Audio tools and drivers
- **Packages:** pipewire, pipewire-alsa, pipewire-pulse, wireplumber, pamixer, wiremix
- **Hooks:** none
- **Dotfiles:** auto-sync `modules/Audio/dotfiles/` to `~/.config/`
  - `wireplumber/` → `~/.config/wireplumber`
- **Enabled on:** Arch-Desktop

### Networking
- **Description:** Networking tools and services
- **Packages:** networkmanager, nmgui-bin, kdeconnect, bluez, bluez-utils, blueman
- **Hooks:** post-install `modules/Networking/scripts/post-networking-root.sh` (once)
- **Dotfiles:** none
- **Enabled on:** Arch-Desktop, Arch-Kube-Server

### Music
- **Description:** Music apps and tools
- **Packages:** spotify-launcher, mpd, mpc, rmpc, cava, playerctl, mpdscribble, spicetify-cli, mpd-mpris
- **Hooks:** post-install `modules/Music/scripts/post-music-user.sh` (once, user)
- **Services:** user `mpd`, `mpd-mpris`
- **Dotfiles:** auto-sync `modules/Music/dotfiles/` to `~/.config/`
  - `mpd/` → `~/.config/mpd`
  - `mpdscribble/` → `~/.config/mpdscribble`
  - `rmpc/` → `~/.config/rmpc`
- **Enabled on:** Arch-Desktop

### Hyprland
- **Description:** Hyprland compositor and Wayland tooling
- **Packages:** hyprland, hypridle, hyprlock, hyprpicker, hyprsunset, xdg-desktop-portal-hyprland, xdg-desktop-portal-gtk, qt5-wayland, qt6-wayland, uwsm, waybar, rofi, swaync, swayosd, swww, wlogout, yazi, nautilus, grim, slurp, satty, wl-clipboard, gpu-screen-recorder, v4l-utils, cliphist, wl-clip-persist, polkit-gnome, brightnessctl, ddcutil, power-profiles-daemon, upower, libnotify, xdg-utils, xdg-user-dirs, inotify-tools, gnome-keyring, libsecret, xorg-xhost, libappindicator-gtk3, matugen, nwg-look, adw-gtk-theme, bibata-cursor-theme-bin, imagemagick, rofimoji, wtype, ttf-jetbrains-mono-nerd, ttf-cascadia-mono-nerd, noto-fonts-emoji, sddm, qt5-quickcontrols, qt5-quickcontrols2, qt5-graphicaleffects, python-terminaltexteffects, gum
- **Hooks:** post-install `modules/Hyprland/scripts/post-hyprland-user.sh` (once, user)
- **Dotfiles:** auto-sync `modules/Hyprland/dotfiles/` to `~/.config/`
  - `cliphist/` → `~/.config/cliphist`
  - `gtk-3.0/` → `~/.config/gtk-3.0`
  - `gtk-4.0/` → `~/.config/gtk-4.0`
  - `hypr/` → `~/.config/hypr`
  - `symphony/` → `~/.config/symphony`
  - `matugen/` → `~/.config/matugen`
  - `waybar/` → `~/.config/waybar`
  - `rofi/` → `~/.config/rofi`
  - `swayosd/` → `~/.config/swayosd`
  - `swaync/` → `~/.config/swaync`
  - `yazi/` → `~/.config/yazi`
  - `uwsm/` → `~/.config/uwsm`
- **Enabled on:** Arch-Desktop

### Productivity
- **Description:** Productivity apps
- **Packages:** vscodium, firefox, libreoffice
- **Hooks:** none
- **Dotfiles:** auto-sync `modules/Productivity/dotfiles/` to `~/.config/`
  - `Typora/` → `~/.config/Typora`
- **Enabled on:** Arch-Desktop

### Other
- **Description:** Miscellaneous apps and tools
- **Packages:** vesktop-bin
- **Hooks:** none
- **Dotfiles (explicit):**
  - `modules/Other/dotfiles/applications` → `~/.local/share/applications`
- **Enabled on:** Arch-Desktop
