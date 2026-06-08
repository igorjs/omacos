#!/usr/bin/env bash
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

# --- Terminal.app ------------------------------------------------------------
# Profile is set by omacos theme set; just ensure secure keyboard is on.
defaults write com.apple.Terminal SecureKeyboardEntry -bool true

# --- Screenshots -------------------------------------------------------------
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Screenshots"
defaults write com.apple.screencapture disable-shadow -bool true

# --- Global UI behaviour -----------------------------------------------------
# Instant window resize (default is ~0.2 s).
defaults write -g NSWindowResizeTime -float 0.001
# Scrollbars always visible (don't hide when not scrolling).
defaults write -g AppleShowScrollBars -string "Always"
# Don't save new documents to iCloud by default.
defaults write -g NSDocumentSaveNewDocumentsToCloud -bool false
# Don't auto-terminate background apps to reclaim memory.
defaults write -g NSDisableAutomaticTermination -bool true
# Double-clicking a title bar does nothing (no minimize/zoom surprise).
defaults write -g AppleMiniaturizeOnDoubleClick -bool false
# WebKit inspect-element available in any WebKit view.
defaults write -g WebKitDeveloperExtras -bool true
# Inline text predictions off (interferes with terminal and code editors).
defaults write -g NSAutomaticInlinePredictionEnabled -bool false

# --- Stage Manager -----------------------------------------------------------
defaults write com.apple.WindowManager GloballyEnabled -bool false

# --- Widgets -----------------------------------------------------------------
defaults write com.apple.WindowManager StandardHideWidgets -bool true
defaults write com.apple.WindowManager StageManagerHideWidgets -bool true

# --- Crash Reporter ----------------------------------------------------------
# Silent crash reports; no dialog prompts during dev work.
defaults write com.apple.CrashReporter DialogType -string "none"

killall Finder 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

ok "Baseline defaults applied"
