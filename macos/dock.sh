#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# Dock: autohide, instant, no recents.
#
set -euo pipefail
# shellcheck source=lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"

info "Configuring Dock"
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0
defaults write com.apple.dock show-recents -bool false

# Appearance and position
defaults write com.apple.dock tilesize -int 36             # Size: small (tweak to taste)
defaults write com.apple.dock magnification -bool false    # Magnification: off
defaults write com.apple.dock orientation -string "bottom" # Dock on the bottom edge
defaults write com.apple.dock mineffect -string "scale"    # Minimise animation: Scale Effect

# Behaviour
defaults write com.apple.dock minimize-to-application -bool true # Minimise into app icon
defaults write com.apple.dock launchanim -bool true              # Animate opening apps
defaults write com.apple.dock show-process-indicators -bool true # Indicators for open apps

# Window title bar double-click action: Zoom (global domain key, lives in this pane)
defaults write -g AppleActionOnDoubleClick -string "Maximize"

# Mission Control: don't auto-reorder Spaces by most-recent use. Essential with
# a tiling WM (AeroSpace) so Space indices stay stable.
defaults write com.apple.dock mru-spaces -bool false

# Trim Mission Control / Launchpad animation delays.
defaults write com.apple.dock expose-animation-duration -float 0.1
defaults write com.apple.dock springboard-show-duration -float 0
defaults write com.apple.dock springboard-hide-duration -float 0

# --- Dock layout -------------------------------------------------------------
# Slim, fixed set: Finder | Apps | Settings | Terminal | <spacer> | Downloads | Bin
# Finder and Bin (Trash) are permanent Dock fixtures pinned at the ends, so
# dockutil only manages the middle (persistent-apps and persistent-others).
# Needs dockutil (in the Brewfile, installed before this step).
if command -v dockutil >/dev/null 2>&1; then
  info "Setting Dock layout"

  # The app launcher is "Apps" on Tahoe (macOS 26+) and "Launchpad" on Sequoia
  # (15) and earlier. Use whichever exists; skip if neither is present.
  apps_launcher=""
  for candidate in "/System/Applications/Apps.app" "/System/Applications/Launchpad.app"; do
    if [[ -d "$candidate" ]]; then
      apps_launcher="$candidate"
      break
    fi
  done

  # System Settings on Ventura (13+); System Preferences on Monterey (12) and older.
  settings_app=""
  for candidate in "/System/Applications/System Settings.app" "/System/Applications/System Preferences.app"; do
    if [[ -d "$candidate" ]]; then
      settings_app="$candidate"
      break
    fi
  done

  dockutil --remove all --no-restart >/dev/null
  [[ -n "$apps_launcher" ]] && dockutil --add "$apps_launcher" --no-restart >/dev/null
  [[ -n "$settings_app" ]] && dockutil --add "$settings_app" --no-restart >/dev/null
  dockutil --add "/Applications/Ghostty.app" --no-restart >/dev/null
  dockutil --add '' --type spacer --section apps --no-restart >/dev/null
  dockutil --add "$HOME/Downloads" --section others --view fan --display folder \
    --sort dateadded --no-restart >/dev/null
  ok "Dock layout: ${apps_launcher:+$(basename "$apps_launcher" .app), }Settings, Ghostty, spacer, Downloads"
else
  info "dockutil not found; skipping Dock layout (install it via the Brewfile)"
fi

killall Dock 2>/dev/null || true
ok "Dock: autohide, instant, no recents, bottom, scale, small"
