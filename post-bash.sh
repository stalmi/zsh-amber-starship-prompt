#!/bin/bash

# Definicja zmian, które chcemy dodać
EXTRA_CONFIG=$(cat << 'EOF'

# --- CUSTOM CONFIG START ---
# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
HISTCONTROL=ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=5000
HISTFILESIZE=10000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

export TERM='xterm-256color'


if [ -f ~/.aliases ]; then
    . ~/.aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

# --- CUSTOM CONFIG END ---
EOF
)

# Funkcja dodająca konfigurację tylko jeśli jeszcze jej nie ma
update_config() {
    local FILE=$1
    if [ -f "$FILE" ]; then
        if ! grep -q "CUSTOM CONFIG START" "$FILE"; then
            echo -e "$EXTRA_CONFIG" >> "$FILE"
            echo -e "\e[32m[OK]\e[0m Zaktualizowano $FILE"
        else
            echo -e "\e[33m[SKIP]\e[0m $FILE posiada już konfigurację"
        fi
    fi
}

#Run
update_config "$HOME/.bashrc"

# Ścieżka do pliku konfiguracyjnego Readline
INPUTRC="$HOME/.inputrc"

# Definicja wpisów do dodania (używamy formatu bez 'bind')
CONFIG_LINES=(
    '# Mapowanie Home, End, Delete'
    '"\e[1~": beginning-of-line'
    '"\e[4~": end-of-line'
    '"\e[h": beginning-of-line'
    '"\e[f": end-of-line'
    '# Wyszukiwanie w historii po wpisaniu początku komendy'
    '"\e[A": history-search-backward'
    '"\e[B": history-search-forward'
)
# Tworzy plik .inputrc jeśli nie istnieje
if [ ! -f "$INPUTRC" ]; then
    touch "$INPUTRC"
fi

for line in "${CONFIG_LINES[@]}"; do
    # Sprawdza czy linia już istnieje, aby nie śmiecić w pliku
    if ! grep -qF "$line" "$INPUTRC"; then
        echo "$line" >> "$INPUTRC"
    fi
done

# 7. Zmiana domyślnej powłoki na Zsh
if [ "$SHELL" != "$(which bash)" ]; then
    chsh -s $(which bash) $USER
fi

# refresh session
source "$HOME/.bashrc" 2>/dev/null


echo -e "\e[32m[OK]\e[0m Bash zostały skonfigurowane."
echo "Wyloguj się i zaloguj ponownie, aby zobaczyć zmiany."
