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
OMACOS_STATE_DIR="${OMACOS_STATE_DIR:-${OMACOS_HOME:-$HOME}/.config/omacos}"
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

plan_configs() {
  local home="${OMACOS_HOME:-$HOME}"

  local -a targets=(
    "$home/.config/aerospace/aerospace.toml"
    "$home/.config/ghostty/config"
    "$home/.tmux.conf"
    "$home/.config/nvim"
  )
  local -a sources=(
    "$OMACOS_ROOT/config/aerospace.toml"
    "$OMACOS_ROOT/config/ghostty.config"
    "$OMACOS_ROOT/config/tmux.conf"
    "$OMACOS_ROOT/config/nvim"
  )

  local i target src link_dest newest_bak
  for ((i = 0; i < ${#targets[@]}; i++)); do
    target="${targets[$i]}"
    src="${sources[$i]}"
    if [[ -L "$target" ]]; then
      link_dest="$(readlink "$target")"
      if [[ "$link_dest" == "${OMACOS_ROOT}/"* ]]; then
        note "remove repo-owned symlink: $target"
      else
        note "skip (symlink not owned by OmacOS): $target"
      fi
    elif [[ -e "$target" ]]; then
      newest_bak="$(find "$(dirname "$target")" -maxdepth 1 \
        -name "$(basename "$target").bak*" 2>/dev/null | sort -r | head -1)"
      if [[ -n "$newest_bak" ]]; then
        note "remove $target, restore newest backup $newest_bak"
      elif cmp -s "$target" "$src" 2>/dev/null; then
        note "remove copied config (matches repo): $target"
      else
        warn "leave user-modified file untouched: $target"
      fi
    else
      note "already absent: $target"
    fi
  done

  # Managed shell blocks
  local shell_file
  for shell_file in "$home/.zshenv" "$home/.zshrc"; do
    if grep -qF '# >>> omacos >>>' "$shell_file" 2>/dev/null; then
      note "strip omacos managed block from $shell_file"
    else
      note "no omacos block in $shell_file"
    fi
  done

  # Generated starship config
  local sp="$home/.config/starship.toml"
  local sp_bak
  sp_bak="$(find "$(dirname "$sp")" -maxdepth 1 \
    -name "$(basename "$sp").bak*" 2>/dev/null | sort -r | head -1)" || sp_bak=""
  if [[ -n "$sp_bak" ]]; then
    note "restore starship.toml from $sp_bak"
  elif [[ -f "$sp" ]]; then
    warn "remove generated starship.toml (warn: not a symlink)"
  else
    note "starship.toml absent"
  fi
}

apply_configs() {
  local home="${OMACOS_HOME:-$HOME}"

  local -a targets=(
    "$home/.config/aerospace/aerospace.toml"
    "$home/.config/ghostty/config"
    "$home/.tmux.conf"
    "$home/.config/nvim"
  )
  local -a sources=(
    "$OMACOS_ROOT/config/aerospace.toml"
    "$OMACOS_ROOT/config/ghostty.config"
    "$OMACOS_ROOT/config/tmux.conf"
    "$OMACOS_ROOT/config/nvim"
  )

  local i target src link_dest newest_bak
  for ((i = 0; i < ${#targets[@]}; i++)); do
    target="${targets[$i]}"
    src="${sources[$i]}"
    if [[ -L "$target" ]]; then
      link_dest="$(readlink "$target")"
      if [[ "$link_dest" == "${OMACOS_ROOT}/"* ]]; then
        rm -f "$target"
        ok "Removed repo-owned symlink: $target"
      else
        note "Skipping symlink not owned by OmacOS: $target"
      fi
    elif [[ -e "$target" ]]; then
      newest_bak="$(find "$(dirname "$target")" -maxdepth 1 \
        -name "$(basename "$target").bak*" 2>/dev/null | sort -r | head -1)"
      if [[ -n "$newest_bak" ]]; then
        mv "$newest_bak" "$target"
        ok "Restored $target from $newest_bak"
      elif cmp -s "$target" "$src" 2>/dev/null; then
        rm -f "$target"
        ok "Removed copied config (matched repo): $target"
      else
        warn "Leaving user-modified file untouched: $target"
      fi
    else
      note "Already absent: $target"
    fi
  done

  # Strip managed shell blocks
  local shell_file
  for shell_file in "$home/.zshenv" "$home/.zshrc"; do
    if grep -qF '# >>> omacos >>>' "$shell_file" 2>/dev/null; then
      managed_block_strip "$shell_file" '# >>> omacos >>>' '# <<< omacos <<<'
      ok "Stripped OmacOS managed block from $shell_file"
    else
      note "No OmacOS block in $shell_file"
    fi
  done

  # Starship config: restore backup or remove generated file
  local sp="$home/.config/starship.toml"
  local sp_bak
  sp_bak="$(find "$(dirname "$sp")" -maxdepth 1 \
    -name "$(basename "$sp").bak*" 2>/dev/null | sort -r | head -1)" || sp_bak=""
  if [[ -n "$sp_bak" ]]; then
    mv "$sp_bak" "$sp"
    ok "Restored starship.toml from $sp_bak"
  elif [[ -f "$sp" ]]; then
    warn "Removing generated starship.toml (no backup found)"
    rm -f "$sp"
  else
    note "starship.toml absent, nothing to do"
  fi
}

plan_state() {
  local home="${OMACOS_HOME:-$HOME}"
  local state_dir="${OMACOS_STATE_DIR:-$home/.config/omacos}"

  local -a targets=(
    "$state_dir"
    "$home/.config/ghostty/theme.conf"
    "$home/.config/tmux/theme.conf"
    "$home/.config/nvim/theme.lua"
  )

  local t
  for t in "${targets[@]}"; do
    if [[ -e "$t" || -L "$t" ]]; then
      note "remove: $t"
    else
      note "already absent: $t"
    fi
  done
}

apply_state() {
  local home="${OMACOS_HOME:-$HOME}"
  local state_dir="${OMACOS_STATE_DIR:-$home/.config/omacos}"

  rm -rf "$state_dir"
  ok "Removed state directory: $state_dir"

  local overlay
  for overlay in \
    "$home/.config/ghostty/theme.conf" \
    "$home/.config/tmux/theme.conf" \
    "$home/.config/nvim/theme.lua"; do
    rm -f "$overlay"
    ok "Removed theme overlay (if present): $overlay"
  done
}

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

  local tiers=(security configs)
  [[ "$do_defaults" == 1 ]] && tiers+=(defaults)
  [[ "$do_packages" == 1 ]] && tiers+=(packages)
  tiers+=(state) # state runs last: it removes baseline/, which --defaults/--packages consume first

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
