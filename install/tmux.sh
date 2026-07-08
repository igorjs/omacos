#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# Install TPM (Tmux Plugin Manager) and bootstrap the plugins listed in
# config/tmux.conf (resurrect + continuum for session save/restore).
#
# Idempotent: re-running clones nothing if TPM is already present and
# re-installs any missing plugins.
#
set -euo pipefail

# --- Tokyo Night colors ------------------------------------------------------
BLUE='\033[38;2;122;162;247m'
GREEN='\033[38;2;158;206;106m'
PURPLE='\033[38;2;187;154;247m'
RED='\033[38;2;247;118;142m'
RESET='\033[0m'
info() { printf "${BLUE}==>${RESET} %s\n" "$1"; }
ok() { printf "${GREEN} ok${RESET} %s\n" "$1"; }
note() { printf "${PURPLE} -- ${RESET}%s\n" "$1"; }
warn() { printf "${RED} !! ${RESET}%s\n" "$1"; }

if ! command -v tmux >/dev/null 2>&1; then
  warn "tmux is not installed — skipping TPM setup. Re-run after 'brew bundle'."
  exit 0
fi

TPM_DIR="$HOME/.tmux/plugins/tpm"

# --- 1. TPM -----------------------------------------------------------------
if [[ -d "$TPM_DIR/.git" ]]; then
  info "TPM already cloned at $TPM_DIR — pulling latest"
  git -C "$TPM_DIR" pull --quiet --ff-only 2>/dev/null ||
    warn "Could not pull TPM updates (continuing with existing version)"
  ok "TPM ready"
else
  info "Cloning TPM into $TPM_DIR"
  mkdir -p "$HOME/.tmux/plugins"
  git clone --quiet --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
  ok "TPM cloned"
fi

# --- 2. Plugins -------------------------------------------------------------
# TPM ships an install_plugins.sh script that reads ~/.tmux.conf and clones any
# @plugin entries not yet present. Safe to run multiple times.
install_script="$TPM_DIR/scripts/install_plugins.sh"
if [[ -x "$install_script" ]]; then
  info "Installing/updating plugins via TPM"
  # install_plugins.sh prefers to talk to a running tmux server but falls back
  # to a one-shot read of ~/.tmux.conf when none is running. Force the fallback
  # so we don't accidentally tamper with an active session.
  TMUX="" "$install_script" >/dev/null 2>&1 ||
    warn "TPM install script returned non-zero (some plugins may not have installed)"
  ok "Plugins installed"
else
  warn "TPM install_plugins.sh not found at $install_script"
fi

note "In a running tmux session, hit  prefix + I  to re-install / refresh plugins."
note "Hit  prefix + Ctrl-s  to manually save state,  prefix + Ctrl-r  to restore."
