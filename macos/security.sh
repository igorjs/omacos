#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# macOS security hardening and privacy defaults.
# The firewall/mDNS/remote-access blocks require sudo — the script prompts once
# up front so sudo commands never block silently mid-run.
#
set -euo pipefail

# shellcheck source=lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"

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
if [[ "${OMACOS_DISABLE_SSH:-1}" == "1" ]]; then
  sudo launchctl disable system/com.openssh.sshd 2>/dev/null || true
  sudo launchctl stop system/com.openssh.sshd 2>/dev/null || true
  ok "Remote Login (SSH) disabled"
else
  ok "Remote Login (SSH) gate skipped (OMACOS_DISABLE_SSH=0)"
fi
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

# --- Apple Intelligence ------------------------------------------------------
info "Apple Intelligence"
defaults write com.apple.CloudSubscriptionFeatures.optIn "545129924" -bool false
ok "Apple Intelligence opt-in disabled"

# --- Blackhole feature endpoints (Weather, News) -----------------------------
# The Weather and News widgets/daemons phone home for content. Blackhole their
# endpoints in /etc/hosts so nothing on the machine fetches them (IPv4 and IPv6,
# since an A-only block would still resolve AAAA). Shared infra is intentionally
# left alone: gsp-ssl.ls.apple.com (Location Services) and gateway.icloud.com
# (iCloud) keep Maps/Find My/iCloud working.
info "Blackholing Weather and News endpoints"
blocked_hosts=(
  weatherkit.apple.com weather-data.apple.com weather-map.apple.com # Weather
  news-edge.apple.com apple.news news-events.apple.com              # News
)
hosts_open="# >>> omacos blocked endpoints >>>"
hosts_close="# <<< omacos blocked endpoints <<<"
blocked_tmp="$(mktemp)"
# Strip any previous block (markers inclusive), then append a fresh one.
awk -v o="$hosts_open" -v c="$hosts_close" '
  $0==o{skip=1; next} $0==c&&skip{skip=0; next} !skip
' /etc/hosts >"$blocked_tmp"
{
  echo "$hosts_open"
  for h in "${blocked_hosts[@]}"; do printf "0.0.0.0 %s\n:: %s\n" "$h" "$h"; done
  echo "$hosts_close"
} >>"$blocked_tmp"
if [[ ! -s "$blocked_tmp" ]]; then
  warn "/etc/hosts transform produced empty output; aborting hosts rewrite"
  rm -f "$blocked_tmp"
  exit 1
fi
sudo cp /etc/hosts "/etc/hosts.bak.$(date +%Y%m%d-%H%M%S)"
# shellcheck disable=SC2024
sudo tee /etc/hosts <"$blocked_tmp" >/dev/null
rm -f "$blocked_tmp"
sudo dscacheutil -flushcache 2>/dev/null || true
sudo killall -HUP mDNSResponder 2>/dev/null || true
ok "Weather and News endpoints blocked in /etc/hosts"

# --- Disable Weather and News background services ----------------------------
# weatherd/newsd back the apps and their widgets; disabling them stops the
# background fetching. `launchctl disable` writes to the override database
# (allowed under SIP) and persists across reboots. The .app bundles live in
# /System and cannot be removed; to block launching them entirely, deny
# com.apple.weather / com.apple.news in your application-control policy.
info "Disabling Weather and News daemons"
for svc in com.apple.weatherd com.apple.newsd; do
  sudo launchctl disable "system/$svc" 2>/dev/null || true
  sudo launchctl bootout "system/$svc" 2>/dev/null || true
done
ok "weatherd and newsd disabled"

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

# --- Software Update ---------------------------------------------------------
# General > Software Update > Automatic Updates: On. The SoftwareUpdate keys
# live in /Library/Preferences (system-wide, need sudo); App Store app updates
# (com.apple.commerce AutoUpdate) are per-user.
info "Software Update: automatic"
SU=/Library/Preferences/com.apple.SoftwareUpdate
sudo defaults write "$SU" AutomaticCheckEnabled -bool true            # check for updates
sudo defaults write "$SU" AutomaticDownload -bool true                # download in background
sudo defaults write "$SU" CriticalUpdateInstall -bool true            # install security responses
sudo defaults write "$SU" ConfigDataInstall -bool true                # install system data files
sudo defaults write "$SU" AutomaticallyInstallMacOSUpdates -bool true # install macOS updates
defaults write com.apple.commerce AutoUpdate -bool true               # App Store app updates
ok "Automatic updates enabled (check, download, install)"

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

# --- Require admin password for system-wide settings -------------------------
# System Settings > Lock Screen > "Require an administrator password to access
# system-wide settings". On a stock Mac the system.preferences authorization
# right is class=user with shared=true; flipping shared=false forces admin auth
# on every locked pane. If the right has been replaced by an MDM/endpoint rule
# (e.g. ThreatLocker), it has no top-level shared key, so we leave it untouched
# rather than clobber managed policy.
info "Require admin password for system-wide settings"
sp_plist="$(mktemp -t omacos.system.preferences)" || sp_plist="/tmp/omacos.system.preferences.plist"
if security authorizationdb read system.preferences >"$sp_plist" 2>/dev/null; then
  if /usr/libexec/PlistBuddy -c "Print :shared" "$sp_plist" >/dev/null 2>&1; then
    /usr/libexec/PlistBuddy -c "Set :shared false" "$sp_plist" >/dev/null 2>&1
    # shellcheck disable=SC2024
    if sudo security authorizationdb write system.preferences <"$sp_plist" 2>/dev/null; then
      ok "Admin password required for system-wide settings"
    else
      warn "Could not update system.preferences authorization right"
    fi
  else
    ok "system.preferences managed externally (MDM); left as-is"
  fi
else
  warn "Could not read system.preferences authorization right"
fi
rm -f "$sp_plist"

# --- Automatic logout after inactivity ---------------------------------------
# System Settings > Lock Screen > "Log out automatically after inactivity".
# AutoLogOutDelay is in seconds; 0 disables. Override the idle window with
# OMACOS_AUTOLOGOUT_MINUTES (default 120).
OMACOS_AUTOLOGOUT_MINUTES="${OMACOS_AUTOLOGOUT_MINUTES:-120}"
info "Automatic logout after ${OMACOS_AUTOLOGOUT_MINUTES} min of inactivity"
sudo defaults write /Library/Preferences/.GlobalPreferences \
  com.apple.autologout.AutoLogOutDelay -int "$((OMACOS_AUTOLOGOUT_MINUTES * 60))"
ok "Auto-logout set to ${OMACOS_AUTOLOGOUT_MINUTES} minutes"

# --- Safari baseline privacy -------------------------------------------------
# Safari preferences are sandboxed — write via open-source domain, not container path.
info "Safari privacy"
defaults write com.apple.Safari SendDoNotTrackHTTPHeader -bool true 2>/dev/null ||
  warn "Safari prefs sandboxed; open Safari once then re-run to apply"
defaults write com.apple.Safari WebKitJavaScriptCanOpenWindowsAutomatically -bool false 2>/dev/null || true
ok "Safari: Do Not Track on, no JS popup windows"

ok "Security hardening complete"
