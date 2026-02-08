#!/bin/bash
ZSHRC="$HOME/.zshrc"
# 1. Instalacja Zsh i curl
 apt update && apt install -y zsh curl

# 2. Instalacja zimfw (Zsh IMproved FrameWork)
# Skrypt automatycznie pobiera zimfw i tworzy pliki konfiguracyjne
# set external aliases
./post-alias.sh
export ZIM_HOME=${ZDOTDIR:-${HOME}}/.zim
if [ ! -d "$ZIM_HOME" ]; then
    curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
fi

# 3. Dodanie wtyczek do .zimrc (Autosuggestions i Syntax Highlighting)
# Zimfw wymaga wpisów w .zimrc i uruchomienia modułu install
cat << 'EOF' > "$HOME/.zimrc"
# Moduły Zimfw
zmodule archive
zmodule git
zmodule completion
zmodule zsh-users/zsh-autosuggestions
zmodule zsh-users/zsh-syntax-highlighting
zmodule zsh-users/zsh-completions
zmodule debian            # Aliasy specyficzne dla Debiana (np. agi -> apt install)
zmodule systemd           # Skróty dla systemctl (np. sc-start, sc-status)
zmodule sudo              # Podwójny ESC dodaje 'sudo' przed komendę
zmodule command-not-found # Podpowiada brakujące pakiety
EOF

zsh -c "source $HOME/.zim/zimfw.zsh install"

# 4. Dodanie obsługi command-not-found do .zshrc
# W Debianie skrypt ten znajduje się w /etc/zsh_command_not_found
if [ -f /etc/zsh_command_not_found ]; then
    echo 'source /etc/zsh_command_not_found' >> "$ZSHRC"
fi

# 5. Instalacja Starship (Prompt w Rust)
if ! command -v starship &> /dev/null; then
  #curl -sS https://starship.rs/install.sh | sh -s -- -y
  apt install starship
fi

# 6. Konfiguracja .zshrc pod Starship i zimfw
# Dodajemy inicjalizację na końcu pliku, sprawdzając czy już tam jest
if ! grep -q "starship init zsh" "$ZSHRC"; then
    cat << 'EOF' >> "$ZSHRC"

# --- STARSHIP & CUSTOM CONFIG ---
# Inicjalizacja Starship Prompt
eval "$(starship init zsh)"

# Maping Home, End, Delete
bindkey "\e[1~" beginning-of-line
bindkey "\e[4~" end-of-line
bindkey "\e[H" beginning-of-line
bindkey "\e[F" end-of-line

export TERM='xterm-256color'

# History Search
bindkey "^[[A" history-beginning-search-backward
bindkey "^[[B" history-beginning-search-forward

if [ -f ~/.aliases ]; then
    . ~/.aliases
fi
EOF
fi

# 7. Zmiana domyślnej powłoki na Zsh
if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s $(which zsh) $USER
fi

# 8. config of starship
# TODO

echo -e "\e[32m[OK]\e[0m Zsh, Zimfw i Starship zostały skonfigurowane."
echo "Wyloguj się i zaloguj ponownie, aby zobaczyć zmiany."
