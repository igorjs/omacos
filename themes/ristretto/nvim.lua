-- SPDX-License-Identifier: Apache-2.0
-- Ristretto colorscheme for Neovim via Monokai Pro (ristretto filter).
-- Copied to ~/.config/nvim/theme.lua by `omacos theme set ristretto`.

require("monokai-pro").setup({
  filter = "ristretto",
})
vim.cmd.colorscheme("monokai-pro")
