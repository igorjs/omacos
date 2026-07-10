#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# Desktop & Dock pane: Stage Manager, desktop items/widgets, window tiling, and
# global window behaviours. Dock-specific keys live in dock.sh; this covers the
# com.apple.WindowManager domain plus a few NSGlobalDomain window settings.
#
# Note: the native edge-tiling keys below coexist with AeroSpace. AeroSpace is
# the primary tiling WM; macOS edge-drag tiling stays on as a fallback because
# the screenshot enables it. Disable these if it fights AeroSpace for you.
#
set -euo pipefail
# shellcheck source=lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"

WM=com.apple.WindowManager

info "Desktop, Stage Manager and widgets"
defaults write "$WM" GloballyEnabled -bool false                 # Stage Manager: off
defaults write "$WM" StandardHideDesktopIcons -bool false        # Show items on Desktop
defaults write "$WM" EnableStandardClickToShowDesktop -bool true # Click wallpaper to show desktop: Always
defaults write "$WM" AppWindowGroupingBehavior -bool true        # Show windows from an app: All at Once
defaults write "$WM" StandardHideWidgets -bool true              # Hide desktop widgets
defaults write "$WM" StageManagerHideWidgets -bool true          # Hide widgets in Stage Manager
ok "Stage Manager off, desktop items on, widgets hidden"

info "Window tiling"
defaults write "$WM" EnableTilingByEdgeDrag -bool true        # Drag to left/right edge to tile
defaults write "$WM" EnableTopTilingByEdgeDrag -bool true     # Drag to menu bar to fill screen
defaults write "$WM" EnableTilingOptionAccelerator -bool true # Hold Option while dragging to tile
defaults write "$WM" EnableTiledWindowMargins -bool false     # Tiled windows have margins: off
ok "Edge-drag tiling on, no tile margins"

info "Window behaviour (global)"
defaults write -g AppleWindowTabbingMode -string "fullscreen" # Prefer tabs: In Full Screen
defaults write -g NSCloseAlwaysConfirmsChanges -bool false    # Don't ask to keep changes on close
defaults write -g NSQuitAlwaysKeepsWindows -bool false        # Close windows when quitting an app
ok "Tabs in full screen, no close confirm, close-on-quit"

killall WindowManager 2>/dev/null || true
