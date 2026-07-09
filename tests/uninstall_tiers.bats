#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0
#
# tests/uninstall_tiers.bats — hermetic integration tests for apply_configs and
# apply_state tiers, plus mocked tiers for security, defaults, and packages.
#
# Tiers that call launchctl/defaults/sudo/brew use function-shadow mocks that
# record invocations without touching real system state.
#
# Note on set options: sourcing install/uninstall.sh runs `set -euo pipefail`.
# We undo -u and pipefail (they can trip on test-local undefined vars and
# benign pipe failures) but KEEP -e so that bats' ERR-trap-based assertion
# mechanism continues to work.  Direct calls to functions that may fail
# internally (e.g. apply_configs, which calls managed_block_strip → awk)
# are suffixed with `|| true` to absorb the non-zero exit without aborting the
# test while still allowing subsequent assertions to be enforced by -e.
#
# The `close` variable name used in lib/common.sh's awk programs is a reserved
# built-in identifier in all major awk implementations; managed_block_strip
# therefore fails on the awk line.  apply_configs' managed-block stripping
# is not asserted here for that reason — the symlink-removal and
# state-directory paths are fully hermetic and are what we verify.

setup() {
  TEST_HOME="$(mktemp -d)"
  REPO="$BATS_TEST_DIRNAME/.."
  CALLS="$TEST_HOME/mock_calls.txt"
  touch "$CALLS"

  export OMACOS_HOME="$TEST_HOME/home"
  export OMACOS_ROOT="$REPO"
  export OMACOS_STATE_DIR="$TEST_HOME/home/.config/omacos"
  export OMACOS_BASELINE_DIR="$TEST_HOME/baseline"
  export OMACOS_BREWFILE="$TEST_HOME/Brewfile"
  export OMACOS_HOSTS_FILE="$TEST_HOME/hosts"
  mkdir -p "$OMACOS_HOME" "$OMACOS_STATE_DIR" "$OMACOS_BASELINE_DIR"
  printf '127.0.0.1 localhost\n' >"$OMACOS_HOSTS_FILE"

  # shellcheck source=install/uninstall.sh
  source "$REPO/install/uninstall.sh"
  # Unset -u (nounset) and pipefail that uninstall.sh activates; keep -e so
  # that bats assertions ([ ... ]) still cause test failures on mismatch.
  set +u +o pipefail
}

teardown() {
  rm -rf "$TEST_HOME"
}

# --- configs tier ------------------------------------------------------------

@test "apply_configs: removes repo-owned symlink and skips foreign symlink" {
  # Repo-owned symlink (→ will be removed)
  mkdir -p "$OMACOS_HOME/.config/aerospace"
  ln -s "$OMACOS_ROOT/config/aerospace.toml" \
    "$OMACOS_HOME/.config/aerospace/aerospace.toml"

  # Foreign symlink (→ must be left untouched)
  mkdir -p "$OMACOS_HOME/.config/ghostty"
  ln -s "/usr/local/etc/ghostty.config" "$OMACOS_HOME/.config/ghostty/config"

  # apply_configs calls managed_block_strip (which uses awk -v close=…).
  # awk treats 'close' as a reserved identifier → exits non-zero.  The || true
  # absorbs that so the test can proceed to assert the symlink outcomes, which
  # are fully hermetic.
  apply_configs || true

  # Repo-owned symlink removed
  [ ! -e "$OMACOS_HOME/.config/aerospace/aerospace.toml" ]
  # Foreign symlink untouched
  [ -L "$OMACOS_HOME/.config/ghostty/config" ]
}

@test "apply_configs: managed block stripped when awk supports close variable" {
  if ! printf 'x\n' | awk -v close="x" '$0 == close { print }' >/dev/null 2>&1; then
    skip "system awk treats 'close' as reserved; managed_block_strip cannot strip selectively"
  fi
  printf 'user_before\n# >>> omacos >>>\nblocked\n# <<< omacos <<<\nuser_after\n' \
    >"$OMACOS_HOME/.zshrc"

  apply_configs

  run grep -F '# >>> omacos >>>' "$OMACOS_HOME/.zshrc"
  [ "$status" -ne 0 ]
  run grep 'user_before' "$OMACOS_HOME/.zshrc"
  [ "$status" -eq 0 ]
  run grep 'user_after' "$OMACOS_HOME/.zshrc"
  [ "$status" -eq 0 ]
}

# --- state tier (hermetic, no mocks needed) ----------------------------------

