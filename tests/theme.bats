#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0
#
# tests/theme.bats — unit tests for cmd_theme_set / cmd_theme_list in bin/omacos
#
# We pre-set OMACOS_ROOT and HOME before sourcing bin/omacos so the top-level
# OMACOS_ROOT="$(find_root)" and mkdir -p "$STATE_DIR" succeed within fixtures.

setup() {
  TEST_HOME="$(mktemp -d)"
  REPO="$BATS_TEST_DIRNAME/.."
  # Keep STATE_DIR inside TEST_HOME so no writes hit the real $HOME.
  export HOME="$TEST_HOME"
  export OMACOS_ROOT="$REPO"
  mkdir -p "$HOME/.config/omacos"
  # shellcheck source=bin/omacos
  source "$REPO/bin/omacos"
}

teardown() {
  rm -rf "$TEST_HOME"
}

@test "cmd_theme_set nonexistent theme → exit 1" {
  run cmd_theme_set "no_such_theme_xyz"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown theme"* ]] || [[ "$output" == *"no_such_theme"* ]]
}

@test "cmd_theme_set empty name → exit 2" {
  run cmd_theme_set ""
  [ "$status" -eq 2 ]
  [[ "$output" == *"usage"* ]] || [[ "$output" == *"Usage"* ]]
}

@test "cmd_theme_list output includes tokyonight" {
  run cmd_theme_list
  [ "$status" -eq 0 ]
  [[ "$output" == *"tokyonight"* ]]
}
