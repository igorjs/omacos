# shellcheck shell=bash
# SPDX-License-Identifier: Apache-2.0
#
# lib/menu.sh — gum-rendered interactive menu renderer for OmacOS.
# Source this file; do not execute it directly (a dispatch guard handles
# direct invocation).
#

# Resolve this file's directory at source time so BASH_SOURCE[0] is captured
# before any nested sourcing changes it.
_MENU_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/common.sh
source "$_MENU_DIR/common.sh"

# Path to the menu definition file (resolved once at source time).
_MENU_JSON="$_MENU_DIR/menu.json"

# OMACOS_ROOT may already be set by the caller (e.g. bin/omacos or tests).
# Fall back to deriving it from this file's location.
OMACOS_ROOT="${OMACOS_ROOT:-$(cd "$_MENU_DIR/.." && pwd)}"

# --- Helpers ------------------------------------------------------------------

# _menu_current_theme
# Prints the name stored in $HOME/.config/omacos/current_theme, or empty.
_menu_current_theme() {
  local f="$HOME/.config/omacos/current_theme"
  if [[ -f "$f" ]]; then
    cat "$f"
  else
    printf ''
  fi
}

# menu_node_provider <id>
# Returns the "provider" value for the item with the given id, or empty.
menu_node_provider() {
  local id="$1"
  jq -r --arg id "$id" '.items[] | select(.id == $id) | .provider // empty' "$_MENU_JSON"
}

# menu_provider_themes <current>
# Lists theme basenames from $OMACOS_ROOT/themes/*/. Appends "  ✓" to <current>.
menu_provider_themes() {
  local current="${1:-}"
  local themes_dir="$OMACOS_ROOT/themes"
  if [[ ! -d "$themes_dir" ]]; then
    return 0
  fi
  local name
  for d in "$themes_dir"/*/; do
    [[ -d "$d" ]] || continue
    name="$(basename "$d")"
    if [[ "$name" == "$current" ]]; then
      printf '%s  ✓\n' "$name"
    else
      printf '%s\n' "$name"
    fi
  done
}

# menu_items <route>
# Outputs one line per choosable item.
#   route=""      → root menu items from menu.json ("icon label")
#   route="theme" → delegate to menu_provider_themes
menu_items() {
  local route="${1:-}"
  if [[ -z "$route" ]]; then
    jq -r '.items[] | "\(.icon) \(.label)"' "$_MENU_JSON"
  else
    # Provider route: currently only "theme" is supported.
    menu_provider_themes "$(_menu_current_theme)"
  fi
}

# menu_dispatch <route> <selection>
# Handles a user selection. Returns 130 on __quit__, 0 otherwise (stay in menu).
menu_dispatch() {
  local route="${1:-}"
  local selection="${2:-}"

  if [[ -z "$route" ]]; then
    # Root menu: strip icon prefix (everything after first space is the label).
    local label="${selection#* }"

    # Look up the item by label.
    local action provider id
    action="$(jq -r --arg label "$label" '.items[] | select(.label == $label) | .action // empty' "$_MENU_JSON")"
    provider="$(jq -r --arg label "$label" '.items[] | select(.label == $label) | .provider // empty' "$_MENU_JSON")"
    id="$(jq -r --arg label "$label" '.items[] | select(.label == $label) | .id' "$_MENU_JSON")"

    if [[ "$action" == "__quit__" ]]; then
      return 130
    elif [[ -n "$action" ]]; then
      if ! eval "$action" 2>&1; then
        warn "Command failed: $action"
      fi
    elif [[ -n "$provider" ]]; then
      menu_render "$id"
    fi
  else
    # Provider route (e.g. "theme"): strip trailing "  ✓" and whitespace.
    local theme_name="${selection%  ✓}"
    # Trim any trailing whitespace.
    theme_name="${theme_name%"${theme_name##*[! ]}"}"

    if ! omacos theme set "$theme_name" 2>&1; then
      warn "Failed to apply theme: $theme_name"
    fi
  fi

  return 0
}

# menu_render [route]
# Interactive gum choose loop. Returns 0 when the user exits/goes back.
menu_render() {
  local route="${1:-}"

  # Build header: root → "OmacOS"; provider → capitalize first letter of route.
  local header
  if [[ -z "$route" ]]; then
    header="OmacOS"
  else
    header="${route^}"
  fi

  while true; do
    # Build choices array.
    local -a choices
    mapfile -t choices < <(menu_items "$route")

    if [[ "${#choices[@]}" -eq 0 ]]; then
      return 0
    fi

    # Pipe choices to gum choose via stdin to avoid arg-length issues.
    local selection
    if ! selection="$(printf '%s\n' "${choices[@]}" | gum choose \
      --limit 1 \
      --header "$header" \
      --header.foreground 212 \
      --selected.foreground 99 \
      --cursor.foreground 99)"; then
      # Non-zero exit from gum means Escape / cancel → go back / quit at root.
      return 0
    fi

    [[ -z "$selection" ]] && return 0

    menu_dispatch "$route" "$selection" || {
      local rc=$?
      [[ "$rc" -eq 130 ]] && return 130
    }
  done
}

# cmd_menu [route]
# Entry point called from bin/omacos.
cmd_menu() {
  menu_render "${1:-}"
}

# --- Dispatch guard -----------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  cmd_menu "${1:-}"
fi
