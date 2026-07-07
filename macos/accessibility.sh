#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# Accessibility pane: Display and Motion sections. All keys live in
# com.apple.universalaccess, which is a TCC-protected preferences domain:
# `defaults write` to it fails with "Could not write domain
# com.apple.universalaccess; exiting" unless the terminal running this script
# has Full Disk Access (System Settings > Privacy & Security > Full Disk
# Access). We probe with the first write; if it fails we warn and skip the rest
# rather than aborting the whole install.
#
set -euo pipefail

BLUE='\033[38;2;122;162;247m'; GREEN='\033[38;2;158;206;106m'
YELLOW='\033[38;2;224;175;104m'; RESET='\033[0m'
info(){ printf "${BLUE}==>${RESET} %s\n" "$1"; }
ok(){   printf "${GREEN} ok${RESET} %s\n" "$1"; }
warn(){ printf "${YELLOW}warn${RESET} %s\n" "$1"; }

UA=com.apple.universalaccess

info "Accessibility: Display and Motion"
if defaults write "$UA" reduceTransparency -bool true 2>/dev/null; then
  defaults write "$UA" differentiateWithoutColor -bool true   # Differentiate without colour: on
  defaults write "$UA" reduceMotion -bool true                # Motion > Reduce motion: on
  defaults write "$UA" increaseContrast -bool false           # Increase contrast: off
  defaults write "$UA" showWindowTitlebarIcons -bool false    # Show window title icons: off
  ok "Reduce transparency/motion, differentiate without colour set"
else
  warn "Cannot write $UA: your terminal needs Full Disk Access."
  warn "Grant it in System Settings > Privacy & Security > Full Disk Access,"
  warn "add your terminal app, restart it, then re-run ./install.sh."
fi
