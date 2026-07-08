# Changelog

All notable changes to OmacOS are documented here.

---

## [1.0.0] - 2026-06-08

Initial release.

### Added

**Bootstrap**
- `install.sh` — idempotent one-command setup with Full Disk Access pre-flight check
- `install/prereqs.sh` — Xcode CLT and Rosetta 2 (Apple Silicon)
- `install/homebrew.sh` — Homebrew install and update
- `install/packages.sh` — Brewfile-driven package install
- `install/languages.sh` — mise (Node LTS, Python, Go, Rust) and uv
- `install/shell.sh` — managed `~/.zshrc` block with ordered hooks
- `install/git.sh` — global git config, Zed as core.editor, GitHub CLI
- `install/claude-code.sh` — Claude Code CLI
- `install/docker.sh` — Docker Desktop
- `install/tmux.sh` — TPM clone and headless plugin install (resurrect + continuum)

**macOS**
- `macos/appearance.sh` — Dark Mode, accent color (Blue), highlight color
- `macos/dock.sh` — Dock size, position, auto-hide
- `macos/input.sh` — key repeat, trackpad
- `macos/locale.sh` — locale, keyboard layout
- `macos/defaults.sh` — Finder, screenshots, global UI, Stage Manager off, widgets off
- `macos/keyboard.sh` — disables conflicting system shortcuts (Mission Control Ctrl+Up/Down, Space-switching Ctrl+Left/Right) via PlistBuddy
- `macos/security.sh` — firewall stealth mode, SSH/Remote Apple Events off, Siri off, analytics/advertising opt-outs, screen lock, AirDrop/Handoff off, iCloud local default

**Configs**
- `config/ghostty.config` — Ghostty terminal: Tokyo Night, JetBrainsMono Nerd Font, tmux-native keybindings (Cmd+T/W/D/1-9, pane splits/navigation)
- `config/tmux.conf` — tmux: Ctrl+A prefix, Tokyo Night tab-style status bar, TPM with resurrect/continuum, allow-passthrough for clickable links
- `config/aerospace.toml` — AeroSpace tiling window manager
- `config/nvim/` — Neovim with lazy.nvim, Treesitter, native LSP, blink.cmp
- `config/zed.settings.json` — Zed base font/theme settings
- `config/starship.toml` — Starship prompt base config

**Theme system**
- `bin/omacos` — CLI: `theme set/list`, `update`, `snapshot`, `export`, `doctor`
- `themes/tokyonight/` — Tokyo Night theme for Ghostty, tmux, Zed, Neovim, Starship, zsh, macOS accent/wallpaper
- `tools/mac-snapshot.sh` — before/after macOS defaults diff tool
- `tools/gen-wallpaper.sh` — Tokyo Night wallpaper generator

### Known quirks

- TPM `prefix+I` install screen requires a mouse click before Enter registers (macOS focus edge case)
- `macos/security.sh` requires sudo; run `sudo -v` first in non-interactive contexts
- Safari privacy defaults are sandboxed and only apply after Safari has been opened once
