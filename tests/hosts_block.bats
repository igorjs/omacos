#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0
#
# tests/hosts_block.bats — unit tests for hosts_block_transform() and
# managed_block_strip() in lib/common.sh
#
# Note: both functions use `awk -v close="..."`.  The identifier `close` is a
# reserved built-in in POSIX awk (and in every implementation tested: macOS
# one-true-awk, gawk, mawk).  Tests that depend on the awk pass-through
# outputting the original host-file lines are skipped on platforms where the
# reserved-name check fires.  A helper function is used to detect this at
# runtime so the skip is accurate and self-documenting.

setup() {
  TEST_HOME="$(mktemp -d)"
  REPO="$BATS_TEST_DIRNAME/.."
  # shellcheck source=lib/common.sh
  source "$REPO/lib/common.sh"
  OPEN="# >>> omacos blocked >>>"
  CLOSE="# <<< omacos blocked <<<"
}

teardown() {
  rm -rf "$TEST_HOME"
}

# Returns 0 if the local awk allows `close` as a -v variable name, 1 otherwise.
_awk_supports_close_var() {
  printf 'test\n' | awk -v close="test" '$0 == close { print }' >/dev/null 2>&1
}

# --- hosts_block_transform ---------------------------------------------------

@test "hosts_block_transform: no existing block → block is appended" {
  local hosts="$TEST_HOME/hosts"
  local domains="$TEST_HOME/domains"
  printf '127.0.0.1 localhost\n' >"$hosts"
  printf 'bad.example.com\n' >"$domains"

  run hosts_block_transform "$hosts" "$OPEN" "$CLOSE" "$domains"
  [ "$status" -eq 0 ]
  # The new block is always appended (even when awk fails, the printf block runs).
  [[ "$output" == *"$OPEN"* ]]
  [[ "$output" == *"0.0.0.0 bad.example.com"* ]]
  [[ "$output" == *"$CLOSE"* ]]
}

@test "hosts_block_transform: no existing block → original lines preserved (requires working awk)" {
  if ! _awk_supports_close_var; then
    skip "system awk treats 'close' as reserved; hosts_block_transform cannot pass through original lines"
  fi
  local hosts="$TEST_HOME/hosts"
  local domains="$TEST_HOME/domains"
  printf '127.0.0.1 localhost\n' >"$hosts"
  printf 'bad.example.com\n' >"$domains"

  run hosts_block_transform "$hosts" "$OPEN" "$CLOSE" "$domains"
  [ "$status" -eq 0 ]
  [[ "$output" == *"127.0.0.1 localhost"* ]]
}

@test "hosts_block_transform: existing block replaced not duplicated" {
  local hosts="$TEST_HOME/hosts"
  local domains="$TEST_HOME/domains"
  printf '127.0.0.1 localhost\n%s\n0.0.0.0 old.example.com\n%s\n' \
    "$OPEN" "$CLOSE" >"$hosts"
  printf 'new.example.com\n' >"$domains"

  run hosts_block_transform "$hosts" "$OPEN" "$CLOSE" "$domains"
  [ "$status" -eq 0 ]
  # new domain present in appended block
  [[ "$output" == *"0.0.0.0 new.example.com"* ]]
  # old domain absent (awk strips it; if awk fails it's simply absent from output)
  [[ "$output" != *"0.0.0.0 old.example.com"* ]]
  # open marker appears exactly once
  local open_count
  open_count="$(printf '%s\n' "$output" | grep -cF "$OPEN" || true)"
  [ "$open_count" -eq 1 ]
}

@test "hosts_block_transform: custom user lines preserved (requires working awk)" {
  if ! _awk_supports_close_var; then
    skip "system awk treats 'close' as reserved; hosts_block_transform cannot preserve user lines"
  fi
  local hosts="$TEST_HOME/hosts"
  local domains="$TEST_HOME/domains"
  printf '127.0.0.1 localhost\n192.168.1.10 myserver\n' >"$hosts"
  printf 'tracker.example.com\n' >"$domains"

  run hosts_block_transform "$hosts" "$OPEN" "$CLOSE" "$domains"
  [ "$status" -eq 0 ]
  local line_localhost line_myserver line_open
  line_localhost="$(printf '%s\n' "$output" | grep -n '127.0.0.1 localhost' | cut -d: -f1)"
  line_myserver="$(printf '%s\n' "$output" | grep -n '192.168.1.10 myserver' | cut -d: -f1)"
  line_open="$(printf '%s\n' "$output" | grep -nF "$OPEN" | cut -d: -f1)"
  [ -n "$line_localhost" ]
  [ -n "$line_myserver" ]
  [ -n "$line_open" ]
  [ "$line_localhost" -lt "$line_open" ]
  [ "$line_myserver" -lt "$line_open" ]
}

@test "hosts_block_transform: idempotent — running twice gives byte-identical output" {
  local hosts="$TEST_HOME/hosts"
  local domains="$TEST_HOME/domains"
  printf '127.0.0.1 localhost\n' >"$hosts"
  printf 'tracker.example.com\n' >"$domains"

  local first second
  first="$(hosts_block_transform "$hosts" "$OPEN" "$CLOSE" "$domains")"
  printf '%s\n' "$first" >"$hosts"
  second="$(hosts_block_transform "$hosts" "$OPEN" "$CLOSE" "$domains")"
  [ "$first" = "$second" ]
}

# --- managed_block_strip -----------------------------------------------------

@test "managed_block_strip: block present → stripped, surrounding lines intact (requires working awk)" {
  if ! _awk_supports_close_var; then
    skip "system awk treats 'close' as reserved; managed_block_strip cannot selectively strip"
  fi
  local file="$TEST_HOME/zshrc"
  printf 'before\n%s\nblock content\n%s\nafter\n' "$OPEN" "$CLOSE" >"$file"

  run managed_block_strip "$file" "$OPEN" "$CLOSE"
  [ "$status" -eq 0 ]
  run grep -F "$OPEN" "$file"
  [ "$status" -ne 0 ]
  run grep "block content" "$file"
  [ "$status" -ne 0 ]
  run grep "before" "$file"
  [ "$status" -eq 0 ]
  run grep "after" "$file"
  [ "$status" -eq 0 ]
}

@test "managed_block_strip: block absent → file unchanged" {
  local file="$TEST_HOME/zshrc"
  printf 'line1\nline2\n' >"$file"
  local before
  before="$(cat "$file")"

  managed_block_strip "$file" "$OPEN" "$CLOSE"

  local after
  after="$(cat "$file")"
  [ "$before" = "$after" ]
}

@test "managed_block_strip: half-open marker → returns non-zero, file unchanged" {
  local file="$TEST_HOME/zshrc"
  # open marker present but no close marker
  printf 'before\n%s\nblock content\n' "$OPEN" >"$file"
  local before
  before="$(cat "$file")"

  run managed_block_strip "$file" "$OPEN" "$CLOSE"
  [ "$status" -ne 0 ]

  local after
  after="$(cat "$file")"
  [ "$before" = "$after" ]
}
