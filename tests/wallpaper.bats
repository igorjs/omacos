#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0
#
# tests/wallpaper.bats — unit tests for the omacos wallpaper verb and mode toggle.
# osascript and killall are shadowed by spy functions; no real GUI/network/filesystem
# dependencies. Each test needing a stub wallpaper.jpg uses a per-test FAKE_ROOT.

REPO="$BATS_TEST_DIRNAME/.."

setup() {
  TEST_HOME="$(mktemp -d)"
  export HOME="$TEST_HOME"
  export OMACOS_ROOT="$REPO"
  mkdir -p "$HOME/.config/omacos"
  STATE_DIR="$HOME/.config/omacos"
  # shellcheck source=bin/omacos
  source "$REPO/bin/omacos"
}

teardown() {
  chmod -R u+rwx "$TEST_HOME" 2>/dev/null || true
  rm -rf "$TEST_HOME"
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# _stub_theme ROOT THEME — create a minimal theme directory with all required
# files so cmd_theme_set won't skip any step due to missing assets.
_stub_theme() {
  local root="$1" theme="$2"
  mkdir -p "$root/themes/$theme"
  touch "$root/themes/$theme/ghostty.conf" \
        "$root/themes/$theme/tmux.conf" \
        "$root/themes/$theme/starship.toml" \
        "$root/themes/$theme/zsh.zsh" \
        "$root/themes/$theme/nvim.lua" \
        "$root/themes/$theme/zed.json" \
        "$root/themes/$theme/wallpaper.jpg"
}

# _install_spies — define osascript and killall spy functions that record
# their arguments to $BATS_TEST_TMPDIR/{osascript,killall}.args and succeed.
_install_spies() {
  osascript() {
    printf '%s\n' "$@" >> "$BATS_TEST_TMPDIR/osascript.args"
    return 0
  }
  export -f osascript

  killall() {
    printf '%s\n' "$@" >> "$BATS_TEST_TMPDIR/killall.args"
    return 0
  }
  export -f killall
}

# _install_theme_set_stubs — no-op stubs for binaries called by cmd_theme_set
# that are not available or not meaningful in a unit-test environment.
_install_theme_set_stubs() {
  python3() { return 0; }
  export -f python3

  tmux() { return 0; }
  export -f tmux
}

# ---------------------------------------------------------------------------
# Scenario 1: apply success — spy-arg path, killall called
# ---------------------------------------------------------------------------

@test "wallpaper: cmd_wallpaper_set copies and calls osascript with STATE_DIR path" {
  FAKE_ROOT="$(mktemp -d)"
  mkdir -p "$FAKE_ROOT/themes/tokyonight"
  echo "fake-jpeg" > "$FAKE_ROOT/themes/tokyonight/wallpaper.jpg"
  export OMACOS_ROOT="$FAKE_ROOT"

  _install_spies

  run cmd_wallpaper_set "tokyonight"

  [ "$status" -eq 0 ]
  [ -f "$STATE_DIR/wallpaper.jpg" ]
  # Spy records one argument per line, so anchor the match to the whole line.
  grep -qx "$STATE_DIR/wallpaper.jpg" "$BATS_TEST_TMPDIR/osascript.args"
  grep -q "WallpaperAgent" "$BATS_TEST_TMPDIR/killall.args"
}

# ---------------------------------------------------------------------------
# Scenario 1b: injection safety — the path travels via argv, never into the
# AppleScript body. Uses a REAL executable osascript on PATH (higher fidelity
# than a bash-function spy: it exercises the heredoc-on-stdin + argv path).
# ---------------------------------------------------------------------------

@test "wallpaper: _wallpaper_apply passes the path via argv, not into the script body" {
  local spydir="$BATS_TEST_TMPDIR/spybin"
  mkdir -p "$spydir"
  cat > "$spydir/osascript" <<'SPY'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$SPY_ARGV"
cat > "$SPY_STDIN"
exit 0
SPY
  chmod +x "$spydir/osascript"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$spydir/killall"
  chmod +x "$spydir/killall"
  export SPY_ARGV="$BATS_TEST_TMPDIR/argv.txt" SPY_STDIN="$BATS_TEST_TMPDIR/stdin.txt"
  export PATH="$spydir:$PATH"

  # Hostile path: spaces, a double-quote, and a command substitution string.
  local evil='/tmp/a b/$(touch '"$BATS_TEST_TMPDIR"'/PWNED)".jpg'
  run _wallpaper_apply "$evil"

  [ "$status" -eq 0 ]
  # '-' is argv item 1 (read script from stdin); the image path is item 2, verbatim.
  [ "$(sed -n 2p "$SPY_ARGV")" = "$evil" ]
  # The path text must never appear inside the AppleScript body...
  ! grep -qF 'PWNED' "$SPY_STDIN"
  # ...and the command substitution must never have run.
  [ ! -e "$BATS_TEST_TMPDIR/PWNED" ]
}

# ---------------------------------------------------------------------------
# Scenario 2: osascript soft-fail — exits 0, prints note
# ---------------------------------------------------------------------------

@test "wallpaper: osascript failure prints note and exits 0" {
  FAKE_ROOT="$(mktemp -d)"
  mkdir -p "$FAKE_ROOT/themes/tokyonight"
  echo "fake-jpeg" > "$FAKE_ROOT/themes/tokyonight/wallpaper.jpg"
  export OMACOS_ROOT="$FAKE_ROOT"

  osascript() { return 1; }
  export -f osascript

  run cmd_wallpaper_set "tokyonight"

  [ "$status" -eq 0 ]
  # Copy runs before apply, so the staged file must exist even when osascript fails.
  [ -f "$STATE_DIR/wallpaper.jpg" ]
  [[ "$output" == *"Could not set wallpaper"* ]]
}

# ---------------------------------------------------------------------------
# Scenario 3: cp failure (chmod 000 on STATE_DIR) — exits 0, prints note
# ---------------------------------------------------------------------------

@test "wallpaper: cp failure prints note and exits 0" {
  [[ $EUID -ne 0 ]] || skip "root ignores mode bits"

  FAKE_ROOT="$(mktemp -d)"
  mkdir -p "$FAKE_ROOT/themes/tokyonight"
  echo "fake-jpeg" > "$FAKE_ROOT/themes/tokyonight/wallpaper.jpg"
  export OMACOS_ROOT="$FAKE_ROOT"

  _install_spies

  chmod 000 "$STATE_DIR"

  run cmd_wallpaper_set "tokyonight"

  chmod 700 "$STATE_DIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Could not copy"* ]]
  [ ! -f "$BATS_TEST_TMPDIR/osascript.args" ]
}

