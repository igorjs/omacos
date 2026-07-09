#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# Docker Desktop is installed via the Brewfile (cask "docker"). This script
# just verifies install and prints the manual first-launch step.
#
# Colima alternative (CLI-only): `brew install colima docker && colima start`
#
set -euo pipefail

# shellcheck source=lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"

if [[ -d "/Applications/Docker.app" ]]; then
  ok "Docker Desktop present at /Applications/Docker.app"
else
  info "Docker Desktop not found; install via Brewfile (cask 'docker') and re-run"
fi

note "Open Docker Desktop once to finish setup (privileged helper install, license accept)."
