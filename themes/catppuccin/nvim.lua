-- SPDX-License-Identifier: Apache-2.0
-- Catppuccin Mocha colorscheme for Neovim.
-- Copied to ~/.config/nvim/theme.lua by `omacos theme set catppuccin`.

require("catppuccin").setup({
  flavour = "mocha",
  transparent_background = false,
  styles = {
    comments = { italic = true },
    keywords = { italic = false },
  },
})
vim.cmd.colorscheme("catppuccin")
