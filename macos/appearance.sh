#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# macOS appearance: non-color, scriptable parts only.
# Theme colors (accent, highlight, wallpaper) live in themes/<name>/macos.sh
# so they swap with the theme.
#
set -euo pipefail

BLUE='\033[38;2;122;162;247m'
GREEN='\033[38;2;158;206;106m'
RESET='\033[0m'
info() { printf "${BLUE}==>${RESET} %s\n" "$1"; }
ok() { printf "${GREEN} ok${RESET} %s\n" "$1"; }

info "Setting Dark mode"
osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true' || true
ok "Dark mode on"

# Reduce Transparency (tames Tahoe's Liquid Glass) lives in accessibility.sh
# alongside the other com.apple.universalaccess keys, which need Full Disk
# Access to write.

# Scroll bars: always visible (macOS default hides them until scrolling).
info "Always showing scroll bars"
defaults write -g AppleShowScrollBars -string "Always"
ok "Scroll bars always visible"

# These two already match macOS defaults; set explicitly so the intent is
# documented and survives a machine where the default ever changes.
defaults write -g NSTableViewDefaultSizeMode -int 2       # sidebar icons: Medium
defaults write -g AppleScrollerPagingBehavior -bool false # click scroll track: jump to next page
ok "Sidebar icon size Medium, scroll-track click jumps to next page"

# Menu bar autohide: only when sketchybar is installed (it replaces the native
# bar, so we hide macOS's). Without sketchybar, keep the bar visible ("Never"),
# matching the default. sketchybar is opt-in via the Brewfile and `brew bundle`
# runs before this step, so detecting the binary tells us the user's choice.
if command -v sketchybar >/dev/null 2>&1; then
  info "Autohiding the menu bar (sketchybar detected)"
  defaults write -g _HIHideMenuBar -bool true
  ok "Menu bar autohide enabled"
else
  info "Keeping the menu bar visible (no sketchybar)"
  defaults write -g _HIHideMenuBar -bool false
  ok "Menu bar autohide disabled"
fi
