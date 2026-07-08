#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# Prereqs: Xcode Command Line Tools and (on Apple Silicon) Rosetta 2.
# These must be in place before Homebrew can be installed cleanly.
#
set -euo pipefail

BLUE='\033[38;2;122;162;247m'
GREEN='\033[38;2;158;206;106m'
RED='\033[38;2;247;118;142m'
PURPLE='\033[38;2;187;154;247m'
RESET='\033[0m'
info() { printf "${BLUE}==>${RESET} %s\n" "$1"; }
ok() { printf "${GREEN} ok${RESET} %s\n" "$1"; }
warn() { printf "${RED} !! ${RESET}%s\n" "$1"; }
note() { printf "${PURPLE} MANUAL${RESET} %s\n" "$1"; }

# --- Xcode Command Line Tools ----------------------------------------------
if /usr/bin/xcode-select -p >/dev/null 2>&1; then
  ok "Xcode CLT present at $(/usr/bin/xcode-select -p)"
else
  info "Installing Xcode Command Line Tools (a system GUI dialog will appear)"
  /usr/bin/xcode-select --install >/dev/null 2>&1 || true
  # The CLT installer is asynchronous; poll until xcode-select -p succeeds.
  printf '%b' "${BLUE}    waiting for Xcode CLT install to finish (Cmd-Q the installer if it hangs):${RESET}\n"
  tries=0
  until /usr/bin/xcode-select -p >/dev/null 2>&1; do
    sleep 10
    tries=$((tries + 1))
    if ((tries % 6 == 0)); then
      printf "${PURPLE}    still waiting (%d minute(s))${RESET}\n" $((tries / 6))
    fi
    if ((tries > 60)); then
      warn "Gave up waiting after ~10 minutes."
      note "Finish the Xcode CLT install dialog by hand, then re-run ./install.sh"
      exit 1
    fi
  done
  ok "Xcode CLT installed at $(/usr/bin/xcode-select -p)"
fi

# --- Rosetta 2 (Apple Silicon only) ----------------------------------------
arch="$(uname -m)"
if [[ "$arch" == "arm64" ]]; then
  if /usr/bin/pgrep -q oahd 2>/dev/null || /usr/bin/arch -x86_64 /usr/bin/true >/dev/null 2>&1; then
    ok "Rosetta 2 already installed"
  else
    info "Installing Rosetta 2"
    /usr/sbin/softwareupdate --install-rosetta --agree-to-license
    ok "Rosetta 2 installed"
  fi
else
  ok "Intel Mac (arch=$arch); Rosetta not applicable"
fi
