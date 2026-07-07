#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# Battery: Low Power Mode "Only on Battery". pmset needs sudo. -b is the
# battery power source, -c is charger/AC. So enable on battery, disable on AC.
#
set -euo pipefail

BLUE='\033[38;2;122;162;247m'; GREEN='\033[38;2;158;206;106m'
YELLOW='\033[38;2;224;175;104m'; RESET='\033[0m'
info(){ printf "${BLUE}==>${RESET} %s\n" "$1"; }
ok(){   printf "${GREEN} ok${RESET} %s\n" "$1"; }
warn(){ printf "${YELLOW}warn${RESET} %s\n" "$1"; }

# Desktops have no battery power source; skip cleanly there.
if ! pmset -g batt 2>/dev/null | grep -q "InternalBattery"; then
  warn "No internal battery detected; skipping Low Power Mode"
  exit 0
fi

if ! sudo -n true 2>/dev/null; then
  echo "sudo required to set Low Power Mode"
  sudo -v
fi

info "Low Power Mode: only on battery"
sudo pmset -b lowpowermode 1   # on battery: enabled
sudo pmset -c lowpowermode 0   # on charger: disabled
ok "Low Power Mode enabled on battery, off on AC"
