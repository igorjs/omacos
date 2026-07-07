#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# Opinionated macOS defaults beyond appearance, Dock, input, and locale.
#
# Start thin; populate this from real snapshot diffs via:
#   tools/mac-snapshot.sh watch
# That reveals the exact `defaults write <domain> <key>` for a setting you
# toggled in System Settings, so this script never emits writes that silently
# do nothing.
#
set -euo pipefail

BLUE='\033[38;2;122;162;247m'; GREEN='\033[38;2;158;206;106m'; RESET='\033[0m'
info(){ printf "${BLUE}==>${RESET} %s\n" "$1"; }
ok(){   printf "${GREEN} ok${RESET} %s\n" "$1"; }

info "Applying baseline defaults"

# --- Finder ------------------------------------------------------------------
defaults write -g AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder WarnOnEmptyTrash -bool false
defaults write com.apple.finder FXRemoveOldTrashItems -bool true
defaults write com.apple.finder QuitMenuItem -bool true
# New Finder windows open to the home folder.
defaults write com.apple.finder NewWindowTarget -string "PfHm"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"
# Don't litter .DS_Store files on network shares or USB volumes.
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# --- Terminal.app ------------------------------------------------------------
# Profile is set by omacos theme set; just ensure secure keyboard is on.
defaults write com.apple.Terminal SecureKeyboardEntry -bool true

# --- Screenshots -------------------------------------------------------------
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Screenshots"
defaults write com.apple.screencapture disable-shadow -bool true
defaults write com.apple.screencapture type -string "png"

# --- Global UI behaviour -----------------------------------------------------
# Instant window resize (default is ~0.2 s).
defaults write -g NSWindowResizeTime -float 0.001
# Don't save new documents to iCloud by default.
defaults write -g NSDocumentSaveNewDocumentsToCloud -bool false
# Don't auto-terminate background apps to reclaim memory.
defaults write -g NSDisableAutomaticTermination -bool true
# WebKit inspect-element available in any WebKit view.
defaults write -g WebKitDeveloperExtras -bool true
# Inline text predictions off (interferes with terminal and code editors).
defaults write -g NSAutomaticInlinePredictionEnabled -bool false
# Expand the save and print dialogs by default (show all options).
defaults write -g NSNavPanelExpandedStateForSaveMode -bool true
defaults write -g NSNavPanelExpandedStateForSaveMode2 -bool true
defaults write -g PMPrintingExpandedStateForPrint -bool true
defaults write -g PMPrintingExpandedStateForPrint2 -bool true
# Scrollbars (AppleShowScrollBars) now live in appearance.sh; the title-bar
# double-click action (AppleActionOnDoubleClick = Zoom) lives in dock.sh; Stage
# Manager and widget visibility live in windows.sh.

# --- Crash Reporter ----------------------------------------------------------
# Silent crash reports; no dialog prompts during dev work.
defaults write com.apple.CrashReporter DialogType -string "none"

killall Finder 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

ok "Baseline defaults applied"
