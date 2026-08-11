# OmacOS

One-command macOS setup. 10 themes. Interactive menu. Modular and re-runnable.

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
- Node.js 24 (LTS)
- Python 3.14 (plus uv for package management)
- Go 1.26
- Rust 1.96 (with rustfmt, clippy, rust-analyzer, rust-src)

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

4. **Zed theme extensions**: Open Zed, press Cmd+Shift+X, and install any theme extensions you want to use. The extensions needed by the built-in themes are pre-listed in `config/zed.extensions` and install automatically when Zed first opens. For reference: Tokyo Night, Catppuccin, Nord, Everforest, and Kanagawa are extensions; Gruvbox Dark, Rose Pine, One Dark, and Solarized Dark are built into Zed.

5. **macOS Sequoia appearance tweaks**: System Settings > Appearance lets you set Icon Style and Folder Color. These settings have no stable scriptable defaults keys, so they require manual selection.

6. **LuLu network extension**: On first launch, LuLu prompts to approve its system/network extension. System Settings > Privacy and Security, allow the extension for the firewall to filter traffic.

7. **Restart your shell**: Open a new terminal window, or run `source ~/.zshrc`.

---

## Theme System

OmacOS ships 10 app-level themes. Themes cover Ghostty, tmux, Starship, Neovim, Zed, and zsh. Each theme also bundles a curated public-domain painting as a wallpaper (see [Wallpapers](#wallpapers) below).

### Available themes

| Name | Style |
|------|-------|
| `tokyonight` | Tokyo Night Night (default) |
| `catppuccin` | Catppuccin Mocha |
| `nord` | Nord |
| `everforest` | Everforest Dark Hard |
| `gruvbox` | Gruvbox Dark |
| `kanagawa` | Kanagawa Wave |
| `rose-pine` | Rose Pine Main |
| `ristretto` | Monokai Pro ristretto filter |
| `matte-black` | vague (dark, desaturated minimal) |
| `osaka-jade` | Solarized Osaka (solarized-osaka.nvim) |

### Interactive menu

```bash
omacos
```

Opens the gum-powered interactive menu. Requires `gum` (installed via Brewfile). Without gum, falls back to `omacos help`.

### Apply a theme

```bash
omacos theme set catppuccin
```

### List available themes

```bash
omacos theme list
```

### Theme file structure

Each `themes/<name>/` directory ships these files:

| File | Purpose |
|------|---------|
| `ghostty.conf` | Ghostty terminal colors |
| `tmux.conf` | tmux status bar colors |
| `zed.json` | Zed theme name |
| `starship.toml` | Starship palette block |
| `nvim.lua` | Neovim colorscheme setup |
| `zsh.zsh` | zsh-autosuggestions and zsh-syntax-highlighting colors |
| `wallpaper.jpg` | Bundled wallpaper (public-domain painting, 2560px wide) |

The `starship.toml` in a theme defines a `[palettes.active]` block that gets concatenated onto `config/starship.toml`. The base config uses named palette colors (blue, green, etc.), so themes only need to override those color values.

### Add a new theme

1. Create `themes/mytheme/` with the 6 required files listed above.
2. Run `omacos theme set mytheme`.
3. Optionally add `themes/mytheme/wallpaper.jpg` (JPEG, 2560px wide) to enable `omacos wallpaper mytheme`.

---

## Wallpapers

Each theme bundles a curated public-domain painting as `themes/<name>/wallpaper.jpg`. The `omacos wallpaper` command applies it to the macOS desktop.

### Apply a wallpaper

```bash
omacos wallpaper            # apply the active theme's wallpaper
omacos wallpaper catppuccin # apply a specific theme's wallpaper
```

The first run triggers a one-time macOS Automation permission prompt. If macOS blocks it, open System Settings > Privacy & Security > Automation and enable the terminal that ran the command, then retry.

### Auto-swap on theme change

By default, `omacos theme set` does not touch your wallpaper (`manual` mode). To swap automatically on every theme change:

```bash
omacos wallpaper auto    # enable auto-swap
omacos wallpaper manual  # restore manual control (default)
```

Under `auto` mode, `omacos update` re-applies the current theme's wallpaper as part of its re-apply step. No visible change occurs since it's the same image.

### Regenerate wallpapers

`tools/fetch-wallpapers.sh` re-fetches all wallpapers from Wikimedia Commons and repacks them to 2560px JPEG (quality 82). Sources are listed in `tools/wallpapers.manifest`.

### Provenance

All bundled wallpapers are public domain (pre-1929 or explicitly PD) or released under CC0.

| Theme | Artwork | License |
|-------|---------|---------|
| `tokyonight` | Kobayashi Kiyochika, The Sumida River at Night (1881) | Public Domain |
| `kanagawa` | Katsushika Hokusai, The Great Wave off Kanagawa (c.1831) | Public Domain |
| `nord` | Harald Sohlberg, Winter Night in the Mountains (1914) | Public Domain |
| `everforest` | Aerial view of a forest, Maria Mekht (2016) | CC0 |
| `gruvbox` | Isaac Levitan, Golden Autumn (1895) | Public Domain |
| `rose-pine` | Henri Fantin-Latour, Roses de Nice on a Table (1882) | Public Domain |
| `catppuccin` | Vincent van Gogh, Cafe Terrace at Night (1888) | Public Domain |
| `ristretto` | Pieter Claesz, Breakfast (1646) | Public Domain |
| `osaka-jade` | Utagawa Hiroshige, Ships Arriving at Hachikenya, Osaka (1834) | Public Domain |
| `matte-black` | James McNeill Whistler, Nocturne: Blue and Gold, Southampton Water (1872) | Public Domain |

---

## CLI Reference

```
omacos                     Open interactive theme/action menu (requires gum)
omacos menu [route]        Open menu at a specific route (e.g. theme)
omacos theme set <name>    Apply a theme to all tools
omacos theme list          List available themes
omacos update              Update Homebrew packages, Claude Code, and re-apply theme
omacos snapshot [label]    Take a macOS defaults snapshot
omacos export [dir]        Export Brewfile + key defaults plists with a restore.sh
omacos wallpaper [theme]   Apply a theme's wallpaper (default: active theme)
omacos wallpaper auto      Swap wallpaper automatically on theme change
omacos wallpaper manual    Disable auto-swap (default)
omacos doctor              Check system health, print pass/fail for all components
omacos uninstall           Revert the install (security + configs + state by default)
omacos help                Print command reference
```

---

## Uninstall

```bash
omacos uninstall                  # security + configs + state
omacos uninstall --dry-run        # preview only, no changes
omacos uninstall --all            # also restore defaults + remove packages
omacos uninstall --defaults       # also restore macOS defaults from baseline
omacos uninstall --packages       # also remove OmacOS-added Homebrew packages
```

`omacos uninstall` reverts what the installer applied. It runs three default tiers and accepts two opt-in flags.

**Default tiers (always run):**

- **`security`**: re-enables Remote Login (SSH) and Remote Apple Events, restores `/etc/hosts` from the timestamped backup (or strips just the OmacOS blocked-endpoints block if no backup exists), re-enables the Weather and News daemons, and resets the `system.preferences` admin-password requirement. Skipped automatically if MDM manages those settings.
- **`configs`**: removes OmacOS-owned config symlinks (only those pointing back into the repo), restores backups where present, strips the `# >>> omacos >>>` managed blocks from `~/.zshenv` and `~/.zshrc`, and removes the generated `~/.config/starship.toml`. Files you've modified that have no backup are left alone.
- **`state`**: removes `~/.config/omacos` and the generated theme overlays.

**Opt-in tiers:**

- **`--defaults`**: restores macOS `defaults` from the pre-install baseline captured by `macos/baseline.sh` (see caveat below).
- **`--packages`**: runs `brew rm` on only the packages OmacOS added. Packages that were already installed before OmacOS aren't touched.
- **`--all`**: shorthand for both `--defaults` and `--packages`.

Applying any non-dry-run tier requires you to type `YES` exactly when prompted. `--dry-run` prints the plan for every selected tier without making changes.

### Caveat: `--defaults` restores the whole domain

The baseline is a `defaults export` snapshot taken during install, before OmacOS writes any settings. Replaying it with `defaults import` replaces the entire domain, so it also reverts unrelated Finder, Dock, Safari, and global preferences you changed after install. The baseline reflects your machine's pre-OmacOS state, not macOS factory defaults. It's opt-in, gated behind a `YES` confirmation, and previewable with `--dry-run`.

### Caveat: Neovim lockfile churn

`config/nvim` is symlinked into `~/.config/nvim`, so `:Lazy sync` and `omacos update` write through the symlink into the tracked `config/nvim/lazy-lock.json`, dirtying the working tree. The [Reproducibility](#reproducibility) section covers this. Commit the lockfile change intentionally when you mean to bump it.

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
