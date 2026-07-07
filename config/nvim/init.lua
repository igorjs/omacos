-- SPDX-License-Identifier: Apache-2.0
vim.g.mapleader = " "
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.guicursor = "a:block-blinkon0"
vim.opt.clipboard = "unnamedplus"

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  { "folke/tokyonight.nvim", lazy = false, priority = 1000 },
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate",
    opts = { highlight = { enable = true }, ensure_installed = {
      "lua","vim","vimdoc","bash","python","javascript","typescript","tsx",
      "go","gomod","rust","json","yaml","toml","markdown","markdown_inline",
      "html","css","dockerfile","gitcommit" } },
    config = function(_, opts) require("nvim-treesitter.configs").setup(opts) end },
  { "mason-org/mason.nvim", opts = {} },
  { "mason-org/mason-lspconfig.nvim",
    opts = { ensure_installed = {
      "basedpyright","ruff","vtsls","gopls","rust_analyzer","lua_ls","bashls" } } },
  { "neovim/nvim-lspconfig" },
  { "saghen/blink.cmp", version = "^1", opts = {
      keymap = { preset = "super-tab" },
      sources = { default = { "lsp", "path", "snippets", "buffer" } } } },
})

vim.lsp.enable({ "basedpyright","ruff","vtsls","gopls","rust_analyzer","lua_ls","bashls" })

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local b = ev.buf
    local map = function(k, fn) vim.keymap.set("n", k, fn, { buffer = b }) end
    map("gd", vim.lsp.buf.definition)
    map("K", vim.lsp.buf.hover)
    map("<leader>rn", vim.lsp.buf.rename)
    map("<leader>ca", vim.lsp.buf.code_action)
    map("[d", function() vim.diagnostic.jump({ count = -1 }) end)
    map("]d", function() vim.diagnostic.jump({ count = 1 }) end)
  end,
})

pcall(dofile, vim.fn.stdpath("config") .. "/theme.lua")
