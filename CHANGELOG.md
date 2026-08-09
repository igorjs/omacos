# Changelog

All notable changes to OmacOS are documented here.

---

## [Unreleased]

### Added

- `omacos wallpaper [theme]`: applies a theme's bundled wallpaper to the macOS desktop
- `omacos wallpaper auto|manual`: opt-in auto-swap mode; when `auto`, every `omacos theme set` also sets the matching wallpaper (default: `manual`, no automatic changes)
- 10 bundled public-domain wallpaper JPEGs (`themes/*/wallpaper.jpg`), one per theme, repacked to 2560px wide JPEG via `sips`
- `tools/fetch-wallpapers.sh`: fetch-and-repack script; sources listed in `tools/wallpapers.manifest`
- `lib/menu.json` Wallpaper item (`omacos wallpaper` action) in the interactive menu
- `tests/wallpaper.bats`: 13 unit tests covering apply, soft-fail, mode toggle, and `cmd_theme_set` integration
- `tests/theme_parity.bats`: new `theme_parity: each theme ships a valid wallpaper.jpg` guard

---

## [1.1.0] - 2026-08-03

### Added

**Interactive menu**
- `gum` added to Brewfile; bare `omacos` now opens an interactive gum menu for theme selection and common actions
- `omacos menu [route]` deep-links into a specific menu route (e.g. `omacos menu theme`)
- `lib/menu.json` — data-driven menu structure (items, icons, actions, providers)
- `lib/menu.sh` — gum renderer, provider system, and dispatch logic
- `omacos doctor` now checks for `gum` in its binary health scan
- `omacos help` / `omacos -h` / `omacos --help` — explicit help alias
- Falls back to `omacos help` when gum is absent

**Theme catalog (9 new themes)**
- `themes/catppuccin/` — Catppuccin Mocha
- `themes/nord/` — Nord
- `themes/everforest/` — Everforest Dark Hard
- `themes/gruvbox/` — Gruvbox Dark
- `themes/kanagawa/` — Kanagawa Wave
- `themes/rose-pine/` — Rose Pine Main
- `themes/ristretto/` — Monokai Pro ristretto filter (Neovim) + One Dark (Zed)
- `themes/matte-black/` — vague.nvim dark minimal (Neovim) + One Dark (Zed)
- `themes/osaka-jade/` — solarized-osaka.nvim (Neovim) + Solarized Dark (Zed)
- `config/zed.extensions` — catppuccin, nord, everforest, kanagawa extensions added
- `config/nvim/init.lua` — 9 colorscheme plugins added (lazy=false, priority=1000 each)

**Tests**
- `tests/theme_parity.bats` — data-driven guard: every `themes/*/` must ship 6 app-level files, valid `zed.json`, a `colorscheme` call in `nvim.lua`, and a cross-check that the colorscheme name is provisioned in `config/nvim/init.lua`

### Changed

- Themes are now app-level only (Ghostty, tmux, Starship, Neovim, Zed, zsh). macOS accent and wallpaper are permanent manual steps set during install.
- `themes/tokyonight/macos.sh`, `themes/tokyonight/wallpaper.png`, and `tools/gen-wallpaper.sh` removed; `macos/appearance.sh` and `macos/defaults.sh` updated to reflect this.

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
- `themes/tokyonight/` — Tokyo Night theme for Ghostty, tmux, Zed, Neovim, Starship, zsh
- `tools/mac-snapshot.sh` — before/after macOS defaults diff tool

### Known quirks

- TPM `prefix+I` install screen requires a mouse click before Enter registers (macOS focus edge case)
- `macos/security.sh` requires sudo; run `sudo -v` first in non-interactive contexts
- Safari privacy defaults are sandboxed and only apply after Safari has been opened once
