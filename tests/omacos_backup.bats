#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0
#
# tests/omacos_backup.bats — unit tests for omacos_backup() in lib/common.sh

setup() {
  TEST_HOME="$(mktemp -d)"
  REPO="$BATS_TEST_DIRNAME/.."
  # shellcheck source=lib/common.sh
  source "$REPO/lib/common.sh"
}

teardown() {
  rm -rf "$TEST_HOME"
}

@test "omacos_backup: absent target returns 0 and no .bak created" {
  run omacos_backup "$TEST_HOME/nonexistent_file"
  [ "$status" -eq 0 ]
  [ ! -e "$TEST_HOME/nonexistent_file.bak" ]
}

@test "omacos_backup: plain file creates byte-identical .bak" {
  printf 'hello world\n' >"$TEST_HOME/myfile"
  omacos_backup "$TEST_HOME/myfile"
  [ -f "$TEST_HOME/myfile.bak" ]
  run cmp -s "$TEST_HOME/myfile" "$TEST_HOME/myfile.bak"
  [ "$status" -eq 0 ]
}

@test "omacos_backup: symlink matching expected link returns 0 and no .bak" {
  local target="$TEST_HOME/real_file"
  local link="$TEST_HOME/mylink"
  printf 'content\n' >"$target"
  ln -s "$target" "$link"
  run omacos_backup "$link" "$target"
  [ "$status" -eq 0 ]
  [ ! -e "$link.bak" ]
}

@test "omacos_backup: symlink not matching expected creates .bak (cp -P)" {
  local target1="$TEST_HOME/real_file1"
  local target2="$TEST_HOME/real_file2"
  local link="$TEST_HOME/mylink"
  printf 'content1\n' >"$target1"
  printf 'content2\n' >"$target2"
  ln -s "$target1" "$link"
  # expected is target2 but link points to target1 → mismatch → .bak
  omacos_backup "$link" "$target2"
  [ -L "$link.bak" ]
}

@test "omacos_backup: running twice on a plain file leaves exactly one .bak" {
  printf 'data\n' >"$TEST_HOME/myfile"
  omacos_backup "$TEST_HOME/myfile"
  omacos_backup "$TEST_HOME/myfile"
  local count
  count="$(find "$TEST_HOME" -maxdepth 1 -name "myfile.bak" | wc -l | tr -d ' ')"
  [ "$count" -eq 1 ]
}
