#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# tools/fetch-wallpapers.sh — regenerate themes/*/wallpaper.jpg from the manifest.
#
# Authoring tool only; not run at install. Requires macOS (sips built-in).
# Each row in tools/wallpapers.manifest is fetched, downscaled with sips to a
# max 3840px side at jpeg quality 82, and written to themes/<theme>/wallpaper.jpg.
#
# Usage: bash tools/fetch-wallpapers.sh
#
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$REPO/tools/wallpapers.manifest"

# shellcheck source=lib/common.sh
source "$REPO/lib/common.sh"

command -v sips >/dev/null 2>&1 || { fail "sips not found (macOS only)"; exit 1; }
command -v curl >/dev/null 2>&1 || { fail "curl not found"; exit 1; }

PASS=0
FAIL=0

while IFS='|' read -r theme url artwork _license; do
  # Skip comments and blank lines.
  [[ "$theme" =~ ^[[:space:]]*# ]] && continue
  [[ -z "$theme" ]] && continue

  theme="$(printf '%s' "$theme" | tr -d '[:space:]')"
  url="$(printf '%s' "$url" | tr -d '[:space:]')"

  # Pause between requests to respect Wikimedia rate limits.
  [[ "${_first_row:-}" == "1" ]] && sleep 3
  _first_row=1

  info "Fetching $theme: $(printf '%s' "$artwork" | xargs)"

  tmp="$(mktemp)"
  # Cleanup tmp on exit from this iteration (use a subshell-safe trap workaround).
  trap 'rm -f "$tmp"' EXIT INT TERM

  if ! curl -fsSL --max-time 120 \
      -H "User-Agent: OmacOS/1.1 (https://github.com/igorjs/omacos; igor@getdigital.com.br)" \
      -o "$tmp" "$url"; then
    fail "  curl failed for $theme ($url)"
    FAIL=$((FAIL + 1))
    rm -f "$tmp"
    trap - EXIT INT TERM
    continue
  fi

  # Verify the downloaded file is an image type sips can handle.
  mime="$(file --mime-type -b "$tmp" 2>/dev/null || true)"
  case "$mime" in
    image/jpeg|image/png|image/tiff|image/gif|image/bmp|image/heic)
      ;;
    *)
      fail "  MIME type '$mime' not supported by sips for $theme"
      FAIL=$((FAIL + 1))
      rm -f "$tmp"
      trap - EXIT INT TERM
      continue
      ;;
  esac

  out="$REPO/themes/$theme/wallpaper.jpg"
  mkdir -p "$(dirname "$out")"

  # Downscale to max 3840px on longest side; convert to JPEG at quality 82.
  if ! sips -Z 2560 -s format jpeg -s formatOptions 82 "$tmp" --out "$out" >/dev/null 2>&1; then
    fail "  sips conversion failed for $theme"
    FAIL=$((FAIL + 1))
    rm -f "$tmp"
    trap - EXIT INT TERM
    continue
  fi

  # Validate the output is a non-empty JPEG.
  if [[ ! -s "$out" ]]; then
    fail "  output is empty for $theme: $out"
    FAIL=$((FAIL + 1))
    rm -f "$tmp"
    trap - EXIT INT TERM
    continue
  fi
  if ! file --brief "$out" | grep -qi jpeg; then
    fail "  output is not a JPEG for $theme: $out"
    FAIL=$((FAIL + 1))
    rm -f "$tmp"
    trap - EXIT INT TERM
    continue
  fi

  size_kb=$(( $(stat -f%z "$out" 2>/dev/null || stat -c%s "$out" 2>/dev/null || echo 0) / 1024 ))
  ok "  $theme -> $out (${size_kb}KB)"
  PASS=$((PASS + 1))
  rm -f "$tmp"
  trap - EXIT INT TERM

done <"$MANIFEST"

printf '\n'
if ((FAIL > 0)); then
  fail "$PASS succeeded, $FAIL failed"
  exit 1
else
  ok "All $PASS wallpapers fetched and validated"
fi
