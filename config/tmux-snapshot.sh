#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# tmux-resurrect post-save hook. Keeps a copy of the pane contents archive for
# every save that has real content. The archive is a single file that each
# save overwrites, so a save taken after a failed restore would erase it.
set -euo pipefail

MIN_PANES=3
KEEP_SNAPSHOTS=48
RESURRECT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
SNAPSHOT_DIR="$RESURRECT_DIR/snapshots"
ARCHIVE="$RESURRECT_DIR/pane_contents.tar.gz"

save_name="$(readlink "$RESURRECT_DIR/last" || true)"
[ -n "$save_name" ] && [ -f "$ARCHIVE" ] || exit 0

pane_count="$(grep -c '^pane' "$RESURRECT_DIR/$save_name" || true)"
[ "$pane_count" -ge "$MIN_PANES" ] || exit 0

mkdir -p "$SNAPSHOT_DIR"
cp "$ARCHIVE" "$SNAPSHOT_DIR/${save_name%.txt}.pane_contents.tar.gz"

# shellcheck disable=SC2012
ls -t "$SNAPSHOT_DIR"/*.pane_contents.tar.gz | tail -n +"$((KEEP_SNAPSHOTS + 1))" |
  while IFS= read -r stale; do
    rm -f -- "$stale"
  done
