#!/usr/bin/env bash
#
# OmacOS bootstrap.
#
# Usage:
#   ./install.sh           # default: symlink configs from this repo
#   ./install.sh --copy    # write fresh copies instead of symlinking
#
# Identity (optional, otherwise prompted later):
#   GIT_USER_NAME="..." GIT_USER_EMAIL="..." ./install.sh
#
# Locale (optional, defaults shown):
#   OMACOS_LOCALE=en_AU OMACOS_KEYBOARD_LAYOUT=USInternational-PC ./install.sh
#
# Idempotent: safe to re-run. Existing user configs are backed up before
# being replaced.
#
set -euo pipefail

# --- Tokyo Night colorized output -------------------------------------------
BG='\033[48;2;26;27;38m'
BLUE='\033[38;2;122;162;247m'
PURPLE='\033[38;2;187;154;247m'
GREEN='\033[38;2;158;206;106m'
YELLOW='\033[38;2;224;175;104m'
RED='\033[38;2;247;118;142m'
DIM='\033[38;2;86;95;137m'
BOLD='\033[1m'
RESET='\033[0m'

banner() {
  printf "\n${BG}${PURPLE}${BOLD}                                                  ${RESET}\n"
  printf "${BG}${PURPLE}${BOLD}    OmacOS: opinionated macOS, Tokyo Night       ${RESET}\n"
  printf "${BG}${PURPLE}${BOLD}                                                  ${RESET}\n\n"
}
step()  { printf "\n${PURPLE}==[ %s ]==${RESET}\n" "$1"; }
info()  { printf "${BLUE}==>${RESET} %s\n" "$1"; }
ok()    { printf "${GREEN} ok${RESET} %s\n" "$1"; }
warn()  { printf "${RED} !! ${RESET}%s\n" "$1"; }
note()  { printf "${PURPLE} MANUAL${RESET} %s\n" "$1"; }

# --- Guards ------------------------------------------------------------------
if [[ "$(uname -s)" != "Darwin" ]]; then
  warn "OmacOS is macOS only. Got $(uname -s)."
  exit 1
fi

# --- Full Disk Access pre-flight ---------------------------------------------
# Some system commands (systemsetup, TCC writes) require the terminal app to
# have Full Disk Access. We detect this early and open System Settings so the
# user can grant it before the install proceeds.
check_full_disk_access() {
  # systemsetup -getremoteappleevents exits with "privileges" message if FDA missing
  sudo systemsetup -getremoteappleevents &>/dev/null
}

if ! check_full_disk_access; then
  printf "\n${YELLOW:-}⚠️  Full Disk Access required${RESET}\n"
  printf "Some installation steps need Full Disk Access for your terminal.\n\n"
  printf "Opening System Settings → Privacy & Security → Full Disk Access...\n\n"
  open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
  printf "1. Find ${BOLD:-}Terminal${RESET} (or your terminal app) in the list\n"
  printf "2. Enable the toggle\n"
  printf "3. Press ${BOLD:-}Enter${RESET} here to continue\n\n"
  read -r -p "Press Enter once Full Disk Access is granted... "
  printf "\n"
fi

# --- Args --------------------------------------------------------------------
LINK_MODE="symlink"
for a in "$@"; do
  case "$a" in
    --copy) LINK_MODE="copy" ;;
    --symlink) LINK_MODE="symlink" ;;
    -h|--help)
      sed -n '3,17p' "$0"
      exit 0
      ;;
    *) warn "Unknown arg: $a"; exit 2 ;;
  esac
done

# --- Paths -------------------------------------------------------------------
OMACOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export OMACOS_ROOT
STATE_DIR="$HOME/.config/omacos"
mkdir -p "$STATE_DIR"
echo "$OMACOS_ROOT" > "$STATE_DIR/root"

TS="$(date +%Y%m%d-%H%M%S)"
MANUAL_STEPS=()
add_manual() { MANUAL_STEPS+=("$1"); }

backup_if_needed() {
  local target="$1"
  if [[ -e "$target" || -L "$target" ]]; then
    if [[ -L "$target" && "$(readlink "$target")" == "$2" ]]; then
      return 1
    fi
    local bak="$target.bak.$TS"
    mv "$target" "$bak"
    info "Backed up existing $target to $bak"
  fi
  return 0
}

link_or_copy() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if backup_if_needed "$dst" "$src"; then
    if [[ "$LINK_MODE" == "symlink" ]]; then
      ln -s "$src" "$dst"
      ok "Linked $dst -> $src"
    else
      cp "$src" "$dst"
      ok "Copied $src -> $dst"
    fi
  else
    ok "$dst already symlinked correctly"
  fi
}

banner

# --- 1. Prereqs (Xcode CLT + Rosetta) ---------------------------------------
step "Prereqs"
bash "$OMACOS_ROOT/install/prereqs.sh"
add_manual "If Xcode CLT prompt appeared, ensure it finished. AeroSpace also needs Accessibility access."

# --- 2. Homebrew ------------------------------------------------------------
step "Homebrew"
bash "$OMACOS_ROOT/install/homebrew.sh"
if [[ -x /opt/homebrew/bin/brew ]]; then eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then eval "$(/usr/local/bin/brew shellenv)"; fi

# --- 3. Packages ------------------------------------------------------------
step "Packages"
bash "$OMACOS_ROOT/install/packages.sh"

# --- 4. TPM (tmux plugin manager) -------------------------------------------
step "tmux plugins"
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ -d "$TPM_DIR/.git" ]]; then
  ok "TPM already installed"
else
  info "Cloning TPM into $TPM_DIR"
  mkdir -p "$HOME/.tmux/plugins"
  git clone --quiet --depth=1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
  ok "TPM installed"
