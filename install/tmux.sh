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

# shellcheck source=lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"

if ! command -v tmux >/dev/null 2>&1; then
  warn "tmux is not installed — skipping TPM setup. Re-run after 'brew bundle'."
  exit 0
fi

TPM_DIR="$HOME/.tmux/plugins/tpm"

# --- 1. TPM -----------------------------------------------------------------
if [[ -d "$TPM_DIR/.git" ]]; then
  ok "TPM already cloned at $TPM_DIR"
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

# --- 3. Pin ------------------------------------------------------------------
# Plugins run unreviewed code inside every shell session. Check out fixed
# commits so a fresh install or prefix + U cannot pull in a new upstream head.
# To upgrade, review the upstream diff and change the SHA here.
PINNED_PLUGINS=(
  "tpm e261deb1b47614eed3400089ce7197dc68acc4eb"
  "tmux-resurrect cff343cf9e81983d3da0c8562b01616f12e8d548"
  "tmux-continuum 0698e8f4b17d6454c71bf5212895ec055c578da0"
)
for entry in "${PINNED_PLUGINS[@]}"; do
  read -r plugin sha <<<"$entry"
  plugin_dir="$HOME/.tmux/plugins/$plugin"
  [[ -d "$plugin_dir/.git" ]] || continue
  if git -C "$plugin_dir" cat-file -e "$sha^{commit}" 2>/dev/null ||
    git -C "$plugin_dir" fetch --quiet origin "$sha" 2>/dev/null; then
    git -C "$plugin_dir" checkout --quiet --detach "$sha"
    ok "$plugin pinned at ${sha:0:7}"
  else
    warn "Could not fetch $plugin at $sha (left unpinned)"
  fi
done

note "In a running tmux session, hit  prefix + I  to install new plugins. Plugins are pinned, so  prefix + U  does not upgrade them."
note "Hit  prefix + Ctrl-s  to manually save state,  prefix + Ctrl-r  to restore."
