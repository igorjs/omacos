# OmacOS

One-command macOS setup. Tokyo Night themed. Modular and re-runnable.

OmacOS is the macOS equivalent of [Omakub](https://omakub.org/) and [Omarchy](https://omarchy.org/): a single `./install.sh` that turns a fresh Mac into a fully configured development environment. Every script is idempotent, so you can re-run it safely at any time. Configs are symlinked from the repo by default, so your settings stay version-controlled.

---

## Why "OmacOS"?

**Omakase** (お任せ) is a Japanese phrase meaning roughly "I leave it up to you," from the verb *makaseru*, to entrust. In a sushi restaurant, ordering omakase means handing the decisions to the chef: no menu, no choosing, you trust their judgment to serve the best of what they have. It is the opposite of a la carte.

OmacOS applies that idea to a Mac dev environment: rather than making you pick every tool and setting, it ships opinionated, curated defaults that you trust and set up with one command. The name is Omakase + macOS, in the spirit of Omakub (Ubuntu) and Omarchy (Arch).

---

## Prerequisites

- A Mac running macOS Sequoia (15) or later
- An internet connection
- That's it

The installer handles Xcode Command Line Tools, Rosetta 2 (Apple Silicon), Homebrew, and everything else automatically.

---

## Installation

```bash
git clone https://github.com/igorjs/omacos.git ~/omacos
cd ~/omacos
./install.sh
```

Or, to copy config files instead of symlinking them:

```bash
./install.sh --copy
```

---

## What Gets Installed

### Window Manager
- **AeroSpace** - tiling window manager with Vim-style keybindings (Alt+hjkl to focus, Alt+Shift+hjkl to move)

### Terminal
- **Ghostty** - GPU-accelerated terminal with Tokyo Night theme and JetBrainsMono Nerd Font
- **tmux** - terminal multiplexer with Tokyo Night status bar

### Editor
- **Zed** - primary editor (`EDITOR="zed --wait"`, `git core.editor = "zed --wait"`), Tokyo Night theme
- **Neovim 0.11+** - terminal fallback editor, configured with lazy.nvim, Treesitter, native LSP, and blink.cmp completion

### Shell
- **Starship** - fast cross-shell prompt with git status, Tokyo Night colors
- zsh-autosuggestions - fish-style suggestions as you type
- zsh-syntax-highlighting - command syntax coloring

### CLI Tools
- ripgrep, fd, fzf, jq, bat, eza, zoxide, lazygit, gh

### Languages (via mise)
- Node.js 22 (LTS)
- Python 3.13 (plus uv for package management)
- Go 1.24
- Rust 1.85 (with rustfmt, clippy, rust-analyzer, rust-src)

### Containers
- **Docker Desktop** - note: requires one manual launch to complete setup

### Security
- **LuLu** - Objective-See firewall that alerts on outgoing network connections
- **OverSight** - Objective-See monitor for microphone and webcam access
- **KnockKnock** - Objective-See scanner for persistently installed software
- **TaskExplorer** - Objective-See process explorer
- **ClamAV** - open-source antivirus engine (run `freshclam` to fetch signatures)

### AI
- **Claude Code** - Anthropic's AI coding tool (requires a paid Anthropic plan or API key)

---

## Post-Install Manual Steps

After the installer finishes, a few things require manual action:

1. **AeroSpace Accessibility permission**: System Settings > Privacy and Security > Accessibility, toggle on AeroSpace. Required for window management to work.

2. **Docker Desktop first launch**: Open Spotlight (Cmd+Space), search "Docker", launch it. Accept the license and allow the helper tool installation.

3. **GitHub CLI authentication**:
   ```bash
   gh auth login
   ```

4. **Zed: Tokyo Night extension**: Open Zed, press Cmd+Shift+X, search "Tokyo Night", install the extension.

5. **macOS Sequoia appearance tweaks**: System Settings > Appearance lets you set Icon Style and Folder Color. These settings have no stable scriptable defaults keys, so they require manual selection.

6. **LuLu network extension**: On first launch, LuLu prompts to approve its system/network extension. System Settings > Privacy and Security, allow the extension for the firewall to filter traffic.

7. **Restart your shell**: Open a new terminal window, or run `source ~/.zshrc`.

---

## Theme System

OmacOS ships with the **Tokyo Night** theme. Themes live in `themes/<name>/` and consist of:

| File | Purpose |
|------|---------|
| `ghostty.conf` | Ghostty theme line |
| `tmux.conf` | tmux status bar colors |
| `zed.json` | Zed theme setting |
| `starship.toml` | Starship color palette |
| `nvim.lua` | Neovim colorscheme |
| `zsh.zsh` | zsh-autosuggestions and zsh-syntax-highlighting colors |
| `macos.sh` | macOS accent color and wallpaper |
| `wallpaper.png` | Desktop wallpaper |

### Apply a theme

```bash
omacos theme set tokyonight
```

### List available themes

```bash
omacos theme list
```

### Add a new theme

1. Create `themes/mytheme/` with the files listed above.
2. Run `omacos theme set mytheme`.

The `starship.toml` in a theme defines a `[palettes.active]` block that gets concatenated onto `config/starship.toml`. The base config uses named palette colors (blue, green, etc.), so themes only need to override those color values.

---

## CLI Reference

```
omacos theme set <name>    Apply a theme to all tools
omacos theme list          List available themes
omacos update              Update Homebrew packages, Claude Code, and re-apply theme
omacos snapshot [label]    Take a macOS defaults snapshot
omacos export [dir]        Export Brewfile + key defaults plists with a restore.sh
omacos doctor              Check system health, print pass/fail for all components
```

---

## Settings Snapshot Tool

`tools/mac-snapshot.sh` lets you capture and diff macOS `defaults` before and after changing a setting in System Settings, so you can find the exact `defaults write` command to reproduce it.

### Take a snapshot

```bash
tools/mac-snapshot.sh snapshot before-changes
```

### Watch for changes (interactive)

```bash
tools/mac-snapshot.sh watch
```

This takes a before snapshot, prompts you to change one setting, then takes an after snapshot and shows you exactly what changed, including suggested `defaults write` commands to add to `macos/defaults.sh`.

### List snapshots

```bash
tools/mac-snapshot.sh list
```

### Diff two snapshots

```bash
tools/mac-snapshot.sh diff before-changes after-changes
```

### Export current settings

```bash
tools/mac-snapshot.sh export
# or via the CLI:
omacos export
```

Exports a `Brewfile`, key domain plists, and a `restore.sh` script.

---

## Language Runtimes (mise)

[mise](https://mise.jdx.dev/) manages language runtimes globally and per-project. Global versions are set during install. Per-project versions are configured in a `.mise.toml` file in the project root.

A sample `.mise.toml` is included at the repo root. Copy it to any project to pin versions:

```bash
cp ~/omacos/.mise.toml myproject/.mise.toml
```

mise activates automatically on `cd` into a directory with a `.mise.toml`.

### Reproducibility

Runtime versions are pinned in `install/languages.sh` (concrete versions, not floating aliases like `lts` or `latest`). The Neovim plugin lockfile (`config/nvim/lazy-lock.json`) is version-controlled; run `:Lazy sync` to update it, then commit the change intentionally.

The Brewfile deliberately floats to the latest formula versions — Homebrew has no general Brewfile version lock. Package versions are not pinned; re-running the install may pick up newer releases. This is an accepted trade-off for keeping the toolchain current.

### uv for Python packages

Rather than `pip install`, use [uv](https://docs.astral.sh/uv/) for fast, reproducible Python package management:

```bash
uv init myproject
uv add requests
uv run python main.py
```

### Rust via mise

mise installs Rust via rustup. The rust-analyzer component is included, so it works out of the box in Neovim and Zed.

---

## Known Quirks

- **TPM plugin install focus**: After pressing `prefix+I` to install tmux plugins, the "Done, press ENTER" screen requires a mouse click before Enter works. This is a macOS window-focus edge case triggered by TPM's install overlay. It only happens during plugin installation (once per machine).

- **Full Disk Access prompt during install**: `install.sh` checks for Full Disk Access and pauses if it is not granted. Open System Settings > Privacy and Security > Full Disk Access, enable the terminal running the install, then press Enter to continue.

- **security.sh requires sudo**: `macos/security.sh` (firewall, SSH, mDNS) needs `sudo`. If running in a non-interactive context where sudo isn't pre-authenticated, it will prompt. Run `sudo -v` first or execute it manually: `bash macos/security.sh`.

- **Safari privacy defaults**: macOS sandboxes Safari's preferences. The `SendDoNotTrackHTTPHeader` default can only be written after Safari has been opened at least once. The installer silently skips it otherwise.

---

## Honest macOS Limits

A few things cannot be fully scripted on macOS:

- **Accent color** is capped at 8 Apple presets. There is no stable way to set an arbitrary hex color as the system accent. `defaults write -g AppleAccentColor -int 5` sets "Purple" (closest to Tokyo Night's `#bb9af7`).

- **Sequoia Icon Style and Folder Color** have no stable scriptable defaults keys as of this writing. Set them in System Settings > Appearance.

- **Window chrome** (titlebars, traffic lights) cannot be arbitrarily themed system-wide. Individual apps like Ghostty use `window-decoration = false` to hide their chrome.

- **Keyboard layout** changes typically require a logout to register. The `macos/locale.sh` sets the defaults key, but you may need to also add the layout manually in System Settings > Keyboard > Text Input > Edit.

Use `tools/mac-snapshot.sh watch` to discover new scriptable keys as macOS evolves.

---

## Adding Future Themes

To add Catppuccin, Gruvbox, or any other theme:

1. Create `themes/catppuccin/` (or your theme name).
2. Add each file following the pattern of `themes/tokyonight/`.
3. The `starship.toml` in your theme should define `[palettes.active]` with the same color names (blue, cyan, green, red, yellow, purple, fg, muted).
4. Test with: `omacos theme set catppuccin`

---

## v2 Roadmap

Features noted for a future v2 release:

- **Raycast** - launcher and productivity tool (would replace Spotlight usage)
- **Sketchybar** - custom menu bar with Tokyo Night styling

These are intentionally excluded from v1 to keep the initial setup minimal and reliable. Uncomment the relevant lines in `Brewfile` to install them manually.

---

## Inspiration

- [Omakub](https://omakub.org/) by DHH - the Ubuntu equivalent
- [Omarchy](https://omarchy.org/) - Arch Linux variant
- [Tokyo Night](https://github.com/folke/tokyonight.nvim) color scheme by Folke Vereecken
