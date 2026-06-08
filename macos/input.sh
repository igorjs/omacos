#!/usr/bin/env bash
#
# Keyboard + trackpad tuning for a fast typist.
# Most of these need a logout/restart and a relaunch of affected apps to
# fully take effect; the installer's summary reminds the user.
#
set -euo pipefail

BLUE='\033[38;2;122;162;247m'; GREEN='\033[38;2;158;206;106m'
PURPLE='\033[38;2;187;154;247m'; RESET='\033[0m'
info(){ printf "${BLUE}==>${RESET} %s\n" "$1"; }
ok(){   printf "${GREEN} ok${RESET} %s\n" "$1"; }
note(){ printf "${PURPLE} -- ${RESET}%s\n" "$1"; }

# --- Key repeat: fast end of the UI sliders --------------------------------
# KeyRepeat=2 and InitialKeyRepeat=15 are near the fast end of System Settings.
# For even faster, use KeyRepeat=1 / InitialKeyRepeat=10 (below the UI minimums).
info "Fast key repeat (KeyRepeat=2, InitialKeyRepeat=15)"
defaults write -g KeyRepeat -int 2
defaults write -g InitialKeyRepeat -int 15
ok "Key repeat tuned"

# --- Disable press-and-hold (accent character popup) -----------------------
# Critical for Neovim and any vim-style editor: a held key should repeat, not
# pop up an accent menu.
info "Disabling press-and-hold (so held keys repeat)"
defaults write -g ApplePressAndHoldEnabled -bool false
ok "Press-and-hold disabled"

# --- Disable intrusive text substitutions ----------------------------------
info "Disabling auto-capitalisation and double-space period"
defaults write -g NSAutomaticCapitalizationEnabled -bool false
defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false
ok "Auto-capitalise and double-space period disabled"

# --- Tap to click on the trackpad ------------------------------------------
info "Tap to click (trackpad + login)"
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write -g com.apple.mouse.tapBehavior -int 1
defaults write -g com.apple.mouse.tapBehavior -int 1
ok "Tap to click enabled"

note "Log out and back in for key repeat and press-and-hold to take effect everywhere."
