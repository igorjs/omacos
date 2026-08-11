#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0
#
# tests/menu.bats — unit tests for lib/menu.sh helper functions.
#
# lib/menu.sh has a dispatch guard so sourcing it is safe (no side effects).

setup() {
  TEST_HOME="$(mktemp -d)"
  REPO="$BATS_TEST_DIRNAME/.."
  export HOME="$TEST_HOME"
  export OMACOS_ROOT="$REPO"
  mkdir -p "$HOME/.config/omacos"
  # shellcheck source=lib/menu.sh
  source "$REPO/lib/menu.sh"
}

teardown() {
  rm -rf "$TEST_HOME"
}

# ---------------------------------------------------------------------------
# 1. menu.json validity
# ---------------------------------------------------------------------------

@test "menu.json parses as valid JSON" {
  run jq . "$REPO/lib/menu.json"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# 2. menu.json static actions reference known omacos verbs
# ---------------------------------------------------------------------------

@test "menu.json static actions reference known omacos verbs" {
  run bash -c "jq -r '.items[] | .action // empty' '$REPO/lib/menu.json'"
  [ "$status" -eq 0 ]
  while IFS= read -r action; do
    [[ -z "$action" ]] && continue
    if [[ "$action" != "__quit__" ]]; then
      [[ "$action" == omacos\ * ]]
    fi
  done <<<"$output"
}

# ---------------------------------------------------------------------------
# 3. menu_provider_themes marks active theme with checkmark
# ---------------------------------------------------------------------------

@test "menu_provider_themes marks active theme with checkmark" {
  # Use a sandboxed OMACOS_ROOT so theme dirs don't leak into the real repo.
  local FAKE_ROOT
  FAKE_ROOT="$(mktemp -d)"
  mkdir -p "$FAKE_ROOT/themes/tokyonight" "$FAKE_ROOT/themes/nord"
  echo "tokyonight" >"$HOME/.config/omacos/current_theme"

  OMACOS_ROOT="$FAKE_ROOT" run menu_provider_themes "tokyonight"

  [ "$status" -eq 0 ]
  [[ "$output" == *"tokyonight  ✓"* ]]
  [[ "$output" == *"nord"* ]]
  [[ "$output" != *"nord  ✓"* ]]
  rm -rf "$FAKE_ROOT"
}

# ---------------------------------------------------------------------------
# 4. menu_provider_themes — inactive theme has no checkmark
# ---------------------------------------------------------------------------

@test "menu_provider_themes unlisted theme has no checkmark" {
  local FAKE_ROOT
  FAKE_ROOT="$(mktemp -d)"
  mkdir -p "$FAKE_ROOT/themes/tokyonight"
  OMACOS_ROOT="$FAKE_ROOT" run menu_provider_themes "nord"
  [ "$status" -eq 0 ]
  [[ "$output" != *"tokyonight  ✓"* ]]
  rm -rf "$FAKE_ROOT"
}

# ---------------------------------------------------------------------------
# 5. menu_node_provider resolves theme provider
# ---------------------------------------------------------------------------

@test "menu_node_provider returns provider for theme item" {
  run menu_node_provider "theme"
  [ "$status" -eq 0 ]
  [ "$output" = "themes" ]
}

# ---------------------------------------------------------------------------
# 6. menu_node_provider returns empty for action-only item
# ---------------------------------------------------------------------------

@test "menu_node_provider returns empty for action-only item" {
  run menu_node_provider "update"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ---------------------------------------------------------------------------
# 7. menu_dispatch at root dispatches action command
# ---------------------------------------------------------------------------

@test "menu_dispatch at root dispatches action command" {
  run bash -c "
    source '$REPO/lib/menu.sh'
    function omacos() { echo \"called:\$*\"; }
    export -f omacos
    menu_dispatch '' '󰚰 Update'
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"called:update"* ]]
}

# ---------------------------------------------------------------------------
# 8. menu_dispatch __quit__ returns 130
# ---------------------------------------------------------------------------

@test "menu_dispatch __quit__ returns 130" {
  run bash -c "
    source '$REPO/lib/menu.sh'
    menu_dispatch '' '󰗼 Quit'
  "
  [ "$status" -eq 130 ]
}

# ---------------------------------------------------------------------------
# 9. menu_items at root lists all items with icons
# ---------------------------------------------------------------------------

@test "menu_items at root lists all items with icons" {
  run menu_items ""
  [ "$status" -eq 0 ]
  [[ "$output" == *"Theme"* ]]
  [[ "$output" == *"Update"* ]]
  [[ "$output" == *"Doctor"* ]]
  [[ "$output" == *"Wallpaper"* ]]
  [[ "$output" == *"Quit"* ]]
}

# ---------------------------------------------------------------------------
# 10. omacos help prints usage (bin/omacos dispatch integration)
# ---------------------------------------------------------------------------

@test "omacos help prints usage" {
  # Arrange: source bin/omacos in a subshell (dispatch guard prevents execution)
  run bash -c "
    export HOME='$TEST_HOME'
    export OMACOS_ROOT='$REPO'
    mkdir -p '$TEST_HOME/.config/omacos'
    source '$REPO/bin/omacos'
    usage
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"omacos"* ]]
  [[ "$output" == *"theme"* ]]
}

# ---------------------------------------------------------------------------
# 11. bare omacos with gum absent falls back to usage (exit 0)
# ---------------------------------------------------------------------------

@test "cmd_menu falls back to usage when gum is absent" {
  run bash -c "
    export HOME='$TEST_HOME'
    export OMACOS_ROOT='$REPO'
    mkdir -p '$TEST_HOME/.config/omacos'
    source '$REPO/bin/omacos'
    # Shadow gum to make it look absent
    function command() {
      if [[ \"\$*\" == *'gum'* ]]; then return 1; fi
      builtin command \"\$@\"
    }
    export -f command
    cmd_menu
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"omacos"* ]]
}
