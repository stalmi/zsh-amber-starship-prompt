#!/bin/bash

#----------
# GIT
# Tworzy czytelny graf logów pod komendą 'git lg'
git config --global alias.lg "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all"

# Podstawowe aliasy dla szybkości
git config --global alias.s "status -s"
git config --global alias.co "checkout"
git config --global alias.br "branch"

# Włączenie kolorów w interfejsie CLI
git config --global color.ui auto

#----------
# Nano konfiguracja
nano_conf="$HOME/.nanorc"

# Konfiguracja: 2 spacje zamiast Tab + podświetlanie składni
# Wczytujemy wszystkie dostępne schematy kolorów z /usr/share/nano/
config_payload=$(cat << 'EOF'
#custom config start
set tabsize 2
set tabstospaces
#set whitespace "»·"
set whitespace "» "
#set linenumbers
set autoindent
set constantshow
include "/usr/share/nano/*.nanorc"
EOF
)

if [ ! -f "$nano_conf" ]; then
  echo -e "$config_payload" > "$nano_conf"
  echo -e "\e[32m[ok]\e[0m Set a new config $nano_conf"
elif ! grep -q "custom config start" "$nano_conf"; then
  echo -e "$config_payload" >> "$nano_conf"
  echo -e "\e[32m[ok]\e[0m Updated nano (taby, kolory dla Python/Java/PHP/Bash/SQL)"
else
	echo -e "\e[33m[skip]\e[0m $nano_conf posiada już konfigurację"
fi

#----------
# Aliases Definicja zmian, które chcemy dodać
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

 export TERM='xterm-256color'

alias grep='grep --color=auto'
#alias nftlist='sudo nft list ruleset'

# --- CUSTOM CONFIG END ---
EOF
)

# Funkcja dodająca konfigurację tylko jeśli jeszcze jej nie ma
update_config() {
  local FILE=$1
  if [ ! -f "$FILE" ]; then
    echo -e "$EXTRA_CONFIG" > "$FILE"
    echo -e "\e[32m[ok]\e[0m utworzono nowy plik $FILE"
  elif ! grep -q "CUSTOM CONFIG START" "$FILE"; then
    echo -e "$EXTRA_CONFIG" >> "$FILE"
    echo -e "\e[32m[ok]\e[0m zaktualizowano $FILE"
  else
    echo -e "\e[33m[skip]\e[0m $FILE posiada już konfigurację"
  fi

}
#Run
update_config "$CONFIG_FILE"

# refresh session
source "$CONFIG_FILE" 2>/dev/null

