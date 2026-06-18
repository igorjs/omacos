#!/usr/bin/env bash
#
# Zed: write settings and install extensions.
# Settings are written fresh on every run (backup preserved). Extensions are
# installed via the zed:// URL scheme — Zed must be running or will be
# launched automatically by open(1).
#
set -euo pipefail

BLUE='\033[38;2;122;162;247m'; GREEN='\033[38;2;158;206;106m'
PURPLE='\033[38;2;187;154;247m'; RESET='\033[0m'
info(){ printf "${BLUE}==>${RESET} %s\n" "$1"; }
ok(){   printf "${GREEN} ok${RESET} %s\n" "$1"; }
note(){ printf "${PURPLE} MANUAL${RESET} %s\n" "$1"; }

OMACOS_ROOT="${OMACOS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# --- Settings ----------------------------------------------------------------
zed_settings="$HOME/.config/zed/settings.json"
zed_src="$OMACOS_ROOT/config/zed.settings.json"
mkdir -p "$(dirname "$zed_settings")"
if [[ -f "$zed_settings" ]]; then
  ts="$(date +%Y%m%d-%H%M%S)"
  cp "$zed_settings" "$zed_settings.bak.$ts"
fi
cp "$zed_src" "$zed_settings"
ok "Zed settings written to $zed_settings"

# --- Extensions --------------------------------------------------------------
ext_list="$OMACOS_ROOT/config/zed.extensions"
[[ -f "$ext_list" ]] || { ok "No zed.extensions file; skipping"; exit 0; }

mapfile -t extensions < <(grep -v '^#' "$ext_list" | grep -v '^[[:space:]]*$')
[[ ${#extensions[@]} -eq 0 ]] && { ok "Extension list is empty; skipping"; exit 0; }

if [[ ! -d "/Applications/Zed.app" ]]; then
  note "Zed not installed; skipping extension install"
  exit 0
fi

info "Installing ${#extensions[@]} Zed extensions via URL scheme"
for ext in "${extensions[@]}"; do
  open "zed://install-extension/$ext" 2>/dev/null || true
done
ok "Extension install triggered for: ${extensions[*]}"
note "Zed may need a moment to finish installing extensions in the background."
