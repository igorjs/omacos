#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# Language runtimes via mise + Python packaging via uv.
# mise and uv come from the Brewfile. This script sets the global defaults.
# Per-project overrides go in `.mise.toml`. Rust is managed by mise, which
# drives rustup under the hood, so the standard Rust ecosystem still works.
#
# Hard rule: NEVER `brew install node/python/go/rust`. They come from mise.
#
set -euo pipefail

# shellcheck source=lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"

command -v mise >/dev/null 2>&1 || {
  warn "mise not on PATH; brew bundle should install it"
  exit 1
}

# Activate mise for this script so `mise use` writes through to its config.
eval "$(mise activate bash --shims 2>/dev/null || true)"
export PATH="$HOME/.local/share/mise/shims:$PATH"

# Pre-trust the omacos repo itself so users don't hit the "not trusted" error
# when they cd into the repo. The .mise.toml here is a documented sample but
# mise still tries to activate it when cwd matches.
OMACOS_ROOT="${OMACOS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
if [[ -f "$OMACOS_ROOT/.mise.toml" ]]; then
  mise trust "$OMACOS_ROOT" >/dev/null 2>&1 &&
    ok "mise: trusted $OMACOS_ROOT/.mise.toml"
fi

# --- Set Rust components BEFORE installing the toolchain ------------------
# mise applies components only at initial toolchain install. Setting them
# afterward is a no-op (use `rustup component add` to extend later).
mise settings set rust.components "rustfmt,clippy,rust-analyzer,rust-src" 2>/dev/null || true
ok "Rust components set: rustfmt, clippy, rust-analyzer, rust-src"

# --- Install + pin global runtimes (concrete versions for reproducibility) ---
# Bump these intentionally when upgrading; avoid floating aliases (lts/latest/stable)
# so installs are reproducible across machines. Keep .mise.toml sample in sync.
declare -a tools=(
  "node@24"
  "python@3.14"
  "go@1.26"
  "rust@1.96"
)

for t in "${tools[@]}"; do
  info "mise use -g $t"
  mise use -g "$t" || warn "mise use -g $t failed; continuing"
done

# --- Verify ---------------------------------------------------------------
info "Resolved versions:"
mise current 2>/dev/null || true

note "Add rust components/targets later with 'rustup component add <name>' or 'rustup target add <triple>'."
note "rust-toolchain.toml in a project takes precedence over mise's rust version."
