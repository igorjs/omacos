-- SPDX-License-Identifier: Apache-2.0
-- Osaka Jade colorscheme for Neovim via solarized-osaka.nvim (craftzdog's jade-tinted Solarized port).
-- Copied to ~/.config/nvim/theme.lua by `omacos theme set osaka-jade`.

require("solarized-osaka").setup({
  transparent = false,
})
vim.cmd.colorscheme("solarized-osaka")