fi

# --- 5. Languages (mise + uv) -----------------------------------------------
step "Languages"
bash "$OMACOS_ROOT/install/languages.sh"

# --- 6. Shell wiring (managed ~/.zshrc block) -------------------------------
step "Shell"
bash "$OMACOS_ROOT/install/shell.sh"

# --- 7. Git + GitHub --------------------------------------------------------
step "Git"
bash "$OMACOS_ROOT/install/git.sh"
add_manual "Run 'gh auth login' to authenticate with GitHub"
add_manual "If GIT_USER_NAME/EMAIL were unset, set them with 'git config --global user.name/.email'"

# --- 8. Claude Code ---------------------------------------------------------
step "Claude Code"
bash "$OMACOS_ROOT/install/claude-code.sh"
add_manual "Claude Code: sign in with a paid Anthropic plan or set ANTHROPIC_API_KEY"

# --- 9. Docker --------------------------------------------------------------
step "Docker Desktop"
bash "$OMACOS_ROOT/install/docker.sh"
add_manual "Open Docker Desktop once to finish setup"

# --- 10. Configs -------------------------------------------------------------
step "Configs (${LINK_MODE})"
link_or_copy "$OMACOS_ROOT/config/aerospace.toml"     "$HOME/.config/aerospace/aerospace.toml"
link_or_copy "$OMACOS_ROOT/config/ghostty.config"     "$HOME/.config/ghostty/config"
link_or_copy "$OMACOS_ROOT/config/tmux.conf"          "$HOME/.tmux.conf"
link_or_copy "$OMACOS_ROOT/config/nvim"               "$HOME/.config/nvim"

# Tmux plugins (TPM + resurrect + continuum). Runs AFTER tmux.conf is linked
# so install_plugins.sh can read the @plugin entries from ~/.tmux.conf.
bash "$OMACOS_ROOT/install/tmux.sh"

# Zed: merge the base font/theme keys into ~/.config/zed/settings.json,
# preserving any user-tuned keys. `omacos theme set` will then overlay the
# theme key on top.
zed_target="$HOME/.config/zed/settings.json"
zed_overlay="$OMACOS_ROOT/config/zed.settings.json"
mkdir -p "$(dirname "$zed_target")"
if [[ -f "$zed_target" ]]; then
  cp "$zed_target" "$zed_target.bak.$TS"
  python3 - "$zed_overlay" "$zed_target" <<'PY'
import json, sys
o_path, t_path = sys.argv[1], sys.argv[2]
def load(p):
    try:
        with open(p) as f: return json.load(f)
    except Exception:
        return {}
o = load(o_path); t = load(t_path)
if not isinstance(t, dict): t = {}
if not isinstance(o, dict): o = {}
t.update(o)
with open(t_path, 'w') as f:
    json.dump(t, f, indent=2); f.write("\n")
PY
  ok "Merged base Zed font/theme keys into $zed_target"
else
  cp "$zed_overlay" "$zed_target"
  ok "Wrote base Zed settings to $zed_target"
fi

# --- 10. Neovim bootstrap (headless: plugins + treesitter + LSP servers) ----
step "Neovim bootstrap"
if command -v nvim >/dev/null 2>&1; then
  info "Installing plugins (this may take a minute)"
  nvim --headless "+Lazy! sync" +qa 2>/dev/null || warn "Lazy sync had warnings (often benign)"
  info "Compiling tree-sitter parsers"
  nvim --headless "+TSUpdate" +qa 2>/dev/null || warn "TSUpdate had warnings (often benign)"
  info "Installing LSP servers via Mason"
  nvim --headless "+MasonInstall basedpyright ruff vtsls gopls rust-analyzer lua-language-server bash-language-server" +qa 2>/dev/null \
    || warn "Mason install had warnings; check ':checkhealth mason' in nvim"
  ok "Neovim bootstrap finished"
else
  warn "nvim not on PATH; skipping bootstrap"
fi

# --- 11. macOS defaults ------------------------------------------------------
step "macOS appearance, Dock, input, locale"
bash "$OMACOS_ROOT/macos/appearance.sh"
bash "$OMACOS_ROOT/macos/dock.sh"
bash "$OMACOS_ROOT/macos/input.sh"
bash "$OMACOS_ROOT/macos/locale.sh"
bash "$OMACOS_ROOT/macos/defaults.sh"
bash "$OMACOS_ROOT/macos/keyboard.sh"
bash "$OMACOS_ROOT/macos/security.sh"

# --- 12. Apply theme --------------------------------------------------------
step "Theme"
"$OMACOS_ROOT/bin/omacos" theme set tokyonight

# Manual steps that the theme/macos scripts already added are captured;
# add install-level reminders.
add_manual "Grant AeroSpace Accessibility access: System Settings > Privacy and Security > Accessibility"
add_manual "Open Zed once and install 'Tokyo Night Themes' (Cmd+Shift+P > zed: extensions)"
add_manual "Appearance > Icon and Widget Style: Dark (or Tinted with blue/purple)"
add_manual "Appearance > Folder Color: Purple"
add_manual "If keyboard layout (US International) did not stick, set it manually in Keyboard > Text Input > Edit"
add_manual "Log out and back in for key repeat, locale, and input source to fully take effect"

# --- Summary -----------------------------------------------------------------
step "Done"
ok "OmacOS bootstrap finished."
printf "\n${PURPLE}MANUAL steps to finish your setup:${RESET}\n"
for s in "${MANUAL_STEPS[@]}"; do
  printf "  ${DIM}-${RESET} %s\n" "$s"
done
printf "\nRun ${BLUE}omacos doctor${RESET} to verify everything.\n"
