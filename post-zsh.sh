#!/bin/bash
echo 'skip_global_compinit=1' >> "$HOME/.zshenv"

ZSHRC="$HOME/.zshrc"
# 1. Instalacja Zsh i curl
sudo apt update && apt install -y zsh curl

# 2. Instalacja zimfw (Zsh IMproved FrameWork)
# Skrypt automatycznie pobiera zimfw i tworzy pliki konfiguracyjne
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
zmodule termtitle
zmodule zsh-users/zsh-autosuggestions
zmodule zsh-users/zsh-syntax-highlighting
zmodule zsh-users/zsh-completions
EOF

zsh -c "source $HOME/.zim/zimfw.zsh install"

# 5. Instalacja Starship (Prompt w Rust)
if ! command -v starship &> /dev/null; then
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# 6. Konfiguracja .zshrc pod Starship i zimfw
# Dodajemy inicjalizację na końcu pliku, sprawdzając czy już tam jest
if ! grep -q "starship init zsh" "$ZSHRC"; then
    cat << 'EOF' >> "$ZSHRC"

# --- ZIM & STARSHIP & CUSTOM CONFIG ---

# Set a custom terminal title format using prompt expansion escape sequences.
# See http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html#Simple-Prompt-Escapes
zstyle ':zim:termtitle' format '%n@%m: %~'

if [[ -z "$MC_SID" && -z "$MC_TMPDIR" ]]; then
  # Inicjalizacja Starship Prompt
  eval "$(starship init zsh)"

  # Funkcja przywracająca pełny prompt Starshipa dla nowej linii
  function precmd() {
    # Starship sam ustawi PROMPT przy każdym nowym poleceniu
  }
  # Transient Prompt dla Starship w Zsh
  function _starship_transient_prompt_widget() {
    # Zapisujemy obecny, wygenerowany już prompt Starshipa do zmiennych tymczasowych
    local saved_prompt="$PROMPT"
    local saved_rprompt="$RPROMPT"
    # 1. Co ma zostać w historii po wciśnięciu Enter:
    # Wyświetla bursztynowy symbol i aktualny czas (opcjonalnie)
    PROMPT='$(print -P "%F{#FFB000}❯%f ")'
    RPROMPT=''
    # 2. Odśwież prompt, aby pokazać uproszczoną wersję
    zle reset-prompt
    # WYMUSZENIE: Uruchamiamy funkcje Starshipa, aby mieć najświeższy RAM i TIME
    for f in $precmd_functions; do $f; done
    # 3. Przywracamy zapisane prompty z pamięci RAM (bez uruchamiania binarki starship)
    # Dzięki temu nowa linia od razu dostanie pełny wygląd
    PROMPT="$saved_prompt"
    RPROMPT="$saved_rprompt"
    # 4. Zaakceptuj linię (wykonaj komendę)
    zle accept-line
  }
  # Tworzymy widget i przypisujemy go pod klawisz Enter (Control+M)
  zle -N _starship_transient_prompt_widget
  bindkey '^M' _starship_transient_prompt_widget
else
    # To wykona się TYLKO wewnątrz Midnight Commandera
    # Najprostszy, szybki prompt bez ikon i pluginów
    # PROMPT='%n@%m:%~%# '

    # Używamy natywnych kolorów Zsh (%F) dla szybkości
    # User@Host w Twoim stylu Amber FFB000
    local user_style="%F{#FF5555}%n@%m%f"
     # Ikona folderu i ścieżka (skrócona do 3 poziomów)
    local dir_style="%F{#FFAF00} %3~%f"

    PROMPT="╭─ ${user_style} ${dir_style}
╰─❯ "
    unsetopt share_history # opcjonalnie: wyłącz dzielenie historii dla szybkości
fi

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
cat << 'EOF' > "$HOME/.config/starship.toml"
# Główne formatowanie: Dwulinijkowy prompt
format = """
╭─(#c0c0c0) $directory$git_branch$git_status$python
╰─(#c0c0c0)$character"""
# Prawa strona: Czas wykonania, obciążenie i zegar
right_format = """$cmd_duration$username$hostname$memory_usage${custom.cpu_usage}$time"""


[username]
show_always = true
style_user = "#FF5555"
format = "[$user]($style)"

[hostname]
ssh_only = false
style = "#FF5555"
format = "[@$hostname]($style) "

[directory]
style = "#FFAF00"
# Musi być false, aby $path zawierało ' ~'
truncate_to_repo = false 
truncation_length = 3
truncation_symbol = '../'
fish_style_pwd_dir_length = 1
read_only = ' 🔒'
read_only_style = 'red'
home_symbol = ' ~'
use_os_path_sep = true
# Zawsze używamy $path - to gwarantuje obecność ikony domku
format = "in [ ](bold #FFAF00)[$path]($style)[$read_only]($read_only_style) "
repo_root_format = "in [ ](bold #FFAF00)[$path]($style)[$read_only]($read_only_style) "

[git_branch]
symbol = " "
style = "#00BB00"
format = "on [$symbol$branch]($style) "

[git_status]
# Logika kolorów Git:
# Jeśli są zmiany (staged, modified, untracked) - ikony będą czerwone/pomarańczowe
conflicted = "   "
ahead = "⇡ "
behind = "⇣ "
diverged = "⇕ "
untracked = "[?](bold #FF0000)"
stashed = "📦 "
modified = "[!](bold #FF4500)"
staged = "[+](bold #00FF41)"
renamed = "» "
deleted = "✘ "
# Formatowanie statusu
format = "([\\[$all_status$ahead_behind\\]]($style) )"

[python]
symbol = "🐍 "
style = "bold #00FF41" # Klasyczny zielony kolor matrycy dla Pythona
format = "via [${symbol}${pyenv_prefix}(${version} )(\\($virtualenv\\))]($style) "

[cmd_duration]
min_time = 5000
show_milliseconds = false
style = "bold #ff0033"
format = "took [ $duration]($style) "

[character]
success_symbol = "[❯](bold #00B000)"
error_symbol = "[❯](bold #00B000)"

[time]
disabled = false
time_format = "%H:%M:\u001b[38;5;60m%S\u001b[0m"
# %T to skrót dla formatu HH:MM:SS  / "%R" to HH:MM
#time_format = "%T"
style = "#00BBBB"
format = " [$time]($style)"

[memory_usage]
disabled = false
threshold = -1
symbol = " "
style = "#FF8700"
format = "[$symbol$ram]($style) "

[custom.cpu_usage]
description = "Wyświetla procentowe zużycie procesora"
# Komenda pobiera sumaryczne zużycie CPU (User + System)
command = "top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}'"
#command = "usage=$(top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}'); if [ $(echo \"$usage > 80\" | bc) -eq 1 ]; then echo \"\u001b[31m$usage\u001b[0m\"; else echo \"$usage\"; fi"

when = "true"
symbol = " "
style = "bold #FF8700"
format = "[$symbol$output%]($style) "
shell = ["sh"]
EOF


echo -e "\e[32m[OK]\e[0m Zsh, Zimfw i Starship zostały skonfigurowane."
echo "Wyloguj się i zaloguj ponownie, aby zobaczyć zmiany."
