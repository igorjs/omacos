#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# OmacOS uninstaller — reverts what install.sh and `omacos` apply.
# Dispatched by `omacos uninstall`; also runnable directly.
#
# Each tier is split into a pure planner (plan_<tier> — prints the intended
# actions to stdout, no side effects) and an applier (apply_<tier> — executes).
# --dry-run prints the plans for every selected tier and changes nothing.
#
# Tiers:
#   security  (default)            re-enable SSH / Remote Apple Events, restore
#                                  /etc/hosts, re-enable weatherd/newsd
#   configs   (default)            remove repo-owned symlinks/copies, strip the
#                                  managed shell blocks, restore starship.toml
#   state     (default)            remove ~/.config/omacos + generated overlays
#   defaults  (--defaults/--all)   whole-domain `defaults import` from baseline
#   packages  (--packages/--all)   brew rm OmacOS-added formulae/casks
#
# Usage:
#   install/uninstall.sh [--all] [--defaults] [--packages] [--dry-run]
#
# Sourcing this file (e.g. from bats) defines the functions and runs nothing.
#
set -euo pipefail

# shellcheck source=lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"

# --- Injected inputs (overridable in tests) ---------------------------------
OMACOS_ROOT="${OMACOS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
OMACOS_STATE_DIR="${OMACOS_STATE_DIR:-$HOME/.config/omacos}"
OMACOS_BASELINE_DIR="${OMACOS_BASELINE_DIR:-$OMACOS_STATE_DIR/baseline}"

# --- Confirm gate: proceed only on an exact "YES" ---------------------------
confirm_or_abort() {
  local prompt="${1:-Type YES to proceed: }" reply
  printf '%b' "${RED} !! ${RESET}${prompt}"
  read -r reply || true
  if [[ "$reply" != "YES" ]]; then
    info "Aborted — no changes made."
    exit 1
  fi
}

# --- Tier planners + appliers (bodies filled by WU-24..28) ------------------
plan_security() { note "TODO(WU-24): re-enable SSH/RAE, restore /etc/hosts, re-enable daemons"; }
apply_security() { note "TODO(WU-24): apply security tier"; }

plan_configs() { note "TODO(WU-25): remove repo-owned configs, strip managed blocks"; }
apply_configs() { note "TODO(WU-25): apply configs tier"; }

plan_state() { note "TODO(WU-26): remove ~/.config/omacos and theme overlays"; }
apply_state() { note "TODO(WU-26): apply state tier"; }

plan_defaults() { note "TODO(WU-27): defaults import from baseline (whole-domain)"; }
apply_defaults() { note "TODO(WU-27): apply defaults tier"; }

plan_packages() { note "TODO(WU-28): brew rm OmacOS-added packages"; }
apply_packages() { note "TODO(WU-28): apply packages tier"; }

# --- Usage ------------------------------------------------------------------
uninstall_usage() {
  cat <<'USAGE'
omacos uninstall — revert OmacOS changes

  (default)     run the security, configs, and state tiers
  --defaults    also restore macOS defaults from the pre-install baseline
                (WHOLE-DOMAIN import — reverts unrelated changes to those domains)
  --packages    also brew rm packages OmacOS added (never pre-existing ones)
  --all         --defaults and --packages
  --dry-run     print the plan for every selected tier; change nothing
  -h, --help    show this help
USAGE
}

# --- Orchestration ----------------------------------------------------------
run_uninstall() {
  local dry_run=0 do_defaults=0 do_packages=0
  for arg in "$@"; do
    case "$arg" in
      --dry-run) dry_run=1 ;;
      --defaults) do_defaults=1 ;;
      --packages) do_packages=1 ;;
      --all)
        do_defaults=1
        do_packages=1
        ;;
      -h | --help)
        uninstall_usage
        return 0
        ;;
      *)
        warn "Unknown option: $arg"
        uninstall_usage
        return 2
        ;;
    esac
  done

  local tiers=(security configs state)
  [[ "$do_defaults" == 1 ]] && tiers+=(defaults)
  [[ "$do_packages" == 1 ]] && tiers+=(packages)

  if [[ "$dry_run" == 1 ]]; then
    info "Dry run — no changes will be made. Planned tiers: ${tiers[*]}"
    for t in "${tiers[@]}"; do
      info "── plan: $t"
      "plan_$t"
    done
    return 0
  fi

  warn "OmacOS uninstall will revert the following tiers: ${tiers[*]}"
  for t in "${tiers[@]}"; do
    info "── plan: $t"
    "plan_$t"
  done
  confirm_or_abort "Type YES to apply the above and revert OmacOS: "
  for t in "${tiers[@]}"; do
    info "── apply: $t"
    "apply_$t"
  done
  ok "OmacOS uninstall complete (tiers: ${tiers[*]})."
}

# --- Dispatch guard: run only when executed, not when sourced ---------------
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  run_uninstall "$@"
fi
