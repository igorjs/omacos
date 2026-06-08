#!/usr/bin/env bash
#
# Install Homebrew if missing and put it on PATH for the current shell.
# Handles Apple Silicon (/opt/homebrew) and Intel (/usr/local) prefixes.
#
set -euo pipefail

BLUE='\033[38;2;122;162;247m'; GREEN='\033[38;2;158;206;106m'
RED='\033[38;2;247;118;142m';  RESET='\033[0m'
info(){ printf "${BLUE}==>${RESET} %s\n" "$1"; }
ok(){   printf "${GREEN} ok${RESET} %s\n" "$1"; }
warn(){ printf "${RED} !! ${RESET}%s\n" "$1"; }

if command -v brew >/dev/null 2>&1; then
  ok "Homebrew already installed at $(command -v brew)"
else
  info "Installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Put brew on PATH for THIS shell, regardless of arch.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Make sure future zsh sessions can find brew too. Idempotent: only append once.
zprofile="$HOME/.zprofile"
brew_line='eval "$(/opt/homebrew/bin/brew shellenv)"'
[[ -x /usr/local/bin/brew && ! -x /opt/homebrew/bin/brew ]] \
  && brew_line='eval "$(/usr/local/bin/brew shellenv)"'

if ! grep -qsF "$brew_line" "$zprofile" 2>/dev/null; then
  printf "\n# OmacOS: load Homebrew\n%s\n" "$brew_line" >> "$zprofile"
  ok "Added brew shellenv to $zprofile"
else
  ok "brew shellenv already in $zprofile"
fi

command -v brew >/dev/null 2>&1 || { warn "brew still not on PATH; open a new shell"; exit 1; }
ok "brew: $(brew --version | head -1)"
