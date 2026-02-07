#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

export PATH="$HOME/.cargo/bin:$PATH" 
export PATH="$HOME/.local/bin:$PATH" 
export QT_QPA_PLATFORMTHEME=qt5ct
export QT_STYLE_OVERRIDE="qt5ct"
alias osu-lazer='DRI_PRIME=1 osu-lazer'

# Make fastfetch logo rendering tmux-safe.
fastfetch() {
	local ff_bin="/usr/bin/fastfetch"
	[[ -x "$ff_bin" ]] || ff_bin="$(command -v fastfetch)"

	if [[ -n "${TMUX:-}" ]]; then
		# Respect explicit user choice.
		for arg in "$@"; do
			case "$arg" in
			--logo-type|--logo-type=*|--kitty|--kitty-direct|--kitty-icat|--sixel|--chafa)
				"$ff_bin" "$@"
				return
				;;
			esac
		done

		# kitty-icat is the most reliable image path in tmux; pin size so it
		# matches non-tmux behavior more closely.
		if command -v kitten >/dev/null 2>&1; then
			"$ff_bin" --pipe false --logo-type kitty-icat \
				--logo-width "${FASTFETCH_TMUX_LOGO_WIDTH:-32}" \
				--logo-height "${FASTFETCH_TMUX_LOGO_HEIGHT:-15}" \
				--logo-preserve-aspect-ratio true "$@" \
				|| "$ff_bin" --pipe false --logo-type chafa "$@"
		else
			"$ff_bin" --pipe false --logo-type chafa "$@"
		fi
		return
	fi

	"$ff_bin" "$@"
}

eval "$(starship init bash)"
eval $(ssh-agent)
ssh-add ~/.ssh/id_ed25519
clear
sleep 0.1
fastfetch
