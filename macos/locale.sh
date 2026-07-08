#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# Language / region / keyboard layout.
# User-configurable via env. Region and language are reliable; the keyboard
# input source dict is fragile and often needs a logout to register, so
# we always print a MANUAL fallback.
#
# Defaults match the user's setup: Australian English writing, US International PC keyboard.
#
set -euo pipefail

BLUE='\033[38;2;122;162;247m'
GREEN='\033[38;2;158;206;106m'
PURPLE='\033[38;2;187;154;247m'
RESET='\033[0m'
info() { printf "${BLUE}==>${RESET} %s\n" "$1"; }
ok() { printf "${GREEN} ok${RESET} %s\n" "$1"; }
note() { printf "${PURPLE} MANUAL${RESET} %s\n" "$1"; }

OMACOS_LOCALE="${OMACOS_LOCALE:-en_AU}"
OMACOS_LANGUAGE="${OMACOS_LANGUAGE:-${OMACOS_LOCALE//_/-}}"
OMACOS_KEYBOARD_LAYOUT="${OMACOS_KEYBOARD_LAYOUT:-USInternational-PC}"

# --- Region / language (reliable) ------------------------------------------
info "Setting locale to $OMACOS_LOCALE, language to $OMACOS_LANGUAGE"
defaults write -g AppleLocale -string "$OMACOS_LOCALE"
defaults write -g AppleLanguages -array "$OMACOS_LANGUAGE"
defaults write -g AppleMeasurementUnits -string "Centimeters"
defaults write -g AppleMetricUnits -bool true
ok "Locale/language set (logout required for the menu bar to update)"

# --- Keyboard input source (FRAGILE) ---------------------------------------
# The HIToolbox AppleEnabledInputSources dict is unreliable across macOS
# versions. We attempt the write, then always print the manual fallback so
# the user knows how to verify and recover.
case "$OMACOS_KEYBOARD_LAYOUT" in
  USInternational-PC)
    info "Attempting to set keyboard layout: US International - PC"
    defaults write com.apple.HIToolbox AppleEnabledInputSources -array \
      '{ "InputSourceKind" = "Keyboard Layout"; "KeyboardLayout ID" = 15000; "KeyboardLayout Name" = "USInternational-PC"; }' ||
      true
    ok "Layout write attempted"
    ;;
  *)
    note "Layout '$OMACOS_KEYBOARD_LAYOUT' is not pre-mapped; set it by hand"
    ;;
esac

note "Verify the layout via: System Settings > Keyboard > Text Input > Edit"
note "If missing, add: 'U.S. International - PC' (Others), then remove the default U.S."
note "If the scripted write did not stick, run: ./tools/mac-snapshot.sh watch to capture the working dict on this machine."
