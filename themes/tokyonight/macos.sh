#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# Tokyo Night macOS overlay: theme-owned colors (accent, highlight, wallpaper).
# Run by `omacos theme set tokyonight`. Re-runnable.
#
set -euo pipefail

# shellcheck source=lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../lib/common.sh"

info "Applying Tokyo Night macOS overlay"

THEME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Accent: Blue (4) matches Tokyo Night's #7aa2f7 better than Purple (5) which
# renders as hot-pink/magenta in macOS. There is no custom-hex accent support.
defaults write -g AppleAccentColor -int 4
ok "Accent color: blue (preset 4, ~#7aa2f7)"

# Highlight color: actual hex is allowed here.
defaults write -g AppleHighlightColor -string "0.478431 0.635294 0.968627 Blue"
ok "Highlight color: ~#7aa2f7"

# Terminal.app: inject Tokyo Night profile directly into preferences (the
# `open -a Terminal file.terminal` import path is unreliable on some macOS
# versions). We read current prefs, upsert the TokyoNight key, write back.
terminal_profile="$THEME_DIR/terminal.terminal"
if [[ -f "$terminal_profile" ]] && command -v python3 >/dev/null 2>&1; then
  python3 - "$terminal_profile" <<'PY'
import plistlib, subprocess, sys

profile_path = sys.argv[1]
with open(profile_path, 'rb') as f:
    profile = plistlib.load(f)

r = subprocess.run(['defaults', 'export', 'com.apple.Terminal', '-'], capture_output=True)
prefs = plistlib.loads(r.stdout)
ws = prefs.get('Window Settings', {})
ws[profile['name']] = profile
prefs['Window Settings'] = ws
prefs['Default Window Settings'] = profile['name']
prefs['Startup Window Settings'] = profile['name']
data = plistlib.dumps(prefs, fmt=plistlib.FMT_XML)
subprocess.run(['defaults', 'import', 'com.apple.Terminal', '-'], input=data, check=True)
PY
  ok "Terminal.app: TokyoNight profile injected and set as default"
else
  note "terminal.terminal not found in $THEME_DIR; skipping Terminal.app theme"
fi

# Wallpaper: shipped with the theme.
wp="$THEME_DIR/wallpaper.png"
if [[ -f "$wp" ]]; then
  if osascript -e "tell application \"System Events\" to tell every desktop to set picture to POSIX file \"$wp\"" >/dev/null 2>&1; then
    ok "Wallpaper applied to all desktops: $wp"
  else
    note "osascript could not set the wallpaper (Automation permission?); set it by hand to $wp"
  fi
else
  note "No wallpaper.png shipped in $THEME_DIR; install.sh should have generated one"
fi

cat <<MANUAL

${PURPLE}MANUAL steps (no stable defaults keys on Tahoe):${RESET}
  ${DIM}-${RESET} System Settings > Appearance > Icon and Widget Style: ${PURPLE}Dark${RESET} (safe) or Tinted with blue/purple
  ${DIM}-${RESET} System Settings > Appearance > Folder Color: ${PURPLE}Purple${RESET}

MANUAL
