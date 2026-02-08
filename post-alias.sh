#!/bin/bash

# Definicja zmian, które chcemy dodać
CONFIG_FILE="$HOME/.aliases"

EXTRA_CONFIG=$(cat << 'EOF'

# --- CUSTOM CONFIG START ---

# You may uncomment the following lines if you want `ls' to be colorized:
export LS_OPTIONS='--color=auto'
eval "$(dircolors)"
alias ls='ls $LS_OPTIONS --indicator-style=slash'
alias ll='ls -alh' # ll = długa lista, czytelne rozmiary plików (KB, MB), ukryte pliki
alias la='ls -A'
alias l='ls -lCF'

if [ -x /usr/bin/lsd ]; then
  alias ls='lsd'
fi

# Some more alias to avoid making mistakes:
 alias rm='rm -i'
 alias cp='cp -i'
 alias mv='mv -i'

 alias lsblk='lsblk -o NAME,SIZE,MAJ:MIN,RM,RO,TYPE,MOUNTPOINTS,SERIAL,MODEL,ID-LINK'

 bind '"\e[A": history-search-backward'
 bind '"\e[B": history-search-forward'

 export TERM='xterm-256color'

alias grep='grep --color=auto'
#alias nftlist='sudo nft list ruleset'

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
update_config "$CONFIG_FILE"

# refresh session
source "$CONFIG_FILE" 2>/dev/null

