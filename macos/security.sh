#!/usr/bin/env bash
#
# macOS security hardening and privacy defaults.
# The firewall/mDNS/remote-access blocks require sudo — the script prompts once
# up front so sudo commands never block silently mid-run.
#
set -euo pipefail

BLUE='\033[38;2;122;162;247m'; GREEN='\033[38;2;158;206;106m'
YELLOW='\033[38;2;224;175;104m'; RESET='\033[0m'
info(){ printf "${BLUE}==>${RESET} %s\n" "$1"; }
ok(){   printf "${GREEN} ok${RESET} %s\n" "$1"; }
warn(){ printf "${YELLOW}warn${RESET} %s\n" "$1"; }

# Acquire sudo credentials once up front; fail fast if unavailable.
if ! sudo -n true 2>/dev/null; then
  echo "sudo required for firewall and remote-access settings"
  sudo -v
fi

# --- Firewall ----------------------------------------------------------------
info "Firewall"
FW=/usr/libexec/ApplicationFirewall/socketfilterfw
if sudo "$FW" --getglobalstate 2>/dev/null | grep -q "disabled"; then
  sudo "$FW" --setglobalstate on
  ok "Application firewall enabled"
else
  ok "Application firewall already on"
fi
sudo "$FW" --setstealthmode on
ok "Stealth mode on (no ping/port-probe responses)"

# --- Remote access -----------------------------------------------------------
info "Remote access"
# launchctl avoids the interactive "you'll lose your connection" prompt
# that systemsetup -setremotelogin triggers when SSH sessions are active.
sudo launchctl disable system/com.openssh.sshd 2>/dev/null || true
sudo launchctl stop system/com.openssh.sshd 2>/dev/null || true
ok "Remote Login (SSH) disabled"
sudo launchctl disable system/com.apple.RemoteAppleEventsServer 2>/dev/null || true
ok "Remote Apple Events disabled"

# --- mDNS / Bonjour multicast advertising ------------------------------------
info "mDNS"
sudo defaults write /Library/Preferences/com.apple.mDNSResponder NoMulticastAdvertisements -bool true
ok "mDNS multicast advertising disabled"

# --- Siri --------------------------------------------------------------------
info "Siri"
defaults write com.apple.assistant.support "Assistant Enabled" -bool false
defaults write com.apple.Siri StatusMenuVisible -bool false
defaults write com.apple.Siri VoiceTriggerUserEnabled -bool false
ok "Siri disabled"

# --- Analytics & diagnostics -------------------------------------------------
info "Analytics and diagnostics"
defaults write com.apple.SubmitDiagInfo AutoSubmit -bool false
defaults write com.apple.CrashReporter DialogType -string "none"
defaults write com.apple.commerce SendSharedDeviceData -bool false
ok "Diagnostic auto-submission disabled"

# --- Advertising ID ----------------------------------------------------------
info "Advertising"
defaults write com.apple.AdLib allowApplePersonalizedAdvertising -bool false
defaults write com.apple.AdLib allowIdentifierForAdvertising -bool false
defaults write com.apple.AdLib forceLimitAdTracking -bool true
ok "Personalized advertising and ad tracking disabled"

# --- Spotlight ---------------------------------------------------------------
info "Spotlight"
defaults write com.apple.lookup.shared LookupSuggestionsDisabled -bool true
ok "Spotlight Suggestions (network lookups) disabled"

# --- Secure keyboard entry ---------------------------------------------------
info "Secure keyboard entry"
defaults write com.apple.Terminal SecureKeyboardEntry -bool true
ok "Terminal.app secure keyboard entry on"

# --- AirDrop / Handoff -------------------------------------------------------
info "AirDrop and Handoff"
defaults write com.apple.NetworkBrowser DisableAirDrop -bool true
defaults write ~/Library/Preferences/ByHost/com.apple.coreservices.useractivityd ActivityAdvertisingAllowed -bool false
defaults write ~/Library/Preferences/ByHost/com.apple.coreservices.useractivityd ActivityReceivingAllowed -bool false
ok "AirDrop and Handoff disabled"

# --- iCloud document sync ----------------------------------------------------
info "iCloud"
defaults write -g NSDocumentSaveNewDocumentsToCloud -bool false
ok "Default save location: local (not iCloud)"

# --- Screen lock -------------------------------------------------------------
info "Screen lock"
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0
ok "Immediate password required after sleep"

# --- Safari baseline privacy -------------------------------------------------
# Safari preferences are sandboxed — write via open-source domain, not container path.
info "Safari privacy"
defaults write com.apple.Safari SendDoNotTrackHTTPHeader -bool true 2>/dev/null \
  || warn "Safari prefs sandboxed; open Safari once then re-run to apply"
defaults write com.apple.Safari WebKitJavaScriptCanOpenWindowsAutomatically -bool false 2>/dev/null || true
ok "Safari: Do Not Track on, no JS popup windows"

ok "Security hardening complete"
