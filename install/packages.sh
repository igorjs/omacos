#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# Install everything in the curated Brewfile. Idempotent: `brew bundle` skips
# already-installed packages.
#
set -euo pipefail

# shellcheck source=lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"

OMACOS_ROOT="${OMACOS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
BREWFILE="$OMACOS_ROOT/Brewfile"

if [[ ! -f "$BREWFILE" ]]; then
  warn "No Brewfile at $BREWFILE"
  exit 1
fi

command -v brew >/dev/null 2>&1 || {
  warn "brew not on PATH; run install/homebrew.sh first"
  exit 1
}

info "brew update"
brew update

# Trust OmacOS taps before bundling so brew bundle doesn't skip their casks.
# Homebrew 6.x will require explicit trust for all third-party taps.
info "Trusting OmacOS taps"
brew trust nikitabobko/tap 2>/dev/null || true
ok "Taps trusted"

info "brew bundle --file=$BREWFILE"
brew bundle --file="$BREWFILE"
ok "Packages installed/updated"
