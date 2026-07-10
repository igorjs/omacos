#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# Disable macOS system keyboard shortcuts that conflict with terminal/tmux usage.
# Changes take effect after the activateSettings call at the bottom.
#
set -euo pipefail
# shellcheck source=lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"

# Helper: disable a symbolic hotkey by ID, preserving its value/parameters.
disable_hotkey() {
  local id="$1"
  /usr/libexec/PlistBuddy \
    -c "Set :AppleSymbolicHotKeys:${id}:enabled false" \
    ~/Library/Preferences/com.apple.symbolichotkeys.plist 2>/dev/null || true
}

info "Disabling conflicting macOS keyboard shortcuts"

# --- Mission Control (Ctrl+Up / Ctrl+Down) -----------------------------------
# These intercept Ctrl+Up/Down before the terminal sees them, breaking
# vim and other tools that use Ctrl+Up/Down.
disable_hotkey 32 # Mission Control      (Ctrl+Up)
disable_hotkey 33 # Application Windows  (Ctrl+Down)
disable_hotkey 34 # Show Desktop         (F11 / secondary)
ok "Mission Control shortcuts disabled (Ctrl+Up, Ctrl+Down)"

# --- Space navigation (Ctrl+Left / Ctrl+Right) --------------------------------
# These intercept Ctrl+Left/Right which are standard readline word-navigation
# shortcuts (move one word backward/forward) used constantly in the terminal.
disable_hotkey 79 # Move left a Space    (Ctrl+Left)
disable_hotkey 80 # Move right a Space   (Ctrl+Right)
disable_hotkey 81 # Move left a Space    (secondary binding)
disable_hotkey 82 # Move right a Space   (secondary binding)
ok "Space-switching shortcuts disabled (Ctrl+Left, Ctrl+Right)"

# Apply changes immediately (no logout required).
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
ok "Settings applied"
