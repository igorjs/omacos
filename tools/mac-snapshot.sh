#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# mac-snapshot.sh: capture, diff, and export macOS settings + installed software.
#
# There is no shipped "factory defaults" on macOS to diff against, so this tool
# supports two workflows:
#
#   1) BASELINE diff. Snapshot once (ideally on a fresh Mac/VM), snapshot again
#      later, diff. The delta is everything you customized.
#
#   2) BEFORE/AFTER. 'snapshot', change ONE thing in System Settings, then
#      'snapshot' again. The diff shows the exact domain+key that toggle maps
#      to. Best for building omacos/macos/defaults.sh key by key.
#
# Usage:
#   ./mac-snapshot.sh snapshot [label]    take a snapshot (default label: timestamp)
#   ./mac-snapshot.sh list                list saved snapshots
#   ./mac-snapshot.sh diff A B            diff two snapshots by label
#   ./mac-snapshot.sh watch               snapshot, wait for Enter, snapshot again, diff
#   ./mac-snapshot.sh export              write Brewfile + defaults export + restore.sh
#
set -euo pipefail

SNAP_DIR="${MAC_SNAPSHOT_DIR:-$HOME/.mac-snapshots}"
mkdir -p "$SNAP_DIR"

BLUE='\033[38;2;122;162;247m'
GREEN='\033[38;2;158;206;106m'
RED='\033[38;2;247;118;142m'
PURPLE='\033[38;2;187;154;247m'
DIM='\033[38;2;86;95;137m'
RESET='\033[0m'
info() { printf "${BLUE}==>${RESET} %s\n" "$1"; }
ok() { printf "${GREEN} ok${RESET} %s\n" "$1"; }
warn() { printf "${RED} !! ${RESET}%s\n" "$1"; }

if [[ "$(uname -s)" != "Darwin" ]]; then
  warn "macOS only."
  exit 1
fi