# ---------------------------------------------------------------------------
# Scenario 4: unknown theme exits 1
# ---------------------------------------------------------------------------

@test "wallpaper: unknown theme exits 1" {
  run cmd_wallpaper_set "no-such-theme"
  [ "$status" -eq 1 ]
}

# ---------------------------------------------------------------------------
# Scenario 4b: theme dir present but no wallpaper.jpg → note, exit 0, no apply
# ---------------------------------------------------------------------------

@test "wallpaper: theme without wallpaper.jpg notes and exits 0 without applying" {
  FAKE_ROOT="$(mktemp -d)"
  mkdir -p "$FAKE_ROOT/themes/nord"   # dir exists, but no wallpaper.jpg
  export OMACOS_ROOT="$FAKE_ROOT"

  _install_spies

  run cmd_wallpaper_set "nord"

  [ "$status" -eq 0 ]
  [[ "$output" == *"No wallpaper bundled"* ]]
  [ ! -f "$BATS_TEST_TMPDIR/osascript.args" ]
}

# ---------------------------------------------------------------------------
# Scenario 5: bare invocation uses current_theme
# ---------------------------------------------------------------------------

@test "wallpaper: bare cmd_wallpaper_set uses current_theme" {
  FAKE_ROOT="$(mktemp -d)"
  mkdir -p "$FAKE_ROOT/themes/everforest"
  echo "fake-jpeg" > "$FAKE_ROOT/themes/everforest/wallpaper.jpg"
  export OMACOS_ROOT="$FAKE_ROOT"
  echo "everforest" > "$STATE_DIR/current_theme"

  _install_spies

  run cmd_wallpaper_set ""

  [ "$status" -eq 0 ]
  [ -f "$STATE_DIR/wallpaper.jpg" ]
}

