#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# Safari defaults — Advanced tab preferences.
#
set -euo pipefail

BLUE='\033[38;2;122;162;247m'
GREEN='\033[38;2;158;206;106m'
RESET='\033[0m'
info() { printf "${BLUE}==>${RESET} %s\n" "$1"; }
ok() { printf "${GREEN} ok${RESET} %s\n" "$1"; }

info "Applying Safari defaults"

# --- Smart Search field -------------------------------------------------------
# Show the full URL instead of just the domain.
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true

# --- Accessibility ------------------------------------------------------------
# Enforce a minimum font size of 10pt.
defaults write com.apple.Safari WebKitMinimumFontSize -int 10
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2MinimumFontSize -int 10
# Tab key cycles through form controls only, not every focusable element.
defaults write com.apple.Safari WebKitTabToLinksPreferenceKey -bool false
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2TabsToLinks -bool false

# --- Privacy ------------------------------------------------------------------
# Enhanced tracking and fingerprinting protection in ALL browsing (not just private).
defaults write com.apple.Safari EnableEnhancedPrivacyInPrivateBrowsing -bool true
defaults write com.apple.Safari EnableEnhancedPrivacyInRegularBrowsing -bool true
# Allow Apple Pay / Apple Card capability detection.
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2ApplePayCapabilityDisclosureAllowed -bool true
# Privacy-preserving ad click measurement (PCM) — on.
defaults write com.apple.Safari WebKitPreferences.privateClickMeasurementEnabled -bool true
# Do NOT block all cookies (value 2 = allow; 3 = block all).
defaults write com.apple.Safari BlockStoragePolicy -int 2
# Highlights opt-in off (prevents Safari from phoning home for page highlights).
defaults write com.apple.Safari HighlightsOptInStatus -int 0

# --- Reading List -------------------------------------------------------------
# Do not automatically save articles for offline reading.
defaults write com.apple.Safari ReadingListSaveArticlesOfflineAutomatically -bool false

# --- Developer ----------------------------------------------------------------
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

killall Safari 2>/dev/null || true

ok "Safari defaults applied"
