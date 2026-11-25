#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Prints a status-bar warning when tmux-continuum has stopped saving.
# Usage in status-right: #(tmux-save-watchdog.sh #{start_time})
# Autosave runs from a #() call in status-right, so a config change that
# overwrites status-right stops saving without any error.
set -euo pipefail

STALE_AFTER_INTERVALS=3
DEFAULT_INTERVAL_MINUTES=15
SECONDS_PER_MINUTE=60
WARNING='#[fg=#f7768e,bold]SAVE STALE#[default] '

server_start="${1:-0}"
interval_minutes="$(tmux show -gqv @continuum-save-interval)"
last_save="$(tmux show -gqv @continuum-save-last-timestamp)"

reference="${last_save:-0}"
[ "$server_start" -gt "$reference" ] && reference="$server_start"

limit=$((${interval_minutes:-$DEFAULT_INTERVAL_MINUTES} * SECONDS_PER_MINUTE * STALE_AFTER_INTERVALS))
if [ "$(($(date +%s) - reference))" -gt "$limit" ]; then
  printf '%s' "$WARNING"
fi