# ---------------------------------------------------------------------------
# Scenario 6: bare invocation with no current_theme falls back to tokyonight
# ---------------------------------------------------------------------------

@test "wallpaper: no current_theme falls back to tokyonight" {
  FAKE_ROOT="$(mktemp -d)"
  mkdir -p "$FAKE_ROOT/themes/tokyonight"
  # Distinctive marker so we can prove the tokyonight asset was the copy source.
  echo "tokyonight-src" > "$FAKE_ROOT/themes/tokyonight/wallpaper.jpg"
  export OMACOS_ROOT="$FAKE_ROOT"

  _install_spies

  run cmd_wallpaper_set ""

  [ "$status" -eq 0 ]
  [ -f "$STATE_DIR/wallpaper.jpg" ]
  grep -qx "tokyonight-src" "$STATE_DIR/wallpaper.jpg"
}

# ---------------------------------------------------------------------------
# Scenario 7: current_theme with trailing newline is trimmed
# ---------------------------------------------------------------------------

@test "wallpaper: current_theme trailing newline is trimmed" {
  FAKE_ROOT="$(mktemp -d)"
  mkdir -p "$FAKE_ROOT/themes/nord"
  echo "fake-jpeg" > "$FAKE_ROOT/themes/nord/wallpaper.jpg"
  export OMACOS_ROOT="$FAKE_ROOT"
  printf 'nord\n' > "$STATE_DIR/current_theme"

  _install_spies

  run cmd_wallpaper_set ""

  [ "$status" -eq 0 ]
  [ -f "$STATE_DIR/wallpaper.jpg" ]
}

# ---------------------------------------------------------------------------
# Scenario 8: mode toggle — auto, manual, and bogus each tested in isolation
# ---------------------------------------------------------------------------

@test "wallpaper: cmd_wallpaper_mode auto writes 'auto'" {
  run cmd_wallpaper_mode auto
  [ "$status" -eq 0 ]
  [ "$(cat "$STATE_DIR/wallpaper_mode")" = "auto" ]
}

@test "wallpaper: cmd_wallpaper_mode manual writes 'manual'" {
  run cmd_wallpaper_mode manual
  [ "$status" -eq 0 ]
  [ "$(cat "$STATE_DIR/wallpaper_mode")" = "manual" ]
}

@test "wallpaper: cmd_wallpaper_mode bogus arg exits 2" {
  run cmd_wallpaper_mode "bogus"
  [ "$status" -eq 2 ]
}

# ---------------------------------------------------------------------------
# Scenario 8b: `wallpaper set <theme>` dispatch alias routes to cmd_wallpaper_set
# ---------------------------------------------------------------------------

@test "wallpaper: dispatch 'wallpaper set <theme>' applies that theme" {
  local FAKE_ROOT; FAKE_ROOT="$(mktemp -d)"
  mkdir -p "$FAKE_ROOT/themes/nord"
  echo "nord-src" > "$FAKE_ROOT/themes/nord/wallpaper.jpg"
  # Stub osascript + killall on PATH so no real GUI call happens on macOS.
  local spydir="$BATS_TEST_TMPDIR/setbin"; mkdir -p "$spydir"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$spydir/osascript"; chmod +x "$spydir/osascript"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$spydir/killall"; chmod +x "$spydir/killall"

  run env PATH="$spydir:$PATH" HOME="$TEST_HOME" OMACOS_ROOT="$FAKE_ROOT" \
    bash "$REPO/bin/omacos" wallpaper set nord

  [ "$status" -eq 0 ]
  [ -f "$STATE_DIR/wallpaper.jpg" ]
  grep -qx "nord-src" "$STATE_DIR/wallpaper.jpg"
}

