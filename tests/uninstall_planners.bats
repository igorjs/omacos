#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0
#
# tests/uninstall_planners.bats — unit tests for the pure planner functions
# in install/uninstall.sh: plan_configs, plan_packages, plan_defaults,
# and confirm_or_abort.
#
# All planners are side-effect-free; sourcing runs nothing (dispatch guard).
# We override OMACOS_HOME / OMACOS_ROOT / OMACOS_BASELINE_DIR / OMACOS_BREWFILE
# via env vars so no real system paths are touched.

setup() {
  TEST_HOME="$(mktemp -d)"
  REPO="$BATS_TEST_DIRNAME/.."
  export OMACOS_HOME="$TEST_HOME/home"
  export OMACOS_ROOT="$REPO"
  export OMACOS_STATE_DIR="$TEST_HOME/state"
  export OMACOS_BASELINE_DIR="$TEST_HOME/baseline"
  export OMACOS_BREWFILE="$TEST_HOME/Brewfile"
  export OMACOS_HOSTS_FILE="$TEST_HOME/hosts"
  mkdir -p "$OMACOS_HOME" "$OMACOS_STATE_DIR" "$OMACOS_BASELINE_DIR"
  # shellcheck source=install/uninstall.sh
  source "$REPO/install/uninstall.sh"
}

teardown() {
  rm -rf "$TEST_HOME"
}

# --- plan_configs ------------------------------------------------------------

@test "plan_configs: repo-owned symlink marked as remove" {
  # Create a symlink that points under OMACOS_ROOT (→ owned).
  mkdir -p "$OMACOS_HOME/.config/aerospace"
  ln -s "$OMACOS_ROOT/config/aerospace.toml" \
    "$OMACOS_HOME/.config/aerospace/aerospace.toml"

  run plan_configs
  [ "$status" -eq 0 ]
  [[ "$output" == *"remove"* ]]
  [[ "$output" == *"aerospace.toml"* ]]
}

@test "plan_configs: foreign symlink marked as skip" {
  mkdir -p "$OMACOS_HOME/.config/ghostty"
  ln -s "/usr/local/etc/ghostty.config" "$OMACOS_HOME/.config/ghostty/config"

  run plan_configs
  [ "$status" -eq 0 ]
  [[ "$output" == *"skip"* ]]
  [[ "$output" == *"ghostty"* ]] || [[ "$output" == *"config"* ]]
}

@test "plan_configs: managed-block .zshrc marked as strip" {
  printf '# >>> omacos >>>\nexport PATH=/opt/omacos/bin:$PATH\n# <<< omacos <<<\n' \
    >"$OMACOS_HOME/.zshrc"

  run plan_configs
  [ "$status" -eq 0 ]
  [[ "$output" == *"strip"* ]]
  [[ "$output" == *".zshrc"* ]]
}

@test "plan_configs: fixture is unchanged after running" {
  mkdir -p "$OMACOS_HOME/.config/aerospace"
  ln -s "$OMACOS_ROOT/config/aerospace.toml" \
    "$OMACOS_HOME/.config/aerospace/aerospace.toml"
  local link_before
  link_before="$(readlink "$OMACOS_HOME/.config/aerospace/aerospace.toml")"

  plan_configs >/dev/null

  local link_after
  link_after="$(readlink "$OMACOS_HOME/.config/aerospace/aerospace.toml")"
  [ "$link_before" = "$link_after" ]
}

# --- plan_packages -----------------------------------------------------------

