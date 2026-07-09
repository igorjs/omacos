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
HOSTS_FILE="${OMACOS_HOSTS_FILE:-/etc/hosts}"

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
plan_security() {
  local hosts_open="# >>> omacos blocked endpoints >>>"
  local hosts_close="# <<< omacos blocked endpoints <<<"

  note "re-enable Remote Login (SSH): launchctl enable system/com.openssh.sshd"
  note "re-enable Remote Apple Events: launchctl enable system/com.apple.RemoteAppleEventsServer"

  # Determine hosts action without mutating anything (read-only)
  local newest_bak
  newest_bak="$(find "$(dirname "${HOSTS_FILE}")" -maxdepth 1 \
    -name "$(basename "${HOSTS_FILE}").bak.*" 2>/dev/null | sort -r | head -1)"
  if [[ -n "$newest_bak" ]]; then
    note "restore /etc/hosts from newest backup: $newest_bak"
  elif grep -qF "$hosts_open" "$HOSTS_FILE" 2>/dev/null; then
    note "strip omacos blocked-endpoints block from /etc/hosts"
  else
    note "no /etc/hosts changes needed"
  fi

  note "re-enable weatherd/newsd: launchctl enable system/com.apple.weatherd, com.apple.newsd"
  note "reset system.preferences authorization right shared=true (skipped if MDM-managed / no top-level shared key)"
  warn "SSH is re-enabled to Apple's default; this may surprise users who intentionally had SSH disabled before OmacOS. /etc/hosts, launchd overrides, and the authdb right are reset to Apple defaults, not restored to a captured pre-install value."
}

apply_security() {
  local hosts_open="# >>> omacos blocked endpoints >>>"
  local hosts_close="# <<< omacos blocked endpoints <<<"

  # Re-enable Remote Login (SSH)
  sudo launchctl enable system/com.openssh.sshd 2>/dev/null || true
  ok "Remote Login (SSH) re-enabled"

  # Re-enable Remote Apple Events
  sudo launchctl enable system/com.apple.RemoteAppleEventsServer 2>/dev/null || true
  ok "Remote Apple Events re-enabled"

  # Re-enable Weather and News daemons
  sudo launchctl enable system/com.apple.weatherd 2>/dev/null || true
  sudo launchctl enable system/com.apple.newsd 2>/dev/null || true
  ok "weatherd and newsd re-enabled"

  # /etc/hosts: restore from newest backup if present, else strip markers, else no-op
  local newest_bak
  newest_bak="$(find "$(dirname "${HOSTS_FILE}")" -maxdepth 1 \
    -name "$(basename "${HOSTS_FILE}").bak.*" 2>/dev/null | sort -r | head -1)"
  if [[ -n "$newest_bak" ]]; then
    sudo cp "$newest_bak" "$HOSTS_FILE"
    ok "Restored $HOSTS_FILE from $newest_bak"
    sudo dscacheutil -flushcache 2>/dev/null || true
    sudo killall -HUP mDNSResponder 2>/dev/null || true
  elif grep -qF "$hosts_open" "$HOSTS_FILE" 2>/dev/null; then
    local tmp
    tmp="$(mktemp)"
    cp "$HOSTS_FILE" "$tmp"
    managed_block_strip "$tmp" "$hosts_open" "$hosts_close"
    # shellcheck disable=SC2024
    sudo tee "$HOSTS_FILE" <"$tmp" >/dev/null
    rm -f "$tmp"
    ok "Stripped omacos blocked-endpoints block from $HOSTS_FILE"
    sudo dscacheutil -flushcache 2>/dev/null || true
    sudo killall -HUP mDNSResponder 2>/dev/null || true
  else
    note "No $HOSTS_FILE changes needed"
  fi

  # system.preferences authdb right: reset shared=true, guarded against MDM-managed rights
  local sp_plist
  sp_plist="$(mktemp -t omacos.system.preferences)" || sp_plist="/tmp/omacos.system.preferences.plist"
  if security authorizationdb read system.preferences >"$sp_plist" 2>/dev/null; then
    if /usr/libexec/PlistBuddy -c "Print :shared" "$sp_plist" >/dev/null 2>&1; then
      /usr/libexec/PlistBuddy -c "Set :shared true" "$sp_plist" >/dev/null 2>&1
      # shellcheck disable=SC2024
      if sudo security authorizationdb write system.preferences <"$sp_plist" 2>/dev/null; then
        ok "system.preferences authorization right reset to shared=true"
      else
        warn "Could not update system.preferences authorization right"
      fi
    else
      note "system.preferences managed externally (MDM); left as-is"
    fi
  else
    warn "Could not read system.preferences authorization right"
  fi
  rm -f "$sp_plist"
}

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
