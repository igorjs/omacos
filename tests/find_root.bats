#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0
#
# tests/find_root.bats — unit tests for find_root() in bin/omacos
#
# Sourcing bin/omacos runs OMACOS_ROOT="$(find_root)" and mkdir -p "$STATE_DIR"
# at the top level (outside the dispatch guard).  We satisfy those by:
#   1. Pre-setting OMACOS_ROOT so the source-time find_root call returns early.
#   2. Pointing HOME into $TEST_HOME so mkdir -p stays in the fixture.
#   3. Running each case in a bash -c subshell for full env isolation.
#
# For tests that need the env-var path to FAIL (state-file and all-fail cases)
# we build a "fake root" tree:
#   $TEST_HOME/fake_root/bin/omacos   — copy of the real bin/omacos
#   $TEST_HOME/fake_root/lib          — symlink to $REPO/lib
# This lets the copy source "../lib/common.sh" correctly while keeping
# BASH_SOURCE[0] pointing away from the real repo, so "fake_root/themes/"
# doesn't exist and the self-relative fallback fails.

setup() {
  TEST_HOME="$(mktemp -d)"
  REPO="$BATS_TEST_DIRNAME/.."
}

teardown() {
  rm -rf "$TEST_HOME"
}

# ── helpers ──────────────────────────────────────────────────────────────────

_make_fake_root() {
  mkdir -p "$TEST_HOME/fake_root/bin"
  # symlink lib so "../lib/common.sh" resolves correctly from fake_root/bin/
  ln -sf "$REPO/lib" "$TEST_HOME/fake_root/lib"
  cp "$REPO/bin/omacos" "$TEST_HOME/fake_root/bin/omacos"
}

# ── tests ────────────────────────────────────────────────────────────────────

@test "find_root: OMACOS_ROOT env var pointing to valid dir → prints that dir" {
  local valid_dir="$TEST_HOME/myrepo"
  mkdir -p "$valid_dir"

  run bash -c "
    export OMACOS_ROOT=\"$valid_dir\"
    export HOME=\"$TEST_HOME\"
    mkdir -p \"\$HOME/.config/omacos\"
    source \"$REPO/bin/omacos\"
    find_root
  "
  [ "$status" -eq 0 ]
  [ "$output" = "$valid_dir" ]
}

@test "find_root: state file \$HOME/.config/omacos/root contains valid dir → prints it" {
  local valid_dir="$TEST_HOME/myrepo"
  mkdir -p "$valid_dir"
  mkdir -p "$TEST_HOME/.config/omacos"
  printf '%s\n' "$valid_dir" >"$TEST_HOME/.config/omacos/root"

  _make_fake_root

  run bash -c "
    export HOME=\"$TEST_HOME\"
    # Pre-set so the source-time top-level find_root call succeeds.
    export OMACOS_ROOT=\"$valid_dir\"
    source \"$TEST_HOME/fake_root/bin/omacos\"
    # Now test the state-file path by unsetting OMACOS_ROOT.
    unset OMACOS_ROOT
    find_root
  "
  [ "$status" -eq 0 ]
  [ "$output" = "$valid_dir" ]
}

@test "find_root: all paths fail → exits 1 and emits error message" {
  # OMACOS_ROOT unset, no state file, fake_root has no themes/ → exit 1.
  _make_fake_root
  local preinit_dir="$TEST_HOME/preinit"
  mkdir -p "$preinit_dir"

  run bash -c "
    export HOME=\"$TEST_HOME\"
    mkdir -p \"\$HOME/.config/omacos\"
    # No root file in state dir.
    export OMACOS_ROOT=\"$preinit_dir\"
    source \"$TEST_HOME/fake_root/bin/omacos\"
    unset OMACOS_ROOT
    find_root
  "
  # find_root exits 1; fail() writes to stdout (no >&2 in common.sh).
  [ "$status" -eq 1 ]
  [[ "$output" == *"locate"* ]] || [[ "$output" == *"Cannot"* ]] || [[ "$output" == *"OMACOS_ROOT"* ]]
}