# ---------------------------------------------------------------------------
# Shared setup for cmd_theme_set wallpaper-step scenarios (9a–9e)
# ---------------------------------------------------------------------------

# _setup_theme_spy ROOT THEME — full stub: theme files + spies + theme_set stubs.
_setup_theme_spy() {
  local root="$1" theme="$2"
  _stub_theme "$root" "$theme"
  # Provide a config/starship.toml so the concat step (step 4) has a source.
  mkdir -p "$root/config"
  touch "$root/config/starship.toml"
  export OMACOS_ROOT="$root"
  _install_spies
  _install_theme_set_stubs
}

# ---------------------------------------------------------------------------
# Scenario 9a: mode=auto + asset present → wallpaper apply runs
# ---------------------------------------------------------------------------

@test "wallpaper: theme_set with mode=auto applies wallpaper" {
  FAKE_ROOT="$(mktemp -d)"
  _setup_theme_spy "$FAKE_ROOT" "tokyonight"
  echo "auto" > "$STATE_DIR/wallpaper_mode"

  run cmd_theme_set "tokyonight"

  [ -f "$BATS_TEST_TMPDIR/osascript.args" ]
  grep -qx "$STATE_DIR/wallpaper.jpg" "$BATS_TEST_TMPDIR/osascript.args"
}

# ---------------------------------------------------------------------------
# Scenario 9b: mode=manual → no apply
# ---------------------------------------------------------------------------

@test "wallpaper: theme_set with mode=manual does not apply wallpaper" {
  FAKE_ROOT="$(mktemp -d)"
  _setup_theme_spy "$FAKE_ROOT" "tokyonight"
  echo "manual" > "$STATE_DIR/wallpaper_mode"

  run cmd_theme_set "tokyonight"

  [ ! -f "$BATS_TEST_TMPDIR/osascript.args" ]
}

# ---------------------------------------------------------------------------
# Scenario 9c: wallpaper_mode file absent → no apply (defaults to manual)
# ---------------------------------------------------------------------------

@test "wallpaper: theme_set with no wallpaper_mode file does not apply wallpaper" {
  FAKE_ROOT="$(mktemp -d)"
  _setup_theme_spy "$FAKE_ROOT" "tokyonight"
  # Ensure no wallpaper_mode file exists.
  rm -f "$STATE_DIR/wallpaper_mode"

  run cmd_theme_set "tokyonight"

  [ ! -f "$BATS_TEST_TMPDIR/osascript.args" ]
}

# ---------------------------------------------------------------------------
# Scenario 9d: mode file has trailing newline 'auto\n' → trimmed → apply runs
# ---------------------------------------------------------------------------

@test "wallpaper: theme_set with wallpaper_mode='auto\\n' applies wallpaper" {
  FAKE_ROOT="$(mktemp -d)"
  _setup_theme_spy "$FAKE_ROOT" "tokyonight"
  printf 'auto\n' > "$STATE_DIR/wallpaper_mode"

  run cmd_theme_set "tokyonight"

  [ -f "$BATS_TEST_TMPDIR/osascript.args" ]
}

# ---------------------------------------------------------------------------
# Scenario 9e: mode=garbage → no apply, note emitted
# ---------------------------------------------------------------------------

@test "wallpaper: theme_set with wallpaper_mode=garbage prints note and does not apply" {
  FAKE_ROOT="$(mktemp -d)"
  _setup_theme_spy "$FAKE_ROOT" "tokyonight"
  echo "garbage" > "$STATE_DIR/wallpaper_mode"

  run cmd_theme_set "tokyonight"

  [ ! -f "$BATS_TEST_TMPDIR/osascript.args" ]
  [[ "$output" == *"Unknown wallpaper_mode"* ]]
}
