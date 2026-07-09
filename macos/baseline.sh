#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# macos/baseline.sh — capture a pre-install snapshot of macOS defaults and brew
# packages so that `omacos uninstall --defaults` / `--packages` can restore the
# system to its state before OmacOS made any changes.
#
# Idempotent: exits immediately if the baseline directory already exists, so
# re-running install.sh never overwrites an existing baseline.
#
# Run BEFORE any `defaults write` calls; install.sh invokes this script before
# the macOS-defaults step.
#
# Environment:
#   OMACOS_BASELINE_DIR  override the baseline directory (default:
#                        ~/.config/omacos/baseline)
#
set -euo pipefail

# shellcheck source=lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"

BASELINE_DIR="${OMACOS_BASELINE_DIR:-$HOME/.config/omacos/baseline}"

# --- Idempotency guard -------------------------------------------------------
if [[ -d "$BASELINE_DIR" ]]; then
  ok "Baseline already exists at $BASELINE_DIR — skipping capture"
  exit 0
fi

info "Capturing pre-install baseline to $BASELINE_DIR"
mkdir -p "$BASELINE_DIR"

# --- Domain lists (hard-coded: deterministic and reviewable) -----------------
# These are every domain OmacOS writes during install; derived from
# `git grep 'defaults write' macos/*.sh themes/tokyonight/macos.sh`.

# Per-user domains written by OmacOS (defaults write <domain> ...)
user_domains=(
  com.apple.AdLib
  com.apple.AppleMultitouchTrackpad
  com.apple.assistant.support
  com.apple.BezelServices.kDim
  com.apple.CloudSubscriptionFeatures.optIn
  com.apple.commerce
  com.apple.CrashReporter
  com.apple.desktopservices
  com.apple.dock
  com.apple.driver.AppleBluetoothMultitouch.trackpad
  com.apple.finder
  com.apple.HIToolbox
  com.apple.lookup.shared
  com.apple.NetworkBrowser
  com.apple.Safari
  com.apple.screencapture
  com.apple.screensaver
  com.apple.Siri
  com.apple.SpeechRecognitionCore
  com.apple.SubmitDiagInfo
  com.apple.Terminal
  com.apple.universalaccess
  com.apple.WindowManager
)

# System-wide domains under /Library/Preferences (sudo defaults write ...)
system_domains=(
  /Library/Preferences/.GlobalPreferences
  /Library/Preferences/com.apple.mDNSResponder
  /Library/Preferences/com.apple.SoftwareUpdate
)

# ByHost (per-hardware) user domains (defaults write ~/Library/Preferences/ByHost/...)
byhost_domains=(
  com.apple.coreservices.useractivityd
)

# --- Helper: safe filename for a domain path (replace / with _) --------------
safe_name() { printf '%s' "$1" | tr '/' '_'; }

# --- Bail out cleanly if defaults(1) is absent (non-macOS host) --------------
if ! command -v defaults >/dev/null 2>&1; then
  warn "defaults(1) not found — skipping plist export (non-macOS host)"
  ok "Baseline directory created at $BASELINE_DIR (no plist export)"
  exit 0
fi

# --- User domains ------------------------------------------------------------
for d in "${user_domains[@]}"; do
  defaults export "$d" "$BASELINE_DIR/$d.plist" 2>/dev/null ||
    warn "Baseline: could not export user domain $d (may not exist yet)"
done

# --- NSGlobalDomain ----------------------------------------------------------
defaults export -g "$BASELINE_DIR/NSGlobalDomain.plist" 2>/dev/null ||
  warn "Baseline: could not export NSGlobalDomain"

# --- System domains ----------------------------------------------------------
for d in "${system_domains[@]}"; do
  sudo defaults export "$d" "$BASELINE_DIR/$(safe_name "$d").plist" 2>/dev/null ||
    warn "Baseline: could not export system domain $d (may not exist yet)"
done

# --- ByHost user domains -----------------------------------------------------
for d in "${byhost_domains[@]}"; do
  defaults -currentHost export "$d" "$BASELINE_DIR/byhost.$d.plist" 2>/dev/null ||
    warn "Baseline: could not export ByHost domain $d (may not exist yet)"
done

# ByHost global (NSGlobalDomain via -currentHost)
defaults -currentHost export -g "$BASELINE_DIR/byhost.NSGlobalDomain.plist" 2>/dev/null ||
  warn "Baseline: could not export ByHost NSGlobalDomain"

# --- Brew package baseline ---------------------------------------------------
if command -v brew >/dev/null 2>&1; then
  brew list --formula >"$BASELINE_DIR/brew-formulae.txt" || true
  brew list --cask >"$BASELINE_DIR/brew-casks.txt" || true
  ok "Brew package lists captured"
else
  warn "brew not found — skipping package baseline"
fi

ok "Baseline captured to $BASELINE_DIR"
