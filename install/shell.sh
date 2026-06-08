#!/usr/bin/env bash
#
# Wire ~/.zshrc into OmacOS: writes a single managed block that sets the
# tools' shell hooks in the EXACT required order. Re-running rewrites the
# block in place (no duplication); ~/.zshrc is backed up before each rewrite.
#
# The order matters:
#   1. mise activate              (sets up shims/PATH)
#   2. fzf + zoxide hooks
#   3. zsh-autosuggestions        (sourced BEFORE prompt)
#   4. theme zsh.zsh              (sets autosuggest + syntax colors)
#   5. starship init              (prompt)
#   6. zsh-syntax-highlighting    (absolutely LAST: wraps ZLE widgets)
#
# EDITOR is set to "zed --wait" because Zed is the primary editor; nvim is
# only an SSH/headless fallback.
#
# Markers are kept as "omacos starship" for backward compatibility with the
# initial release, even though the block now contains the whole managed shell setup.
#
set -euo pipefail

BLUE='\033[38;2;122;162;247m'; GREEN='\033[38;2;158;206;106m'
PURPLE='\033[38;2;187;154;247m'; RED='\033[38;2;247;118;142m'; RESET='\033[0m'
info(){ printf "${BLUE}==>${RESET} %s\n" "$1"; }
ok(){   printf "${GREEN} ok${RESET} %s\n" "$1"; }
note(){ printf "${PURPLE} -- ${RESET}%s\n" "$1"; }
warn(){ printf "${RED} !! ${RESET}%s\n" "$1"; }

zshrc="$HOME/.zshrc"
touch "$zshrc"

open_marker='# >>> omacos starship >>>'
close_marker='# <<< omacos starship <<<'

# Detect brew prefix for plugin source paths
brew_prefix=""
command -v brew >/dev/null 2>&1 && brew_prefix="$(brew --prefix 2>/dev/null || true)"
[[ -z "$brew_prefix" ]] && brew_prefix="/opt/homebrew"

block_body() {
  cat <<BLOCK
# --- OmacOS managed shell setup (order matters; do not edit between markers) ---
# Editor: Zed primary (GUI); override to nvim ad hoc in SSH/headless contexts.
export EDITOR="zed --wait"
export VISUAL="\$EDITOR"

# Disable XON/XOFF flow control so Ctrl+S is available for history search.
stty -ixon 2>/dev/null || true

# 1. mise: language version manager (Node/Python/Go/Rust via rustup)
if command -v mise >/dev/null 2>&1; then
  eval "\$(mise activate zsh)"
fi

# 2. fzf + zoxide hooks
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh) 2>/dev/null || true
fi
if command -v zoxide >/dev/null 2>&1; then
  eval "\$(zoxide init zsh)"
fi

# Suppress the end-of-partial-line marker — it renders as a reverse-video block
# in Terminal.app which inherits the ANSI cyan color and produces a cyan square.
PROMPT_SP=""

# 3. zsh-autosuggestions: fish-style history suggestions
if [[ -f "$brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# 4. Active theme's shell color overrides (autosuggest + syntax highlight)
if [[ -f "\$HOME/.config/omacos/theme.zsh" ]]; then
  source "\$HOME/.config/omacos/theme.zsh"
fi

# 5. Starship prompt
if command -v starship >/dev/null 2>&1; then
  eval "\$(starship init zsh)"
fi

# bat (cat replacement); themes can override BAT_THEME in their theme.zsh
export BAT_THEME="\${BAT_THEME:-base16}"

# 6. zsh-syntax-highlighting: MUST be sourced last (it wraps ZLE widgets)
if [[ -f "$brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
BLOCK
}

write_block() {
  {
    printf "\n%s\n" "$open_marker"
    block_body
    printf "%s\n" "$close_marker"
  } >> "$zshrc"
}

if grep -qsF "$open_marker" "$zshrc"; then
  ts="$(date +%Y%m%d-%H%M%S)"
  cp "$zshrc" "$zshrc.bak.$ts"
  # Strip the existing block (markers inclusive)
  awk -v open="$open_marker" -v close="$close_marker" '
    $0 == open { skip = 1; next }
    $0 == close && skip { skip = 0; next }
    !skip
  ' "$zshrc.bak.$ts" > "$zshrc"
  write_block
  ok "Rewrote managed block in $zshrc (backup at $zshrc.bak.$ts)"
else
  if [[ -s "$zshrc" ]]; then
    ts="$(date +%Y%m%d-%H%M%S)"
    cp "$zshrc" "$zshrc.bak.$ts"
    info "Backed up $zshrc to $zshrc.bak.$ts"
  fi
  write_block
  ok "Added managed block to $zshrc"
fi

note "Start a new shell or 'exec zsh' to pick up changes."
