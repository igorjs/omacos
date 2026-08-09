#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0
#
# tests/theme_parity.bats — data-driven parity guard: every themes/<name>/ must
# ship the 6 app-level target files with valid content.

setup() {
  REPO="$BATS_TEST_DIRNAME/.."
  export OMACOS_ROOT="$REPO"
}

@test "theme_parity: each theme ships all required app-level files" {
  for d in "$OMACOS_ROOT/themes"/*/; do
    [[ -d "$d" ]] || continue
    name="$(basename "$d")"
    for f in ghostty.conf tmux.conf starship.toml zsh.zsh nvim.lua zed.json; do
      [[ -f "$d/$f" ]] || { echo "MISSING: $name/$f"; false; }
    done
  done
}

@test "theme_parity: each theme ships a valid wallpaper.jpg" {
  for d in "$OMACOS_ROOT/themes"/*/; do
    [[ -d "$d" ]] || continue
    name="$(basename "$d")"
    wp="$d/wallpaper.jpg"
    [[ -s "$wp" ]] || { echo "MISSING or empty: $name/wallpaper.jpg"; false; }
    file --brief "$wp" | grep -qi jpeg || { echo "NOT A JPEG: $name/wallpaper.jpg"; false; }
  done
}

@test "theme_parity: each zed.json has a non-empty theme key" {
  for d in "$OMACOS_ROOT/themes"/*/; do
    [[ -d "$d" ]] || continue
    name="$(basename "$d")"
    local theme_val
    theme_val="$(jq -r '.theme // empty' "$d/zed.json" 2>/dev/null || true)"
    [[ -n "$theme_val" ]] || { echo "EMPTY theme key: $name/zed.json"; false; }
  done
}

@test "theme_parity: each nvim.lua references a colorscheme" {
  for d in "$OMACOS_ROOT/themes"/*/; do
    [[ -d "$d" ]] || continue
    name="$(basename "$d")"
    grep -q 'colorscheme' "$d/nvim.lua" || { echo "NO colorscheme in: $name/nvim.lua"; false; }
  done
}

@test "theme_parity: nvim.lua colorscheme name is provisioned in init.lua" {
  for d in "$OMACOS_ROOT/themes"/*/; do
    [[ -d "$d" ]] || continue
    name="$(basename "$d")"
    local cs_name
    cs_name="$(grep -oE 'colorscheme\("([^"]+)"\)' "$d/nvim.lua" | head -1 | grep -oE '"[^"]+"' | tr -d '"')"
    if [[ -z "$cs_name" ]]; then
      cs_name="$(grep -oE 'colorscheme [a-z0-9_-]+' "$d/nvim.lua" | head -1 | awk '{print $2}')"
    fi
    [[ -n "$cs_name" ]] || { echo "Cannot extract colorscheme name from $name/nvim.lua"; false; }
    grep -q "$cs_name" "$OMACOS_ROOT/config/nvim/init.lua" || {
      echo "Colorscheme '$cs_name' (from $name/nvim.lua) not found in config/nvim/init.lua"
      false
    }
  done
}

@test "theme_parity: tokyonight passes all parity checks" {
  local d="$OMACOS_ROOT/themes/tokyonight"
  [[ -d "$d" ]] || skip "tokyonight dir missing"
  for f in ghostty.conf tmux.conf starship.toml zsh.zsh nvim.lua zed.json; do
    [[ -f "$d/$f" ]] || { echo "MISSING: tokyonight/$f"; false; }
  done
  theme_val="$(jq -r '.theme // empty' "$d/zed.json")"
  [[ -n "$theme_val" ]]
  grep -q 'colorscheme' "$d/nvim.lua"
}

@test "theme_parity: a theme missing zsh.zsh fails parity" {
  local tmptheme
  tmptheme="$(mktemp -d)/fake-theme"
  mkdir -p "$tmptheme"
  touch "$tmptheme/ghostty.conf" "$tmptheme/tmux.conf" "$tmptheme/starship.toml"
  touch "$tmptheme/nvim.lua" "$tmptheme/zed.json"
  # Intentionally omit zsh.zsh

  run bash -c "[[ -f '$tmptheme/zsh.zsh' ]] || { echo 'MISSING: zsh.zsh'; false; }"
  [ "$status" -ne 0 ]
  [[ "$output" == *"MISSING"* ]]

  rm -rf "$tmptheme"
}
