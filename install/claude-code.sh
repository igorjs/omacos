#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# Install Claude Code via Anthropic's native installer (NOT Homebrew).
# Reason: the native binary auto-updates and has zero dependencies; the
# Homebrew cask lags behind releases.
#
# Requires a paid Anthropic plan or API key to use after install.
#
set -euo pipefail

# shellcheck source=lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"

if command -v claude >/dev/null 2>&1; then
  ok "Claude Code already installed at $(command -v claude)"
  exit 0
fi

info "Installing Claude Code via native installer"
curl -fsSL https://claude.ai/install.sh | bash

if command -v claude >/dev/null 2>&1; then
  ok "Claude Code installed: $(command -v claude)"
else
  ok "Installed. You may need to open a new shell for 'claude' to be on PATH."
fi

note "Sign in with a paid Anthropic plan or set ANTHROPIC_API_KEY before first use."
