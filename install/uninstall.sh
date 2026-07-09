#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# OmacOS uninstaller — removes everything install.sh and omacos apply.
# Called by `omacos uninstall`; can also be run directly.
#
# Tiers (run in reverse of install order):
#   security  — restore /etc/hosts from backup, re-enable SSH, remove mDNS write
#   configs   — unlink or remove symlinked config files
#   state     — remove ~/.config/omacos state directory
#   defaults  — restore macOS defaults from whole-domain snapshots
#   packages  — uninstall Homebrew packages and remove Homebrew itself
#
# All tiers are run by default. To run a single tier:
#   OMACOS_UNINSTALL_TIERS=security install/uninstall.sh
#
# Dry-run mode (shows what would happen, makes no changes):
#   DRY_RUN=1 install/uninstall.sh
#
set -euo pipefail

# shellcheck source=../lib/common.sh
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"

OMACOS_ROOT="${OMACOS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
DRY_RUN="${DRY_RUN:-0}"
TIERS="${OMACOS_UNINSTALL_TIERS:-security configs state defaults packages}"

dry() {
  if [[ "$DRY_RUN" == "1" ]]; then
    note "[dry-run] $*"
    return 0
  fi
  "$@"
}

# ---------------------------------------------------------------------------
# Tier: security
# Restore /etc/hosts from backup and re-enable SSH if it was disabled.
# ---------------------------------------------------------------------------
uninstall_security() {
  info "Tier: security"
  # Restore /etc/hosts — implemented in WU-24
  note "TODO (WU-24): restore /etc/hosts from backup"
  # Re-enable SSH — implemented in WU-24
  note "TODO (WU-24): re-enable Remote Login (SSH)"
}

# ---------------------------------------------------------------------------
# Tier: configs
# Remove symlinks / copies placed by install.sh and omacos theme set.
# ---------------------------------------------------------------------------
uninstall_configs() {
  info "Tier: configs"
  # Implemented in WU-25
  note "TODO (WU-25): remove config symlinks and theme overlays"
}

# ---------------------------------------------------------------------------
# Tier: state
# Remove the ~/.config/omacos state directory.
# ---------------------------------------------------------------------------
uninstall_state() {
  info "Tier: state"
  # Implemented in WU-25
  note "TODO (WU-25): remove ~/.config/omacos"
}

# ---------------------------------------------------------------------------
# Tier: defaults
# Restore macOS defaults from whole-domain snapshots taken before install.
# ---------------------------------------------------------------------------
uninstall_defaults() {
  info "Tier: defaults"
  # Implemented in WU-26
  note "TODO (WU-26): restore defaults from pre-install snapshots"
}

# ---------------------------------------------------------------------------
# Tier: packages
# Uninstall Homebrew packages and, optionally, Homebrew itself.
# ---------------------------------------------------------------------------
uninstall_packages() {
  info "Tier: packages"
  # Implemented in WU-27
  note "TODO (WU-27): brew bundle --force cleanup; offer to remove Homebrew"
}

# ---------------------------------------------------------------------------
# Main dispatch
# ---------------------------------------------------------------------------
warn "OmacOS uninstaller — this will undo what install.sh applied."
if [[ "$DRY_RUN" != "1" ]]; then
  read -r -p "Continue? [y/N] " _confirm
  [[ "${_confirm:-n}" =~ ^[Yy]$ ]] || {
    info "Aborted."
    exit 0
  }
fi

# shellcheck disable=SC2086
# SC2086: intentional word-splitting — TIERS is a space-separated list of tier names
read -r -a _tier_arr <<<"$TIERS"
for _tier in "${_tier_arr[@]}"; do
  case "$_tier" in
    security) uninstall_security ;;
    configs) uninstall_configs ;;
    state) uninstall_state ;;
    defaults) uninstall_defaults ;;
    packages) uninstall_packages ;;
    *) warn "Unknown tier: $_tier; skipping" ;;
  esac
done

ok "OmacOS uninstall complete (tiers: $TIERS)"
