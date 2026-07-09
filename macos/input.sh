#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# Keyboard + trackpad tuning for a fast typist.
# Most of these need a logout/restart and a relaunch of affected apps to
# fully take effect; the installer's summary reminds the user.
#
set -euo pipefail
# shellcheck source=lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"

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
# Smart quotes/dashes and autocorrect mangle code and shell input, so turn the
# whole set off (autocorrect, capitalisation, period, quotes, dashes).
info "Disabling auto-capitalisation, autocorrect and smart punctuation"
defaults write -g NSAutomaticCapitalizationEnabled -bool false
defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false
defaults write -g NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write -g NSAutomaticDashSubstitutionEnabled -bool false
ok "Autocorrect and smart punctuation disabled"

# --- Tap to click on the trackpad ------------------------------------------
info "Tap to click (trackpad + login)"
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write -g com.apple.mouse.tapBehavior -int 1
defaults write -g com.apple.mouse.tapBehavior -int 1
ok "Tap to click enabled"

# --- Three-finger drag -----------------------------------------------------
# Drag windows/selections with three fingers instead of click-and-hold.
info "Three-finger drag"
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
ok "Three-finger drag enabled"

# --- Globe (fn) key: do nothing ---------------------------------------------
info "Globe key: do nothing"
defaults write com.apple.HIToolbox AppleFnUsageType -integer 0
ok "Globe key set to do nothing"

# --- Keyboard navigation: off -----------------------------------------------
# Tab cycles through text fields only (not all controls on screen).
info "Keyboard navigation off (text fields only)"
defaults write -g AppleKeyboardUIMode -int 0
ok "Keyboard navigation off"

# --- Keyboard backlight: auto-dim in low light ------------------------------
info "Keyboard backlight: auto-dim in low light"
defaults write com.apple.BezelServices.kDim -bool true
ok "Keyboard backlight auto-dim enabled"

# --- Dictation: off, auto-punctuation off -----------------------------------
info "Dictation off, auto-punctuation off"
defaults write com.apple.HIToolbox AppleDictationAutoEnable -int 0
defaults write com.apple.SpeechRecognitionCore SpeechRecognitionAutoPunctuateEnabled -bool false
ok "Dictation disabled"

note "Log out and back in for key repeat and press-and-hold to take effect everywhere."
