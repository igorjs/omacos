#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# Docker Desktop is installed via the Brewfile (cask "docker"). This script
# just verifies install and prints the manual first-launch step.
#
# Colima alternative (CLI-only): `brew install colima docker && colima start`
#
set -euo pipefail

BLUE='\033[38;2;122;162;247m'; GREEN='\033[38;2;158;206;106m'
PURPLE='\033[38;2;187;154;247m'; RESET='\033[0m'
info(){ printf "${BLUE}==>${RESET} %s\n" "$1"; }
ok(){   printf "${GREEN} ok${RESET} %s\n" "$1"; }
note(){ printf "${PURPLE} MANUAL${RESET} %s\n" "$1"; }

if [[ -d "/Applications/Docker.app" ]]; then
  ok "Docker Desktop present at /Applications/Docker.app"
else
  info "Docker Desktop not found; install via Brewfile (cask 'docker') and re-run"
fi

note "Open Docker Desktop once to finish setup (privileged helper install, license accept)."
