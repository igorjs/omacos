#!/usr/bin/env bash
#
# macOS appearance: non-color, scriptable parts only.
# Theme colors (accent, highlight, wallpaper) live in themes/<name>/macos.sh
# so they swap with the theme.
#
set -euo pipefail

BLUE='\033[38;2;122;162;247m'; GREEN='\033[38;2;158;206;106m'; RESET='\033[0m'
info(){ printf "${BLUE}==>${RESET} %s\n" "$1"; }
ok(){   printf "${GREEN} ok${RESET} %s\n" "$1"; }

info "Setting Dark mode"
osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true' || true
ok "Dark mode on"

# Reduce transparency: tames Tahoe's Liquid Glass effect, helps the seamless
# look on a tiled desktop with zero gaps.
info "Reducing transparency (Tahoe Liquid Glass)"
defaults write com.apple.universalaccess reduceTransparency -bool true
ok "Reduce transparency enabled"

info "Autohiding the menu bar"
defaults write -g _HIHideMenuBar -bool true
ok "Menu bar autohide enabled"