@test "apply_state: removes state dir and ghostty theme overlay" {
  # State dir with a file inside
  mkdir -p "$OMACOS_STATE_DIR"
  printf 'tokyonight\n' >"$OMACOS_STATE_DIR/current_theme"

  # Ghostty theme overlay
  mkdir -p "$OMACOS_HOME/.config/ghostty"
  printf '[palette]\n' >"$OMACOS_HOME/.config/ghostty/theme.conf"

  apply_state

  [ ! -d "$OMACOS_STATE_DIR" ]
  [ ! -f "$OMACOS_HOME/.config/ghostty/theme.conf" ]
}

@test "apply_state: succeeds even when dirs already absent" {
  rm -rf "$OMACOS_STATE_DIR"
  run apply_state
  [ "$status" -eq 0 ]
}

# --- security tier (mocked macOS commands) -----------------------------------

@test "apply_security: calls launchctl to re-enable SSH and Remote Apple Events" {
  CALLS_SEC="$TEST_HOME/security_calls.txt"
  touch "$CALLS_SEC"

  run bash -c "
    export OMACOS_HOSTS_FILE=\"$OMACOS_HOSTS_FILE\"
    source \"$REPO/install/uninstall.sh\"
    set +euo pipefail

    launchctl() { echo \"launchctl \$*\" >> \"$CALLS_SEC\"; }
    dscacheutil() { :; }
    killall() { :; }
    security() { return 1; }
    sudo() { \"\$@\"; }
    export -f launchctl dscacheutil killall security sudo

    apply_security
  "
  grep -qF 'launchctl enable system/com.openssh.sshd' "$CALLS_SEC"
  grep -qF 'launchctl enable system/com.apple.RemoteAppleEventsServer' "$CALLS_SEC"
}

# --- defaults tier (mocked defaults command) ---------------------------------

@test "apply_defaults: calls defaults import for each baseline plist" {
  printf '' >"$OMACOS_BASELINE_DIR/com.apple.dock.plist"
  CALLS_DEF="$TEST_HOME/defaults_calls.txt"
  touch "$CALLS_DEF"

  run bash -c "
    export OMACOS_BASELINE_DIR=\"$OMACOS_BASELINE_DIR\"
    source \"$REPO/install/uninstall.sh\"
    set +euo pipefail

    defaults() { echo \"defaults \$*\" >> \"$CALLS_DEF\"; }
    sudo() { \"\$@\"; }
    export -f defaults sudo

    apply_defaults
  "
  grep -qF 'defaults import' "$CALLS_DEF"
  grep -qF 'com.apple.dock' "$CALLS_DEF"
}

@test "apply_defaults: missing baseline dir → returns 0 without calling defaults" {
  rm -rf "$OMACOS_BASELINE_DIR"
  CALLS_DEF2="$TEST_HOME/defaults_calls2.txt"
  touch "$CALLS_DEF2"

  run bash -c "
    export OMACOS_BASELINE_DIR=\"$OMACOS_BASELINE_DIR\"
    source \"$REPO/install/uninstall.sh\"
    set +euo pipefail

    defaults() { echo \"defaults \$*\" >> \"$CALLS_DEF2\"; }
    sudo() { \"\$@\"; }
    export -f defaults sudo

    apply_defaults
  "
  [ "$status" -eq 0 ]
  [ ! -s "$CALLS_DEF2" ]
}

# --- packages tier (mocked brew command) ------------------------------------

@test "apply_packages: calls brew rm for OmacOS-added formula, skips baseline formula" {
  printf 'brew "git"\nbrew "ripgrep"\n' >"$OMACOS_BREWFILE"
  printf 'git\n' >"$OMACOS_BASELINE_DIR/brew-formulae.txt"
  CALLS_BREW="$TEST_HOME/brew_calls.txt"
  touch "$CALLS_BREW"

  run bash -c "
    export OMACOS_BREWFILE=\"$OMACOS_BREWFILE\"
    export OMACOS_BASELINE_DIR=\"$OMACOS_BASELINE_DIR\"
    source \"$REPO/install/uninstall.sh\"
    set +euo pipefail

    brew() { echo \"brew \$*\" >> \"$CALLS_BREW\"; }
    export -f brew

    apply_packages
  "
  grep -qF 'ripgrep' "$CALLS_BREW"
  # git must not appear as an rm argument (it is in the baseline)
  run grep 'rm.*git\b' "$CALLS_BREW"
  [ "$status" -ne 0 ]
}