take_snapshot() {
  local label="${1:-$(date +%Y%m%d-%H%M%S)}"
  local dir="$SNAP_DIR/$label"
  mkdir -p "$dir"
  info "Snapshotting defaults to $dir"

  # Global domain
  defaults read -g >"$dir/_global.txt" 2>/dev/null || true

  # Every per-app / per-system domain
  defaults domains | tr ',' '\n' | sed 's/^ *//' | while read -r domain; do
    [[ -z "$domain" ]] && continue
    local safe="${domain//\//_}"
    defaults read "$domain" >"$dir/$safe.txt" 2>/dev/null || true
  done

  # Combined sorted view for whole-system diffs
  cat "$dir"/*.txt 2>/dev/null | sort >"$dir/_combined_sorted.txt" || true

  ok "Snapshot '$label' saved ($(ls "$dir"/*.txt 2>/dev/null | wc -l | tr -d ' ') domains)"
}

list_snapshots() {
  info "Saved snapshots in $SNAP_DIR:"
  ls -1 "$SNAP_DIR" 2>/dev/null | sed 's/^/  /' || echo "  (none)"
}

diff_snapshots() {
  local a="$1" b="$2"
  local fa="$SNAP_DIR/$a/_combined_sorted.txt"
  local fb="$SNAP_DIR/$b/_combined_sorted.txt"
  [[ -f "$fa" ]] || {
    warn "No snapshot '$a'"
    exit 1
  }
  [[ -f "$fb" ]] || {
    warn "No snapshot '$b'"
    exit 1
  }
  info "Diff $a -> $b  (lines only in $b are likely your changes)"
  echo
  # Per-domain diff so you see WHICH app's domain changed, not just values
  for f in "$SNAP_DIR/$b"/*.txt; do
    local name
    name="$(basename "$f")"
    [[ "$name" == "_combined_sorted.txt" ]] && continue
    local old="$SNAP_DIR/$a/$name"
    if [[ -f "$old" ]]; then
      if ! diff -q "$old" "$f" >/dev/null 2>&1; then
        printf "${PURPLE}### %s${RESET}\n" "${name%.txt}"
        diff "$old" "$f" |
          sed 's/^< /  '"$(printf '\033[38;2;247;118;142m')"'- /; s/^> /  '"$(printf '\033[38;2;158;206;106m')"'+ /' |
          sed 's/$/'"$(printf '\033[0m')"'/'
        echo
      fi
    else
      printf "${PURPLE}### %s (new domain)${RESET}\n" "${name%.txt}"
    fi
  done
}

watch_change() {
  local before="_watch_before" after="_watch_after"
  take_snapshot "$before"
  echo
  printf "${PURPLE}Now change ONE setting in System Settings, then press Enter...${RESET}"
  read -r _
  take_snapshot "$after"
  echo
  diff_snapshots "$before" "$after"
  printf "\n${DIM}Tip: the domain header above is the 'defaults write <domain> <key>' target.${RESET}\n"
}

export_bundle() {
  local out="${1:-$HOME/mac-config-export}"
  mkdir -p "$out"
  info "Exporting to $out"

  # 1. Software via Brewfile (formulae, casks, taps, and Mac App Store apps)
  if command -v brew >/dev/null 2>&1; then
    # mas captures App Store apps; install it if missing so the dump includes them
    brew list mas >/dev/null 2>&1 || brew install mas >/dev/null 2>&1 || true
    brew bundle dump --describe --force --file="$out/Brewfile"
    ok "Brewfile written"
  else
    warn "Homebrew not found; skipping Brewfile"
  fi

  # 2. Selected defaults domains exported as importable plists.
  #    Curated short list; extend this in the script after running 'watch' to
  #    learn which domains your settings actually live in. Most other domains
  #    are machine-specific noise (recent files, window positions).
  local domains=(
    "com.apple.dock"
    "com.apple.finder"
    "com.apple.screencapture"
    "com.apple.universalaccess"
    "NSGlobalDomain"
  )
  mkdir -p "$out/defaults"
  for d in "${domains[@]}"; do
    defaults export "$d" "$out/defaults/$d.plist" 2>/dev/null &&
      ok "exported $d" || warn "could not export $d"
  done

  # 3. Restore script for a fresh Mac.
  cat >"$out/restore.sh" <<'RESTORE'
#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Reinstall software
command -v brew >/dev/null 2>&1 || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew bundle --file="$DIR/Brewfile"
# Re-import defaults
for plist in "$DIR"/defaults/*.plist; do
  domain="$(basename "$plist" .plist)"
  defaults import "$domain" "$plist" && echo "imported $domain"
done
killall Dock Finder SystemUIServer 2>/dev/null || true
echo "Done. Some changes need logout/restart."
RESTORE
  chmod +x "$out/restore.sh"
  ok "restore.sh written"
  printf "\n${DIM}Edit the 'domains' list in this script to add what your diffs revealed,\nthen commit %s to your dotfiles repo.\nNote: some settings live outside 'defaults' (app DBs, keychain, sudo-gated)\nand will not be captured.${RESET}\n" "$out"
}

cmd="${1:-}"
shift || true
case "$cmd" in
  snapshot) take_snapshot "${1:-}" ;;
  list) list_snapshots ;;
  diff)
    [[ $# -ge 2 ]] || {
      warn "usage: diff A B"
      exit 1
    }
    diff_snapshots "$1" "$2"
    ;;
  watch) watch_change ;;
  export) export_bundle "${1:-}" ;;
  *)
    cat <<USAGE
mac-snapshot.sh: capture/diff/export macOS settings

  snapshot [label]   Take a snapshot (default label = timestamp)
  list               List saved snapshots
  diff A B           Diff snapshot A against B (B's extra lines = your changes)
  watch              Snapshot, pause while you change one setting, then diff
  export [dir]       Write Brewfile + defaults plists + restore.sh

Workflows:
  Reverse-engineer one setting:   ./mac-snapshot.sh watch
  Baseline then compare later:    ./mac-snapshot.sh snapshot baseline
                                  ...customize your Mac...
                                  ./mac-snapshot.sh snapshot now
                                  ./mac-snapshot.sh diff baseline now
  Export everything to a repo:    ./mac-snapshot.sh export ~/dotfiles/mac
USAGE
    ;;
esac
