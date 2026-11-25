#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Restore tmux sessions once per server start. Replaces tmux-continuum's
# auto-restore, which skips itself when more than one tmux process exists at
# startup (Ghostty reopens every saved window at login, each running tmux).
#
# If the newest save is nearly empty (an autosave taken after a failed
# restore), restore from the newest save that has real content instead, along
# with the pane contents archive that tmux-snapshot.sh kept for it.
set -euo pipefail

MIN_PANES=3
SESSION_WAIT_SECONDS=10
RESURRECT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
RESTORE_SCRIPT="$HOME/.tmux/plugins/tmux-resurrect/scripts/restore.sh"
LAST_LINK="$RESURRECT_DIR/last"
SNAPSHOT_DIR="$RESURRECT_DIR/snapshots"
ARCHIVE="$RESURRECT_DIR/pane_contents.tar.gz"

pane_count() {
  grep -c '^pane' "$1" || true
}

[ -e "$LAST_LINK" ] || exit 0

if [ "$(pane_count "$LAST_LINK")" -lt "$MIN_PANES" ]; then
  while IFS= read -r save; do
    if [ "$(pane_count "$save")" -ge "$MIN_PANES" ]; then
      ln -sfn "$(basename "$save")" "$LAST_LINK"
      snapshot="$SNAPSHOT_DIR/$(basename "$save" .txt).pane_contents.tar.gz"
      [ -f "$snapshot" ] && cp "$snapshot" "$ARCHIVE"
      break
    fi
  done < <(ls -t "$RESURRECT_DIR"/tmux_resurrect_*.txt)
fi

# Config loads before `new-session -A` creates the first session.
for _ in $(seq "$SESSION_WAIT_SECONDS"); do
  tmux has-session 2>/dev/null && break
  sleep 1
done

"$RESTORE_SCRIPT"