@test "plan_packages: targets OmacOS-added packages only (not baseline)" {
  printf 'brew "git"\nbrew "ripgrep"\ncask "ghostty"\ncask "docker"\ntap "homebrew/cask"\nmas "Xcode", id: 497799835\n' \
    >"$OMACOS_BREWFILE"
  printf 'git\n' >"$OMACOS_BASELINE_DIR/brew-formulae.txt"
  printf 'docker\n' >"$OMACOS_BASELINE_DIR/brew-casks.txt"

  run plan_packages
  [ "$status" -eq 0 ]
  # ripgrep and ghostty are OmacOS-added (not in baseline)
  [[ "$output" == *"ripgrep"* ]]
  [[ "$output" == *"ghostty"* ]]
  # git and docker are pre-existing (in baseline) → must NOT be targeted
  [[ "$output" != *"formula: git"* ]]
  [[ "$output" != *"cask: docker"* ]]
  # tap/mas lines are silently ignored — verify they don't appear as targets
  [[ "$output" != *"homebrew/cask"* ]]
  [[ "$output" != *"Xcode"* ]]
}

@test "plan_packages: missing baseline dir → warn and exit 0, nothing targeted" {
  rm -rf "$OMACOS_BASELINE_DIR"
  printf 'brew "ripgrep"\n' >"$OMACOS_BREWFILE"

  run plan_packages
  [ "$status" -eq 0 ]
  [[ "$output" == *"no brew baseline"* ]] || [[ "$output" == *"skip"* ]] \
    || [[ "$output" == *"baseline"* ]]
  [[ "$output" != *"ripgrep"* ]]
}

# --- plan_defaults -----------------------------------------------------------

@test "plan_defaults: classifies user, global-g, system-sudo, byhost, byhost-global" {
  # user domain plist
  printf '' >"$OMACOS_BASELINE_DIR/com.apple.dock.plist"
  # global domain (-g)
  printf '' >"$OMACOS_BASELINE_DIR/NSGlobalDomain.plist"
  # system domain (sudo) — underscore prefix maps to path
  printf '' >"$OMACOS_BASELINE_DIR/_Library_Preferences_com.apple.mDNSResponder.plist"
  # byhost regular
  printf '' >"$OMACOS_BASELINE_DIR/byhost.com.apple.X.plist"
  # byhost global
  printf '' >"$OMACOS_BASELINE_DIR/byhost.NSGlobalDomain.plist"

  run plan_defaults
  [ "$status" -eq 0 ]
  # user domain
  [[ "$output" == *"user domain"* ]] || [[ "$output" == *"com.apple.dock"* ]]
  # global -g
  [[ "$output" == *"global"* ]] || [[ "$output" == *"NSGlobalDomain"* ]]
  # system sudo
  [[ "$output" == *"system"* ]] || [[ "$output" == *"sudo"* ]]
  # byhost
  [[ "$output" == *"byhost"* ]]
}

@test "plan_defaults: missing baseline dir → warn and return 0, no abort" {
  rm -rf "$OMACOS_BASELINE_DIR"

  run plan_defaults
  [ "$status" -eq 0 ]
  [[ "$output" == *"no baseline"* ]] || [[ "$output" == *"nothing to restore"* ]] \
    || [[ "$output" == *"baseline"* ]]
}

# --- confirm_or_abort --------------------------------------------------------

@test "confirm_or_abort: YES input → proceeds (exit 0 from caller)" {
  run bash -c "
    source \"$REPO/install/uninstall.sh\"
    printf 'YES\n' | (confirm_or_abort 'Type YES to proceed: ' && echo 'proceeded')
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"proceeded"* ]]
}

@test "confirm_or_abort: 'no' input → exits non-zero" {
  run bash -c "
    source \"$REPO/install/uninstall.sh\"
    printf 'no\n' | confirm_or_abort 'Type YES to proceed: '
    echo 'should not reach here'
  "
  [ "$status" -ne 0 ]
  [[ "$output" != *"should not reach here"* ]]
}

@test "confirm_or_abort: empty input → exits non-zero" {
  run bash -c "
    source \"$REPO/install/uninstall.sh\"
    printf '' | confirm_or_abort 'Type YES to proceed: '
    echo 'should not reach here'
  "
  [ "$status" -ne 0 ]
  [[ "$output" != *"should not reach here"* ]]
}
