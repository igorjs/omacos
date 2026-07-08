# shellcheck shell=bash
# SPDX-License-Identifier: Apache-2.0
#
# lib/common.sh — shared helpers for all OmacOS scripts. Source this file;
# do not execute it directly. Side-effect-free: sourcing produces no output.
#
# Source from any script:
#   # shellcheck source=lib/common.sh
#   source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"
#   (adjust the relative path per the sourcing script's depth)
#

[[ -n "${_OMACOS_COMMON_SOURCED:-}" ]] && return 0
_OMACOS_COMMON_SOURCED=1

# --- Tokyo Night palette -----------------------------------------------------

BLUE='\033[38;2;122;162;247m'
GREEN='\033[38;2;158;206;106m'
PURPLE='\033[38;2;187;154;247m'
RED='\033[38;2;247;118;142m'
# shellcheck disable=SC2034
DIM='\033[38;2;86;95;137m'
# shellcheck disable=SC2034
BOLD='\033[1m'
RESET='\033[0m'

# --- Output helpers ----------------------------------------------------------

info() { printf '%b\n' "${BLUE}==> ${RESET}$1"; }
ok() { printf '%b\n' "${GREEN} ok ${RESET}$1"; }
warn() { printf '%b\n' "${RED} !! ${RESET}$1"; }
note() { printf '%b\n' "${PURPLE} -- ${RESET}$1"; }
fail() { printf '%b\n' "${RED} !! ${RESET}$1"; }

# --- Pure helper functions ---------------------------------------------------

omacos_backup() {
  local target="$1" expected="${2:-}"
  [[ -e "$target" || -L "$target" ]] || return 0
  if [[ -n "$expected" && -L "$target" ]]; then
    local actual
    actual="$(readlink "$target")"
    [[ "$actual" == "$expected" ]] && return 0
  fi
  cp -P "$target" "${target}.bak"
}

managed_block_strip() {
  local file="$1" open="$2" close="$3"
  [[ -f "$file" ]] || return 0
  if grep -qF "$open" "$file"; then
    if ! grep -qF "$close" "$file"; then
      warn "managed_block_strip: half-open marker in $file; leaving unchanged"
      return 1
    fi
    local tmp
    tmp="$(mktemp)"
    awk -v open="$open" -v close="$close" '
      $0 == open { skip=1; next }
      $0 == close { skip=0; next }
      !skip { print }
    ' "$file" >"$tmp"
    mv "$tmp" "$file"
  fi
}

hosts_block_transform() {
  local hosts="$1" open="$2" close="$3" domains="$4"
  awk -v open="$open" -v close="$close" '
    $0 == open { skip=1; next }
    $0 == close { skip=0; next }
    !skip { print }
  ' "$hosts"
  printf '%s\n' "$open"
  while IFS= read -r domain; do
    [[ -z "$domain" || "$domain" == \#* ]] && continue
    printf '0.0.0.0 %s\n' "$domain"
  done <"$domains"
  printf '%s\n' "$close"
}
