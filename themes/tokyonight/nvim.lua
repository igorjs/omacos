-- Tokyo Night colorscheme for Neovim.
-- Copied to ~/.config/nvim/theme.lua by `omacos theme set tokyonight`.
-- Pin style = "night" so plain `tokyonight` renders the dark #1a1b26 palette
-- (matching Ghostty TokyoNight, Zed Tokyo Night, tmux/Starship hex). Without
-- this pin the plugin drifts to a lighter default.

require("tokyonight").setup({
  style = "night",
  transparent = false,
  styles = {
    comments = { italic = true },
    keywords = { italic = false },
  },
})
vim.cmd.colorscheme("tokyonight")
