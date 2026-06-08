#!/usr/bin/env bash
#
# git + gh configuration.
# git and gh are installed by the Brewfile; this script sets identity and
# opinionated defaults. gh auth login remains a MANUAL step.
#
# Identity is user-configurable. Set GIT_USER_NAME and GIT_USER_EMAIL in the
# environment to skip the prompt:
#   GIT_USER_NAME="Ada Lovelace" GIT_USER_EMAIL="ada@example.com" ./install.sh
#
set -euo pipefail

BLUE='\033[38;2;122;162;247m'; GREEN='\033[38;2;158;206;106m'
PURPLE='\033[38;2;187;154;247m'; RED='\033[38;2;247;118;142m'; RESET='\033[0m'
info(){ printf "${BLUE}==>${RESET} %s\n" "$1"; }
ok(){   printf "${GREEN} ok${RESET} %s\n" "$1"; }
note(){ printf "${PURPLE} MANUAL${RESET} %s\n" "$1"; }
warn(){ printf "${RED} !! ${RESET}%s\n" "$1"; }

command -v git >/dev/null 2>&1 || { warn "git not on PATH; run install/packages.sh first"; exit 1; }

# --- Opinionated git defaults (only set if not already set) -----------------
set_if_unset() {
  local key="$1" value="$2"
  if git config --global --get "$key" >/dev/null 2>&1; then
    ok "git $key already set"
  else
    git config --global "$key" "$value"
    ok "git $key = $value"
  fi
}

set_if_unset init.defaultBranch       "main"
set_if_unset pull.rebase              "true"
set_if_unset push.autoSetupRemote     "true"
set_if_unset core.editor              "zed --wait"

# --- Identity ---------------------------------------------------------------
GIT_USER_NAME="${GIT_USER_NAME:-$(git config --global --get user.name 2>/dev/null || true)}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-$(git config --global --get user.email 2>/dev/null || true)}"

if [[ -z "$GIT_USER_NAME" ]]; then
  note "git user.name not set; run: git config --global user.name \"Your Name\""
else
  git config --global user.name  "$GIT_USER_NAME"
  ok "git user.name = $GIT_USER_NAME"
fi

if [[ -z "$GIT_USER_EMAIL" ]]; then
  note "git user.email not set; run: git config --global user.email \"you@example.com\""
else
  git config --global user.email "$GIT_USER_EMAIL"
  ok "git user.email = $GIT_USER_EMAIL"
fi

# --- gh authentication is interactive --------------------------------------
if command -v gh >/dev/null 2>&1; then
  if gh auth status >/dev/null 2>&1; then
    ok "gh: authenticated"
  else
    note "Run 'gh auth login' to authenticate with GitHub (browser or token flow)"
  fi
else
  warn "gh not on PATH; was it installed via Brewfile?"
fi
