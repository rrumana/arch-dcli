#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

export PATH="$HOME/.cargo/bin:$PATH" 
export QT_QPA_PLATFORMTHEME=qt5ct
export QT_STYLE_OVERRIDE="qt5ct"
alias osu-lazer='DRI_PRIME=1 osu-lazer'

eval "$(starship init bash)"
eval $(ssh-agent)
ssh-add ~/.ssh/id_ed25519
clear
sleep 0.1
fastfetch
